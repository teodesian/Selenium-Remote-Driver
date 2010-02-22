#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Selenium::Remote::Driver' ) || print "Bail out!
";
}

diag( "Testing Selenium::Remote::Driver $Selenium::Remote::Driver::VERSION, Perl $], $^X" );
