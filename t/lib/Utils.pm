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

sub get_expected {
    my $tcm = shift;
    my $name = shift;
    my @expected = $tcm->get_param(name=>$name);
    if (scalar(@expected) == 0) {
        croak 'where is the test data?';
    }
    my $is_file_upload = (ref $expected[0] eq 'HASH');
    if ($is_file_upload) {
        foreach my $e (@expected) {
            if (!exists $e->{type}) {
                $e->{type} = 'text/plain';
            }
        }
    }
    return \@expected;
}

sub get_actual_upload {
    my $cgi = shift;
    my $name = shift;

    my @got;
    my $class = ref $cgi;

    if ($class eq 'CGI::Minimal') {
        my @fnames = $cgi->param_filename($name);
        my @data = $cgi->param($name);
        my @types = $cgi->param_mime($name);
        foreach my $i (@0..$#fnames) {
            push @got, {
                file=>$fnames[$i],
                value=>$data[$i],
                type=>$types[$i],
                name=>$name
            }
        }
    }
    else {
        my @fh = $cgi->upload($name);
        foreach my $fh (@fh) {
            if ($fh) {
                my $io = $fh->handle;
                my $data = slurp($io);
                $io->close;
                my $file = $cgi->param($name);
                my $type = $cgi->uploadInfo($file)->{'Content-Type'};
                push @got, {
                    file=>$file,
                    value=>$data,
                    type=>$type,
                    name=>$name
                };
            }
            else {
                return undef;
            }               
        }
    }

    return \@got;
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
        foreach my $e (@expected) {
            if (!exists $e->{type}) {
                $e->{type} = 'text/plain';
            }
        }

        my @fh = $cgi->upload($name);
        foreach my $fh (@fh) {
            if ($fh) {
                my $io = undef;
                if (ref $fh eq 'IO::File') {
                    $io = $fh;
                }
                else {
                    $io = $fh->handle;
                }
                my $data = slurp($io);
                $io->close;
                my $file = $cgi->param($name);
                my $type = $cgi->uploadInfo($file)->{'Content-Type'};
                push @got, {
                    file=>$file,
                    value=>$data,
                    type=>$type,
                    name=>$name
                };
            }
            else {
                return (undef, \@expected);
            }
        }
    }
    else {
        @got = $cgi->param($name);
    }
    return (\@got, \@expected);
}

sub get_actual_versus_expected_minimal {
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
        foreach my $e (@expected) {
            if (!exists $e->{type}) {
                $e->{type} = 'text/plain';
            }
        }

        my @fnames = $cgi->param_filename($name);
        my @data = $cgi->param($name);
        my @types = $cgi->param_mime($name);
        foreach my $i (@0..$#fnames) {
            push @got, {
                file=>$fnames[$i],
                value=>$data[$i],
                type=>$types[$i],
                name=>$name
            }
        }
    }
    else {
        @got = $cgi->param($name);
    }
    return (\@got, \@expected);
}

1
