#!perl -w
use strict;
use warnings;
use Test::More;
use Test::CGI::Multipart;
use Readonly;
use lib qw(t/lib);
use Utils;
Readonly my $PETS => ['Rex','Oscar','Bidgie','Fish'];

my @cgi_modules = Utils::get_cgi_modules;
plan tests => 9+5*scalar(@cgi_modules);

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
    name=>'files',
    file=>'doo_doo.blah',
    value=>'Blah, Blah, Blah,....'),
'uploading blah file');
@names= sort $tcm->get_names;
is_deeply(\@names, ['files', 'first_name', 'pets'], 'names deep');


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
    is_deeply(\@names, ['files', 'first_name','pets'], 'names deep');
    foreach my $name (@names) {
        my @got = $cgi->param($name);
        my @expected = $tcm->get_param(name=>$name);
        if (ref($expected[0]) eq "HASH") {
            foreach my $i (0..$#expected) {
                $expected[$i] = $expected[$i]->{value};
            }
        }
        is_deeply(\@got, \@expected, $name);
    }
}
