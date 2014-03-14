#! /usr/bin/perl

use strict;
use warnings;

use Selenium::Remote::Driver;
use Test::More;

use MIME::Base64 qw/decode_base64/;
use Archive::Extract;
use File::Temp;
use JSON;

BEGIN {
    unless (use_ok('Selenium::Remote::Driver::Firefox::Profile')) {
        BAIL_OUT ("Couldn't load Firefox Profile");
        exit;
    }

    if (defined $ENV{'WD_MOCKING_RECORD'} && ($ENV{'WD_MOCKING_RECORD'}==1))
    {
        use t::lib::MockSeleniumWebDriver;
        my $p = Net::Ping->new("tcp", 2);
        $p->port_number(4444);
        unless ($p->ping('localhost')) {
            plan skip_all => "Selenium server is not running on localhost:4444";
            exit;
        }
        warn "\n\nRecording...\n\n";
    }
}

my $record = (defined $ENV{'WD_MOCKING_RECORD'} && ($ENV{'WD_MOCKING_RECORD'}==1))?1:0;
my $os  = $^O;
if ($os =~ m/(aix|freebsd|openbsd|sunos|solaris)/)
{
    $os = 'linux';
}
my $mock_file = "firefox-profile-mock-$os.json";
if (!$record && !(-e "t/mock-recordings/$mock_file"))
{
    plan skip_all => "Mocking of tests is not been enabled for this platform";
}
t::lib::MockSeleniumWebDriver::register($record,"t/mock-recordings/$mock_file");

# Start our local http server
if ($^O eq 'MSWin32' && $record)
{
    system("start \"TEMP_HTTP_SERVER\" /MIN perl t/http-server.pl");
} elsif ($record)
{
    system("perl t/http-server.pl > /dev/null &");
}

CUSTOM_EXTENSION_LOADED: {
    my $profile = Selenium::Remote::Driver::Firefox::Profile->new();
    $profile->set_preferences(
        "browser.startup.homepage" => "http://www.google.com"
       );

    $profile->add_extension('t/www/redisplay.xpi');

    my $driver = Selenium::Remote::Driver->new(firefox_profile => $profile);

    ok(defined $driver, "made a driver without dying");

    # the initial automatic homepage load isn't blocking, so we need
    # to wait until the page is loaded (when we can find elements)
    $driver->set_implicit_wait_timeout(30000);
    $driver->find_element("h1", "tag_name");
    cmp_ok($driver->get_title, '=~', qr/google/i, "profile loaded and preference respected!");

    $driver->get("http://www.google.com");
    cmp_ok($driver->get_text("body", "tag_name"), "=~", qr/ruleset/,
           "custom profile with extension loaded");
}

PREFERENCES_FORMATTING: {
    my $profile = Selenium::Remote::Driver::Firefox::Profile->new();
    my $prefs = {
        'string' => "howdy, there",
        'integer' => 12345,
        'true' => JSON::true,
        'false' => JSON::false,
        'string.like.integer' => '"12345"',
    };

    my %expected = map {
        my $q = $_ eq 'string' ? '"' : '';
        $_ => $q . $prefs->{$_} . $q
    } keys %$prefs;

    $profile->set_preference(%$prefs);

    foreach (keys %$prefs) {
        cmp_ok($profile->get_preference($_), "eq", $expected{$_},
               "$_ preference is formatted properly");
    }

    my $encoded = $profile->_encode();
    my $fh = File::Temp->new();
    print $fh decode_base64($encoded);
    close $fh;
    my $zip = Archive::Extract->new( archive => $fh->filename,
                                     type => "zip");
    my $tempdir = File::Temp->newdir();
    my $ok = $zip->extract( to => $tempdir );
    my $outdir = $zip->extract_path;

    my $filename = $tempdir . "/user.js";
    open ($fh, "<", $filename);
    my (@file) = <$fh>;
    close ($fh);
    my $userjs = join('', @file);

    foreach (keys %expected) {
        cmp_ok($userjs, "=~", qr/$expected{$_}\);/,
               "$_ preference is formatted properly");
    }
}

CROAKING: {
    my $profile = Selenium::Remote::Driver::Firefox::Profile->new();
    {
        eval {
            $profile->add_extension('00-load.t');
        };
        ok($@, "caught invalid extension filetype");
    }

    {
        eval {
            $profile->add_extension('t/www/invalid-extension.xpi');
            my $test = $profile->_encode;
        };
        ok($@, "caught invalid extension structure");
    }
}

# Kill our HTTP Server
if ($^O eq 'MSWin32' && $record)
{
   system("taskkill /FI \"WINDOWTITLE eq TEMP_HTTP_SERVER\"");
}
elsif ($record)
{
    `ps aux | grep http-server\.pl | grep perl | awk '{print \$2}' | xargs kill`;
}

done_testing;
