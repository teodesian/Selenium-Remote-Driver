#! /usr/bin/perl

use strict;
use warnings;
use Cwd qw/abs_path/;

my $this_file = abs_path(__FILE__);
my $srd_folder = $this_file;
$srd_folder =~ s/t\/bin\/record\.pl//;

resetEnv();
startServer();

print 'Cleaning...and building...
';
print `cd $srd_folder && dzil build`;

if ($^O eq 'linux') {
    print "Headless and need a webdriver server started? Try\n\n\tDISPLAY=:1 xvfb-run --auto-servernum java -jar /usr/lib/node_modules/protractor/selenium/selenium-server-standalone-2.42.2.jar\n\n";
}

my @files = map {
    $srd_folder . $_
} (
    't/01-driver.t',
    't/02-webelement.t',
    't/Firefox-Profile.t'
);

my $srdLib = glob($srd_folder . 'Selenium-Remote-Driver*/lib');
my $tLib = glob($srd_folder . 'Selenium-Remote-Driver*');
my $executeTests = join( ' && ', map {
    'perl -I' . $srdLib
      . ' -I' . $tLib
      . ' ' . $_
  } @files);

my $export = $^O eq 'MSWin32' ? 'set' : 'export';
print `$export WD_MOCKING_RECORD=1 && $executeTests`;
resetEnv();

sub startServer {
    if ($^O eq 'MSWin32') {
        system('start "TEMP_HTTP_SERVER" /MIN perl ' . $srd_folder . 't/http-server.pl');
    }
    else {
        system('perl ' . $srd_folder . 't/http-server.pl > /dev/null &');
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
    `cd $srd_folder && dzil clean`;
    killServer();
}
