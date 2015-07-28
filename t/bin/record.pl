#! /usr/bin/env perl
use strict;
use warnings;

use Cwd qw/abs_path/;
use FindBin;
# We can only dzil from the root of the repository.
my $this_folder = $FindBin::Bin . '/../../'; # t/bin/../../
my $repo_root = abs_path($this_folder) . '/';

reset_env();
start_server();
output_linux_help();

my $built_lib = find_built_lib();
my $export = $^O eq 'MSWin32' ? 'set' : 'export';
my $wait = $^O eq 'MSWin32' ? 'START /WAIT' : '';
my $prove_opts = '-I' . $built_lib .' -j9 -r --verbose --trap --merge --state=save,slow';
print `$export WD_MOCKING_RECORD=1 && cd $repo_root && prove $prove_opts t/`;
reset_env();

sub find_built_lib {
    my $built_lib = glob($repo_root . 'Selenium-Remote-Driver-*/lib');
    if (not defined $built_lib) {
        print 'Building a dist.' . "\n";
        print `cd $repo_root && dzil build`;
    }
    # If built_lib wasn't around in the first place, we'll have to glob
    # for it again.
    $built_lib ||= glob($repo_root . 'Selenium-Remote-Driver-*/lib');
    return $built_lib;
}

sub output_linux_help {
    if ($^O eq 'linux') {
        print "Headless and need a webdriver server started? Try\n\n\tDISPLAY=:1 xvfb-run --auto-servernum java -jar /usr/lib/node_modules/protractor/selenium/selenium-server-standalone-*.jar\n\n";
    }
}

sub start_server {
    if ($^O eq 'MSWin32') {
        system('start "TEMP_HTTP_SERVER" /MIN perl ' . $repo_root . 't/http-server.pl');
    }
    else {
        system('perl ' . $repo_root . 't/http-server.pl > /dev/null &');
    }
    print 'Starting a new server.' . "\n";
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
    if (@ARGV && $ARGV[0] eq 'reset') {
        print 'Cleaning. ';
        `cd $repo_root && dzil clean`;
    }
    print 'Taking out any existing servers. ' . "\n";
    kill_server();
}
