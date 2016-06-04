use strict;
use warnings;
use Selenium::Chrome;
use Selenium::Firefox;
use Selenium::InternetExplorer;
use Selenium::PhantomJS;
use Test::Selenium::Chrome;
use Test::Selenium::Firefox;
use Test::Selenium::InternetExplorer;
use Test::Selenium::PhantomJS;
use Test::More;

use FindBin;
use lib $FindBin::Bin . '/lib';
use TestHarness;

my $harness = TestHarness->new(
    this_file => $FindBin::Script
);

my %caps = %{ $harness->base_caps };
$caps{remote_server_addr} = '127.0.0.1';
delete $caps{browser_name};

subtest Driver => sub {
	my $phantomjs = Selenium::PhantomJS->new( %caps );
	ok( $phantomjs->browser_name eq 'phantomjs', 'convenience phantomjs is okay' );
	$phantomjs->quit;

	my $firefox = Selenium::Firefox->new( %caps );
	ok( $firefox->browser_name eq 'firefox', 'convenience firefox is okay' );
	$firefox->quit;

	my $chrome = Selenium::Chrome->new( %caps );
	ok( $chrome->browser_name eq 'chrome', 'convenience chrome is okay' );
	$chrome->quit;

	SKIP: {
		skip 'Can only test IE on windows', 1 unless $^O eq 'MSWin32';

		my $ie = Selenium::InternetExplorer->new( %caps );
		ok( $ie->browser_name eq 'internet_explorer', 'convenience ie is okay' );
		$ie->quit;
	}
};

subtest TestDriver => sub {
	my $phantomjs = Test::Selenium::PhantomJS->new( %caps );
	ok( $phantomjs->browser_name eq 'phantomjs', 'convenience phantomjs is okay' );
	$phantomjs->get_ok('about:config');
	$phantomjs->quit;

	my $firefox = Test::Selenium::Firefox->new( %caps );
	$firefox->get_ok('about:config');
	ok( $firefox->browser_name eq 'firefox', 'convenience firefox is okay' );
	$firefox->quit;

	my $chrome = Test::Selenium::Chrome->new( %caps );
	ok( $chrome->browser_name eq 'chrome', 'convenience chrome is okay' );
	$chrome->get_ok('about:config');
	$chrome->quit;

	SKIP: {
		skip 'Can only test IE on windows', 1 unless $^O eq 'MSWin32';

		my $ie = Test::Selenium::InternetExplorer->new( %caps );
		ok( $ie->browser_name eq 'internet_explorer', 'convenience ie is okay' );
		$ie->quit;
	}
};


done_testing;
