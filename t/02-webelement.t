use strict;
use warnings;

use Test::More;
use Net::Ping;
use Data::Dumper;

BEGIN {
   unless (use_ok( 'Selenium::Remote::Driver'))
   {
      BAIL_OUT ("Couldn't load Driver");
      exit;
   }
   
   if (defined $ENV{'WD_MOCKING_RECORD'} && ($ENV{'WD_MOCKING_RECORD'}==1))
   {
      use t::lib::MockSeleniumWebDriver;
      my $p = Net::Ping->new("tcp", 2);
      $p->port_number(4444);
      unless ($p->ping('localhost')) {
         plan skip_all => "Selenium server is not running on localhost:4444";
         exit;
      }
      warn "\n\nRecording...\n\n";
   }
}

my $record = (defined $ENV{'WD_MOCKING_RECORD'} && ($ENV{'WD_MOCKING_RECORD'}==1))?1:0;
my $os  = $^O;
if ($os =~ m/(aix|freebsd|openbsd|sunos|solaris)/)
{
   $os = 'linux';
}
my $mock_file = "02-webelement-mock-$os.json";
if (!$record && !(-e "t/mock-recordings/$mock_file"))
{
   plan skip_all => "Mocking of tests is not been enabled for this platform";
}
t::lib::MockSeleniumWebDriver::register($record,"t/mock-recordings/$mock_file");

# Start our local http server
if ($^O eq 'MSWin32' && $record)
{
   system("start \"TEMP_HTTP_SERVER\" /MIN perl t/http-server.pl");
}
elsif ($record)
{
    system("perl t/http-server.pl > /dev/null &");
}

my $driver = new Selenium::Remote::Driver(browser_name => 'firefox');
my $website = 'http://localhost:63636';
my $ret;
my $elem;

LINK: {
        $driver->get("$website/formPage.html");
        $driver->find_element("//a[\@href='/index.html']")->click;
        pass('Click Link...');
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
            $ret = $elem->get_tag_name();
            is($ret, 'input', 'Get tag name');
            
            $elem = $driver->find_element('checky', 'id');
            $ret = $elem->is_selected();
            is($ret, 'false', 'Checkbox not selected');
            $ret = $elem->click();
            $ret = $elem->is_selected();
            is($ret, 'true', 'Checkbox is selected');
            TODO: {
            local $TODO = "toggle doesn't appear to be working currently in selenium server";
            eval {$ret = $elem->toggle();};
            $ret = $elem->is_selected();
            is($ret, 'false', 'Toggle & Checkbox is selected');
            };
            note "describe return data has not yet been defined";
            ok($elem->describe,"describe returns data");
       }

MODIFIER: {
            $driver->get("$website/metakeys.html");
            $elem = $driver->find_element('metainput','id');
            eval {
              $driver->send_modifier('Alt','down');
              $elem->send_keys('c');
              $driver->send_modifier('Alt','up');
            };
            if($@) {
              TODO: {
                local $TODO = "modifier keys broken case 1993 and 1427";
                fail "sent modifier keys";
              }
            } else {
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
            eval {$ret = $elem->drag(200,200);};
            $ret = $elem->get_element_location();
            is($ret->{'x'}, ($x+200), 'Moved to new x coord');
            is($ret->{'y'}, ($y+200), 'Moved to new y coord');
            };
        }

QUIT: {
        $ret = $driver->quit();
        ok((not defined $driver->{'session_id'}), 'Killed the remote session');
      }

# Kill our HTTP Server
if ($^O eq 'MSWin32' && $record)
{
   system("taskkill /FI \"WINDOWTITLE eq TEMP_HTTP_SERVER\"");
}
elsif ($record)
{
    `ps aux | grep http-server\.pl | grep perl | awk '{print \$2}' | xargs kill`;
}

done_testing;
