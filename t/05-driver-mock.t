#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Data::Dumper;
use t::lib::MockSeleniumWebDriver;

use_ok('Selenium::Remote::Driver');



# Start our local http server only if release testing
if ($^O eq 'MSWin32' && $ENV{RELEASE_TESTING})
{
   system("start \"TEMP_HTTP_SERVER\" /MIN perl t/http-server.pl");
} elsif($ENV{RELEASE_TESTING})
{
    system("perl t/http-server.pl > /dev/null &");
}

my $website = 'http://localhost:63636';

my $record = $ENV{RELEASE_TESTING};
t::lib::MockSeleniumWebDriver::register($record,'t/mock-recordings/05-driver-mock-recording.json');

my $driver = Selenium::Remote::Driver->new;
isa_ok($driver,'Selenium::Remote::Driver');
$driver->get("$website/alerts.html");

$driver->quit;

done_testing;

# Kill our HTTP Server
if ($^O eq 'MSWin32' && $ENV{RELEASE_TESTING})
{
   system("taskkill /FI \"WINDOWTITLE eq TEMP_HTTP_SERVER\"");
}
elsif($ENV{RELEASE_TESTING})
{
    `ps aux | grep http-server\.pl | grep perl | awk '{print \$2}' | xargs kill`;
}

0;
