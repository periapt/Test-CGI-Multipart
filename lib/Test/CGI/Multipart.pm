package Test::CGI::Multipart;

use warnings;
use strict;
use Carp;
use UNIVERSAL::require;
use Params::Validate qw(:all);
use MIME::Entity;
use Readonly;

use version; our $VERSION = qv('0.0.1');

# Module implementation here

# Parameter specs
# Note the purpose of these spcs is to protect our data structures.
# It should not protect the code that will be tested
# as that must look after itself.
Readonly my $NAME_SPEC => {type=>SCALAR};
Readonly my $VALUE_SPEC => {type=>SCALAR|ARRAYREF};
Readonly my $CGI_SPEC => {
    type=>SCALAR,
    default=>'CGI',
    regex=> qr{
                \A              # start of string
                (?:
                    \w          
                    |(?:\:\:)   # Module name separator
                )+
                \z              # end of string
    }xms
};
Readonly my $TYPE_SPEC => {
    type=>SCALAR,
    optional=>1,
    regex=> qr{
                \A              # start of string
                [\w\-]+         # major type
                \/              # MIME type separator
                [\w\-]+         # sub-type
                \z              # end of string
    }xms
};
Readonly my $FILE_SPEC => {
    type=>SCALAR,
    optional=>1,
};
Readonly my $MIME_SPEC => {
    type=>OBJECT,
    isa=>'MIME::Entity',
};

sub new {
    my $class = shift;
    my $self = {
        file_index=>0,
        params=>{},
    };
    bless $self, $class;
    return $self;
}

sub set_param {
    my $self = shift;
    my %params = validate(@_, {name=>$NAME_SPEC, value=>$VALUE_SPEC});
    my @values  = ref $params{value} eq 'ARRAY'
                ? @{$params{value}}
                : $params{value}
    ;
    $self->{params}->{$params{name}} = \@values;
    return;
}

sub upload_file {
    my $self = shift;
    my %params = validate(@_, {
                    name=>$NAME_SPEC,
                    value=>$VALUE_SPEC,
                    file=>$FILE_SPEC,
                    type=>$TYPE_SPEC
    });
    my $name = $params{name};

    if (!exists $self->{params}->{$name}) {
        $self->{params}->{$name} = {};
    }
    if (ref $self->{params}->{$name} ne 'HASH') {
        croak "mismatch: is $name a file upload or not";
    }

    my $file_index = $self->{file_index};

    $self->{params}->{$name}->{$file_index} = \%params;

    $self->{file_index}++;

    return;
}

sub get_param {
    my $self = shift;
    my %params = validate(@_, {name=>$NAME_SPEC});
    my $name = $params{name};
    if (ref $self->{params}->{$name} eq 'HASH') {
        return values %{$self->{params}->{$name}};
    }
    return @{$self->{params}->{$name}};
}

sub get_names {
    my $self = shift;
    return keys %{$self->{params}};
}

sub create_cgi {
    use autodie qw(open);
    my $self = shift;
    my %params = validate(@_, {cgi=>$CGI_SPEC});

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
    open(STDIN, '<', \$mime_string);
    binmode STDIN;

    $params{cgi}->require;
    my $cgi = $params{cgi}->new;
    return $cgi;
}

sub _mime_data {
    my $self = shift;

    my $mime = $self->_create_multipart;
    foreach my $name ($self->get_names) {
        my $value = $self->{params}->{$name};
        if (ref($value) eq "ARRAY") {
            foreach my $v (@$value) {
                $self->_attach_field(
                    mime=>$mime,
                    name=>$name,
                    value=>$v,
                );
            }
        }
        elsif(ref($value) eq "HASH") {
            $self->_encode_upload(mime=>$mime,values=>$value);
        }
        else {
            croak "unexpected data structure";
        }
    }

    # Required so at least we don't have an empty MIME structure.
    # And lynx at least does send it.
    # CGI.pm seems to strip it out where as the others seem to pass it on.
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
                mime => $MIME_SPEC,
                name=>$NAME_SPEC,
                value=>$VALUE_SPEC,
        }
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

sub _encode_upload {
    my $self = shift;
    my %params = validate(@_, {
                mime => $MIME_SPEC,
                values => {type=>HASHREF}
    });
    my %values = %{$params{values}};
    if (keys %values > 1) {
        croak "not implemented yet";
    }
    else {
        my $key = (keys %values)[0];
        $self->_attach_file(
            mime=>$params{mime},
            %{$values{$key}}
        );
    }
    return;
}

sub _attach_file {
    my $self = shift;
    my %params = validate(@_, {
                mime => $MIME_SPEC,
                file=>$FILE_SPEC,
                type=>$TYPE_SPEC,
                name=>$NAME_SPEC,
                value=>$VALUE_SPEC,
        }
    );
    my %attach = (
        'Content-Disposition'=>"form-data; name=\"$params{name}\"",
        Data=>$params{value},
    );
    if ($params{file}) {
        $attach{'Content-Disposition'} .= "; filename=\"$params{file}\"";
    }
    if ($params{type}) {
        $attach{Type} = $params{type};
    }
    $params{mime}->attach(
        %attach
    );
    return;
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
    $tcm->upload_file(name=>'file1',file=>$file_made_earlier);
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

=item C<cgi>

This option defines the CGI module. It should be a scalar consisting only
of alphanumeric characters and C<::>. It defaults to 'CGI'.

=item C<name>

This is the name of form parameter. It must be a scalar.

=item C<value>

This is the value of the form parameter. It should either be
a scalar or an array reference of scalars.

=item C<file_name>

Where a form parameter represents a file, this is the name of that file.
It is optional since it is possible that a browser may not send it.

=item C<size>

This specifies the size of the file to be created. It is always an optional parameter.

=item C<width>, C<height>

The dimensions of image files.

=item C<type>

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

=item A pipe is created. The far end of the pipe is attached to our standard input. And the MIME content is pushed through the pipe.

=item The CGI object is created and returned.

=back

As far as I can see this simulates what happens when a CGI script processes a multi-part POST form. One can specify a different CGI class using the C<cgi> named parameter.

=head2 set_param

This can be used to set a single form parameter. It takes two named arguments C<name> and C<value>. Note that this method overrides any previous settings including file uploads.

=head2 get_param

This retrieves a single form parameter. It takes a single named
parameter: C<name>. The data returned will be a list either of scalar
values or (in the case of a file upload) of HASHREFs. The HASHREFs would have
the following fields: C<file>, C<value> and C<type> representing the file name, the content and the MIME type respectively.

=head2 get_names

This returns a list of stashed parameter names.

=head2 upload_file

This method takes two mandatory named parameters: C<name> and C<value> and two optional parameters C<type> and C<file>. Unlike the C<set_param> method this will not override previous settings for this parameter but will add. However setting a normal parameter and then n upload on the same name will throw an error.

=head1 DIAGNOSTICS

=over

=item C<< unexpected data structure >>

During the construction of the MIME data, the internal
data structure turned out to have unexpected features.
Since we control that data structure that should not happen.

=item C<< mismatch: is %s a file upload or not >>

The parameter was being used for both for file upload and normal
parameters.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Test::CGI::Multipart requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

I would like to get this working with L<CGI::Lite::Request> and L<Apache::Request> if that makes sense. So far I have not managed that.

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
