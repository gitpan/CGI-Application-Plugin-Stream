package CGI::Application::Plugin::Stream;

use 5.006;
use strict;
use warnings;

use CGI::Application 3.21;
use File::Basename;
require Exporter;
use vars (qw/@ISA @EXPORT_OK/);
@ISA = qw(Exporter);

@EXPORT_OK = qw(stream stream_file);

our $VERSION = '3.00_1';

sub stream {
    my ( $self, $file_or_fh, $bytes ) = @_;

    $bytes ||= 1024;

    # Use unbuffered output, but return the state of $| to its previous state when we are done. 
    local $| = 1;

    my ($fh, $basename);
    my  $size = (stat( $file_or_fh ))[7];

    # If we have a file path
    if ( ref( \$file_or_fh ) eq 'SCALAR' ) {
        # They passed along a scalar, pointing to the path of the file
        # So we need to open the file
        open($fh,"<$file_or_fh"  ) || die "failed to open file: $file_or_fh: $!";
        # Now let's go binmode (Thanks, William!)
        binmode $fh;
        $basename = basename( $file_or_fh );
    } 
    # We have a file handle.
    else {
        $fh = $file_or_fh;
        $basename = 'FILE';
    }

    # Use FileHandle to make File::MMagic happy;
    # bless the filehandle into the FileHandle package to make File::MMagic happy
    require FileHandle;
    bless $fh,  "FileHandle";

    # Check what headers the user has already set and 
    # don't override them. 
    my %existing_headers = $self->header_props();

    # Check for a existing type header set with or without a hypheout a hyphen
    unless ( $existing_headers{'-type'} ||  $existing_headers{'type'} ) {
    	my $mime_type;

        eval {
            require File::MMagic;
            my $magic = File::MMagic->new(); 
            $mime_type = $magic->checktype_filehandle($fh);
        };
        warn "Failed to load File::MMagic module to determine mime type: $@" if $@;
        
        # Set Default
        $mime_type ||= 'application/octet-stream';

        $self->header_add('-type' => $mime_type);
    }


    unless ( $existing_headers{'Content_Length'} 
        ||   $existing_headers{'-Content_Length'} 
        ) {
        $self->header_add('-Content_Length' => $size);
    }

    unless ( $existing_headers{'-attachment'}
        ||   $existing_headers{'attachment'}
        ||   grep( /-?content-disposition/i, keys %existing_headers )
        ) {
        $self->header_add('-attachment' => $basename);
    }

    $self->header_type( 'none' );
    print $self->query->header( $self->header_props() );

    # This reads in the file in $byte size chunks
    my $first;
    # File::MMagic may have read some of the file, so seek back to the beginning
    seek($fh,0,0);
    while ( read( $fh, my $buffer, $bytes ) ) {
		print $buffer;
    }

    print '';	# print a null string at the end
    close ( $fh );
    return 1;
}

# The old way. Requires manually calling error_mode() if there's a problem,
# but error_mode() won't have access to "$@"
sub stream_file {
    my $self = shift;
    my $out;

    # Perhaps bad style to not use a method call here,
    # But this keeps the legacy case working, where only stream_file() was exported. 
    eval { stream($self,@_) }; 

    # Starting with 3.0, we warn if there's a problem opening the file
    # instead of ignoring the error. 
    if ($@) {
        warn $@;
        return 0;
    }
    else {
        return 1;
    }
}

1;
__END__
=head1 NAME

CGI::Application::Plugin::Stream - CGI::Application Plugin for streaming files

=head1 SYNOPSIS

  use CGI::Application::Plugin::Stream 'stream';

  sub runmode {
    # ...

    # Set up any headers you want to set explicitly
    # using header_props() or header_add() as usual

    #...

    return $self->stream($file);
  }

=head1 DESCRIPTION

This plugin provides a way to stream a file back to the user.

This is useful if you are creating a PDF or Spreadsheet document dynamically to
deliver to the user.

The file is read and printed in small chunks to keep memory consumption down.

The C<stream()> method should be run as the last call in a a run mode, and
affects the HTTP response headers.  If you pass along a filehandle, we'll make
sure to close it for you.

=head1 METHODS

=head2 stream()

  $self->stream($fh);
  $self->stream( '/path/to/file',2048);

This method can take two parameters, the first the path to the file
or a filehandle and the second, an optional number of bytes to determine
the chunk size of the stream. It defaults to 1024.

It will either stream a file to the user or die if it fails, perhaps
because it couldn't find the file you referenced. 

We highly recommend you provide a file name if passing along a filehandle, as we
won't be able to deduce the file name, and will use 'FILE' by default. Example:

 $self->header_add( -attachment => 'my_file.txt' );

With both a file handle or file name, we will try to determine the correct
content type by using L<File::MMagic>. A default of 'application/octet-stream'
will be used if File::MMagic can't figure it out. 

The size will be calculated and added to the headers as well. 

Again, you can set these explicitly if you want as well:

 $self->header_add(
      -type		        =>	'text/plain',
      -Content_Length	=>	42, # bytes
 );

=head2 stream_file()  ( deprecated ) 

This works the same as stream(), but returns false to indicate a problem.

This is included because this was the original API. It does not give you
access to "$@" if there is a problem. 

=head1 AUTHOR

Jason Purdy, E<lt>Jason@Purdy.INFOE<gt>,
with inspiration from Tobias Henoeckl
and tremendous support from the cgiapp mailing list.

Mark Stosberg also contributed to this module.

=head1 SEE ALSO

L<CGI::Application>,
L<http://www.cgi-app.org>,
L<CGI.pm/"CREATING A STANDARD HTTP HEADER">,
L<http://www.mail-archive.com/cgiapp@lists.erlbaum.net/msg02660.html>,
L<File::Basename>,
L<perlvar/$E<verbar>>

=head1 LICENSE

Copyright (C) 2004-2005 Jason Purdy, E<lt>Jason@Purdy.INFOE<gt>

This library is free software. You can modify and or distribute it under the same terms as Perl itself.

=cut
