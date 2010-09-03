#!perl -w
use strict;
use warnings;
use Test::More;
use Test::CGI::Multipart;
use Test::CGI::Multipart::Gen::Text;
use Readonly;
use lib qw(t/lib);
use Utils;
srand(0);

eval {require Text::Lorem;};
if ($@) {
    my $msg = "This test requires Text::Lorem";
    plan skip_all => $msg;
}

Readonly my $PETS => ['Rex','Oscar','Bidgie','Fish'];
Readonly my $NAMES => ['first_name', 'pets', 'sentences', 'uninteresting', 'words'];
my @cgi_modules = Utils::get_cgi_modules;
plan tests => 15+(2+scalar @$NAMES)*@cgi_modules;

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
    name=>'uninteresting',
    file=>'other.blah',
    value=>'Fee Fi Fo Fum',
), 'uploading other file');
@names= sort $tcm->get_names;
is_deeply(\@names, ['first_name', 'pets', 'uninteresting'], 'names deep');

ok(!defined $tcm->upload_file(
    name=>'words',
    file=>'words.txt',
    words=>5,
    sentences=>2,
    paragraphs=>2,
), 'uploading other file');
@names= sort $tcm->get_names;
is_deeply(\@names, ['first_name', 'pets', 'uninteresting', 'words'], 'names deep');
is_deeply(Utils::get_expected($tcm, 'words'), [{name=>'words',value=>'ipsum placeat explicabo accusamus in',file=>'words.txt',type=>'text/plain'}], 'words');

ok(!defined $tcm->upload_file(
    name=>'sentences',
    file=>'sentences.txt',
    sentences=>2,
    paragraphs=>2,
), 'uploading other file');
@names= sort $tcm->get_names;
is_deeply(\@names, $NAMES);
is_deeply(Utils::get_expected($tcm, 'sentences'), [{name=>'sentences',value=>'Eligendi consequatur officiis maxime ducimus ex minus quaerat. Omnis nulla in porro vitae blanditiis.',file=>'sentences.txt',type=>'text/plain'}], 'sentences');


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
    is_deeply(\@names, $NAMES, 'names deep');
    foreach my $name (@names) {
        my $expected = Utils::get_expected($tcm, $name);
        my $got = undef;
        if (ref $expected->[0] eq 'HASH') {
            $got = Utils::get_actual_upload($cgi, $name);
        }
        else {
            my @got = $cgi->param($name);
            $got = \@got;
        }

        is_deeply($got, $expected, $name);
    }

}


