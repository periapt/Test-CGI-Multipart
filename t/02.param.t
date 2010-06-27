#!perl -wT
use Test::More tests => 4;
use Test::CGI::Multipart;

my $tcm = Test::CGI::Multipart->new;
isa_ok($tcm, 'Test::CGI::Multipart', 'object created');
is($tcm->get_cgi, 'CGI', 'default CGI class');

ok(!defined $tcm->set_param('first_name'=>'Jim'), 'setting parameter');
isa_ok($tcm->create_cgi, 'CGI', 'created CGI object okay');
