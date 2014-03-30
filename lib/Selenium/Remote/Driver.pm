package Selenium::Remote::Driver;
$Selenium::Remote::Driver::VERSION = '0.18';
use Moo;
use Try::Tiny;

use 5.006;
use v5.10.0;    # Before 5.006, v5.10.0 would not be understood.

# See http://perldoc.perl.org/5.10.0/functions/use.html#use-VERSION
# and http://www.dagolden.com/index.php/369/version-numbers-should-be-boring/
# for details.

use Carp;
our @CARP_NOT;

use IO::Compress::Zip qw(zip $ZipError);
use Scalar::Util;
use Selenium::Remote::RemoteConnection;
use Selenium::Remote::Commands;
use Selenium::Remote::WebElement;

use constant FINDERS => {
    class             => 'class name',
    class_name        => 'class name',
    css               => 'css selector',
    id                => 'id',
    link              => 'link text',
    link_text         => 'link text',
    name              => 'name',
    partial_link_text => 'partial link text',
    tag_name          => 'tag name',
    xpath             => 'xpath',
};

=head1 NAME

Selenium::Remote::Driver - Perl Client for Selenium Remote Driver

=head1 VERSION

version 0.18

=cut

=head1 SYNOPSIS

    use Selenium::Remote::Driver;

    my $driver = Selenium::Remote::Driver->new;
    $driver->get('http://www.google.com');
    print $driver->get_title();
    $driver->quit();

=cut

=head1 DESCRIPTION

Selenium is a test tool that allows you to write
automated web application UI tests in any programming language against
any HTTP website using any mainstream JavaScript-enabled browser. This module is
an implementation of the client for the Remote driver that Selenium provides.
You can find bindings for other languages at this location:

L<http://code.google.com/p/selenium/>

This module sends commands directly to the Server using HTTP. Using this module
together with the Selenium Server, you can automatically control any supported
browser. To use this module, you need to have already downloaded and started
the Selenium Server (Selenium Server is a Java application).

=cut

=head1 USAGE (read this first)

=head2 Remote Driver Response

Selenium::Remote::Driver uses the L<JsonWireProtocol|http://code.google.com/p/selenium/wiki/JsonWireProtocol> to communicate with the
Selenium Server. If an error occurs while executing the command then the server
sends back an HTTP error code with a JSON encoded reponse that indicates the
precise L<Response Error Code|http://code.google.com/p/selenium/wiki/JsonWireProtocol#Response_Status_Codes>. The module will then croak with the error message
associated with this code. If no error occurred, then the subroutine called will
return the value sent back from the server (if a return value was sent).

So a rule of thumb while invoking methods on the driver is if the method did not
croak when called, then you can safely assume the command was successful even if
nothing was returned by the method.

=head2 WebElement

Selenium Webdriver represents all the HTML elements as WebElement, which is
in turn represented by L<Selenium::Remote::WebElement> module. So any method that
deals with WebElements will return and/or expect WebElement object. The POD for
that module describes all the methods that perform various actions on the
WebElements like click, submit etc.

To interact with any WebElement you have to first "find" it, read the POD for
find_element or find_elements for further info. Once you find the required element
then you can perform various actions. If you don't call find_* method first, all
your further actions will fail for that element. Finally, just remember that you
don't have to instantiate WebElement objects at all - they will be automatically
created when you use the find_* methods.

A sub-class of Selenium::Remote::WebElement may be used instead of Selenium::Remote::WebElement,
by providing that class name as an option the constructor:

   my $driver = Selenium::Remote::Driver->new( webelement_class => ... );

For example, a testing-subclass may extend the web-element object with testing methods.

=head1 TESTING

If are writing automated tests using this module, make sure you also see
L<Test::Selenium::Remote::Driver> which is also included in this distribution.
It includes convenience testing methods for many of the selenum methods
available here.

=head1 FUNCTIONS

=head2 new

 Description:
    Constructor for Driver. It'll instantiate the object if it can communicate
    with the Selenium RC server.

 Input: (all optional)
    desired_capabilities - HASH - Following options are accepted:
      Optional:
        'remote_server_addr'   - <string>   - IP or FQDN of the RC server machine
        'browser_name'         - <string>   - desired browser string: {iphone|firefox|internet explorer|htmlunit|iphone|chrome}
        'version'              - <string>   - desired browser version number
        'platform'             - <string>   - desired platform: {WINDOWS|XP|VISTA|MAC|LINUX|UNIX|ANY}
        'javascript'           - <boolean>  - whether javascript should be supported
        'accept_ssl_certs'     - <boolean>  - whether SSL certs should be accepted, default is true.
        'auto_close'           - <boolean>  - whether driver should end session on remote server on close.
        'default_finder'       - <string>   - choose default finder used for find_element* {class|class_name|css|id|link|link_text|name|partial_link_text|tag_name|xpath}
        'extra_capabilities'   - HASH of extra capabilities
        'webelement_class'     - <string>   - sub-class of Selenium::Remote::WebElement if you wish to use an alternate WebElement class.
        'proxy'                - HASH       - Proxy configuration with the following keys:
            'proxyType' - <string> - REQUIRED, Possible values are:
                direct     - A direct connection                                                                    - no proxy in use,
                manual     - Manual proxy settings configured, e.g. setting a proxy for HTTP, a proxy for FTP, etc,
                pac        - Proxy autoconfiguration from a URL,
                autodetect - proxy autodetection, probably with WPAD,
                system     - Use system settings
            'proxyAutoconfigUrl' - <string> - REQUIRED if proxyType is 'pac', ignored otherwise. Expected format: http://hostname.com:1234/pacfile.
            'ftpProxy'           - <string> - OPTIONAL, ignored if proxyType is not 'manual'. Expected format: hostname.com:1234
            'httpProxy'          - <string> - OPTIONAL, ignored if proxyType is not 'manual'. Expected format: hostname.com:1234
            'sslProxy'           - <string> - OPTIONAL, ignored if proxyType is not 'manual'. Expected format: hostname.com:1234


        If no values are provided, then these defaults will be assumed:
            'remote_server_addr' => 'localhost'
            'port'               => '4444'
            'browser_name'       => 'firefox'
            'version'            => ''
            'platform'           => 'ANY'
            'javascript'         => 1
            'auto_close'         => 1

 Output:
    Remote Driver object

 Usage:
    my $driver = Selenium::Remote::Driver->new;
    or
    my $driver = Selenium::Remote::Driver->new('browser_name' => 'firefox',
                                              'platform' => 'MAC');
    or
    my $driver = Selenium::Remote::Driver->new('remote_server_addr' => '10.10.1.1',
                                              'port' => '2222',
                                              auto_close => 0
                                              );
    or
    my $driver = Selenium::Remote::Driver->new('browser_name'       => 'chrome',
                                              'platform'           => 'VISTA',
                                              'extra_capabilities' => {'chrome.switches' => ["--user-data-dir=$ENV{LOCALAPPDATA}\\Google\\Chrome\\User Data"],
                                                                                                'chrome.prefs' => {'download.default_directory' =>'/home/user/tmp', 'download.prompt_for_download' =>1 }
                                                                                                },
                                              );
    or
    my $driver = Selenium::Remote::Driver->new('proxy' => {'proxyType' => 'manual', 'httpProxy' => 'myproxy.com:1234'});
    or
    my $driver = Selenium::Remote::Driver->new('default_finder' => 'css');

=cut

has 'remote_server_addr' => (
    is      => 'rw',
    coerce  => sub { ( defined($_[0]) ? $_[0] : 'localhost' )},
    default => sub {'localhost'},
);

has 'browser_name' => (
    is      => 'rw',
    coerce  => sub { ( defined($_[0]) ? $_[0] : 'firefox' )},
    default => sub {'firefox'},
);

has 'platform' => (
    is      => 'rw',
    coerce  => sub { ( defined($_[0]) ? $_[0] : 'ANY' )},
    default => sub {'ANY'},
);

has 'port' => (
    is      => 'rw',
    coerce  => sub { ( defined($_[0]) ? $_[0] : '4444' )},
    default => sub {'4444'},
);

has 'version' => (
    is      => 'rw',
    default => sub {''},
);

has 'webelement_class' => (
    is      => 'rw',
    default => sub {'Selenium::Remote::WebElement'},
);


has 'default_finder' => (
    is      => 'rw',
    coerce  => sub { FINDERS->{ $_[0] } },
    default => sub {'xpath'},
);

has 'session_id' => (
    is      => 'rw',
    default => sub {undef},
);

has 'remote_conn' => (
    is      => 'lazy',
    builder => sub {
        my $self = shift;
        return Selenium::Remote::RemoteConnection->new(
            remote_server_addr => $self->remote_server_addr,
            port               => $self->port
        );
    },
);

has 'commands' => (
    is      => 'lazy',
    builder => sub { return Selenium::Remote::Commands->new; },
);

has 'auto_close' => (
    is      => 'rw',
    coerce  => sub { ( defined($_[0]) ? $_[0] : 1 )},
    default => sub {1},
);

has 'pid' => (
    is      => 'lazy',
    builder => sub { return $$ }
);

has 'javascript' => (
    is     => 'rw',
    coerce => sub { $_[0] ? JSON::true : JSON::false },
    default => sub { return JSON::true }
);

has 'accept_ssl_certs' => (
    is     => 'rw',
    coerce => sub { $_[0] ? JSON::true : JSON::false },
    default => sub { return JSON::true }
);

has 'proxy' => (
    is     => 'rw',
    coerce => sub {
        my $proxy = $_[0];
        if ( $proxy->{proxyType} eq 'pac' ) {
            if ( not defined $proxy->{proxyAutoconfigUrl} ) {
                croak "proxyAutoconfigUrl not provided\n";
            }
            elsif ( not( $proxy->{proxyAutoconfigUrl} =~ /^http/g ) ) {
                croak "proxyAutoconfigUrl should be of format http://";
            }
        }
    },
);

has 'extra_capabilities' => (
    is      => 'rw',
    default => sub { {} },
);

sub BUILD {
    my $self = shift;

    # Connect to remote server & establish a new session
    $self->new_session( $self->extra_capabilities );

    if ( !( defined $self->session_id ) ) {
        croak "Could not establish a session with the remote server\n";
    }
}

sub DESTROY {
    my ($self) = @_;
    return if $$ != $self->pid;
    $self->quit() if ( $self->auto_close && defined $self->session_id );
}

# This is an internal method used the Driver & is not supposed to be used by
# end user. This method is used by Driver to set up all the parameters
# (url & JSON), send commands & receive processed response from the server.
sub _execute_command {
    my ( $self, $res, $params ) = @_;
    $res->{'session_id'} = $self->session_id;
    my $resource = $self->commands->get_params($res);
    if ($resource) {
        my $resp =
          $self->remote_conn->request( $resource->{'method'},
            $resource->{'url'}, $params );
        if ( ref($resp) eq 'HASH' ) {
            if ( $resp->{cmd_status} && $resp->{cmd_status} eq 'OK' ) {
                return $resp->{cmd_return};
            }
            else {
                my $msg = "Error while executing command";
                if ( $resp->{cmd_error} ) {
                    $msg .= ": $resp->{cmd_error}" if $resp->{cmd_error};
                }
                elsif ( $resp->{cmd_return} ) {
                    if ( ref( $resp->{cmd_return} ) eq 'HASH' ) {
                        $msg .= ": $resp->{cmd_return}->{error}->{msg}"
                          if $resp->{cmd_return}->{error}->{msg};
                        $msg .= ": $resp->{cmd_return}->{message}"
                          if $resp->{cmd_return}->{message};
                    }
                    else {
                        $msg .= ": $resp->{cmd_return}";
                    }
                }
                croak $msg;
            }
        }
        return $resp;
    }
    else {
        croak "Couldn't retrieve command settings properly\n";
    }
}

# A method that is used by the Driver itself. It'll be called to set the
# desired capabilities on the server.
sub new_session {
    my ( $self, $extra_capabilities ) = @_;
    $extra_capabilities ||= {};
    my $args = {
        'desiredCapabilities' => {
            'browserName'       => $self->browser_name,
            'platform'          => $self->platform,
            'javascriptEnabled' => $self->javascript,
            'version'           => $self->version,
            'acceptSslCerts'    => $self->accept_ssl_certs,
            %$extra_capabilities,
        },
    };

    if ( defined $self->proxy ) {
        $args->{desiredCapabilities}->{proxy} = $self->proxy;
    }

    # command => 'newSession' to fool the tests of commands implemented
    # TODO: rewrite the testing better, this is so fragile.
    my $resp = $self->remote_conn->request(
        $self->commands->get_method('newSession'),
        $self->commands->get_url('newSession'), $args,
    );
    if ( ( defined $resp->{'sessionId'} ) && $resp->{'sessionId'} ne '' ) {
        $self->session_id( $resp->{'sessionId'} );
    }
    else {
        my $error = 'Could not create new session';
        $error .= ": $resp->{cmd_return}" if defined $resp->{cmd_return};
        croak $error;
    }
}

=head2 debug_on

  Description:
    Turns on debugging mode and the driver will print extra info like request
    and response to stdout. Useful, when you want to see what is being sent to
    the server & what response you are getting back.

  Usage:
    $driver->debug_on;

=cut

sub debug_on {
    my ($self) = @_;
    $self->remote_conn->debug(1);
}

=head2 debug_off

  Description:
    Turns off the debugging mode.

  Usage:
    $driver->debug_off;

=cut

sub debug_off {
    my ($self) = @_;
    $self->remote_conn->debug(0);
}

=head2 get_sessions

  Description:
    Returns a list of the currently active sessions. Each session will be
    returned as an array of Hashes with the following keys:

    'id' : The session ID
    'capabilities: An object describing session's capabilities

  Output:
    Array of Hashes

  Usage:
    print Dumper $driver->get_sessions();

=cut

sub get_sessions {
    my ($self) = @_;
    my $res = { 'command' => 'getSessions' };
    return $self->_execute_command($res);
}

=head2 status

  Description:
    Query the server's current status. All server implementations
    should return two basic objects describing the server's current
    platform and when the server was built.

  Output:
    Hash ref

  Usage:
    print Dumper $driver->status;

=cut

sub status {
    my ($self) = @_;
    my $res = { 'command' => 'status' };
    return $self->_execute_command($res);
}

=head2 get_alert_text

 Description:
    Gets the text of the currently displayed JavaScript alert(), confirm()
    or prompt() dialog.

 Example
    my $string = $driver->get_alert_text;

=cut

sub get_alert_text {
    my ($self) = @_;
    my $res = { 'command' => 'getAlertText' };
    return $self->_execute_command($res);
}

=head2 send_keys_to_active_element

 Description:
    Send a sequence of key strokes to the active element. This command is
    similar to the send keys command in every aspect except the implicit
    termination: The modifiers are not released at the end of the call.
    Rather, the state of the modifier keys is kept between calls, so mouse
    interactions can be performed while modifier keys are depressed.

 Input: 1
    Required:
        {ARRAY | STRING} - Array of strings or a string.

 Usage:
    $driver->send_keys_to_active_element('abcd', 'efg');
    $driver->send_keys_to_active_element('hijk');

    or

    # include the WDKeys module
    use Selenium::Remote::WDKeys;
    .
    .
    $driver->send_keys_to_active_element(KEYS->{'space'}, KEYS->{'enter'});

=cut

sub send_keys_to_active_element {
    my ( $self, @strings ) = @_;
    my $res = { 'command' => 'sendKeysToActiveElement' };
    my $params = {
        'value' => \@strings,
    };
    return $self->_execute_command( $res, $params );
}

=head2 send_keys_to_alert

Synonymous with send_keys_to_prompt

=cut

sub send_keys_to_alert {
    return shift->send_keys_to_prompt(@_);
}

=head2 send_keys_to_prompt

 Description:
    Sends keystrokes to a JavaScript prompt() dialog.

 Input:
    {string} keys to send

 Example:
    $driver->send_keys_to_prompt('hello world');
  or
    ok($driver->get_alert_text eq 'Please Input your name','prompt appears');
    $driver->send_keys_to_alert("Larry Wall");
    $driver->accept_alert;

=cut

sub send_keys_to_prompt {
    my ( $self, $keys ) = @_;
    my $res    = { 'command' => 'sendKeysToPrompt' };
    my $params = { 'text'    => $keys };
    return $self->_execute_command( $res, $params );
}

=head2 accept_alert

 Description:
    Accepts the currently displayed alert dialog.  Usually, this is
    equivalent to clicking the 'OK' button in the dialog.

 Example:
    $driver->accept_alert;

=cut

sub accept_alert {
    my ($self) = @_;
    my $res = { 'command' => 'acceptAlert' };
    return $self->_execute_command($res);
}

=head2 dismiss_alert

 Description:
    Dismisses the currently displayed alert dialog. For comfirm()
    and prompt() dialogs, this is equivalent to clicking the
    'Cancel' button. For alert() dialogs, this is equivalent to
    clicking the 'OK' button.

 Example:
    $driver->dismiss_alert;

=cut

sub dismiss_alert {
    my ($self) = @_;
    my $res = { 'command' => 'dismissAlert' };
    return $self->_execute_command($res);
}

=head2 mouse_move_to_location

 Description:
    Move the mouse by an offset of the specificed element. If no
    element is specified, the move is relative to the current mouse
    cursor. If an element is provided but no offset, the mouse will be
    moved to the center of the element. If the element is not visible,
    it will be scrolled into view.

 Output:
    STRING -

 Usage:
    # element - the element to move to. If not specified or is null, the offset is relative to current position of the mouse.
    # xoffset - X offset to move to, relative to the top-left corner of the element. If not specified, the mouse will move to the middle of the element.
    # yoffset - Y offset to move to, relative to the top-left corner of the element. If not specified, the mouse will move to the middle of the element.

    print $driver->mouse_move_to_location(element => e, xoffset => x, yoffset => y);

=cut

sub mouse_move_to_location {
    my ( $self, %params ) = @_;
    $params{element} = $params{element}{id} if exists $params{element};
    my $res = { 'command' => 'mouseMoveToLocation' };
    return $self->_execute_command( $res, \%params );
}

=head2 move_to

Synonymous with mouse_move_to_location

=cut

sub move_to {
    return shift->mouse_move_to_location(@_);
}

=head2 get_capabilities

 Description:
    Retrieve the capabilities of the specified session.

 Output:
    HASH of all the capabilities.

 Usage:
    my $capab = $driver->get_capabilities();
    print Dumper($capab);

=cut

sub get_capabilities {
    my $self = shift;
    my $res = { 'command' => 'getCapabilities' };
    return $self->_execute_command($res);
}

=head2 set_timeout

 Description:
    Configure the amount of time that a particular type of operation can execute
    for before they are aborted and a |Timeout| error is returned to the client.

 Input:
    type - <STRING> - The type of operation to set the timeout for.
                      Valid values are:
                      "script"    : for script timeouts,
                      "implicit"  : for modifying the implicit wait timeout
                      "page load" : for setting a page load timeout.
    ms - <NUMBER> - The amount of time, in milliseconds, that time-limited
            commands are permitted to run.

 Usage:
    $driver->set_timeout('script', 1000);

=cut

sub set_timeout {
    my ( $self, $type, $ms ) = @_;
    if ( not defined $type or not defined $ms ) {
        croak "Expecting type & timeout in ms";
    }
    my $res = { 'command' => 'setTimeout' };
    my $params = { 'type' => $type, 'ms' => $ms };
    return $self->_execute_command( $res, $params );
}

=head2 set_async_script_timeout

 Description:
    Set the amount of time, in milliseconds, that asynchronous scripts executed
    by execute_async_script() are permitted to run before they are
    aborted and a |Timeout| error is returned to the client.

 Input:
    ms - <NUMBER> - The amount of time, in milliseconds, that time-limited
            commands are permitted to run.

 Usage:
    $driver->set_async_script_timeout(1000);

=cut

sub set_async_script_timeout {
    my ( $self, $ms ) = @_;
    if ( not defined $ms ) {
        croak "Expecting timeout in ms";
    }
    my $res    = { 'command' => 'setAsyncScriptTimeout' };
    my $params = { 'ms'      => $ms };
    return $self->_execute_command( $res, $params );
}

=head2 set_implicit_wait_timeout

 Description:
    Set the amount of time the driver should wait when searching for elements.
    When searching for a single element, the driver will poll the page until
    an element is found or the timeout expires, whichever occurs first.
    When searching for multiple elements, the driver should poll the page until
    at least one element is found or the timeout expires, at which point it
    will return an empty list. If this method is never called, the driver will
    default to an implicit wait of 0ms.

 Input:
    Time in milliseconds.

 Output:
    Server Response Hash with no data returned back from the server.

 Usage:
    $driver->set_implicit_wait_timeout(10);

=cut

sub set_implicit_wait_timeout {
    my ( $self, $ms ) = @_;
    my $res    = { 'command' => 'setImplicitWaitTimeout' };
    my $params = { 'ms'      => $ms };
    return $self->_execute_command( $res, $params );
}

=head2 pause

 Description:
    Pause execution for a specified interval of milliseconds.

 Usage:
    $driver->pause(10000);  # 10 second delay
    $driver->pause();       #  1 second delay default

=cut

sub pause {
    my $self = shift;
    my $timeout = ( shift // 1000 ) / 1000;
    select( undef, undef, undef, $timeout );    # Fractional-second sleep
}

=head2 close

 Description:
    Close the current window.

 Usage:
    $driver->close();
 or
    #close a popup window
    my $handles = $driver->get_window_handles;
    $driver->switch_to_window($handles->[1]);
    $driver->close();
    $driver->switch_to_window($handles->[0]);

=cut

sub close {
    my $self = shift;
    my $res = { 'command' => 'close' };
    $self->_execute_command($res);
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
    $self->_execute_command($res);
    $self->session_id(undef);
}

=head2 get_current_window_handle

 Description:
    Retrieve the current window handle.

 Output:
    STRING - the window handle

 Usage:
    print $driver->get_current_window_handle();

=cut

sub get_current_window_handle {
    my $self = shift;
    my $res = { 'command' => 'getCurrentWindowHandle' };
    return $self->_execute_command($res);
}

=head2 get_window_handles

 Description:
    Retrieve the list of window handles used in the session.

 Output:
    ARRAY of STRING - list of the window handles

 Usage:
    print Dumper $driver->get_window_handles;
 or
    # get popup, close, then back
    my $handles = $driver->get_window_handles;
    $driver->switch_to_window($handles->[1]);
    $driver->close;
    $driver->switch_to_window($handles->[0]);

=cut

sub get_window_handles {
    my $self = shift;
    my $res = { 'command' => 'getWindowHandles' };
    return $self->_execute_command($res);
}

=head2 get_window_size

 Description:
    Retrieve the window size

 Input:
    STRING - <optional> - window handle (default is 'current' window)

 Output:
    HASH - containing keys 'height' & 'width'

 Usage:
    my $window_size = $driver->get_window_size();
    print $window_size->{'height'}, $window_size->('width');

=cut

sub get_window_size {
    my ( $self, $window ) = @_;
    $window = ( defined $window ) ? $window : 'current';
    my $res = { 'command' => 'getWindowSize', 'window_handle' => $window };
    return $self->_execute_command($res);
}

=head2 get_window_position

 Description:
    Retrieve the window position

 Input:
    STRING - <optional> - window handle (default is 'current' window)

 Output:
    HASH - containing keys 'x' & 'y'

 Usage:
    my $window_size = $driver->get_window_position();
    print $window_size->{'x'}, $window_size->('y');

=cut

sub get_window_position {
    my ( $self, $window ) = @_;
    $window = ( defined $window ) ? $window : 'current';
    my $res = { 'command' => 'getWindowPosition', 'window_handle' => $window };
    return $self->_execute_command($res);
}

=head2 get_current_url

 Description:
    Retrieve the url of the current page

 Output:
    STRING - url

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
    STRING - url

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
    STRING - url

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
    STRING - Page title

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

=head2 go_forward

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
    my $res = { 'command' => 'refresh' };
    return $self->_execute_command($res);
}

=head2 javascript

 Description:
    returns true if javascript is enabled in the driver.

 Usage:
    if ($driver->has_javascript) { ...; }

=cut

sub has_javascript {
    my $self = shift;
    return $self->javascript == JSON::true;
}

=head2 execute_async_script

 Description:
    Inject a snippet of JavaScript into the page for execution in the context
    of the currently selected frame. The executed script is assumed to be
    asynchronous and must signal that is done by invoking the provided
    callback, which is always provided as the final argument to the function.
    The value to this callback will be returned to the client.

    Asynchronous script commands may not span page loads. If an unload event
    is fired while waiting for a script result, an error should be returned
    to the client.

 Input: 2 (1 optional)
    Required:
        STRING - Javascript to execute on the page
    Optional:
        ARRAY - list of arguments that need to be passed to the script.

 Output:
    {*} - Varied, depending on the type of result expected back from the script.

 Usage:
    my $script = q{
        var arg1 = arguments[0];
        var callback = arguments[arguments.length-1];
        var elem = window.document.findElementById(arg1);
        callback(elem);
    };
    my $elem = $driver->execute_async_script($script,'myid');
    $elem->click;

=cut

sub execute_async_script {
    my ( $self, $script, @args ) = @_;
    if ( $self->has_javascript ) {
        if ( not defined $script ) {
            croak 'No script provided';
        }
        my $res = { 'command' => 'executeAsyncScript' };

        # Check the args array if the elem obj is provided & replace it with
        # JSON representation
        for ( my $i = 0; $i < @args; $i++ ) {
            if ( Scalar::Util::blessed( $args[$i] )
                and $args[$i]->isa('Selenium::Remote::WebElement') )
            {
                $args[$i] = { 'ELEMENT' => ( $args[$i] )->{id} };
            }
        }

        my $params = { 'script' => $script, 'args' => \@args };
        my $ret = $self->_execute_command( $res, $params );

        # replace any ELEMENTS with WebElement
        if (    ref($ret)
            and ( ref($ret) eq 'HASH' )
            and exists $ret->{'ELEMENT'} )
        {
            $ret = $self->webelement_class->new( id => $ret->{ELEMENT},
                driver => $self );
        }
        return $ret;
    }
    else {
        croak 'Javascript is not enabled on remote driver instance.';
    }
}

=head2 execute_script

 Description:
    Inject a snippet of JavaScript into the page and return its result.
    WebElements that should be passed to the script as an argument should be
    specified in the arguments array as WebElement object. Likewise,
    any WebElements in the script result will be returned as WebElement object.

 Input: 2 (1 optional)
    Required:
        STRING - Javascript to execute on the page
    Optional:
        ARRAY - list of arguments that need to be passed to the script.

 Output:
    {*} - Varied, depending on the type of result expected back from the script.

 Usage:
    my $script = q{
        var arg1 = arguments[0];
        var elem = window.document.findElementById(arg1);
        return elem;
    };
    my $elem = $driver->execute_script($script,'myid');
    $elem->click;

=cut

sub execute_script {
    my ( $self, $script, @args ) = @_;
    if ( $self->has_javascript ) {
        if ( not defined $script ) {
            croak 'No script provided';
        }
        my $res = { 'command' => 'executeScript' };

        # Check the args array if the elem obj is provided & replace it with
        # JSON representation
        for ( my $i = 0; $i < @args; $i++ ) {
            if ( Scalar::Util::blessed( $args[$i] )
                and $args[$i]->isa('Selenium::Remote::WebElement') )
            {
                $args[$i] = { 'ELEMENT' => ( $args[$i] )->{id} };
            }
        }

        my $params = { 'script' => $script, 'args' => [@args] };
        my $ret = $self->_execute_command( $res, $params );

        return $self->_convert_to_webelement($ret);
    }
    else {
        croak 'Javascript is not enabled on remote driver instance.';
    }
}

# _convert_to_webelement
# An internal method used to traverse a data structure
# and convert any ELEMENTS with WebElements

sub _convert_to_webelement {
    my ( $self, $ret ) = @_;

    if ( ref($ret) and ( ref($ret) eq 'HASH' ) ) {
        if ( ( keys %$ret == 1 ) and exists $ret->{'ELEMENT'} ) {

            # replace an ELEMENT with WebElement
            return $self->webelement_class->new( id => $ret->{ELEMENT},
                driver => $self );
        }

        my %hash;
        foreach my $key ( keys %$ret ) {
            $hash{$key} = $self->_convert_to_webelement( $ret->{$key} );
        }
        return \%hash;
    }

    if ( ref($ret) and ( ref($ret) eq 'ARRAY' ) ) {
        my @array = map { $self->_convert_to_webelement($_) } @$ret;
        return \@array;
    }

    return $ret;
}

=head2 screenshot

 Description:
    Get a screenshot of the current page as a base64 encoded image.

 Output:
    STRING - base64 encoded image

 Usage:
    print $driver->screenshot();

To conveniently write the screenshot to a file, see L<capture_screenshot()>.

=cut

sub screenshot {
    my ($self) = @_;
    my $res = { 'command' => 'screenshot' };
    return $self->_execute_command($res);
}

=head2 capture_screenshot

 Description:
    Capture a screenshot and save as a PNG to provided file name.
    (The method is compatible with the WWW::Selenium method fo the same name)

 Output:
    TRUE - (Screenshot is written to file)

 Usage:
    $driver->capture_screenshot($filename);

=cut

sub capture_screenshot {
    my ( $self, $filename ) = @_;
    croak '$filename is required' unless $filename;

    require MIME::Base64;
    open( my $fh, '>', $filename );
    binmode $fh;
    print $fh MIME::Base64::decode_base64( $self->screenshot() );
    CORE::close $fh;
    return 1;
}


=head2 available_engines

 Description:
    List all available engines on the machine. To use an engine, it has to be present in this list.

 Output:
    {Array.<string>} A list of available engines

 Usage:
    print Dumper $driver->available_engines;

=cut

sub available_engines {
    my ($self) = @_;
    my $res = { 'command' => 'availableEngines' };
    return $self->_execute_command($res);
}

=head2 switch_to_frame

 Description:
    Change focus to another frame on the page. If the frame ID is null, the
    server will switch to the page's default content. You can also switch to a
    WebElement, for e.g. you can find an iframe using find_element & then
    provide that as an input to this method. Also see e.g.

 Input: 1
    Required:
        {STRING | NUMBER | NULL | WebElement} - ID of the frame which can be one of the three
                                   mentioned.

 Usage:
    $driver->switch_to_frame('frame_1');
    or
    $driver->switch_to_frame($driver->find_element('iframe', 'tag_name'));

=cut

sub switch_to_frame {
    my ( $self, $id ) = @_;
    my $json_null = JSON::null;
    my $params;
    $id = ( defined $id ) ? $id : $json_null;

    my $res = { 'command' => 'switchToFrame' };
    if ( ref $id eq $self->webelement_class ) {
        $params = { 'id' => { 'ELEMENT' => $id->{'id'} } };
    }
    else {
        $params = { 'id' => $id };
    }
    return $self->_execute_command( $res, $params );
}

=head2 switch_to_window

 Description:
    Change focus to another window. The window to change focus to may be
    specified by its server assigned window handle, or by the value of its name
    attribute.

 Input: 1
    Required:
        STRING - Window handle or the Window name

 Usage:
    $driver->switch_to_window('MY Homepage');
 or
    # close a popup window and switch back
    my $handles = $driver->get_window_handles;
    $driver->switch_to_window($handles->[1]);
    $driver->close;
    $driver->switch_to_window($handles->[0]);

=cut

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
    STRING - One of these: SLOW, MEDIUM, FAST

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
    STRING - One of these: SLOW, MEDIUM, FAST

 Usage:
    $driver->set_speed('MEDIUM');

 Note: This function is a no-op in WebDriver (?). See
       https://groups.google.com/d/topic/selenium-users/oX0ZnYFPuSA/discussion and
       http://code.google.com/p/selenium/source/browse/trunk/java/client/src/org/openqa/selenium/WebDriverCommandProcessor.java

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

=head2 set_window_position

 Description:
    Set the position (on screen) where you want your browser to be displayed.

 Input:
    INT - x co-ordinate
    INT - y co-ordinate
    STRING - <optional> - window handle (default is 'current' window)

 Output:
    BOOLEAN - Success or failure

 Usage:
    $driver->set_window_position(50, 50);

=cut

sub set_window_position {
    my ( $self, $x, $y, $window ) = @_;
    $window = ( defined $window ) ? $window : 'current';
    if ( not defined $x and not defined $y ) {
        croak "X & Y co-ordinates are required";
    }
    my $res = { 'command' => 'setWindowPosition', 'window_handle' => $window };
    my $params = { 'x' => $x, 'y' => $y };
    my $ret = $self->_execute_command( $res, $params );
    if ( $ret =~ m/204/g ) {
        return 1;
    }
    else { return 0; }
}

=head2 set_window_size

 Description:
    Set the size of the browser window

 Input:
    INT - height of the window
    INT - width of the window
    STRING - <optional> - window handle (default is 'current' window)

 Output:
    BOOLEAN - Success or failure

 Usage:
    $driver->set_window_size(640, 480);

=cut

sub set_window_size {
    my ( $self, $height, $width, $window ) = @_;
    $window = ( defined $window ) ? $window : 'current';
    if ( not defined $height and not defined $width ) {
        croak "height & width of browser are required";
    }
    my $res = { 'command' => 'setWindowSize', 'window_handle' => $window };
    my $params = { 'height' => $height, 'width' => $width };
    my $ret = $self->_execute_command( $res, $params );
    if ( $ret =~ m/204/g ) {
        return 1;
    }
    else { return 0; }
}

=head2 get_all_cookies

 Description:
    Retrieve all cookies visible to the current page. Each cookie will be
    returned as a HASH reference with the following keys & their value types:

    'name' - STRING
    'value' - STRING
    'path' - STRING
    'domain' - STRING
    'secure' - BOOLEAN

 Output:
    ARRAY of HASHES - list of all the cookie hashes

 Usage:
    print Dumper($driver->get_all_cookies());

=cut

sub get_all_cookies {
    my ($self) = @_;
    my $res = { 'command' => 'getAllCookies' };
    return $self->_execute_command($res);
}

=head2 add_cookie

 Description:
    Set a cookie on the domain.

 Input: 5 (1 optional)
    Required:
        'name' - STRING
        'value' - STRING
        'path' - STRING
        'domain' - STRING
    Optional:
        'secure' - BOOLEAN - default is false.

 Usage:
    $driver->add_cookie('foo', 'bar', '/', '.google.com', 0)

=cut

sub add_cookie {
    my ( $self, $name, $value, $path, $domain, $secure ) = @_;

    if (   ( not defined $name )
        || ( not defined $value )
        || ( not defined $path )
        || ( not defined $domain ) )
    {
        croak "Missing parameters";
    }

    my $res        = { 'command' => 'addCookie' };
    my $json_false = JSON::false;
    my $json_true  = JSON::true;
    $secure = ( defined $secure && $secure ) ? $json_true : $json_false;

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

=head2 delete_all_cookies

 Description:
    Delete all cookies visible to the current page.

 Usage:
    $driver->delete_all_cookies();

=cut

sub delete_all_cookies {
    my ($self) = @_;
    my $res = { 'command' => 'deleteAllCookies' };
    return $self->_execute_command($res);
}

=head2 delete_cookie_named

 Description:
    Delete the cookie with the given name. This command will be a no-op if there
    is no such cookie visible to the current page.

 Input: 1
    Required:
        STRING - name of cookie to delete

 Usage:
    $driver->delete_cookie_named('foo');

=cut

sub delete_cookie_named {
    my ( $self, $cookie_name ) = @_;
    if ( not defined $cookie_name ) {
        croak "Cookie name not provided";
    }
    my $res = { 'command' => 'deleteCookieNamed', 'name' => $cookie_name };
    return $self->_execute_command($res);
}

=head2 get_page_source

 Description:
    Get the current page source.

 Output:
    STRING - The page source.

 Usage:
    print $driver->get_page_source();

=cut

sub get_page_source {
    my ($self) = @_;
    my $res = { 'command' => 'getPageSource' };
    return $self->_execute_command($res);
}

=head2 find_element

 Description:
    Search for an element on the page, starting from the document root. The
    located element will be returned as a WebElement object.

 Input: 2 (1 optional)
    Required:
        STRING - The search target.
    Optional:
        STRING - Locator scheme to use to search the element, available schemes:
                 {class, class_name, css, id, link, link_text, partial_link_text,
                  tag_name, name, xpath}
                 Defaults to 'xpath' if not configured global during instantiation.

 Output:
    Selenium::Remote::WebElement - WebElement Object
        (This could be a subclass of L<Selenium::Remote::WebElement> if C<webelement_class> was set.

 Usage:
    $driver->find_element("//input[\@name='q']");

=cut

sub find_element {
    my ( $self, $query, $method ) = @_;
    if ( not defined $query ) {
        croak 'Search string to find element not provided.';
    }
    my $using =
      ( defined $method ) ? FINDERS->{$method} : $self->default_finder;
    if ( defined $using ) {
        my $res = { 'command' => 'findElement' };
        my $params = { 'using' => $using, 'value' => $query };
        my $ret_data = eval { $self->_execute_command( $res, $params ); };
        if ($@) {
            if ( $@
                =~ /(An element could not be located on the page using the given search parameters)/
              )
            {
                # give details on what element wasn't found
                $@ = "$1: $query,$using";
                local @CARP_NOT = ( "Selenium::Remote::Driver", @CARP_NOT );
                croak $@;
            }
            else {
                # re throw if the exception wasn't what we expected
                die $@;
            }
        }
        return $self->webelement_class->new( id => $ret_data->{ELEMENT},
            driver => $self );
    }
    else {
        croak "Bad method, expected - class, class_name, css, id, link,
                link_text, partial_link_text, name, tag_name, xpath";
    }
}

=head2 find_elements

 Description:
    Search for multiple elements on the page, starting from the document root.
    The located elements will be returned as an array of WebElement object.

 Input: 2 (1 optional)
    Required:
        STRING - The search target.
    Optional:
        STRING - Locator scheme to use to search the element, available schemes:
                 {class, class_name, css, id, link, link_text, partial_link_text,
                  tag_name, name, xpath}
                 Defaults to 'xpath' if not configured global during instantiation.

 Output:
    ARRAY of WebElement Objects

 Usage:
    $driver->find_elements("//input");

=cut

sub find_elements {
    my ( $self, $query, $method ) = @_;
    if ( not defined $query ) {
        croak 'Search string to find element not provided.';
    }

    my $using =
      ( defined $method ) ? FINDERS->{$method} : $self->default_finder;

    if ( defined $using ) {
        my $res = { 'command' => 'findElements' };
        my $params = { 'using' => $using, 'value' => $query };
        my $ret_data = eval { $self->_execute_command( $res, $params ); };
        if ($@) {
            if ( $@
                =~ /(An element could not be located on the page using the given search parameters)/
              )
            {
                # give details on what element wasn't found
                $@ = "$1: $query,$using";
                local @CARP_NOT = ( "Selenium::Remote::Driver", @CARP_NOT );
                croak $@;
            }
            else {
                # re throw if the exception wasn't what we expected
                die $@;
            }
        }
        my @elem_obj_arr = ();
        foreach (@$ret_data) {
            push(
                @elem_obj_arr,
                $self->webelement_class->new(
                    id => $_->{ELEMENT}, driver => $self
                )
            );
        }
        return @elem_obj_arr;
    }
    else {
        croak "Bad method, expected - class, class_name, css, id, link,
                link_text, partial_link_text, name, tag_name, xpath";
    }
}

=head2 find_child_element

 Description:
    Search for an element on the page, starting from the identified element. The
    located element will be returned as a WebElement object.

 Input: 3 (1 optional)
    Required:
        Selenium::Remote::WebElement - WebElement object from where you want to
                                       start searching.
        STRING - The search target. (Do not use a double whack('//')
                 in an xpath to search for a child element
                 ex: '//option[@id="something"]'
                 instead use a dot whack ('./')
                 ex: './option[@id="something"]')
    Optional:
        STRING - Locator scheme to use to search the element, available schemes:
                 {class, class_name, css, id, link, link_text, partial_link_text,
                  tag_name, name, xpath}
                 Defaults to 'xpath' if not configured global during instantiation.

 Output:
    WebElement Object

 Usage:
    my $elem1 = $driver->find_element("//select[\@name='ned']");
    # note the usage of ./ when searching for a child element instead of //
    my $child = $driver->find_child_element($elem1, "./option[\@value='es_ar']");

=cut

sub find_child_element {
    my ( $self, $elem, $query, $method ) = @_;
    if ( ( not defined $elem ) || ( not defined $query ) ) {
        croak "Missing parameters";
    }
    my $using = ( defined $method ) ? $method : $self->default_finder;
    if ( exists FINDERS->{$using} ) {
        my $res = { 'command' => 'findChildElement', 'id' => $elem->{id} };
        my $params = { 'using' => FINDERS->{$using}, 'value' => $query };
        my $ret_data = eval { $self->_execute_command( $res, $params ); };
        if ($@) {
            if ( $@
                =~ /(An element could not be located on the page using the given search parameters)/
              )
            {
                # give details on what element wasn't found
                $@ = "$1: $query,$using";
                local @CARP_NOT = ( "Selenium::Remote::Driver", @CARP_NOT );
                croak $@;
            }
            else {
                # re throw if the exception wasn't what we expected
                die $@;
            }
        }
        return $self->webelement_class->new( id => $ret_data->{ELEMENT},
            driver => $self );
    }
    else {
        croak "Bad method, expected - class, class_name, css, id, link,
                link_text, partial_link_text, name, tag_name, xpath";
    }
}

=head2 find_child_elements

 Description:
    Search for multiple element on the page, starting from the identified
    element. The located elements will be returned as an array of WebElement
    objects.

 Input: 3 (1 optional)
    Required:
        Selenium::Remote::WebElement - WebElement object from where you want to
                                       start searching.
        STRING - The search target.
    Optional:
        STRING - Locator scheme to use to search the element, available schemes:
                 {class, class_name, css, id, link, link_text, partial_link_text,
                  tag_name, name, xpath}
                 Defaults to 'xpath' if not configured global during instantiation.

 Output:
    ARRAY of WebElement Objects.

 Usage:
    my $elem1 = $driver->find_element("//select[\@name='ned']");
    my $child = $driver->find_child_elements($elem1, "//option");

=cut

sub find_child_elements {
    my ( $self, $elem, $query, $method ) = @_;
    if ( ( not defined $elem ) || ( not defined $query ) ) {
        croak "Missing parameters";
    }
    my $using = ( defined $method ) ? $method : $self->default_finder;
    if ( exists FINDERS->{$using} ) {
        my $res = { 'command' => 'findChildElements', 'id' => $elem->{id} };
        my $params = { 'using' => FINDERS->{$using}, 'value' => $query };
        my $ret_data = eval { $self->_execute_command( $res, $params ); };
        if ($@) {
            if ( $@
                =~ /(An element could not be located on the page using the given search parameters)/
              )
            {
                # give details on what element wasn't found
                $@ = "$1: $query,$using";
                local @CARP_NOT = ( "Selenium::Remote::Driver", @CARP_NOT );
                croak $@;
            }
            else {
                # re throw if the exception wasn't what we expected
                die $@;
            }
        }
        my $elem_obj_arr;
        my $i = 0;
        foreach (@$ret_data) {
            $elem_obj_arr->[$i] =
              $self->webelement_class->new( id => $_->{ELEMENT},
                driver => $self );
            $i++;
        }
        return wantarray ? @{$elem_obj_arr} : $elem_obj_arr;
    }
    else {
        croak "Bad method, expected - class, class_name, css, id, link,
                link_text, partial_link_text, name, tag_name, xpath";
    }
}

=head2 get_active_element

 Description:
    Get the element on the page that currently has focus.. The located element
    will be returned as a WebElement object.

 Output:
    WebElement Object

 Usage:
    $driver->get_active_element();

=cut

sub get_active_element {
    my ($self) = @_;
    my $res = { 'command' => 'getActiveElement' };
    my $ret_data = eval { $self->_execute_command($res) };
    if ($@) {
        croak $@;
    }
    else {
        return $self->webelement_class->new( id => $ret_data->{ELEMENT},
            driver => $self );
    }
}

=head2 send_modifier

 Description:
    Send an event to the active element to depress or release a modifier key.

  Input: 2
    Required:
      value - String - The modifier key event to be sent. This key must be one 'Ctrl','Shift','Alt',' or 'Command'/'Meta' as defined by the send keys command
      isdown - Boolean/String - Whether to generate a key down or key up

 Usage:
    $driver->send_modifier('Alt','down');
    $elem->send_keys('c');
    $driver->send_modifier('Alt','up');

    or

    $driver->send_modifier('Alt',1);
    $elem->send_keys('c');
    $driver->send_modifier('Alt',0);

=cut

sub send_modifier {
    my ( $self, $modifier, $isdown ) = @_;
    if ( $isdown =~ /(down|up)/ ) {
        $isdown = $isdown =~ /down/ ? 1 : 0;
    }
    my $res = { 'command' => 'sendModifier' };
    my $params = {
        value  => $modifier,
        isdown => $isdown
    };
    return $self->_execute_command( $res, $params );
}

=head2 compare_elements

 Description:
    Test if two element IDs refer to the same DOM element.

 Input: 2
    Required:
        Selenium::Remote::WebElement - WebElement Object
        Selenium::Remote::WebElement - WebElement Object

 Output:
    BOOLEAN

 Usage:
    $driver->compare_elements($elem_obj1, $elem_obj2);

=cut

sub compare_elements {
    my ( $self, $elem1, $elem2 ) = @_;
    my $res = {
        'command' => 'elementEquals',
        'id'      => $elem1->{id},
        'other'   => $elem2->{id}
    };
    return $self->_execute_command($res);
}

=head2 click

 Description:
    Click any mouse button (at the coordinates set by the last moveto command).

 Input:
    button - any one of 'LEFT'/0 'MIDDLE'/1 'RIGHT'/2
             defaults to 'LEFT'

 Usage:
    $driver->click('LEFT');
    $driver->click(1); #MIDDLE
    $driver->click('RIGHT');
    $driver->click;  #Defaults to left

=cut

sub click {
    my ( $self, $button ) = @_;
    my $button_enum = { LEFT => 0, MIDDLE => 1, RIGHT => 2 };
    if ( defined $button && $button =~ /(LEFT|MIDDLE|RIGHT)/i ) {
        $button = $button_enum->{ uc $1 };
    }
    elsif ( defined $button && $button =~ /(0|1|2)/ ) {
        $button = $1;
    }
    else {
        $button = 0;
    }
    my $res    = { 'command' => 'click' };
    my $params = { 'button'  => $button };
    return $self->_execute_command( $res, $params );
}

=head2 double_click

 Description:
    Double-clicks at the current mouse coordinates (set by moveto).

 Usage:
    $driver->double_click;

=cut

sub double_click {
    my ($self) = @_;
    my $res = { 'command' => 'doubleClick' };
    return $self->_execute_command($res);
}

=head2 button_down

 Description:
    Click and hold the left mouse button (at the coordinates set by the
    last moveto command). Note that the next mouse-related command that
    should follow is buttonup . Any other mouse command (such as click
    or another call to buttondown) will yield undefined behaviour.

 Usage:
    $self->button_down;

=cut

sub button_down {
    my ($self) = @_;
    my $res = { 'command' => 'buttonDown' };
    return $self->_execute_command($res);
}

=head2 button_up

 Description:
    Releases the mouse button previously held (where the mouse is
    currently at). Must be called once for every buttondown command
    issued. See the note in click and buttondown about implications of
    out-of-order commands.

 Usage:
    $self->button_up;

=cut

sub button_up {
    my ($self) = @_;
    my $res = { 'command' => 'buttonUp' };
    return $self->_execute_command($res);
}

=head2 upload_file

 Description:
    Upload a file from the local machine to the selenium server
    machine. That file then can be used for testing file upload on web
    forms. Returns the remote-server's path to the file.

 Usage:
    my $remote_fname = $driver->upload_file( $fname );
    my $element = $driver->find_element( '//input[@id="file"]' );
    $element->send_keys( $remote_fname );

=cut

# this method duplicates upload() method in the
# org.openqa.selenium.remote.RemoteWebElement java class.

sub upload_file {
    my ( $self, $filename ) = @_;
    if ( not -r $filename ) { die "upload_file: no such file: $filename"; }
    my $string = "";    # buffer
    zip $filename => \$string
      or die "zip failed: $ZipError\n";    # compress the file into string
    my $res = { 'command' => 'uploadFile' };    # /session/:SessionId/file
    require MIME::Base64;

    my $params = {
        file => encode_base64($string)          # base64-encoded string
    };
    return $self->_execute_command( $res, $params );
}

=head2 get_text

 Description:
    Get the text of a particular element. Wrapper around L<find_element()>

 Usage:
    $text = $driver->get_text("//div[\@name='q']");

=cut

sub get_text {
    my $self = shift;
    return $self->find_element(@_)->get_text();
}

=head2 get_body

 Description:
    Get the current text for the whole body. If you want the entire raw HTML instead,
    See L<get_page_source>.

 Usage:
    $body_text = $driver->get_body();

=cut

sub get_body {
    my $self = shift;
    return $self->get_text('//body');
}

=head2 get_path

 Description:
     Get the path part of the current browser location.

 Usage:
     $path = $driver->get_path();

=cut

sub get_path {
    my $self     = shift;
    my $location = $self->get_current_url;
    $location =~ s/\?.*//;               # strip of query params
    $location =~ s/#.*//;                # strip of anchors
    $location =~ s#^https?://[^/]+##;    # strip off host
    return $location;
}


1;

__END__

=head1 SEE ALSO

For more information about Selenium , visit the website at
L<http://code.google.com/p/selenium/>.

Also checkout project's wiki page at
L<https://github.com/gempesaw/Selenium-Remote-Driver/wiki>.

=head1 BUGS

The Selenium issue tracking system is available online at
L<http://github.com/gempesaw/Selenium-Remote-Driver/issues>.

=head1 AUTHOR

Perl Bindings for Selenium Remote Driver by Aditya Ivaturi C<< <ivaturi@gmail.com> >>

=head1 ACKNOWLEDGEMENTS

The following people have contributed to this module. (Thanks!)

=over 4

=item * Gordon Child

=item * Daniel Gempesaw

=item * Charles Howes

=item * Tom Hukins

=item * Phil Kania

=item * Allen Lew

=item * Phil Mitchell

=item * Emmanuel Peroumalnaik

=item * Mark Stosberg

=back

=head1 LICENSE

Copyright (c) 2010-2011 Aditya Ivaturi, Gordon Child
Copyright (c) 2014      Daniel Gempesaw

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
