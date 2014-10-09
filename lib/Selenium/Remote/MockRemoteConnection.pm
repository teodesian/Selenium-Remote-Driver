package Selenium::Remote::MockRemoteConnection;

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

has 'session_id' => ( 
    is => 'lazy', 
    builder => sub { 
        my $id = join '',
        map +( 0 .. 9, 'a' .. 'z', 'A' .. 'Z' )[ rand( 10 + 26 * 2 ) ], 1 .. 50;
        return $id;
    },
);

sub request { 
    my $self = shift;
    my ($method, $url, $no_content_success, $params) = @_;
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
            my $mock_return = $return_sub->($params);
            if (ref($mock_return) eq 'HASH') { 
                $ret->{cmd_status} = $mock_return->{status};
                $ret->{cmd_return} = $mock_return->{return};
                $ret->{cmd_error} = $mock_return->{error} // ''
            }
            else { 
                $ret = $mock_return;
            }
        }
        $ret->{session_id} = $self->session_id if (ref($ret) eq 'HASH');
    }
    else { 
        $ret->{sessionId} = $self->session_id;
    }
    return $ret;
}

1;
