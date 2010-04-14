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
    my $ress = new Selenium::Remote::Commands;

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
          commands           => $ress,
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

sub _execute_command {
    my ($self, $res, $params) = @_;
    $res->{'session_id'} = $self->{'session_id'};
    my $resource = $self->{commands}->get_params($res);
    if ($resource) {
        return $self->{remote_conn}->request($resource->{'method'}, $resource->{'url'}, $params);
    }
    else {
        croak "Couldn't retrieve command settings properly\n";
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
    my $res = 'getCapabilities';
    return $self->_execute_command($res);
}

sub quit {
    my $self = shift;
    my $res = {'command' => 'quit'};
    return $self->_execute_command($res);
}

sub get_current_window_handle {
    my $self = shift;
    my $res = {'command' => 'getCurrentWindowHandle'};
    return $self->_execute_command($res);
}

sub get_window_handles {
    my $self = shift;
    my $res = {'command' => 'getWindowHandles'};
    return $self->_execute_command($res);
}

sub get_current_url {
    my $self = shift;
    my $res = {'command' => 'getCurrentUrl'};
    return $self->_execute_command($res);
}

sub navigate {
    my ($self, $url) = @_;
    $self->get($url);
}

sub get {
    my ($self, $url) = @_;
    my $res = {'command' => 'get'};
    my $params = {'url' => $url};
    return $self->_execute_command($res, $params);
}

sub get_title {
    my $self    = shift;
    my $res = {'command' => 'getTitle'};
    return $self->_execute_command($res);
}

sub go_back {
    my $self    = shift;
    my $res = {'command' => 'goBack'};
    return $self->_execute_command($res);
}

sub go_forward {
    my $self    = shift;
    my $res = {'command' => 'goForward'};
    return $self->_execute_command($res);
}

sub refresh {
    my $self    = shift;
    my $res = {'command' => 'goForward'};
    return $self->_execute_command($res);
}

sub execute_script {
    # TODO: this method is not finished
    
    my ($self, $script, @args)    = @_;
    if (not defined $script) {
        return 'No script provided';
    }
    my $res = {'command' => 'executeScript'};
    my $args    = { 'session_id' => $self->{'session_id'}, };
    my $resource    = $self->{commands}->getParams($res, $args);

    if ($resource) {
        return $self->{remote_conn}->request($resource->{'method'}, $resource->{'url'});
    }
    else {
        croak "Couldn't retrieve command $res settings\n";
    }
}

sub screenshot {
    my ($self)    = @_;
    my $res = {'command' => 'screenshot'};
    return $self->_execute_command($res);
}

sub switch_to_frame {
    my ($self, $id)    = @_;
    my $json_null = JSON::null;
    $id = (defined $id)?$id:$json_null;

    my $res = {'command' => 'switchToFrame'};
    my $params = {'id' => $id};
    return $self->_execute_command($res, $params);
}

sub switch_to_window {
    my ($self, $name)    = @_;
    if (not defined $name) {
        return 'Window name not provided';
    }
    my $res = {'command' => 'switchToWindow'};
    my $params = {'name' => $name};
    return $self->_execute_command($res, $params);
}

sub get_speed {
    my ($self)    = @_;
    my $res = {'command' => 'getSpeed'};
    return $self->_execute_command($res);
}

sub set_speed {
    my ($self, $speed)    = @_;
    if (not defined $speed) {
        return 'Speed not provided.';
    }
    my $res = {'command' => 'switchToWindow'};
    my $params = {'speed' => $speed};
    return $self->_execute_command($res, $params);
}

# TODO: Verify all these cookied methods - some return errors some don't
#       No idea whether they're implemented on the server yet

sub get_all_cookies {
    my ($self)    = @_;
    my $res = {'command' => 'getAllCookies'};
    return $self->_execute_command($res);
}

sub add_cookie {
    my($self, $name, $value, $path, $domain, $secure) = @_;
    
    if ((not defined $name) ||(not defined $value) ||(not defined $path) ||
        (not defined $domain)) {
        return "Missing parameters";
    }
    
    my $res = {'command' => 'addCookie'};
    my $json_false = JSON::false;
    my $json_true = JSON::true;
    $secure = (defined $secure)?$json_true:$json_false;
    
    my $params = {
        'name' => $name,
        'value' => $value,
        'path' => $path,
        'domain' => $domain,
        'secure' => $secure,
    };
    
    return $self->_execute_command($res, $params);
}

sub delete_all_cookies {
    my ($self)    = @_;
    my $res = {'command' => 'deleteAllCookies'};
    return $self->_execute_command($res);
}

sub delete_cookie_named {
    my ($self, $cookie_name)    = @_;
    if (not defined $cookie_name) {
        return "Cookie name not provided";
    }
    my $res = {'command' => 'deleteAllCookies', 'name' => $cookie_name};
    return $self->_execute_command($res);
}

sub get_page_source {
    my ($self)    = @_;
    my $res = {'command' => 'getPageSource'};
    return $self->_execute_command($res);
}

sub find_element {
    # TODO: Find out what the locator strategies are - I am assuming xpath, css
    # dom etc.
    
    my ($self, $query, $method)    = @_;
    if (not defined $query) {
        return 'Search string to find element not provided.';
    }
    my $using = (defined $method)?$method:'xpath';
    my $res = {'command' => 'findElement'};
    my $params = {'using' => $using, 'value' => $query};
    return $self->_execute_command($res, $params);
}

sub find_elements {
    # TODO: Find out what the locator strategies are - I am assuming xpath, css
    # dom etc. 
    
    my ($self, $query, $method)    = @_;
    if (not defined $query) {
        return 'Search string to find element not provided.';
    }
    my $using = (defined $method)?$method:'xpath';
    my $res = {'command' => 'findElements'};
    my $params = {'using' => $using, 'value' => $query};
    return $self->_execute_command($res, $params);
}

sub get_active_element {
    my ($self)    = @_;
    my $res = {'command' => 'getActiveElement'};
    return $self->_execute_command($res);
}

sub describe_element {
    my ($self, $element)    = @_;
    #if (not defined $element) {
    #    return "Element not provided";
    #}
    #my $res = {'command' => 'desribeElement', 'name' => $element};
    #return $self->_execute_command($res);
    return "Not yet supported";
}

sub find_child_element {
    # TODO: same as find_element - no idea what locator strategy string is & no
    # idea what the id is.
    
    my ($self, $id, $query, $method)    = @_;
    if ((not defined $id) || (not defined $query)) {
        return "Missing parameters";
    }
    my $using = (defined $method)?$method:'xpath';
    my $res = {'command' => 'findChildElement', 'id' => $id};
    my $params = {'using' => $using, 'value' => $query};
    return $self->_execute_command($res, $params);
}

sub find_child_elements {
    # TODO: same as find_element - no idea what locator strategy string is & no
    # idea what the id is.
    
    my ($self, $id, $query, $method)    = @_;
    if ((not defined $id) || (not defined $query)) {
        return "Missing parameters";
    }
    my $using = (defined $method)?$method:'xpath';
    my $res = {'command' => 'findChildElements', 'id' => $id};
    my $params = {'using' => $using, 'value' => $query};
    return $self->_execute_command($res, $params);
}

sub click {
    #TODO: verify - my local tests are failing
    
    my ($self, $id)    = @_;
    if (not defined $id) {
        return "Element id not provided";
    }
    my $res = {'command' => 'clickElement', 'id' => $id};
    return $self->_execute_command($res);
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
