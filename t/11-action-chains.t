use strict;
use warnings;

use JSON;
use Test::More;
use Test::Selenium::Remote::Driver;
use Selenium::ActionChains;
use Selenium::Remote::WDKeys 'KEYS';

use FindBin;
use lib $FindBin::Bin . '/lib';
use TestHarness;

my $harness = TestHarness->new(
    this_file => $FindBin::Script
);

# while Firefox is transferring to geckodriver, it doesn't support the
# entire JSONWireProtocol - at the time of writing, this test depends
# on `POST sendKeysToActiveElement` and `POST
# /session/:sessionId/moveTo`, neither of which are in geckodriver.
my %selenium_args = (
    %{ $harness->base_caps },
    browser_name => 'chrome'
);

{
    my $driver = Test::Selenium::Remote::Driver->new(%selenium_args);
    my $action_chains = Selenium::ActionChains->new( driver => $driver );

    $driver->get('https://www.google.com');
    my $input_text = $driver->find_element("//input[\@type='text']");

    # type text to search on Google and press 'Enter'
    $action_chains->send_keys_to_element( $input_text, "test" )
      ->key_down( [ KEYS->{'enter'} ] )->key_up( [ KEYS->{'enter'} ] )
      ->perform;
    $driver->find_elements_ok( "//*[\@class='hdtb-mitem']",
        "We found Google's navbar" );
    $driver->quit;
}

{
    my $driver = Test::Selenium::Remote::Driver->new(%selenium_args);
    my $action_chains = Selenium::ActionChains->new( driver => $driver );

    $driver->get("http://medialize.github.io/jQuery-contextMenu/demo.html");
    my $right_click_zone =
      $driver->find_element("//*[contains(text(),'right click me')]");
    $action_chains->context_click($right_click_zone)->perform;
    $driver->find_element("//*[text()='Paste']")
      ->is_displayed_ok("The menu is correctly displayed on right click");
    $driver->quit;
}


done_testing;
