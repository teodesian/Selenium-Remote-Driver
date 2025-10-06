package Selenium::Remote::RemoteConnection;

use strict;
use warnings;

#ABSTRACT: Connect to a selenium server

use Moo;
use Try::Tiny;
use LWP::UserAgent;
use HTTP::Headers;
use HTTP::Request;
use Carp qw(croak);
use JSON;
use Data::Dumper;
use Selenium::Remote::ErrorHandler;
use Scalar::Util qw{looks_like_number};

has 'remote_server_addr' => ( is => 'rw', );

has 'port' => ( is => 'rw', );

has 'debug' => (
    is      => 'rw',
    default => sub { 0 }
);

has 'ua' => (
    is      => 'lazy',
    builder => sub { return LWP::UserAgent->new; }
);

has 'error_handler' => (
    is      => 'lazy',
    builder => sub { return Selenium::Remote::ErrorHandler->new; }
);

with 'Selenium::Remote::Driver::CanSetWebdriverContext';

=head1 DESCRIPTION

You shouldn't really need to use this module unless debugging or checking connections when testing dangerous things.

=head1 SYNOPSIS

    my $driver = Selenium::Remote::Driver->new();
    eval { $driver->remote_conn->check_status() };
    die "do something to kick the server" if $@;

=head1 CONSTRUCTOR

=head2 new(%parameters)

Accepts 5 parameters:

=over 4

=item B<remote_server_addr> - address of selenium server

=item B<port> - port of selenium server

=item B<ua> - Useful to override with Test::LWP::UserAgent in unit tests

=item B<debug> - Should be self-explanatory

=item B<error_handler> - Defaults to Selenium::Remote::ErrorHandler.

=back

These can be set any time later by getter/setters with the same name.

=head1 METHODS

=head2 check_status

Croaks unless the selenium server is responsive.  Sometimes is useful to call in-between tests (the server CAN die on you...)

=cut

sub check_status {
    my $self = shift;
    my $status;

    try {
        $status = $self->request( { method => 'GET', url => 'status' } );
    }
    catch {
        croak "Could not connect to SeleniumWebDriver: $_";
    };

    my $cmdOut = $status->{cmd_status} || '';
    if ( $cmdOut ne 'OK' ) {

        # Could be grid, see if we can talk to it
        $status = undef;
        $status =
          $self->request( { method => 'GET', url => 'grid/api/hub/status' } );
    }

    unless ( $cmdOut eq 'OK' ) {
        my $cr = $status->{cmd_return} // '';
        croak "Selenium server did not return proper status: $cmdOut: $cr";
    }
}

=head2 request

Make a request of the Selenium server.  Mostly useful for debugging things going wrong with Selenium::Remote::Driver when not in normal operation.

=cut

sub request {
    my ( $self, $resource, $params, $dont_process_response ) = @_;
    my $method             = $resource->{method};
    my $url                = $resource->{url};
    my $no_content_success = $resource->{no_content_success} // 0;

    my $content = '';
    my $fullurl = '';

    # Construct full url.
    if ( $url =~ m/^http/g ) {
        $fullurl = $url;
    }
    elsif ( $url =~ m/^\// ) {

        # This is used when we get a 302 Redirect with a Location header.
        $fullurl =
          "http://" . $self->remote_server_addr . ":" . $self->port . $url;
    }
    elsif ( $url =~ m/grid/g ) {
        $fullurl =
          "http://" . $self->remote_server_addr . ":" . $self->port . "/$url";
    }
    else {
        $fullurl =
            "http://"
          . $self->remote_server_addr . ":"
          . $self->port
          . $self->wd_context_prefix . "/$url";
    }

    if ( ( defined $params ) && $params ne '' ) {

        #WebDriver 3 shims
        if ( $resource->{payload} ) {
            foreach my $key ( keys( %{ $resource->{payload} } ) ) {
                $params->{$key} = $resource->{payload}->{$key};
            }
        }

        my $json = JSON->new;
        $json->allow_blessed;
        $content = $json->allow_nonref->utf8->encode($params);
    }

    print "REQ: $method, $fullurl, $content\n" if $self->debug;

    # HTTP request
    my $header =
      HTTP::Headers->new( Content_Type => 'application/json; charset=utf-8' );
    $header->header( 'Accept' => 'application/json' );
    my $request = HTTP::Request->new( $method, $fullurl, $header, $content );
    my $response = $self->ua->request($request);
    if ($dont_process_response) {
        return $response;
    }
    return $self->_process_response( $response, $no_content_success );
}

sub _process_response {
    my ( $self, $response, $no_content_success ) = @_;
    my $data;    # server response 'value' that'll be returned to the user
    my $json = JSON->new;

    if ( $response->is_redirect ) {
        my $redirect = {
            method => 'GET',
            url    => $response->header('location')
        };
        return $self->request($redirect);
    }
    else {
        my $decoded_json = undef;
        print "RES: " . $response->decoded_content . "\n\n" if $self->debug;

        if (   ( $response->message ne 'No Content' )
            && ( $response->content ne '' ) )
        {
            if ( $response->content_type !~ m/json/i ) {
                $data->{'cmd_status'} = 'NOTOK';
                $data->{'cmd_return'}->{message} =
                    'Server returned error message '
                  . $response->content
                  . ' instead of data';
                return $data;
            }
            $decoded_json =
              $json->allow_nonref(1)->utf8(1)->decode( $response->content );
            $data->{'sessionId'} = $decoded_json->{'sessionId'};
        }

        if ( $response->is_error ) {
            $data->{'cmd_status'} = 'NOTOK';
            if ( defined $decoded_json ) {
                $data->{'cmd_return'} =
                  $self->error_handler->process_error($decoded_json);
            }
            else {
                $data->{'cmd_return'} =
                    'Server returned error code '
                  . $response->code
                  . ' and no data';
            }
            return $data;
        }
        elsif ( $response->is_success ) {
            $data->{'cmd_status'} = 'OK';
            if ( defined $decoded_json ) {

                #XXX MS edge doesn't follow spec here either
                if (   looks_like_number( $decoded_json->{status} )
                    && $decoded_json->{status} > 0
                    && $decoded_json->{value}{message} )
                {
                    $data->{cmd_status} = 'NOT OK';
                    $data->{cmd_return} = $decoded_json->{value};
                    return $data;
                }

                #XXX shockingly, neither does InternetExplorerDriver
                if ( ref $decoded_json eq 'HASH' && $decoded_json->{error} ) {
                    $data->{cmd_status} = 'NOT OK';
                    $data->{cmd_return} = $decoded_json;
                    return $data;
                }

                if ($no_content_success) {
                    $data->{'cmd_return'} = 1;
                }
                else {
                    $data->{'cmd_return'} = $decoded_json->{'value'};
                    if ( ref( $data->{cmd_return} ) eq 'HASH'
                        && exists $data->{cmd_return}->{sessionId} )
                    {
                        $data->{sessionId} = $data->{cmd_return}->{sessionId};
                    }
                }
            }
            else {
                $data->{'cmd_return'} =
                    'Server returned status code '
                  . $response->code
                  . ' but no data';
            }
            return $data;
        }
        else {
            # No idea what the server is telling me, must be high
            $data->{'cmd_status'} = 'NOTOK';
            $data->{'cmd_return'} =
                'Server returned status code '
              . $response->code
              . ' which I don\'t understand';
            return $data;
        }
    }
}

1;

__END__
