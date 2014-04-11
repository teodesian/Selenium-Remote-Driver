#! /usr/bin/perl

use strict;
use warnings;

use Selenium::Remote::Driver;
use Test::More;

use MIME::Base64 qw/decode_base64/;
use Archive::Extract;
use File::Temp;
use JSON;
use Selenium::Remote::Driver::Firefox::Profile;

BEGIN {
    if (defined $ENV{'WD_MOCKING_RECORD'} && ($ENV{'WD_MOCKING_RECORD'}==1)) {
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
if ($os =~ m/(aix|freebsd|openbsd|sunos|solaris)/) {
    $os = 'linux';
}
my $mock_file = "firefox-profile-mock-$os.json";
if (!$record && !(-e "t/mock-recordings/$mock_file")) {
    plan skip_all => "Mocking of tests is not been enabled for this platform";
}
t::lib::MockSeleniumWebDriver::register($record,"t/mock-recordings/$mock_file");

CUSTOM_EXTENSION_LOADED: {
    my $profile = Selenium::Remote::Driver::Firefox::Profile->new;

    my $website = 'http://localhost:63636';
    $profile->set_preference(
        'browser.startup.homepage' => $website
    );

    # This extension rewrites any page url to a single <h1>. The
    # following javascript is in redisplay.xpi's
    # resources/gempesaw/lib/main.js:

    # var pageMod = require("sdk/page-mod");
    # pageMod.PageMod({
    #     include: "*",
    #     contentScript: 'document.body.innerHTML = ' +
    #         ' "<h1>Page matches ruleset</h1>";'
    # });
    $profile->add_extension('t/www/redisplay.xpi');

    my $driver = Selenium::Remote::Driver->new(
        firefox_profile => $profile
    );

    ok(defined $driver, "made a driver without dying");

    # the initial automatic homepage load found in the preference
    # 'browser.startup.homepage' isn't blocking, so we need to wait
    # until the page is loaded (when we can find elements)
    $driver->set_implicit_wait_timeout(30000);
    $driver->find_element("h1", "tag_name");
    cmp_ok($driver->get_current_url, '=~', qr/localhost/i,
           "profile loaded and preference respected!");

    $driver->get($website . '/index.html');
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
    my $zip = Archive::Extract->new(
        archive => $fh->filename,
        type => "zip"
    );
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
               "$_ preference is formatted properly after packing and unpacking");
    }
}

CROAKING: {
    my $profile = Selenium::Remote::Driver::Firefox::Profile->new;
    {
        eval {
            $profile->add_extension('00-load.t');
        };
        ok($@ =~ /xpi format/i, "caught invalid extension filetype");
    }

    {
        eval {
            $profile->add_extension('t/www/invalid-extension.xpi');
            my $test = $profile->_encode;
        };
        ok($@ =~ /install\.rdf/i, "caught invalid extension structure");
    }

    {
        eval {
            my $croakingDriver = Selenium::Remote::Driver->new(
                firefox_profile => 'clearly invalid!'
            );
        };
        ok ($@ =~ /coercion.*failed/, "caught invalid extension in driver constructor");
    }
}

done_testing;
