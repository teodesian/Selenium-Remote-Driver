use strict;
use warnings;

use Test::More 'no_plan';
use Data::Dumper;

BEGIN {
    use_ok( 'Selenium::Remote::Driver' ) || print "Can't load Driver, giving up.";
}

# Start our local http server
system("perl t/http-server.pl > /dev/null &");

my $driver = new Selenium::Remote::Driver(browser_name => 'firefox');
my $website = 'http://localhost:63636';
my $ret;

CHECK_DRIVER: {
                ok(defined $driver, 'Object loaded fine...');
                ok($driver->isa('Selenium::Remote::Driver'), '...and of right type');
                ok(defined $driver->{'session_id'}, 'Established session on remote server');
                $ret = $driver->get_capabilities;
                is($ret->{'cmd_return'}->{'browserName'}, 'firefox', 'Right capabilities');
              }

LOAD_PAGE: {
                $ret = $driver->get("$website/index.html");
                is($ret->{'cmd_status'}, 'OK', 'Loaded home page');
                $ret = $driver->get_title();
                is($ret->{'cmd_return'}, 'Hello WebDriver', 'Got the title');
                $ret = $driver->get_current_url();
                ok($ret->{'cmd_return'} =~ m/$website/i, 'Got proper URL');
           }

WINDOW: {
            $ret = $driver->get_current_window_handle();
            ok($ret->{'cmd_return'} =~ m/^{.*}$/, 'Proper window handle received');
            $ret = $driver->get_window_handles();
            is(ref $ret->{'cmd_return'}, 'ARRAY', 'Received all window handles');
            $ret = $driver->get_page_source();
            ok($ret->{'cmd_return'} =~ m/^<html>/i, 'Received page source');
            $ret = $driver->get_speed();
            ok($ret->{'cmd_return'} =~ m/[SLOW|MEDIUM|FAST]/i, 'Got speed...');
            $ret = $driver->set_speed('FAST');
            is($ret->{'cmd_status'}, 'OK', 'Setting speed to FAST...');
            $ret = $driver->get_speed();
            is($ret->{'cmd_return'}, 'FAST', '...confirmed set_speed()');
            $ret = $driver->get("$website/frameset.html");
            $ret = $driver->switch_to_frame('second');
            is($ret->{'cmd_status'}, 'OK', 'Setting speed to FAST...');
        }

COOKIES: {
            $driver->get("$website/cookies.html");
            $ret = $driver->get_all_cookies();
            is(@{$ret->{'cmd_return'}}, 2, 'Got 2 cookies');
            $ret = $driver->delete_all_cookies();
            is($ret->{'cmd_status'}, 'OK', 'Deleting cookies...');
            $ret = $driver->get_all_cookies();
            is(@{$ret->{'cmd_return'}}, 0, 'Deleted all cookies.');
            $ret = $driver->add_cookie('foo', 'bar', '/', 'localhost', 0);
            is($ret->{'cmd_status'}, 'OK', 'Adding cookie foo...');
            $ret = $driver->get_all_cookies();
            is(@{$ret->{'cmd_return'}}, 1, 'foo cookie added.');
            $ret = $driver->delete_cookie_named('foo');
            is($ret->{'cmd_status'}, 'OK', 'Deleting cookie foo...');
            $ret = $driver->get_all_cookies();
            is(@{$ret->{'cmd_return'}}, 0, 'foo cookie deleted.');
            $ret = $driver->delete_all_cookies();
         }

MOVE: {
        $driver->get("$website/index.html");
        $driver->get("$website/formPage.html");
        $ret = $driver->go_back();
        is($ret->{'cmd_status'}, 'OK', 'Clicked Back...');
        $ret = $driver->get_title();
        is($ret->{'cmd_return'}, 'Hello WebDriver', 'Got the right title');
        $ret = $driver->go_forward();
        is($ret->{'cmd_status'}, 'OK', 'Clicked Forward...');
        $ret = $driver->get_title();
        is($ret->{'cmd_return'}, 'We Leave From Here', 'Got the right title');
        $ret = $driver->refresh();
        is($ret->{'cmd_status'}, 'OK', 'Clicked Refresh...');
        $ret = $driver->get_title();
        is($ret->{'cmd_return'}, 'We Leave From Here', 'Got the right title');
      }

FIND: {
        $ret = $driver->find_element("//input[\@id='checky']");
        my $elem = $ret->{'cmd_return'};
        ok($elem->isa('Selenium::Remote::WebElement'), 'Got WebElement via Xpath');
        $ret = $driver->find_element('checky', 'id');
        $elem = $ret->{'cmd_return'};
        ok($elem->isa('Selenium::Remote::WebElement'), 'Got WebElement via Id');
        $ret = $driver->find_element('checky', 'name');
        $elem = $ret->{'cmd_return'};
        ok($elem->isa('Selenium::Remote::WebElement'), 'Got WebElement via Name');
        
        $elem = ($driver->find_element('multi', 'id'))->{'cmd_return'};
        $ret = $driver->find_child_element($elem, "/option");
        ok($elem->isa('Selenium::Remote::WebElement'), 'Got child WebElement...');
        $ret = $elem->get_value();
        is($ret->{'cmd_return'}, 'Eggs', '...right child WebElement');
        $ret = $driver->find_child_elements($elem, "//option[\@selected='selected']");
        is(@{$ret->{'cmd_return'}}, 2, 'Got 2 WebElements');
      }


QUIT: {
        $ret = $driver->quit();
        ok((not defined $driver->{'session_id'}), 'Killed the remote session');
      }

# Kill our HTTP Server
`ps aux | grep http-server\.pl | grep perl | awk '{print \$2}' | xargs kill`;