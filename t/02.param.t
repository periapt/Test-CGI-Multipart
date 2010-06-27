#!perl -wT
use Test::More tests => 9;
use Test::CGI::Multipart;
use Readonly;

my $tcm = Test::CGI::Multipart->new;
isa_ok($tcm, 'Test::CGI::Multipart', 'object created');
is($tcm->get_cgi, 'CGI', 'default CGI class');

ok(!defined $tcm->set_param(
        name=>'first_name',
        value=>'Jim'),
    'setting parameter');
is($tcm->get_param(name=>'first_name'), 'Jim', 'get param');
my @names= $tcm->get_names;
is_deeply(\@names, ['first_name'], 'first name deep');

Readonly my $PETS => ['Rex','Oscar','Bidgie','Fish'];
ok(!defined $tcm->set_param(
        name=>'pets',
        value=>$PETS),
    'setting parameter');
is($tcm->get_param(name=>'pets'), $PETS, 'get param');
@names= sort $tcm->get_names;
is_deeply(\@names, ['first_name','pets'], 'names deep');

isa_ok($tcm->create_cgi, 'CGI', 'created CGI object okay');
