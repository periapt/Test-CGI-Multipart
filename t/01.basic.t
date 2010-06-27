#!perl -wT
use Test::More tests => 3;
use Test::CGI::Multipart;

my $tcm = Test::CGI::Multipart->new;
isa_ok($tcm, 'Test::CGI::Multipart');
is($tcm->get_cgi, 'CGI');
isa_ok($tcm->create_cgi, 'CGI');
