use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'				=> 'CGI::Application::Plugin::Stream',
    'VERSION_FROM'		=> 'Stream.pm', # finds $VERSION
    'PREREQ_PM'			=>	{
								'File::Basename'	=>	1.0,
								'CGI::Application'	=>	3.21
							},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM	=> 'Stream.pm', # retrieve abstract from module
       AUTHOR			=> 'Jason Purdy <Jason@Purdy.INFO>') : ()),
);
