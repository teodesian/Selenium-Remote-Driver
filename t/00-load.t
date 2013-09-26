use strict;

use Test::More tests => 2;

BEGIN {
    use_ok( 'Selenium::Remote::Driver' ) || print "Bail out!";
    use_ok( 'Test::Selenium::Remote::Driver' ) || print "Bail out!";
}

