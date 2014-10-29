#! /usr/bin/perl

use strict;
use warnings;

use Cwd qw/abs_path/;
use FindBin;
# We can only dzil from the root of the repository.
my $this_folder = $FindBin::Bin . '/../../'; # t/bin/../../
my $srd_folder = abs_path($this_folder) . '/';

reset_env();
start_server();

print 'Cleaning...and building...
';
print `cd $srd_folder && dzil build`;

if ($^O eq 'linux') {
    print "Headless and need a webdriver server started? Try\n\n\tDISPLAY=:1 xvfb-run --auto-servernum java -jar /usr/lib/node_modules/protractor/selenium/selenium-server-standalone-2.42.2.jar\n\n";
}

my @files = map { $srd_folder . $_ } (
    't/01-driver.t',
    't/02-webelement.t',
    't/Firefox-Profile.t'
);

my $srd_lib = glob($srd_folder . 'Selenium-Remote-Driver*/lib');
my $t_lib = glob($srd_folder . 'Selenium-Remote-Driver*');

my $execute_tests = join( ' && ', map {
    'perl -I' . $srd_lib
      . ' -I' . $t_lib
      . ' ' . $_
  } @files);

my $export = $^O eq 'MSWin32' ? 'set' : 'export';
my $wait = $^O eq 'MSWin32' ? 'START /WAIT' : '';
print `$export WD_MOCKING_RECORD=1 && $wait $execute_tests`;
reset_env();

sub start_server {
    if ($^O eq 'MSWin32') {
        system('start "TEMP_HTTP_SERVER" /MIN perl ' . $srd_folder . 't/http-server.pl');
    }
    else {
        system('perl ' . $srd_folder . 't/http-server.pl > /dev/null &');
    }
}

sub kill_server {
    if ($^O eq 'MSWin32') {
        system("taskkill /FI \"WINDOWTITLE eq TEMP_HTTP_SERVER\"");
    }
    else {
        `ps aux | grep [h]ttp-server\.pl  | awk '{print \$2}' | xargs kill`;
    }
}


sub reset_env {
    `cd $srd_folder && dzil clean`;
    kill_server();
}
