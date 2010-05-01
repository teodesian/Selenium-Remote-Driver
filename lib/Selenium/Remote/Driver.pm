package Selenium::Remote::Driver;

use strict;
use warnings;
use Data::Dumper;

use Carp qw(croak);

use Selenium::Remote::RemoteConnection;
use Selenium::Remote::Commands;
use Selenium::Remote::WebElement;

use constant FINDERS => {
        class             => 'ClassName',
        class_name        => 'ClassName',
        css               => 'CssSelector',
        id                => 'Id',
        link              => 'LinkText',
        link_text         => 'LinkText',
        name              => 'Name',
        partial_link_text => 'PartialLinkText',
        tag_name          => 'TagName',
        xpath             => 'Xpath',
};

our $VERSION = "0.10";

=head1 NAME

Selenium::Remote::Driver - Perl Client for Selenium Remote Driver

=cut

=head1 SYNOPSIS

    use Selenium::Remote::Driver;
    
    my $driver = new Selenium::Remote::Driver;
    $driver->get('http://www.google.com');
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

=head1 FUNCTIONS

=cut

=head2 new

 Description:
    Constructor for Driver. It'll instantiate the object if it can communicate
    with the Selenium RC server.

 Input Parameter: 1
    desired_capabilities - HASH - Following options are accepted:
      Optional:
        'remote_server_addr' - <string> - IP or FQDN of the RC server machine
        'browser_name' - <string> - desired browser string:
                      {iphone|firefox|internet explorer|htmlunit|iphone|chrome}
        'version' - <string> - desired browser version number
        'platform' - <string> - desired platform:
                                {WINDOWS|XP|VISTA|MAC|LINUX|UNIX|ANY}
        'javascript' - <boolean> - whether javascript should be supported
        
        If no values are provided, then these defaults will be assumed:
            'remote_server_addr' => 'localhost'
            'browser_name' => 'firefox'
            'version'      => ''
            'platform'     => 'ANY'
            'javascript'   => 1

 Output:
    Remote Driver object

 Usage:
    my $driver = new Selenium::Remote::Driver;
    or
    my $driver = new Selenium::Remote::Driver('browser_name' => '10.37.129.2',
                                              'platform' => 'MAC')

=cut

sub new {
    my ( $class, %args ) = @_;
    my $ress = new Selenium::Remote::Commands;

    # Set the defaults if user doesn't send any
    my $self = {
        remote_server_addr => delete $args{remote_server_addr} || 'localhost',
        browser_name       => delete $args{browser_name}       || 'firefox',
        platform           => delete $args{platform}           || 'ANY',
        port               => delete $args{port}               || '4444',
        version            => delete $args{version}            || '',
        session_id         => undef,
        remote_conn        => undef,
        commands           => $ress,
    };
    bless $self, $class or die "Can't bless $class: $!";

    if ( defined $args{javascript} ) {
        if ( $args{javascript} ) {
            $self->{javascript} = JSON::true;
        }
        else {
            $self->{javascript} = JSON::false;
        }
    }
    else {
        $self->{javascript} = JSON::true;
    }

    # Connect to remote server & establish a new session
    $self->{remote_conn} =
      new Selenium::Remote::RemoteConnection( $self->{remote_server_addr},
        $self->{port} );
    $self->new_session();

    if ( !( defined $self->{session_id} ) ) {
        croak "Could not establish a session with the remote server\n";
    }

    return $self;
}

# This is an internal method used the Driver & is not supposed to be used by
# end user. This method is used by Driver to set up all the parameters (url & JSON),
# send commands & receive response from the server.
sub _execute_command {
    my ( $self, $res, $params ) = @_;
    $res->{'session_id'} = $self->{'session_id'};
    my $resource = $self->{commands}->get_params($res);
    if ($resource) {
        my $resp = $self->{remote_conn}
          ->request( $resource->{'method'}, $resource->{'url'}, $params );
        return $resp;
    }
    else {
        croak "Couldn't retrieve command settings properly\n";
    }
}

# A method that is used by the Driver itself. It'll be called to set the
# desired capabilities on the server.
sub new_session {
    my $self = shift;
    my $args = {
        'desiredCapabilities' => {
            'browserName'       => $self->{browser_name},
            'platform'          => $self->{platform},
            'javascriptEnabled' => $self->{javascript},
            'version'           => $self->{version},
        }
    };
    my $resp =
      $self->{remote_conn}
      ->request( $self->{commands}->{'newSession'}->{'method'},
        $self->{commands}->{'newSession'}->{'url'}, $args, );
    if ( ( defined $resp->{'sessionId'} ) && $resp->{'sessionId'} ne '' ) {
        $self->{session_id} = $resp->{'sessionId'};
    }
    else {
        croak "Could not create new session";
    }
}

=head2 get_capabilities

 Description:
    Retrieve the capabilities of the specified session.

 Output:
    A hash of all the values.

 Usage:
    my $capab = $driver->get_capabilities();
    print Dumper($capab);

=cut

sub get_capabilities {
    my $self = shift;
    my $res  = {'command' => 'getCapabilities'};
    return $self->_execute_command($res);
}

sub set_implicit_wait_timeout {
    my ($self, $ms) = @_;
    my $res  = {'command' => 'setImplicitWaitTimeout'};
    my $params  = {'ms' => $ms};
    return $self->_execute_command($res, $params);
}

=head2 quit

 Description:
    Delete the session & close open browsers.

 Usage:
    $driver->quit();

=cut

sub quit {
    my $self = shift;
    my $res = { 'command' => 'quit' };
    return $self->_execute_command($res);
}

=head2 get_current_window_handle

 Description:
    Retrieve the current window handle.

 Output:
    String - the window handle

 Usage:
    print $driver->get_current_window_handle();

=cut

sub get_current_window_handle {
    my $self = shift;
    my $res = { 'command' => 'getCurrentWindowHandle' };
    return $self->_execute_command($res);
}

=head2 get_current_window_handles

 Description:
    Retrieve the list of window handles used in the session.

 Output:
    Array of string - list of the window handles

 Usage:
    print Dumper($driver->get_current_window_handles());

=cut

sub get_window_handles {
    my $self = shift;
    my $res = { 'command' => 'getWindowHandles' };
    return $self->_execute_command($res);
}

=head2 get_current_url

 Description:
    Retrieve the url of the current page

 Output:
    String - url

 Usage:
    print $driver->get_current_url();

=cut

sub get_current_url {
    my $self = shift;
    my $res = { 'command' => 'getCurrentUrl' };
    return $self->_execute_command($res);
}

=head2 navigate

 Description:
    Navigate to a given url. This is same as get() method.
    
 Input:
    String - url

 Usage:
    $driver->navigate('http://www.google.com');

=cut

sub navigate {
    my ( $self, $url ) = @_;
    $self->get($url);
}

=head2 get

 Description:
    Navigate to a given url
    
 Input:
    String - url

 Usage:
    $driver->get('http://www.google.com');

=cut

sub get {
    my ( $self, $url ) = @_;
    my $res    = { 'command' => 'get' };
    my $params = { 'url'     => $url };
    return $self->_execute_command( $res, $params );
}

=head2 get_title

 Description:
    Get the current page title

 Output:
    String - Page title

 Usage:
    print $driver->get_title();

=cut

sub get_title {
    my $self = shift;
    my $res = { 'command' => 'getTitle' };
    return $self->_execute_command($res);
}

=head2 go_back

 Description:
    Equivalent to hitting the back button on the browser.

 Usage:
    $driver->go_back();

=cut

sub go_back {
    my $self = shift;
    my $res = { 'command' => 'goBack' };
    return $self->_execute_command($res);
}

=head2 go_back

 Description:
    Equivalent to hitting the forward button on the browser.

 Usage:
    $driver->go_forward();

=cut

sub go_forward {
    my $self = shift;
    my $res = { 'command' => 'goForward' };
    return $self->_execute_command($res);
}

=head2 refresh

 Description:
    Reload the current page.

 Usage:
    $driver->refresh();

=cut

sub refresh {
    my $self = shift;
    my $res = { 'command' => 'goForward' };
    return $self->_execute_command($res);
}

sub execute_script {
    my ( $self, $script, @args ) = @_;
    if ($self->javascript) {
        if ( not defined $script ) {
            return 'No script provided';
        }
        my $res  = { 'command'    => 'executeScript' };
        
        # Check the args array if the elem obj is provided & replace it with
        # JSON representation
        for (my $i=0; $i<@args; $i++) {
            if (ref $args[$i] eq 'Selenium::Remote::WebElement') {
                $args[$i] = {'ELEMENT' => ($args[$i])->{id}};
            }
        }
        
        my $params = {'args' => @args};
        my $ret = $self->_execute_command($res, $params);
        
        # replace any ELEMENTS with WebElement
        if (exists $ret->{'cmd_return'}->{'ELEMENT'}) {
            $ret->{'cmd_return'} =
                new Selenium::Remote::WebElement(
                                        $ret->{'cmd_return'}->{ELEMENT}, $self);
        }
        return $ret;
    }
    else {
        return 'Javascript is not enabled on remote driver instance.';
    }
}

=head2 screenshot

 Description:
    Get a screenshot of the current page as a base64 encoded image.

 Output:
    String - base64 encoded image

 Usage:
    print $driver->go_screenshot();

=cut

sub screenshot {
    my ($self) = @_;
    my $res = { 'command' => 'screenshot' };
    return $self->_execute_command($res);
}

sub switch_to_frame {
    my ( $self, $id ) = @_;
    my $json_null = JSON::null;
    $id = ( defined $id ) ? $id : $json_null;

    my $res    = { 'command' => 'switchToFrame' };
    my $params = { 'id'      => $id };
    return $self->_execute_command( $res, $params );
}

sub switch_to_window {
    my ( $self, $name ) = @_;
    if ( not defined $name ) {
        return 'Window name not provided';
    }
    my $res    = { 'command' => 'switchToWindow' };
    my $params = { 'name'    => $name };
    return $self->_execute_command( $res, $params );
}

=head2 get_speed

 Description:
    Get the current user input speed. The actual input speed is still browser
    specific and not covered by the Driver.

 Output:
    String - One of these: SLOW, MEDIUM, FAST

 Usage:
    print $driver->get_speed();

=cut

sub get_speed {
    my ($self) = @_;
    my $res = { 'command' => 'getSpeed' };
    return $self->_execute_command($res);
}

=head2 set_speed

 Description:
    Set the user input speed.

 Input:
    String - One of these: SLOW, MEDIUM, FAST

 Usage:
    $driver->set_speed('MEDIUM');

=cut

sub set_speed {
    my ( $self, $speed ) = @_;
    if ( not defined $speed ) {
        return 'Speed not provided.';
    }
    my $res    = { 'command' => 'setSpeed' };
    my $params = { 'speed'   => $speed };
    return $self->_execute_command( $res, $params );
}

sub get_all_cookies {
    my ($self) = @_;
    my $res = { 'command' => 'getAllCookies' };
    return $self->_execute_command($res);
}

sub add_cookie {
    my ( $self, $name, $value, $path, $domain, $secure ) = @_;

    if (   ( not defined $name )
        || ( not defined $value )
        || ( not defined $path )
        || ( not defined $domain ) )
    {
        return "Missing parameters";
    }

    my $res        = { 'command' => 'addCookie' };
    my $json_false = JSON::false;
    my $json_true  = JSON::true;
    $secure = ( defined $secure ) ? $json_true : $json_false;

    my $params = {
        'cookie' => {
            'name'   => $name,
            'value'  => $value,
            'path'   => $path,
            'domain' => $domain,
            'secure' => $secure,
        }
    };

    return $self->_execute_command( $res, $params );
}

sub delete_all_cookies {
    my ($self) = @_;
    my $res = { 'command' => 'deleteAllCookies' };
    return $self->_execute_command($res);
}

sub delete_cookie_named {
    my ( $self, $cookie_name ) = @_;
    if ( not defined $cookie_name ) {
        return "Cookie name not provided";
    }
    my $res = { 'command' => 'deleteAllCookies', 'name' => $cookie_name };
    return $self->_execute_command($res);
}

sub get_page_source {
    my ($self) = @_;
    my $res = { 'command' => 'getPageSource' };
    return $self->_execute_command($res);
}

sub find_element {
    my ( $self, $query, $method ) = @_;
    if ( not defined $query ) {
        return 'Search string to find element not provided.';
    }
    my $using = ( defined $method ) ? $method : 'xpath';
    my $ret;
    if (exists FINDERS->{$using}) {
        my $res = { 'command' => 'findElement' };
        my $params = { 'using' => $using, 'value' => $query };
        my $ret_data = $self->_execute_command( $res, $params );
        if (defined $ret_data->{'cmd_error'}) {
            $ret = $ret_data;
        }
        else {
            $ret_data->{'cmd_return'} = new Selenium::Remote::WebElement($ret_data->{'cmd_return'}->{ELEMENT}, $self);
            $ret = $ret_data;
        }
    }
    else {
        $ret = "Bad method, expected - class, class_name, css, id, link,
                link_text, partial_link_text, name, tag_name, xpath";
    }
    return $ret;
}

sub find_elements {
    my ( $self, $query, $method ) = @_;
    if ( not defined $query ) {
        return 'Search string to find element not provided.';
    }
    my $using = ( defined $method ) ? $method : 'xpath';
    my $ret;
    if (exists FINDERS->{$using}) {
        my $res = { 'command' => 'findElements' };
        my $params = { 'using' => $using, 'value' => $query };
        my $ret_data = $self->_execute_command( $res, $params );
        if (defined $ret_data->{'cmd_error'}) {
            $ret = $ret_data;
        }
        else {
            my $elem_obj_arr;
            my $i = 0;
            my $elem_arr = $ret_data->{'cmd_return'};
            foreach (@$elem_arr) {
                $elem_obj_arr->[$i] = new Selenium::Remote::WebElement($_->{ELEMENT}, $self);
                $i++;
            }
            $ret_data->{'cmd_return'} = $elem_obj_arr;
            $ret = $ret_data;
        }
    }
    else {
        $ret = "Bad method, expected - class, class_name, css, id, link,
                link_text, partial_link_text, name, tag_name, xpath";
    }
    return $ret;
}

sub find_child_element {
    my ( $self, $elem, $query, $method ) = @_;
    my $ret;
    if ( ( not defined $elem ) || ( not defined $query ) ) {
        return "Missing parameters";
    }
    my $using = ( defined $method ) ? $method : 'xpath';
    if (exists FINDERS->{$using}) {
        my $res = { 'command' => 'findChildElement', 'id' => $elem->{id} };
        my $params = { 'using' => $using, 'value' => $query };
        my $ret_data = $self->_execute_command( $res, $params );
        if (defined $ret_data->{'cmd_error'}) {
            $ret = $ret_data;
        }
        else {
            $ret_data->{'cmd_return'} = new Selenium::Remote::WebElement($ret_data->{'cmd_return'}->{ELEMENT}, $self);
            $ret = $ret_data;
        }
    }
    else {
        $ret = "Bad method, expected - class, class_name, css, id, link,
                link_text, partial_link_text, name, tag_name, xpath";
    }
    return $ret;
}

sub find_child_elements {
    my ( $self, $elem, $query, $method ) = @_;
    my $ret;
    if ( ( not defined $elem ) || ( not defined $query ) ) {
        return "Missing parameters";
    }
    my $using = ( defined $method ) ? $method : 'xpath';
    if (exists FINDERS->{$using}) {
        my $res = { 'command' => 'findChildElements', 'id' => $elem->{id} };
        my $params = { 'using' => $using, 'value' => $query };
        my $ret_data = $self->_execute_command( $res, $params );
        if (defined $ret_data->{'cmd_error'}) {
            $ret = $ret_data;
        }
        else {
            my $elem_obj_arr;
            my $i = 0;
            my $elem_arr = $ret_data->{'cmd_return'};
            foreach (@$elem_arr) {
                $elem_obj_arr->[$i] = new Selenium::Remote::WebElement($_->{ELEMENT}, $self);
                $i++;
            }
            $ret_data->{'cmd_return'} = $elem_obj_arr;
            $ret = $ret_data;
        }
    }
    else {
        $ret = "Bad method, expected - class, class_name, css, id, link,
                link_text, partial_link_text, name, tag_name, xpath";
    }

    return $ret;
}

sub get_active_element {
    my ($self) = @_;
    my $res = { 'command' => 'getActiveElement' };
    return $self->_execute_command($res);
}

sub describe_element {
    my ( $self, $element ) = @_;

    #if (not defined $element) {
    #    return "Element not provided";
    #}
    #my $res = {'command' => 'desribeElement', 'name' => $element};
    #return $self->_execute_command($res);
    return "Not yet supported";
}

sub compare_elements {
    my ($self, $elem1, $elem2) = @_;
    my $res = { 'command' => 'elementEquals',
                'id' => $elem1->{id},
                'other' => $elem2->{id}
              };
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

Copyright (c) 2010 Aditya Ivaturi

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
