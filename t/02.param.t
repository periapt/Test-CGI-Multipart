#!perl -wT
use Test::More tests => 5;
use Test::CGI::Multipart;

my $tcm = Test::CGI::Multipart->new;
isa_ok($tcm, 'Test::CGI::Multipart', 'object created');
is($tcm->get_cgi, 'CGI', 'default CGI class');

ok(!defined $tcm->set_param(
        name=>'first_name',
        value=>'Jim'),
    'setting parameter');
is($tcm->get_param(name=>'first_name'), 'Jim', 'get param');
isa_ok($tcm->create_cgi, 'CGI', 'created CGI object okay');
