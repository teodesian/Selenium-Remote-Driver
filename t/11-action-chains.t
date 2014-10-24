use strict;
use warnings;

use JSON;
use Test::More;
use Selenium::Remote::Driver;
use Selenium::Remote::Mock::Commands;
use Selenium::Remote::Mock::RemoteConnection;
use Selenium::Remote::Driver::ActionChains;

my $record = (defined $ENV{'WD_MOCKING_RECORD'} && ($ENV{'WD_MOCKING_RECORD'}==1))?1:0;
my $os  = $^O;
if ($os =~ m/(aix|freebsd|openbsd|sunos|solaris)/) {
    $os = 'linux';
}
my %selenium_args = ( 
    browser_name => 'firefox'
);


my $mock_file = "11-action-chains-mock-$os.json";
if (!$record && !(-e "t/mock-recordings/$mock_file")) {
    plan skip_all => "Mocking of tests is not been enabled for this platform";
}

if ($record) { 
    $selenium_args{remote_conn} = Selenium::Remote::Mock::RemoteConnection->new(record => 1);
}
else { 
    $selenium_args{remote_conn} =
      Selenium::Remote::Mock::RemoteConnection->new( replay => 1,
        replay_file => "t/mock-recordings/$mock_file" );
}

my $driver = Selenium::Remote::Driver->new(%selenium_args);
my $action_chains = Selenium::Remote::Driver::ActionChains->new(driver => $driver);
$driver->get('http://html5demos.com/drag');
$driver->pause('1000');
my $src = $driver->find_element('a#two', 'css'); 
my $tgt = $driver->find_element('div#bin','css');
$action_chains->drag_and_drop($src,$tgt)->perform();
if ($record) { 
    $driver->remote_conn->dump_session_store("t/mock-recordings/$mock_file");
}

done_testing;
