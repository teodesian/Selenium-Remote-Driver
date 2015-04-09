use strict;
use warnings;

use JSON;
use Test::More;
use LWP::UserAgent;
use Test::LWP::UserAgent;
use IO::Socket::INET;
use Selenium::Remote::Driver;
use Selenium::Remote::Mock::Commands;
use Selenium::Remote::Mock::RemoteConnection;

use FindBin;
use lib $FindBin::Bin . '/lib';
use TestHarness;
use Test::Fatal;

my $harness = TestHarness->new(
    this_file => $FindBin::Script
);
my %selenium_args = %{ $harness->base_caps };

my $driver = Selenium::Remote::Driver->new(%selenium_args);
my $domain = $harness->domain;
my $website = $harness->website;
my $ret;

my $chrome;
eval { $chrome = Selenium::Remote::Driver->new(
    %selenium_args,
    browser_name => 'firefox'
); };

use File::Basename 'dirname';
use File::Spec::Functions qw{catfile};

UPLOAD: {
    my $file = catfile(dirname(__FILE__), '01-driver-jamadam.t');
    my $file2 = catfile(dirname(__FILE__), '../Changes');
    eval {
        $driver->upload_file($file);
    };
    is $@, '';
    eval {
        $driver->upload_file($file2);
    };
    is $@, '';
}

done_testing;
