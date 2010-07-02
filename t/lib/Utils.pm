package Utils;
use Readonly;
Readonly @CLASSES => (
    'CGI::Minimal',
    'CGI::Simple',
);

# TODO:
# Can we work with CGI::Lite::Request, Apache::Request?

sub get_cgi_modules {
    my @cgi_modules = (undef, 'CGI');
    foreach $class (@CLASSES) {
        eval "require $class";
        if (!$@) {
            push @cgi_modules, $class;
        }
    }
    return @cgi_modules;
}

1
