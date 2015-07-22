
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'Selenium::Remote::Driver' ) || print "Bail out!";
    use_ok( 'Test::Selenium::Remote::Driver' ) || print "Bail out!";
    use_ok('Selenium::Remote::Driver::Firefox::Profile') || print "Bail out!";
}

done_testing;
