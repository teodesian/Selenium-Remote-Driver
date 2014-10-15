package Selenium::Remote::RemoteConnection;

#ABSTRACT: Connect to a selenium server

use Moo;
use Try::Tiny;
use LWP::UserAgent;
use HTTP::Headers;
use HTTP::Request;
use Net::Ping;
use Carp qw(croak);
use JSON;
use Data::Dumper;
use Selenium::Remote::ErrorHandler;

has 'remote_server_addr' => (
    is => 'rw',
);

has 'port' => (
    is => 'rw',
);

has 'debug' => (
    is => 'rw',
    default => sub { 0 }
);

has 'ua' => (
    is => 'lazy',
    builder => sub { return LWP::UserAgent->new; }
);

has 'error_handler' => (
    is => 'lazy',
    builder => sub { return Selenium::Remote::ErrorHandler->new; }
);



sub check_status { 
    my $self = shift;
    my $status;
    try {
        $status = $self->request({method => 'GET', url => 'status'});
    }
    catch {
        croak "Could not connect to SeleniumWebDriver: $_" ;
    };

    if($status->{cmd_status} ne 'OK') {
        # Could be grid, see if we can talk to it
        $status = undef;
        $status = $self->request({method => 'GET', url => 'grid/api/hub/status'});
    }

    unless ($status->{cmd_status} eq 'OK') {
        croak "Selenium server did not return proper status";
    }
    
}



# This request method is tailored for Selenium RC server
sub request {
    my ($self,$resource,$params,$dont_process_response) = @_;
    my $method =        $resource->{method};
    my $url =        $resource->{url};
    my $no_content_success =        $resource->{no_content_success} // 0;

    my $content = '';
    my $fullurl = '';

    # Construct full url.
    if ($url =~ m/^http/g) {
        $fullurl = $url;
    }
    elsif ($url =~ m/grid/g) {
        $fullurl =
            "http://"
          . $self->remote_server_addr . ":"
          . $self->port
          . "/$url";
    }
    else {
        $fullurl =
            "http://"
          . $self->remote_server_addr . ":"
          . $self->port
          . "/wd/hub/$url";
    }

    if ((defined $params) && $params ne '') {
        my $json = JSON->new;
        $json->allow_blessed;
        $content = $json->allow_nonref->utf8->encode($params);
    }

    print "REQ: $method, $url, $content\n" if $self->debug;

    # HTTP request
    my $header =
      HTTP::Headers->new(Content_Type => 'application/json; charset=utf-8');
    $header->header('Accept' => 'application/json');
    my $request = HTTP::Request->new($method, $fullurl, $header, $content);
    my $response = $self->ua->request($request);
    if ($dont_process_response) { 
        return $response;
    }
    return $self->_process_response($response, $no_content_success);
}

sub _process_response {
    my ($self, $response, $no_content_success) = @_;
    my $data; # server response 'value' that'll be returned to the user
    my $json = JSON->new;

    if ($response->is_redirect) {
        return $self->request('GET', $response->header('location'));
    }
    else {
        my $decoded_json = undef;
        print "RES: ".$response->decoded_content."\n\n" if $self->debug;

        if (($response->message ne 'No Content') && ($response->content ne '')) {
            if ($response->content_type !~ m/json/i) {
                $data->{'cmd_status'} = 'NOTOK';
                $data->{'cmd_return'}->{message} = 'Server returned error message '.$response->content.' instead of data';
                return $data;
            }
            $decoded_json = $json->allow_nonref(1)->utf8(1)->decode($response->content);
            $data->{'sessionId'} = $decoded_json->{'sessionId'};
        }

        if ($response->is_error) {
            $data->{'cmd_status'} = 'NOTOK';
            if (defined $decoded_json) {
                $data->{'cmd_return'} = $self->error_handler->process_error($decoded_json);
            }
            else {
                $data->{'cmd_return'} = 'Server returned error code '.$response->code.' and no data';
            }
            return $data;
        }
        elsif ($response->is_success) {
            $data->{'cmd_status'} = 'OK';
            if (defined $decoded_json) {
                if ($no_content_success) {
                    $data->{'cmd_return'} = 1
                }
                else {
                    $data->{'cmd_return'} = $decoded_json->{'value'};
                }
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
