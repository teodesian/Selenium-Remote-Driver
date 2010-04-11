package Selenium::Remote::RemoteConnection;

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Headers;
use HTTP::Request;
use Net::Ping;
use Carp qw(croak);
use JSON;
use Error;
use Data::Dumper;

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
        #$content = "[" . $json->allow_nonref->utf8->encode($params) . "]";
        $content = $json->allow_nonref->utf8->encode($params);
    }

    # HTTP request
    my $ua = LWP::UserAgent->new;
    my $header =
      HTTP::Headers->new(Content_Type => 'application/json; charset=utf-8');
    $header->header('Accept' => 'application/json');
    my $request = HTTP::Request->new($method, $fullurl, $header, $content);
    
    #print Dumper($request);
    my $response = $ua->request($request);

    #return $response;
    return $self->_process_response($response);
}

sub _process_response {
    my ($self, $response) = @_;
    my $data;    #returned data from server

    if ($response->is_redirect) {
        return $self->request('GET', $response->header('location'));
    }
    elsif (($response->is_success) && ($response->code == 200)) {
        $data = from_json($response->content);
        if ($data->{'status'} != 0) {
            croak "Error occurred in server while processing request: $data";
        }
        return $data;
    }
    elsif (   ($response->is_success)
           && (($response->code == 200) || ($response->code == 204))) {

        # Nothing to do.
    }
    elsif ($response->code == 404) {
        croak "No such command.";
    }
    else {
        croak "Remote server error with status = " . $response->code;
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

Copyright (c) 2010 Juniper Networks, Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
