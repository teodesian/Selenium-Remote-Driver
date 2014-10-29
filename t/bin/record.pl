#! /usr/bin/perl

use strict;
use warnings;

use Cwd qw/abs_path/;
use FindBin;
# We can only dzil from the root of the repository.
my $this_folder = $FindBin::Bin . '/../../'; # t/bin/../../
my $repo_root = abs_path($this_folder) . '/';

reset_env();
start_server();

print 'Cleaning...and building...
';
print `cd $repo_root && dzil build`;

if ($^O eq 'linux') {
    print "Headless and need a webdriver server started? Try\n\n\tDISPLAY=:1 xvfb-run --auto-servernum java -jar /usr/lib/node_modules/protractor/selenium/selenium-server-standalone-2.42.2.jar\n\n";
}

my $built_lib = $repo_root . glob('Selenium-Remote-Driver-*/lib');
my $export = $^O eq 'MSWin32' ? 'set' : 'export';
my $wait = $^O eq 'MSWin32' ? 'START /WAIT' : '';
print `$export WD_MOCKING_RECORD=1 && cd $repo_root && prove -I$built_lib -rv t/`;
reset_env();

sub start_server {
    if ($^O eq 'MSWin32') {
        system('start "TEMP_HTTP_SERVER" /MIN perl ' . $repo_root . 't/http-server.pl');
    }
    else {
        system('perl ' . $repo_root . 't/http-server.pl > /dev/null &');
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
    `cd $repo_root && dzil clean`;
    kill_server();
}
