use strict;
use warnings;

use Test::More;
use Selenium::Remote::Driver;
use Selenium::Remote::Mock::RemoteConnection;

use FindBin;
use lib $FindBin::Bin . '/lib';
use TestHarness;

my $harness = TestHarness->new(
    this_file => $FindBin::Script
);
my %selenium_args = %{ $harness->base_caps };

my $driver = Selenium::Remote::Driver->new(%selenium_args);
my $domain = $harness->domain;
my $website = $harness->website;

$driver->get("$website/formPage.html");
my $ret;
my $elem;

LINK: {
    $driver->find_element("//a[\@href='/index.html']")->click;
    pass('Click Link...');
    isa_ok($driver->get_active_element,"Selenium::Remote::WebElement","get_active_element");
    $ret = $driver->get_title();
    is($ret, 'Hello WebDriver', 'Verify clicked link.');
    $driver->go_back();
}

INPUT: {
    $elem = $driver->find_element('withText', 'id');
    $ret = $elem->get_text();
    is($ret, 'Example text', 'Get innerText');
    $elem = $driver->find_element('id-name1', 'id');
    $ret = $elem->get_value();
    is($ret, 'id', 'Get value (attribute)');
    $ret = $elem->get_attribute('value');
    is($ret, 'id', 'Get attribute @value');
    $ret = $elem->get_attribute('missing-attribute');
    ok(!$ret, 'Get attribute returns false for a missing attribute.');
    $ret = $elem->get_tag_name();
    is($ret, 'input', 'Get tag name');

    $elem = $driver->find_element('checky', 'id');
    $ret = $elem->is_selected();
    is($ret, 0, 'Checkbox not selected');
    $ret = $elem->click();
    $ret = $elem->is_selected();
    is($ret, 1, 'Checkbox is selected');
  TODO: {
        local $TODO = "toggle doesn't appear to be working currently in selenium server";
        eval {$ret = $elem->toggle();};
        $ret = $elem->is_selected();
        is($ret, 0, 'Toggle & Checkbox is selected');
    }
}

MODIFIER: {
    $driver->get("$website/metakeys.html");
    $elem = $driver->find_element('metainput','id');
    eval {
        $driver->send_modifier('Alt','down');
        $elem->send_keys('c');
        $driver->send_modifier('Alt','up');
    };
    if ($@) {
      TODO: {
            local $TODO = "modifier keys broken case 1993 and 1427";
            fail "sent modifier keys";
        }
    }
    else {
        $elem = $driver->find_element('metaoutput','id');
        like($elem->get_value,qr/18/,"sent modifier keys");
        note $elem->get_value;
    }
}

IMAGES: {
    $driver->get("$website/dragAndDropTest.html");
    $elem = $driver->find_element('test1', 'id');
    $ret = $elem->get_size();
    is($ret->{'width'}, '18', 'Image - right width');
    is($ret->{'height'}, '18', 'Image - right height');
    $ret = $elem->get_element_location();
    ok(defined $ret->{'x'}, 'Image - got x coord');
    ok(defined $ret->{'y'}, 'Image - got y coord');
    my $x = $ret->{'x'};
    my $y = $ret->{'y'};
}

VISIBILITY: {
    $driver->get("$website/index.html");
    $elem = $driver->find_element('displayed', 'id');
    ok($elem->is_displayed(), 'Elements are displayed by default.');
    ok(!$elem->is_hidden(), 'Elements are not hidden by default.');

    $elem = $driver->find_element('hidden', 'id');
    ok(!$elem->is_displayed(), 'Hidden elements are not displayed.');
    ok($elem->is_hidden(), 'Hidden elements are hidden.');
}

EXECUTE_SCRIPT: {
    $driver->get("$website/index.html");

    my $elem = $driver->find_element('div', 'css');
    my $script_elem = $driver->execute_script('return arguments[0]', $elem);
    isa_ok($script_elem, 'Selenium::Remote::WebElement', 'execute_script element return');
    is($elem->id, $script_elem->id, 'Sync script returns identical WebElement id');

    my $async = q{
        var callback = arguments[arguments.length - 1];
        callback(arguments[0]);
    };
    my $async_elem = $driver->execute_async_script($async, $elem);
    isa_ok($async_elem, 'Selenium::Remote::WebElement', 'execute_async_script element return');
    is($elem->id, $async_elem->id, 'Async script returns identical WebElement id');
}

QUIT: {
    $ret = $driver->quit();
    ok((not defined $driver->{'session_id'}), 'Killed the remote session');
}

OBJECT_INSTANTIATION: {
  SRD: {
        my $value = { ELEMENT => 0 };
        my $elem = Selenium::Remote::WebElement->new(
            id => $value,
            driver => ''
        );
        is($elem->id, 0,
           'Can make element with standard SRD response');
    }

  GECKODRIVER:{
        my $value = {
            'element-6066-11e4-a52e-4f735466cecf' => '4f134cd0-4873-1148-aac8-5d496bea013f'
        };
        my $elem = Selenium::Remote::WebElement->new(
            id => $value,
            driver => ''
        );
        is($elem->id, '4f134cd0-4873-1148-aac8-5d496bea013f',
           'Can make element with Geckodriver response');

    }
}

done_testing;
