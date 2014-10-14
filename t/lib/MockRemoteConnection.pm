package MockRemoteConnection;

# ABSTRACT: utility class to mock the responses from Selenium server

use Moo; 
use JSON; 
use Carp;
use Try::Tiny;
# use lib 't/lib';
# use MockCommands;

extends 'Selenium::Remote::RemoteConnection';

has 'spec' => (
    is       => 'ro',
    required => 1,
);

has 'mock_cmds' => ( 
    is => 'ro', 
    # default => sub { return MockCommands->new }
);

has 'fake_session_id' => ( 
    is => 'lazy', 
    builder => sub { 
        my $id = join '',
        map +( 0 .. 9, 'a' .. 'z', 'A' .. 'Z' )[ rand( 10 + 26 * 2 ) ], 1 .. 50;
        return $id;
    },
);

has 'record' => ( 
    is => 'ro', 
    default => sub { 0 } 
);

has 'session_store' => (
    is => 'ro', 
    default => sub { {} }
);

has 'session_id' => ( 
    is => 'rw',
    default => sub { undef },
);

sub BUILD {
    my $self = shift; 
    $self->remote_server_addr('localhost');
    $self->port('4444');
}

sub check_status { 
    return;
}

sub dump_session_store { 
    my $self = shift; 
    my ($file,$session_id) = @_;
    open (my $fh, '>', $file) or croak "Opening '$file' failed";
    my $session_store = $self->session_store;
    my $dump = {};
    foreach my $path (keys %{$session_store->{$session_id}}) { 
        $dump->{$path} = $session_store->{$session_id}->{$path};
    }
        my $json = JSON->new;
        $json->allow_blessed;
    my $json_session = $json->allow_nonref->utf8->encode($dump);
    print $fh $json_session; 
    close ($fh);
}

sub request { 
    my $self = shift;
    my ($resource, $params) = @_;
    my $method =        $resource->{method};
    my $url =        $resource->{url};
    my $no_content_success =        $resource->{no_content_success} // 0;
    my $url_params = $resource->{url_params};
    if ( $self->record ) {
        my $response = $self->SUPER::request( $resource, $params, 1 );

        if (   ( $response->message ne 'No Content' )
            && ( $response->content ne '' ) )
        {
            if ( $response->content_type =~ m/json/i ) {
                my $json = JSON->new;
                $json->allow_blessed;
                my $decoded_json =
                  $json->allow_nonref(1)->utf8(1)->decode( $response->content );
                $self->session_id( $decoded_json->{'sessionId'} )
                  unless $self->session_id;
            }
        }
        $self->session_store->{$self->session_id}->{"$method $url"} = $response if ($self->session_id);
        return $self->_process_response($response,$no_content_success);
    }
    my $mock_cmds = $self->mock_cmds;
    my $spec = $self->spec; 
    my $cmd = $mock_cmds->get_method_name_from_parameters({method => $method,url => $url});
    my $ret = {cmd_status => 'OK', cmd_return => 1};
    if (defined($spec->{$cmd})) { 
        my $return_sub = $spec->{$cmd};
        if ($no_content_success) { 
            $ret->{cmd_return} = 1;
        }
        else { 
            my $mock_return = $return_sub->($url_params,$params);
            if (ref($mock_return) eq 'HASH') { 
                $ret->{cmd_status} = $mock_return->{status};
                $ret->{cmd_return} = $mock_return->{return};
                $ret->{cmd_error} = $mock_return->{error} // ''
            }
            else { 
                $ret = $mock_return;
            }
        }
        $ret->{session_id} = $self->fake_session_id if (ref($ret) eq 'HASH');
    }
    else { 
        $ret->{sessionId} = $self->fake_session_id;
    }
    return $ret;
}

1;
