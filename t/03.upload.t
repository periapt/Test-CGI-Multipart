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
plan tests => 8+4*scalar(@cgi_modules);

my $tcm = Test::CGI::Multipart->new;
isa_ok($tcm, 'Test::CGI::Multipart');

ok(!defined $tcm->set_param(
    name=>'first_name',
    value=>'Jim'),
'setting parameter');
is($tcm->get_param(name=>'first_name'), 'Jim', 'get param');
my @names= $tcm->get_names;
is_deeply(\@names, ['first_name'], 'first name deep');

ok(!defined $tcm->set_param(
    name=>'pets',
    value=>$PETS),
'setting parameter');
is($tcm->get_param(name=>'pets'), $PETS, 'get param');
@names= sort $tcm->get_names;
is_deeply(\@names, ['first_name','pets'], 'names deep');

ok(!defined $tcm->upload_file(
    name=>'files',
    type=>'application/blah',
    file=>'doo_doo.blah',
    value=>'Blah, Blah, Blah,....'),
'uploading blah file');


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
    is_deeply(\@names, ['first_name','pets'], 'names deep');
    foreach my $name (@names) {
        my @values = $cgi->param($name);
        my $value = scalar(@values) == 1 ? $values[0] : \@values;
        is_deeply($value, $tcm->get_param(name=>$name), $name);
    }
}
