package CGI::Application::Plugin::Stream;

use 5.006;
use strict;
use warnings;

use CGI::Application 3.21;
use File::Basename;

require Exporter;

our @EXPORT = qw(
	stream_file
);
sub import { goto &Exporter::import }

our $VERSION = '1.00';

sub stream_file {
    my ( $self, $file_or_fh, $header, $fh, $basename );

    $self = shift;
    ( $file_or_fh, $header ) = @_;

    if ( ref( \$file_or_fh ) eq 'SCALAR' ) {
		# They passed along a scalar, pointing to the path of the file
		# So we need to open the file
		open( $fh, "$file_or_fh" ) || return 0;
		$basename = basename( $file_or_fh );
    } else {
		$fh = $file_or_fh;
		$basename = 'FILE';
    }

    if ( ! $header ) {
		$header = $self->query->header(
			-type		=>	'application/octet-stream',
			-size		=>	-s $fh,
			-attachment	=>	$basename,
			);
    }

	$self->header_type( 'none' );
    print $header;

    # This reads in the file in 1KB pieces ... should I parameterize the size?
    while ( read( $fh, my $buffer, 1024 ) ) {
		print $buffer;
    }

    print '';	# print a null string at the end
    close ( $fh );
    return 1;
}

1;
__END__
=head1 NAME

CGI::Application::Plugin::Stream - CGI::Application Plugin for streaming files

=head1 SYNOPSIS

  use CGI::Application::Plugin::Stream;

  sub runmode {
    # ...
    return $self->stream_file( $file )
      or $self->error_mode();
  }

=head1 DESCRIPTION

This plugin provides a way to stream a file back to the user from
within your runmode.  This would be useful if you have a button or
link on a page somewhere to prompt for a download.  Then when the
user clicks the link/button, it calls this runmode, which will
prompt a download session, delivering the file to the user through
the browser's download functionality.

This plugin will also refrain from slurping up the file, rather
reading it in, in 1KB blocks, which will keep memory consumption
down.

This plugin will return a false value if there was some problem
(most likely access to the file), which you can use to trigger
an error runmode to handle politely for the user.

This plugin is a consumer, as in your runmode shouldn't try to do
any output or anything afterwards.  This plugin affects the HTTP
response headers, so anything you do afterwards will probably not
work.  If you pass along a filehandle, we'll make sure to close it
for you.

It's recommended that you increment $| (or set it to 1), which will
autoflush the buffer as your application is streaming out the file.

=head1 METHODS

=head2 stream_file

This method can take two parameters, the first the path to the file
or a filehandle and the second, an optional CGI.pm header():

  $self->stream_file(
	'/path/to/file',
	$self->query->header(
	    -type	=>	'text/xml'
	  )
    );

  - or -

  $self->stream_file(
	$fh,
	$self->query->header(
	    -type	=>	'text/xml'
	  )
    );

We highly recommend you provide a header if passing along a filehandle,
as we won't be able to deduce a lot of information from the filehandle
(such as size and basename).  Otherwise, if you pass along a scalar
(pointing to the path of the file) and do not pass along a header, we
will use the as the default:

  CGI->header(
      -type		=>	'application/octet-stream',
      -size		=>	-s $file,
      -attachment	=>	basename( $file )
    );

In the case of the filehandle and if you don't pass along a header,
we will use this as the default:

  CGI->header(
      -type		=>	'application/octet-stream',
      -size		=>	-s $fh,
      -attachment	=>	'FILE'
    );

That's a bad default (because we can't get the original filename from
the filehandle), as it will download a non-descript file named "FILE"
to the user's computer.  So please construct and pass along a header.

=head1 TODO

This module doesn't really have any tests, so that needs to be done at
some point.  Also, I'm thinking we should add a 3rd parameter for
specifying the block size of the stream (from the 1KB default).

=head1 AUTHOR

Jason Purdy, E<lt>Jason@Purdy.INFOE<gt>,
with inspiration from Tobias Henoeckl
and tremendous support from the cgiapp mailing list.

=head1 SEE ALSO

L<CGI::Application>,
L<http://www.cgi-app.org>,
L<CGI.pm/"CREATING A STANDARD HTTP HEADER">,
L<http://www.mail-archive.com/cgiapp@lists.erlbaum.net/msg02660.html>,
L<File::Basename>,
L<perlvar/$E<verbar>>

=head1 LICENSE

Copyright (C) 2004 Jason Purdy, E<lt>Jason@Purdy.INFOE<gt>

This library is free software. You can modify and or distribute it under the same terms as Perl itself.

=cut
