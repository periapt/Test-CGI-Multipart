use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::CGI::Multipart',
    license             => 'perl',
    dist_author         => 'Nicholas Bamber <nicholas@periapt.co.uk>',
    dist_version_from   => 'lib/Test/CGI/Multipart.pm',
    build_requires => {
        'Test::More' => 0,
    }
    requires => {
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Test-CGI-Multipart-*' ],
);

$builder->create_build_script();
