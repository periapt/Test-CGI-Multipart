package Test::CGI::Multipart::Gen::Image;

use warnings;
use strict;
use Carp;
use Readonly;
use Test::CGI::Multipart;

use version; our $VERSION = qv('0.0.1');

# Module implementation here

Test::CGI::Multipart->register_callback(
    callback => sub {
        my $hashref = shift;

        # If the MIME type is not text/plain its not ours.
        return $hashref if $hashref->{type} !~ m{\Aimage/\w+\z}xms;

    
        return $hashref;
    }
);

1; # Magic true value required at end of module
__END__

=head1 NAME

Test::CGI::Multipart::Gen::Image - Generate image test data for multipart forms

=head1 VERSION

This document describes Test::CGI::Multipart::Gen::Image version 0.0.1


=head1 SYNOPSIS

    use Test::CGI::Multipart;
    use Test::CGI::Multipart::Gen::Image;

    my $tcm = Test::CGI::Multipart;

    # specify the form parameters
    $tcm->upload_file(
        name='cv',
        file=>'cv.doc',
        paragraphs=>6,
        type=>'text/plain'
    );
    $tcm->upload_file(
        name=>'sample_work',
        type=>'text/plain',
        value=>[
            'Blah Blah Blah....', 
            'To be or not to be.',
            'Are we there yet?',
        ],
        size=>2000
    );
    $tcm->set_param(name=>'first_name',value=>'Jim');
    $tcm->set_param(name=>'last_name',value=>'Hacker');

    # Behind the scenes this will fake the browser and web server behaviour
    # with regard to environment variables, MIME format and standard input.
    my $cgi = $tcm->create_cgi;

    # Okay now we have a CGI object which we can pass into the code 
    # that needs testing and run the form handling various tests.
  
=head1 DESCRIPTION

    This is a callback package for L<Test::CGI::Multipart> that facilitates 
    the testing of the upload of text files of a given size and sample content.

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

=item C<file>

Where a form parameter represents a file, this is the name of that file.

=item C<type>

The MIME type of the content. This defaults to 'text/plain'.

=back

=head2 new

An instance of this class might best be thought of as a "CGI object factory".
The constructor takes no parameters.

=head2 create_cgi

This returns a CGI object created according to the specification encapsulated in the object. The exact mechanics are as follows:

=over

=item The parameters are packaged up in MIME format.

=item The environment variables are set.

=item A pipe is created. The far end of the pipe is attached to our standard
input and the MIME content is pushed through the pipe.

=item The appropriate CGI class is required.

=item Uploads are enabled if the CGI class is L<CGI::Simple>.

=item The CGI object is created and returned.

=back

As far as I can see this simulates what happens when a CGI script processes a multi-part POST form. One can specify a different CGI class using the C<cgi> named parameter.

=head2 set_param

This can be used to set a single form parameter. It takes two named arguments C<name> and C<value>. Note that this method overrides any previous settings including file uploads.

=head2 get_param

This retrieves a single form parameter. It takes a single named
parameter: C<name>. The data returned will be a list either of scalar
values or (in the case of a file upload) of HASHREFs. The HASHREFs would have
the following fields: C<file>, C<value> and C<type> representing the parameter
name, the file name, the content and the MIME type respectively.

=head2 get_names

This returns a list of stashed parameter names.

=head2 upload_file

In the abscence of any defined callbacks, this method takes three mandatory
named parameters: C<name>, C<file> and C<value> and one optional parameter
C<type>. If there are any callbacks then the parameters are passed through each
of the callbacks and must meet the standard parmeter requirements by the time
all the callbacks have been called.

Unlike the C<set_param> method this will not override previous
settings for this parameter but will add. However setting a normal parameter
and then an upload on the same name will throw an error.

=head2 register_callback

Callbacks are used by the C<upload_file> method, to allow a file to be specified
by properties rather than strict content. This method takes a single named
parameter called C<callback>, which adds that callback to an internal array
of callbacks. The idea being that the C<upload_file> method can take any
arguments you like so long as after all the callbacks have been applied, the
parameters consist of C<name>, C<file>, C<value> and possibly C<type>.
A callback should take and return a single hash reference.

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

However it should be noted that the module will overwrite the following 
environment variables:

=over

=item REQUEST_METHOD

=item CONTENT_LENGTH

=item CONTENT_TYPE

=back

=head1 INCOMPATIBILITIES

I would like to get this working with L<CGI::Lite::Request> and L<Apache::Request> if that makes sense. So far I have not managed that.

=head1 BUGS AND LIMITATIONS

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
