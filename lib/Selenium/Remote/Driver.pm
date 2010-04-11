package Selenium::Remote::Driver;

use strict;
use warnings;
use Data::Dumper;

use Carp qw(croak);

use Selenium::Remote::RemoteConnection;
use Selenium::Remote::Commands;
use Selenium::Remote::ErrorHandler;

=head1 NAME

Selenium::Remote::Driver - Perl Client for Selenium Remote Driver

=cut

=head1 SYNOPSIS

    use Selenium::Remote::Driver;
    
    my $driver = new Selenium::Remote::Driver;
    $driver->get("http://www.google.com");
    print $driver->get_title();
    $driver->quit();

=cut

=head1 DESCRIPTION

Selenium is a test tool that allows you to write
automated web application UI tests in any programming language against
any HTTP website using any mainstream JavaScript-enabled browser. This module is
an implementation of the Perl Bindings (client) for the Remote driver that
Selenium provides. You can find bindings for other languages at this location:

L<http://code.google.com/p/selenium/>

This module sends commands directly to the Server using simple HTTP requests.
Using this module together with the Selenium Server, you can automatically
control any supported browser.

To use this module, you need to have already downloaded and started
the Selenium Server.  (The Selenium Server is a Java application.)

=cut

sub new {
    my ($class, %args) = @_;
    my $commands = new Selenium::Remote::Commands;

    # Set the defaults if user doesn't send any
    my $self = {
          remote_server_addr => delete $args{remote_server_addr} || 'localhost',
          browser_name       => delete $args{browser_name}       || 'firefox',
          platform           => delete $args{platform}           || 'ANY',
          port               => delete $args{port}               || '4444',
          javascript         => delete $args{javascript}         || JSON::true,
          version            => delete $args{version}            || '',
          session_id         => undef,
          remote_conn        => undef,
          error_handler      => undef,
          commands           => $commands,
    };
    bless $self, $class or die "Can't bless $class: $!";
    
    $self->{error_handler} = new Selenium::Remote::ErrorHandler;
    # Connect to remote server & establish a new session
    $self->{remote_conn} =
      new Selenium::Remote::RemoteConnection($self->{remote_server_addr},
                                             $self->{port});
    $self->new_session();

    if (!(defined $self->{session_id})) {
        croak "Could not establish a session with the remote server\n";
    }

    return $self;
}

# When a command is processed by the remote server & a result is sent back, it
# also includes other relevant info. We strip those & just return the value we're
# interested in. And if there is an error, ErrorHandler will handle it.
sub _get_command_result {
    my ($self, @args) = @_;
    my $resp = $self->{remote_conn}->request(@args);
    if (defined $resp->{'status'} && $resp->{'status'} != 0) {
        $self->{error_handler}->process_error($resp);
    }
    elsif (defined $resp->{'value'}) {
        return $resp->{'value'};
    }
    else {
        # If there is no value or status assume success
        return 1;
    }
}

sub new_session {
    my $self = shift;
    my $args = { 'desiredCapabilities' => {
                                            'browserName'       => $self->{browser_name},
                                            'platform'          => $self->{platform},
                                            'javascriptEnabled' => $self->{javascript},
                                            'version'           => $self->{version},
                                          }
                };
    my $resp =
      $self->{remote_conn}->request(
                                  $self->{commands}->{'newSession'}->{'method'},
                                  $self->{commands}->{'newSession'}->{'url'},
                                  $args,
      );
    if ((defined $resp->{'sessionId'}) && $resp->{'sessionId'} ne '') {
        $self->{session_id} = $resp->{'sessionId'};
    }
    else {
        croak "Could not create new session";
    }
}

sub get_capabilities {
    my $self = shift;
    my $command = 'getCapabilities';
    my $args = { 'session_id' => $self->{'session_id'}, };
    my $data = $self->{commands}->getParams($command, $args);
    
    if ($data) {
        return $self->_get_command_result($data->{'method'}, $data->{'url'});
    }
    else {
        croak "Couldn't retrieve command $command settings\n";
    }
}

sub quit {
    my $self = shift;

    my $args = { 'session_id' => $self->{'session_id'}, };
    my $data = $self->{commands}->getParams('quit', $args);

    if ($data) {
        $self->{remote_conn}->request($data->{'method'}, $data->{'url'});
    }
    else {
        croak "Couldn't retrieve command settings properly\n";
    }
}

sub get_current_window_handle {
    my $self = shift;
    my $command = 'getCurrentWindowHandle';
    my $args = { 'session_id' => $self->{'session_id'}, };
    my $data = $self->{commands}->getParams($command, $args);
    
    if ($data) {
        return $self->_get_command_result($data->{'method'}, $data->{'url'});
    }
    else {
        croak "Couldn't retrieve command $command settings\n";
    }
}

sub get_window_handles {
    my $self = shift;
    my $command = 'getWindowHandles';
    my $args = { 'session_id' => $self->{'session_id'}, };
    my $data = $self->{commands}->getParams($command, $args);
    
    if ($data) {
        return $self->_get_command_result($data->{'method'}, $data->{'url'});
    }
    else {
        croak "Couldn't retrieve command $command settings\n";
    }
}

sub get_current_url {
    my $self = shift;
    my $command = 'getCurrentUrl';
    my $args = { 'session_id' => $self->{'session_id'}, };
    my $data = $self->{commands}->getParams($command, $args);
    
    if ($data) {
        return $self->_get_command_result($data->{'method'}, $data->{'url'});
    }
    else {
        croak "Couldn't retrieve command $command settings\n";
    }
}

sub navigate {
    my ($self, $url) = @_;
    $self->get($url);
}

sub get {
    my ($self, $url) = @_;
    my $command = 'get';
    my $args    = { 'session_id' => $self->{'session_id'}, };
    my $data    = $self->{commands}->getParams($command, $args);
    my $params = {'url' => $url};

    if ($data) {
        $self->{remote_conn}->request($data->{'method'}, $data->{'url'}, $params);
    }
    else {
        croak "Couldn't retrieve command $command settings\n";
    }
}

sub get_title {
    my $self    = shift;
    my $command = 'getTitle';
    my $args    = { 'session_id' => $self->{'session_id'}, };
    my $data    = $self->{commands}->getParams($command, $args);

    if ($data) {
        return $self->_get_command_result($data->{'method'}, $data->{'url'});
    }
    else {
        croak "Couldn't retrieve command $command settings\n";
    }
}

sub go_back {
    my $self    = shift;
    my $command = 'goBack';
    my $args    = { 'session_id' => $self->{'session_id'}, };
    my $data    = $self->{commands}->getParams($command, $args);

    if ($data) {
        $self->{remote_conn}->request($data->{'method'}, $data->{'url'});
    }
    else {
        croak "Couldn't retrieve command $command settings\n";
    }
}

sub go_forward {
    my $self    = shift;
    my $command = 'goForward';
    my $args    = { 'session_id' => $self->{'session_id'}, };
    my $data    = $self->{commands}->getParams($command, $args);

    if ($data) {
        $self->{remote_conn}->request($data->{'method'}, $data->{'url'});
    }
    else {
        croak "Couldn't retrieve command $command settings\n";
    }
}

sub refresh {
    my $self    = shift;
    my $command = 'goForward';
    my $args    = { 'session_id' => $self->{'session_id'}, };
    my $data    = $self->{commands}->getParams($command, $args);

    if ($data) {
        $self->{remote_conn}->request($data->{'method'}, $data->{'url'});
    }
    else {
        croak "Couldn't retrieve command $command settings\n";
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
