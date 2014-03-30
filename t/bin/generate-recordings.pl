#! /usr/bin/perl

use strict;
use warnings;
use IPC::Open2;

unless (-d "t" && -f "dist.ini" && -f "t/01-driver.t" && -f "t/02-webelement.t") {
    die "Please run this from the root of the repo.";
}

startServer();
if ($^O eq 'linux') {
    print "Headless and need a webdriver server started? Try\n\n\tDISPLAY=:1 xvfb-run --auto-servernum java -jar /usr/lib/node_modules/protractor/selenium/selenium-server-standalone-2.40.0.jar\n\n";
}

my $export = $^O eq 'MSWin32' ? 'set' : 'export';
my $srdLib = glob('Selenium-Remote-Driver*/lib');

print `dzil build`;
print `$export WD_MOCKING_RECORD=1 && perl -I$srdLib t/01-driver.t && perl -I$srdLib t/02-webelement.t`;
killServer();

sub startServer {
    if ($^O eq 'MSWin32') {
        system("start \"TEMP_HTTP_SERVER\" /MIN perl t/http-server.pl");
    } else {
        system("perl t/http-server.pl > /dev/null &");
    }
}

sub killServer {
    if ($^O eq 'MSWin32') {
        system("taskkill /FI \"WINDOWTITLE eq TEMP_HTTP_SERVER\"");
    }
    else {
        `ps aux | grep [h]ttp-server\.pl  | awk '{print \$2}' | xargs kill`;
    }
}
