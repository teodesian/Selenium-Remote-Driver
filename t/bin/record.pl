#! /usr/bin/perl

use strict;
use warnings;

unless (-d "t" && -f "dist.ini" && -f "t/01-driver.t" && -f "t/02-webelement.t") {
    die "Please run this from the root of the repo.";
}

resetEnv();
startServer();

print 'Cleaning...and building...
';
print `dzil clean`;
print `dzil build`;

if ($^O eq 'linux') {
    print "Headless and need a webdriver server started? Try\n\n\tDISPLAY=:1 xvfb-run --auto-servernum java -jar /usr/lib/node_modules/protractor/selenium/selenium-server-standalone-2.42.2.jar\n\n";
}

my $srdLib = glob('Selenium-Remote-Driver*/lib');
my @files = (
    't/01-driver.t',
    't/02-webelement.t',
    't/Firefox-Profile.t'
);

my $export = $^O eq 'MSWin32' ? 'set' : 'export';
my $executeTests = join( ' && ', map { 'perl -I' . $srdLib . ' ' . $_ } @files);
print `$export WD_MOCKING_RECORD=1 && $executeTests`;
resetEnv();

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

sub resetEnv {
    `dzil clean`;
    killServer();
}
