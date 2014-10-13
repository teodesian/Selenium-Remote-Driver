package MockRemoteConnection;

# ABSTRACT: utility class to mock the responses from Selenium server

use Moo; 
use JSON; 
use Try::Tiny;

has 'spec' => (
    is       => 'ro',
    required => 1,
);

has 'mock_cmds' => ( 
    is => 'ro', 
);

has 'fake_session_id' => ( 
    is => 'lazy', 
    builder => sub { 
        my $id = join '',
        map +( 0 .. 9, 'a' .. 'z', 'A' .. 'Z' )[ rand( 10 + 26 * 2 ) ], 1 .. 50;
        return $id;
    },
);

sub request { 
    my $self = shift;
    my ($resource, $params) = @_;
    my $method =        $resource->{method};
    my $url =        $resource->{url};
    my $no_content_success =        $resource->{no_content_success} // 0;
    my $url_params = $resource->{url_params};
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
