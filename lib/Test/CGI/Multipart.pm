package Test::CGI::Multipart;

use warnings;
use strict;
use Carp;
use UNIVERSAL::require;
use Params::Validate qw(:all);
use MIME::Entity;

use version; our $VERSION = qv('0.0.1');


# Module implementation here

sub new {
    my $class = shift;
    my $self = {
        params=>{},
    };
    bless $self, $class;
    return $self;
}

sub set_param {
    my $self = shift;
    my %params = validate(@_, {name=>{type=>SCALAR}, value=>1});
    $self->{params}->{$params{name}} = $params{value};
    return;
}

sub get_param {
    my $self = shift;
    my %params = validate(@_, {name=>{type=>SCALAR}});
    return $self->{params}->{$params{name}};
}

sub get_names {
    my $self = shift;
    return keys %{$self->{params}};
}

sub create_cgi {
    my $self = shift;
    my %params = validate(@_, {cgi=>{type=>SCALAR,default=>'CGI'}});

    my $mime = $self->_mime_data;
    my $mime_string = $mime->stringify;
    $mime_string =~ s{
                        \n      # MIME::Tools returns this rather than CRLF
                    }{\015\012}xmsg;
    my $boundary = $mime->head->multipart_boundary;

    local $ENV{REQUEST_METHOD}='POST';
    local $ENV{CONTENT_TYPE}="multipart/form-data; boundary=$boundary";
    local $ENV{CONTENT_LENGTH}=length($mime_string);

    local *STDIN;
    open(STDIN, '<', \$mime_string) or croak "could not open MIME handle";
    binmode STDIN;

    $params{cgi}->require;
    my $cgi = $params{cgi}->new;
    return $cgi;
}

sub _mime_data {
    my $self = shift;

    my $mime = $self->_create_multipart;
    foreach my $name ($self->get_names) {
        my $value = $self->get_param(name=>$name);
        if (ref($value) eq "") {
            $self->_attach_field(
                mime=>$mime,
                name=>$name,
                value=>$value,
            );
        }
        elsif(ref($value) eq "ARRAY") {
            foreach my $v (@$value) {
                $self->_attach_field(
                    mime=>$mime,
                    name=>$name,
                    value=>$v,
                );
            }
        }
    }

    $self->_attach_field(
        mime=>$mime,
        name=>'.submit',
        value=>'Submit',
    );

    return $mime;
}

sub _attach_field {
    my $self = shift;
    my %params = validate(@_, {
                mime => {isa=>'MIME::Entity'},
                name=>{type=>SCALAR},
                value=>{type=>SCALAR}}
    );
    $params{mime}->attach(
        'Content-Disposition'=>"form-data; name=\"$params{name}\"",
        Data=>$params{value},
    );
    return;
}

sub _create_multipart {
    my $self = shift;
    my %params = validate(@_, {});
    return MIME::Entity->build(
        'Type'=>"multipart/form-data",
    );
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Test::CGI::Multipart - Test posting of multi-part form data

=head1 VERSION

This document describes Test::CGI::Multipart version 0.0.1


=head1 SYNOPSIS

    use Test::CGI::Multipart;

    my $tcm = Test::CGI::Multipart;

    # specify the form parameters
    $tcm->set_param(name='email',value=>'jim@hacker.com');
    $tcm->set_param(name=>'pets',value=> ['Rex', 'Oscar', 'Bidgie', 'Fish']);
    $tcm->set_param(name=>'first_name',value=>'Jim');
    $tcm->set_param(name=>'last_name',value=>'Hacker');
    $tcm->upload_file(name=>'file1',file_name=>$file_made_earlier);
    $tcm->create_upload_file(
        name=>'file2',
        file_name=>'mega.txt',
        size=>1_000_000
    );
    $tcm->create_upload_image(
        name=>'file3',
        type=>'gif',
        # let's lie about the type to see if the code can spot it.
        file_name=>'my_image.jpg',
        width=>1000,
        height=>1000
    );

    # Behind the scenes this will fake the browser and web server behaviour
    # with regard to environment variables, MIME format and standard input.
    my $cgi = $tcm->create_cgi;

    # Okay now we have a CGI object which we can pass into the code 
    # that needs testing and run the form handling various tests.
  
=head1 DESCRIPTION

    It is quite difficult to write test code to capture the behaviour 
    of CGI or similar objects handling forms that include a file upload.
    Such code needs to harvest the parameters, build file content in MIME
    format, set the environment variables accordingly and pump it into the 
    the standard input of the required CGI object. This module attempts to
    encapsulate this in such a way, that the tester can concentrate on
    specifying what he is trying to test.

=head1 INTERFACE 

Several of the methods below take named parameters. For convenience we define those parameters here:

=over 

=item cgi

This option defines the CGI module.

=item name

This is the name of form parameter.

=item value

In simple cases the value of the form parameter.

=item file_name

Where a form parameter represents a file, this is the name of that file. If the method name includes the word "create" the file is to be created, otherwise it must exist and be readable.

=item size

This specifies the size of the file to be created. It is always an optional parameter.

=item width, height

The dimensions of image files.

=item type

The type of image files.

=back

=head2 new

An instance of this class might best be thought of as a "CGI object factory".
Currently the constructor takes no parameters.

=head2 create_cgi

This returns a CGI object created according to the specification encapsulated in the object. The exact mechanics are as follows:

=over

=item The parameters are packaged up in MIME format.

=item The environment variables are set locally.

=item A pipe is created. The far end of the pipe is attached to our standard input.

=item The CGI object is created and returned.

=back

One can specify a different CGI class using the C<cgi> named parameter.

=head2 set_param

This can be used to set a single form parameter. It takes two named arguments C<param> and C<value>.

=head2 get_param

This retrieves a single form parameter. It takes a single named parameter: C<name>.

=head2 get_names

This returns a list of stashed parameter names.

=head2 upload_file

This method takes two named parameters: C<param> and C<file_name>.

=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

Test::CGI::Multipart requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

This software is not tested and does not yet contain enough functionality
to meet even its most basic goals.

It is now at the point where it actually needs to grapple with MIME.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-test-cgi-multipart@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Nicholas Bamber  C<< <nicholas@periapt.co.uk> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Nicholas Bamber C<< <nicholas@periapt.co.uk> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
