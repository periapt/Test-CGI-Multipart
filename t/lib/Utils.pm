package Utils;
use Readonly;
use Carp;
use Perl6::Slurp;
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

sub get_actual_versus_expected {
    my $tcm = shift;
    my $cgi = shift;
    my $name = shift;
    my @expected = $tcm->get_param(name=>$name);
    if (scalar(@expected) == 0) {
        croak 'where is the test data?';
    }
    my $is_file_upload = (ref $expected[0] eq 'HASH');
    my @got;
    if ($is_file_upload) {
        if (!exists $expected[0]->{type}) {
            $expected[0]->{type} = 'text/plain';
        }

        my $fh = $cgi->upload($name);
        if ($fh) {
            my $io = $fh->handle;
            my $data = slurp($io);
            $io->close;
            my $file = $cgi->param($name);
            my $type = $cgi->uploadInfo($file)->{'Content-Type'};
            push @got, {file=>$file, value=>$data, type=>$type, name=>$name};
        }
        else {
            return (undef, \@expected);
        }
    }
    else {
        @got = $cgi->param($name);
    }
    return (\@got, \@expected);
}

1
