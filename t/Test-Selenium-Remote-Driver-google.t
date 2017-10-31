use strict;
use warnings;
use Test::More tests => 3;
use Test::Selenium::Remote::Driver;
use Selenium::Remote::Mock::RemoteConnection;
use Carp::Always;
use FindBin;
use lib $FindBin::Bin . '/lib';
use TestHarness;

my $harness = TestHarness->new(
    this_file => $FindBin::Script
);
my %selenium_args = %{ $harness->base_caps };

# Try to find
my $t = Test::Selenium::Remote::Driver->new(
    %selenium_args
);
$t->get_ok('http://www.google.com');
$t->title_like(qr/Google/, "We were able to get the expected page title" );
{
    no warnings 'redefine';
    local *Selenium::Remote::WebElement::get_text = sub { return 'Google'; };
    $t->body_like(qr/Google/, "We got the expected text on the page");
}
