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
          commands           => $commands,
    };
    bless $self, $class or die "Can't bless $class: $!";
    
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
    my $resource = $self->{commands}->getParams($command, $args);
    
    if ($resource) {
        return $self->{remote_conn}->request($resource->{'method'}, $resource->{'url'});
    }
    else {
        croak "Couldn't retrieve command $command settings\n";
    }
}

sub quit {
    my $self = shift;

    my $args = { 'session_id' => $self->{'session_id'}, };
    my $resource = $self->{commands}->getParams('quit', $args);

    if ($resource) {
        return $self->{remote_conn}->request($resource->{'method'}, $resource->{'url'});
    }
    else {
        croak "Couldn't retrieve command settings properly\n";
    }
}

sub get_current_window_handle {
    my $self = shift;
    my $command = 'getCurrentWindowHandle';
    my $args = { 'session_id' => $self->{'session_id'}, };
    my $resource = $self->{commands}->getParams($command, $args);
    
    if ($resource) {
        return $self->{remote_conn}->request($resource->{'method'}, $resource->{'url'});
    }
    else {
        croak "Couldn't retrieve command $command settings\n";
    }
}

sub get_window_handles {
    my $self = shift;
    my $command = 'getWindowHandles';
    my $args = { 'session_id' => $self->{'session_id'}, };
    my $resource = $self->{commands}->getParams($command, $args);
    
    if ($resource) {
        return $self->{remote_conn}->request($resource->{'method'}, $resource->{'url'});
    }
    else {
        croak "Couldn't retrieve command $command settings\n";
    }
}

sub get_current_url {
    my $self = shift;
    my $command = 'getCurrentUrl';
    my $args = { 'session_id' => $self->{'session_id'}, };
    my $resource = $self->{commands}->getParams($command, $args);
    
    if ($resource) {
        return $self->{remote_conn}->request($resource->{'method'}, $resource->{'url'});
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
    my $resource    = $self->{commands}->getParams($command, $args);
    my $params = {'url' => $url};

    if ($resource) {
        return $self->{remote_conn}->request($resource->{'method'}, $resource->{'url'}, $params);
    }
    else {
        croak "Couldn't retrieve command $command settings\n";
    }
}

sub get_title {
    my $self    = shift;
    my $command = 'getTitle';
    my $args    = { 'session_id' => $self->{'session_id'}, };
    my $resource    = $self->{commands}->getParams($command, $args);

    if ($resource) {
        return $self->{remote_conn}->request($resource->{'method'}, $resource->{'url'});
    }
    else {
        croak "Couldn't retrieve command $command settings\n";
    }
}

sub go_back {
    my $self    = shift;
    my $command = 'goBack';
    my $args    = { 'session_id' => $self->{'session_id'}, };
    my $resource    = $self->{commands}->getParams($command, $args);

    if ($resource) {
        return $self->{remote_conn}->request($resource->{'method'}, $resource->{'url'});
    }
    else {
        croak "Couldn't retrieve command $command settings\n";
    }
}

sub go_forward {
    my $self    = shift;
    my $command = 'goForward';
    my $args    = { 'session_id' => $self->{'session_id'}, };
    my $resource    = $self->{commands}->getParams($command, $args);

    if ($resource) {
        return $self->{remote_conn}->request($resource->{'method'}, $resource->{'url'});
    }
    else {
        croak "Couldn't retrieve command $command settings\n";
    }
}

sub refresh {
    my $self    = shift;
    my $command = 'goForward';
    my $args    = { 'session_id' => $self->{'session_id'}, };
    my $resource    = $self->{commands}->getParams($command, $args);

    if ($resource) {
        return $self->{remote_conn}->request($resource->{'method'}, $resource->{'url'});
    }
    else {
        croak "Couldn't retrieve command $command settings\n";
    }
}

sub execute_script {
    my ($self, $script, @args)    = @_;
    if (not defined $script) {
        return 'No script provided';
    }
    my $command = 'executeScript';
    my $args    = { 'session_id' => $self->{'session_id'}, };
    my $resource    = $self->{commands}->getParams($command, $args);

    if ($resource) {
        return $self->{remote_conn}->request($resource->{'method'}, $resource->{'url'});
    }
    else {
        croak "Couldn't retrieve command $command settings\n";
    }
}

sub screenshot {
    my ($self)    = @_;
    my $command = 'screenshot';
    my $args    = { 'session_id' => $self->{'session_id'}, };
    my $resource    = $self->{commands}->getParams($command, $args);

    if ($resource) {
        return $self->{remote_conn}->request($resource->{'method'}, $resource->{'url'});
    }
    else {
        croak "Couldn't retrieve command $command settings\n";
    }
}

sub switch_to_frame {
    my ($self, $id)    = @_;
    my $json_null = JSON::null;
    $id = (defined $id)?$id:$json_null;

    my $command = 'switchToFrame';
    my $args    = { 'session_id' => $self->{'session_id'}, };
    my $resource    = $self->{commands}->getParams($command, $args);
    my $params = {'id' => $id};

    if ($resource) {
        return $self->{remote_conn}->request($resource->{'method'}, $resource->{'url'}, $params);
    }
    else {
        croak "Couldn't retrieve command $command settings\n";
    }
}

sub switch_to_window {
    my ($self, $name)    = @_;
    if (not defined $name) {
        return 'Window name not provided';
    }
    my $command = 'switchToWindow';
    my $args    = { 'session_id' => $self->{'session_id'}, };
    my $resource    = $self->{commands}->getParams($command, $args);
    my $params = {'name' => $name};

    if ($resource) {
        return $self->{remote_conn}->request($resource->{'method'}, $resource->{'url'}, $params);
    }
    else {
        croak "Couldn't retrieve command $command settings\n";
    }
}

sub get_speed {
    my ($self)    = @_;
    my $command = 'getSpeed';
    my $args    = { 'session_id' => $self->{'session_id'}, };
    my $resource    = $self->{commands}->getParams($command, $args);

    if ($resource) {
        return $self->{remote_conn}->request($resource->{'method'}, $resource->{'url'});
    }
    else {
        croak "Couldn't retrieve command $command settings\n";
    }
}

sub set_speed {
    my ($self, $speed)    = @_;
    if (not defined $speed) {
        return 'Speed not provided.';
    }
    my $command = 'switchToWindow';
    my $args    = { 'session_id' => $self->{'session_id'}, };
    my $resource    = $self->{commands}->getParams($command, $args);
    my $params = {'speed' => $speed};

    if ($resource) {
        return $self->{remote_conn}->request($resource->{'method'}, $resource->{'url'}, $params);
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
