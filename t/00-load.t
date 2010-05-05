use strict;

use Test::More tests => 1;

BEGIN {
    if ($^O eq 'MSWin32') {
        BAIL_OUT 'Unit tests not supported yet, need to be on Mac on Linux with Firefox';
    }
    use_ok( 'Selenium::Remote::Driver' ) || print "Bail out!";
}

