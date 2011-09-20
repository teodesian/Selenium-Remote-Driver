package Selenium::Remote::RemoteConnection;

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Headers;
use HTTP::Request;
use Net::Ping;
use Carp qw(croak);
use JSON;

use Selenium::Remote::ErrorHandler;

sub new {
    my ($class, $remote_srvr, $port) = @_;
    
    my $self = {
                 remote_server_addr => $remote_srvr,
                 port               => $port,
    };
    bless $self, $class or die "Can't bless $class: $!";
    my $status = eval {$self->request('GET','status');};
    croak "Could not connect to SeleniumWebDriver" if($@);
    if($status->{cmd_status} eq 'OK') {
      return $self;
    } else {
      croak "Selenium server did not return proper status";
    }
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

sub _process_response {
    my ($self, $response) = @_;
    my $data; # server response 'value' that'll be returned to the user
    my $json = new JSON;

    if ($response->is_redirect) {
        return $self->request('GET', $response->header('location'));
    }
    else {
        my $decoded_json = undef; 
        if (($response->message ne 'No Content') && ($response->content ne '')) {
            $decoded_json = $json->allow_nonref(1)->utf8(1)->decode($response->content);
            $data->{'sessionId'} = $decoded_json->{'sessionId'};
        }
        
        if ($response->is_error) {
            my $error_handler = new Selenium::Remote::ErrorHandler;
            $data->{'cmd_status'} = 'NOTOK';
            if (defined $decoded_json) {
                $data->{'cmd_return'} = $error_handler->process_error($decoded_json);
            }
            else {
                $data->{'cmd_return'} = 'Server returned error code '.$response->code.' and no data';          
            }
            return $data;
        }
        elsif ($response->is_success) {
            $data->{'cmd_status'} = 'OK';
            if (defined $decoded_json) {
                $data->{'cmd_return'} = $decoded_json->{'value'};
            }
            else {
                $data->{'cmd_return'} = 'Server returned status code '.$response->code.' but no data';          
            }
            return $data;
        }
        else {
            # No idea what the server is telling me, must be high
            $data->{'cmd_status'} = 'NOTOK';
            $data->{'cmd_return'} = 'Server returned status code '.$response->code.' which I don\'t understand';
            return $data;
        }
    }
}


1;

__END__

=head1 SEE ALSO

For more information about Selenium , visit the website at
L<http://code.google.com/p/selenium/>.

=head1 BUGS

The Selenium issue tracking system is available online at
L<http://github.com/aivaturi/Selenium-Remote-Driver/issues>.

=head1 CURRENT MAINTAINER

Gordon Child C<< <gchild@gordonchild.com> >>

=head1 AUTHOR

Perl Bindings for Selenium Remote Driver by Aditya Ivaturi C<< <ivaturi@gmail.com> >>

=head1 LICENSE

Copyright (c) 2010-2011 Aditya Ivaturi, Gordon Child

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
