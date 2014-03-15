#! /usr/bin/perl

use strict;
use warnings;
use IPC::Open2;

unless (-d "t" && -f "dist.ini" && -f "t/01-driver.t" && -f "t/02-webelement.t") {
    die "Please run this from the root of the repo.";
}

startServer();
print `dzil build`;
print `export WD_MOCKING_RECORD=1 && perl -I"Selenium-Remote-Driver/lib" -w t/01-driver.t & perl -I"Selenium-Remote-Driver/lib" -w t/02-webelement.t & wait`;
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
        `ps aux | grep http-server\.pl | grep perl | awk '{print \$2}' | xargs kill`;
    }
}
