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
unless ($harness->mocks_exist_for_platform) {
    plan skip_all => "Mocking of tests is not been enabled for this platform";
}

my $driver = Selenium::Remote::Driver->new(%selenium_args);
my $website = 'http://localhost:63636';
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
  TODO: {
        local $TODO = "drag doesn't appear to be working currently in selenium server";
        $ret = $elem->drag(200,200);
        $ret = $elem->get_element_location();
        is($ret->{'x'}, ($x+200), 'Moved to new x coord');
        is($ret->{'y'}, ($y+200), 'Moved to new y coord');
    }
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

QUIT: {
    $ret = $driver->quit();
    ok((not defined $driver->{'session_id'}), 'Killed the remote session');
}

done_testing;
