#!perl -w
use Test::More tests => 12;
use Test::CGI::Multipart;
use Readonly;
use lib qw(/home/nicholas/git/CGI.pm/lib);
use CGI qw(read_multipart);
CGI->compile();


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

my $cgi = $tcm->create_cgi;
isa_ok($cgi, 'CGI', 'created CGI object okay');

@names = sort $cgi->param;
is_deeply(\@names, ['first_name','pets'], 'names deep');
foreach my $name (@names) {
    my @values = $cgi->param($name);
    my $value = scalar(@values) == 1 ? $values[0] : \@values;
    is_deeply($value, $tcm->get_param(name=>$name), $name);
}

