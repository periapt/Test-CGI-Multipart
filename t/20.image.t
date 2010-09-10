#!perl -w
use strict;
use warnings;
use Test::More;
use Test::CGI::Multipart;
use Test::CGI::Multipart::Gen::Image;
use Readonly;
use lib qw(t/lib);
use Utils;
use autodie qw(open close);
Readonly my $PETS => ['Rex','Oscar','Bidgie','Fish'];

my @cgi_modules = Utils::get_cgi_modules;
plan tests => 37; #7+3*@cgi_modules;

my $tcm = Test::CGI::Multipart->new;
isa_ok($tcm, 'Test::CGI::Multipart');

ok(!defined $tcm->set_param(
    name=>'first_name',
    value=>'Jim'),
'setting parameter');
my @values = $tcm->get_param(name=>'first_name');
is_deeply(\@values, ['Jim'], 'get param');
my @names= $tcm->get_names;
is_deeply(\@names, ['first_name'], 'first name deep');

ok(!defined $tcm->set_param(
    name=>'pets',
    value=>$PETS),
'setting parameter');
@values = $tcm->get_param(name=>'pets');
is_deeply(\@values, $PETS, 'get param');
@names= sort $tcm->get_names;
is_deeply(\@names, ['first_name','pets'], 'names deep');

ok(!defined $tcm->upload_file(
        name=>'image',
        width=>400,
        height=>250,
        instructions=>[
            ['bgcolor','red'],
            ['fgcolor','blue'],
            ['rectangle',30,30,100,100],
            ['moveTo',80,210],
            ['fontsize',20],
            ['string','Helloooooooooooo world!'],
        ],
        file=>'cleopatra.doc',
        type=>'image/jpeg'
), 'image');
@names= sort $tcm->get_names;
is_deeply(\@names, ['first_name', 'image', 'pets'], 'names deep');

foreach my $class (@cgi_modules) {

    if ($class) {
        diag "Testing with $class";
    }

    my $cgi = undef;
    if ($class) {
        $cgi = $tcm->create_cgi(cgi=>$class);
    }
    else {
        $cgi = $tcm->create_cgi;
    }
    isa_ok($cgi, $class||'CGI', 'created CGI object okay');

    @names = grep {$_ ne '' and $_ ne '.submit'} sort $cgi->param;
    is_deeply(\@names, ['first_name', 'image', 'pets'], 'names deep');
    foreach my $name (@names) {
        my $expected = Utils::get_expected($tcm, $name);
        my $got = undef;
        if (ref $expected->[0] eq 'HASH') {
            $got = Utils::get_actual_upload($cgi, $name);
            is($got->[0]->{type}, $expected->[0]->{type}, 'type');
            is($got->[0]->{name}, $expected->[0]->{name}, 'name');
            is($got->[0]->{file}, $expected->[0]->{file}, 'file');
            is(substr($got->[0]->{value},0,100), substr($expected->[0]->{value},0,100), 'value');
            open my $fh, '>', '/home/nicholas/a.txt';
            print {$fh} $got->[0]->{value};
            close $fh;
            open $fh, '>', '/home/nicholas/b.txt';
            print {$fh} $expected->[0]->{value};
            close $fh;
        }
        else {
            my @got = $cgi->param($name);
            $got = \@got;
            is_deeply($got, $expected);
        }
        #is_deeply($got, $expected, $name);
    }

}


