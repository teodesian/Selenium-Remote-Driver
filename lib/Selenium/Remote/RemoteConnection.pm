package Selenium::Remote::RemoteConnection;

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Headers;
use HTTP::Request;
use Net::Ping;
use Carp qw(croak);
use JSON;
use Data::Dumper;

use Selenium::Remote::ErrorHandler;

sub new {
    my ($class, $remote_srvr, $port) = @_;
    
    my $self = {
                 remote_server_addr => $remote_srvr,
                 port               => $port,
    };
    bless $self, $class or die "Can't bless $class: $!";
    
    # Try connecting to the Selenium RC port
    my $p = Net::Ping->new("tcp", 2);
    $p->port_number($self->{'port'});
    croak "Selenium RC server is not responding\n"
            unless $p->ping($self->{'remote_server_addr'});
    undef($p);
    
    return $self;
}

# This request method is tailored for Selenium RC server
sub request {
    my ($self, $method, $url, $params) = @_;
    my $content = '';
    my $fullurl = '';

    # Construct full url.
    if ($url =~ m/^http/g) {
        $fullurl = $url;
    }
    else {
        $fullurl =
            "http://"
          . $self->{remote_server_addr} . ":"
          . $self->{port}
          . "/wd/hub/$url";
    }

    if ((defined $params) && $params ne '') {
        my $json = new JSON;
        $content = $json->allow_nonref->utf8->encode($params);
    }

    # HTTP request
    my $ua = LWP::UserAgent->new;
    my $header =
      HTTP::Headers->new(Content_Type => 'application/json; charset=utf-8');
    $header->header('Accept' => 'application/json');
    my $request = HTTP::Request->new($method, $fullurl, $header, $content);
    my $response = $ua->request($request);

    return $self->_process_response($response);
}

# Even though there are multiple error codes returned, at this point we care
# mainly about 404. We should add code to handle specific HTTP Response codes.
sub _process_response {
    my ($self, $response) = @_;
    my $data;    #returned data from server
     my $json = new JSON;

    if ($response->is_redirect) {
        return $self->request('GET', $response->header('location'));
    }
    elsif ($response->code == 404) {
        return "Command not implemented on the RC server.";
    }
    elsif ($response->code > 199) {
        my $decoded_json; 
        if ($response->message ne 'No Content') {
            $decoded_json = $json->allow_nonref->utf8->decode($response->content);
        }
        return $self->_get_command_result($decoded_json);
    }
    else {
        return "Unrecognized server status = " . $response->code;
    }
}

# When a command is processed by the remote server & a result is sent back, it
# also includes other relevant info. We strip those & just return the value we're
# interested in. And if there is an error, ErrorHandler will handle it.
sub _get_command_result {
    my ($self, $resp) = @_;
    my $error_handler = new Selenium::Remote::ErrorHandler;
    
    if (defined $resp) {
        if (ref $resp eq 'HASH') {
            if (defined $resp->{'status'} && $resp->{'status'} != 0) {
                return $error_handler->process_error($resp);
            }
            else {
                # For new session we need to grab the session id.
                if ((ref $resp->{'value'} eq 'HASH') &&
                    ($resp->{'value'}->{'class'} eq 'org.openqa.selenium.remote.DesiredCapabilities')) {
                        return $resp;
                }
                else {
                    return $resp->{'value'};
                }
            }
        }
        else
        {
            return $resp;
        }
    }
    else {
        # If there is no value or status assume success
        return 1;
    }
}

1;

__END__

=head1 SEE ALSO

For more information about Selenium , visit the website at
L<http://code.google.com/p/selenium/>.

=head1 BUGS

The Selenium issue tracking system is available online at
L<http://code.google.com/p/selenium/issues/list>.

=head1 AUTHOR

Perl Bindings for Remote Driver by Aditya Ivaturi <ivaturi@gmail.com>

=head1 LICENSE

Copyright (c) 2010 Aditya Ivaturi

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
