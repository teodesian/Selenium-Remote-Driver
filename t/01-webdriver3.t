use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;
use Scalar::Util qw{looks_like_number};

use Selenium::Remote::Driver;
use Selenium::Firefox::Profile;
use Selenium::Remote::Spec;

#So we only modify _request_new_session to get webd3 working.
#As such, we should only test that.
NEWSESS: {

    #TODO cover case where ISA Selenium::Firefox
    my $self = bless({ is_wd3 => 1 },"Selenium::Remote::Driver");
    my $profile = Selenium::Firefox::Profile->new();
    $profile->set_preference(
        'browser.startup.homepage' => 'http://www.google.com',
    );
    my $args = {
        desiredCapabilities => {
            browserName       => 'firefox',
            version            => 666,
            platform           => 'ANY',
            javascript         => 1,
            acceptSslCerts     => 1,
            firefox_profile    => $profile,
            pageLoadStrategy   => 'none',
            proxy => {
                proxyType => 'direct',
                proxyAutoconfigUrl => 'http://localhost',
                ftpProxy           => 'localhost:1234',
                httpProxy          => 'localhost:1234',
                sslProxy           => 'localhost:1234',
                socksProxy         => 'localhost:1234',
                socksVersion       => 2,
                noProxy            => ['http://localhost'],
            },
            extra_capabilities => { #TODO these need to be translated as moz:firefoxOptions => {} automatically, and then to be put in the main hash
                binary  => '/usr/bin/firefox',
                args    => ['-profile', '~/.mozilla/firefox/vbdgri9o.default'], #gotta check this gets overridden
                profile => 'some Base64 string of a zip file. I should really make this a feature',
                log     => 'trace', #trace|debug|config|info|warn|error|fatal
                prefs   => {}, #TODO check that this is auto-set above by the Selenium::Firefox::Profile stuff
                webdriverClick => 0, #This option is OP, *must* be set to false 24/7
            },
        },
    };

    no warnings qw{redefine once};
    local *Selenium::Remote::RemoteConnection::request = sub {return { sessionId => 'zippy', cmd_status => 'OK', cmd_return => {capabilities => 'eee'} }};
    local *File::Temp::Dir::dirname = sub { return '/tmp/zippy' };
    use warnings;

    my ($args_modified,undef) = $self->_request_new_session($args);

    my $expected = {
        'alwaysMatch' => {
            'browserVersion'     => 666,
            'moz:firefoxOptions' => {
                'args' => [
                    '-profile',
                    '/tmp/zippy'
                ],
                'binary'  => '/usr/bin/firefox',
                'log'     => 'trace',
                'prefs'   => {},
                'profile' => 'some Base64 string of a zip file. I should really make this a feature',
                'webdriverClick' => 0
            },
            'platformName' => 'ANY',
            'proxy'        => {
                'ftpProxy'           => 'localhost:1234',
                'httpProxy'          => 'localhost:1234',
                'noProxy'            => [
                    'http://localhost'
                ],
                'proxyAutoconfigUrl' => 'http://localhost',
                'proxyType'          => 'direct',
                'socksProxy'         => 'localhost:1234',
                'socksVersion'       => 2,
                'sslProxy'           => 'localhost:1234'
            },
            'browserName'      => 'firefox',
            'pageLoadStrategy' => 'none',
            acceptInsecureCerts => 1,
        }
    };

    is($self->{capabilities},'eee',"Caps set correctly in wd3 mode");
    is_deeply($args_modified->{capabilities},$expected,"Desired capabilities correctly translated to Firefox (WD3)");

    #$expected->{alwaysMatch}->{'goog:chromeOptions'} = $expected->{alwaysMatch}->{'moz:firefoxOptions'};
    $expected->{alwaysMatch}->{'moz:firefoxOptions'} = {};
    #$expected->{alwaysMatch}->{'goog:chromeOptions'}->{args} = ['-profile', '~/.mozilla/firefox/vbdgri9o.default'];
    $expected->{alwaysMatch}->{browserName} = 'chrome';

    $args->{desiredCapabilities}->{browserName} = 'chrome';
    ($args_modified,undef) = $self->_request_new_session($args);
    is_deeply($args_modified->{capabilities},$expected,"Desired capabilities correctly translated to Krom (WD3)");

}

EXECOMMAND: {

    #_execute_command with payload 'hitting all the right buttons'
    #also check that fallback works w/ the right special missing word
    #also check capability shortcut
    my $self = bless({ is_wd3 => 1, capabilities => 'wakka wakka', browser_name => 'firefox' },"Selenium::Remote::Driver");

    no warnings qw{redefine once};
    local *Selenium::Remote::RemoteConnection::request = sub {return { sessionId => 'zippy', cmd_status => 'OK' }};
    local *Selenium::Remote::Spec::get_params          = sub { my ($self,$ret)       = @_; $ret->{v3} = 1; return $ret; };
    local *Selenium::Remote::Commands::get_params      = sub { die 'whee' };
    local *Selenium::Remote::Spec::parse_response      = sub { my ($self,undef,$ret) = @_; $ret->{rv3} = 1; return $ret; };
    local *Selenium::Remote::Commands::parse_response  = sub { die 'zippy' };
    use warnings;

    my ($input,$params) = ({ command => 'zippy'},{ ms => 1, type=> 1, text => 1, value => 1, using => 1});

    my $ret = $self->_execute_command($input,$params);
    is($ret->{rv3},1,"v3 code walked in _execute_command on happy path");

    $input->{command} = 'getCapabilities';
    $ret = $self->_execute_command($input,$params);
    is($ret,'wakka wakka',"v3 code walked in _execute_command on getCapabilities path");

    $input->{command} = 'HORGLE';

    no warnings qw{redefine once};
    local *Selenium::Remote::Spec::get_params          = sub { return undef; };
    local *Selenium::Remote::Commands::get_params      = sub { die 'whee' };
    local *Selenium::Remote::Spec::parse_response      = sub { my ($self,undef,$ret) = @_; $ret->{rv3} = 1; return $ret; };
    local *Selenium::Remote::Commands::parse_response  = sub { die 'zippy' };
    use warnings;

    $ret = exception { $self->_execute_command($input,$params) };
    like($ret,qr/whee/,"v2 fallback walked in _execute_command on getCapabilities path");

}

REMOTECONN: {
    my $self = bless({},'Selenium::Remote::RemoteConnection');
    $self->remote_server_addr('eee');
    $self->port(666);
    no warnings qw{redefine once};
    local *LWP::UserAgent::request = sub { my ($self,$req) = @_; return $req };
    use warnings;

    my $res = $self->request({ payload => { zippy => 1}, url => 'grid', method => 'eee' },{},1);
    is($res->content,'{"zippy":1}',"RemoteConnection payload shim works");
}

#get_cmds, get_params, parse_response
#get_caps and get_caps map have already been checked above in the _request_new_session code

SPEC: {
    my $obj = Selenium::Remote::Spec->new();
    my $cmds = $obj->get_cmds();
    subtest "parsing of spec blob done correctly" => sub {
        foreach my $key (keys(%$cmds)) {
            like($cmds->{$key}->{url},qr/^session|status/,"url parsed for $key correctly");
            is($cmds->{$key}->{url},$obj->get_url($key),"get_url accessor works for $key");
            like($cmds->{$key}->{method},qr/^GET|POST|DELETE|PUT$/,"method parsed for $key correctly");
            is($cmds->{$key}->{method},$obj->get_method($key),"get_method accessor works for $key");
            ok($cmds->{$key}->{description},"description parsed for $key correctly");
            ok(looks_like_number($cmds->{$key}->{no_content_success}),"no_content_success parsed for $key correctly");
            is($cmds->{$key}->{no_content_success},$obj->get_no_content_success($key),"get_no_content_success accessor works for $key");
        }
    };
}

SPEC_PARAMS: {
    no warnings qw{redefine once};
    local *Selenium::Remote::Spec::get_url = sub { return ':sessionId/:id/:name/:propertyName/:other/:windowHandle/timeouts' };
    use warnings;

    my $obj = Selenium::Remote::Spec->new();
    my $args = {
        session_id    => 'a',
        id            => 'man',
        name          => 'a',
        property_name => 'plan',
        other         => 'a canal',
        window_handle => 'panama',
        command       => 'fullscreenWindow',
        ms            => 666,
        type          => 'page load',
        using         => 'id',
        value         => 'whee',
        text          => 'zippy',
    };
    my $expected = {
        'method'             => 'POST',
        'no_content_success' => 1,
        'url'                => 'a/man/a/plan/a canal/panama/timeouts',
        'payload'            => {
            'handle'   => 'panama',
            'pageLoad' => 666,
            'using'    => 'css selector',
            'value'    => 'zippy',
        },
    };

    is_deeply($obj->get_params($args),$expected,"get_params: var substitution works, payload construction works (mostly)");

    $args->{type} = 'implicit';
    $expected->{payload}{implicit} = 666;
    delete $expected->{payload}{pageLoad};
    is_deeply($obj->get_params($args),$expected,"get_params: timeout payload mongling (implicit) works");

    $args->{type} = 'script';
    $expected->{payload}{script} = 666;
    delete $expected->{payload}{implicit};
    is_deeply($obj->get_params($args),$expected,"get_params: timeout payload mongling (script) works");

    no warnings qw{redefine once};
    local *Selenium::Remote::Spec::get_url = sub { return ':sessionId/:id/:name/:propertyName/:other/:windowHandle/timeouts/async_script' };
    use warnings;

    $args->{type} = 'page load';
    delete $expected->{payload}{pageLoad};
    $expected->{payload}{script} = 666;
    $expected->{payload}{type} = 'script';
    is_deeply($obj->get_params($args),$expected,"get_params: async_script substitution works");

    no warnings qw{redefine once};
    local *Selenium::Remote::Spec::get_url = sub { return ':sessionId/:id/:name/:propertyName/:other/:windowHandle/timeouts/implicit_wait' };
    use warnings;

    delete $expected->{payload}{script};
    $expected->{payload}{implicit} = 666;
    $expected->{payload}{type} = 'implicit';
    is_deeply($obj->get_params($args),$expected,"get_params: implicit_wait substitution works");

    delete $args->{text};
    $expected->{payload}{value} = "[id='whee']";
    is_deeply($obj->get_params($args),$expected,"get_params: id css substitution works");

    $args->{using} = 'class name';
    $expected->{payload}{value} = ".whee";
    is_deeply($obj->get_params($args),$expected,"get_params: class name css substitution works");

    $args->{using} = 'name';
    $expected->{payload}{value} = "[name='whee']";
    is_deeply($obj->get_params($args),$expected,"get_params: name css substitution works");
}

PARSE_RESP: {
    my $obj = Selenium::Remote::Spec->new();
    my $expected = { error => 'ID10T', 'message' => 'Please insert another quarter'};
    my $args = {
        cmd_status => 'OK',
        cmd_return => $expected,
    };
    is_deeply($obj->parse_response(undef,$args),$expected,"parse_response works");
    $args->{cmd_status} = 'NOT OK';
    like(exception { $obj->parse_response(undef,$args) },qr/insert another quarter/i,"parse_response throws on failure");
}

done_testing();
