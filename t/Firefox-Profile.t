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
    my $mock_encoded_profile = "t/www/encoded_profile.b64";
    my $encoded;

    # Set this to true to re-encode the profile. This should not need
    # to happen often.
    my $create_new_profile = 0;
    if ($record && $create_new_profile) {
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

        $encoded = $profile->_encode;

        open (my $fh, ">", $mock_encoded_profile);
        print $fh $encoded;
        close ($fh);
    }
    else {
        open (my $fh, "<", $mock_encoded_profile);
        $encoded = do {local $/ = undef; <$fh>};
        close ($fh);
    }

    my $driver = Selenium::Remote::Driver->new(extra_capabilities => {
        firefox_profile => $encoded
    });

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

PREFERENCES: {
    my $profile = Selenium::Remote::Driver::Firefox::Profile->new();
    # We're keeping the expected values together as we accumulate them
    # so we can validate them all at the end in the pack_and_unpack
    # section
    my $expected = {};

  STRINGS_AND_INTEGERS: {
        my $prefs = {
            'string' => "howdy, there",
            'integer' => 12345,
            'string.like.integer' => '"12345"',
        };

        foreach (keys %$prefs) {
            my $q = $_ eq 'string' ? '"' : '';
            $expected->{$_} = $q . $prefs->{$_} . $q;
        }

        $profile->set_preference(%$prefs);

        foreach (keys %$prefs) {
            cmp_ok($profile->get_preference($_), "eq", $expected->{$_},
                   "$_ preference is formatted properly");
        }
    }

  BOOLEANS: {
        my $prefs = {
            'boolean.true' => 1,
            'boolean.false' => 0,
        };

        foreach (keys %$prefs) {
            $expected->{$_} = $prefs->{$_} ? 'true' : 'false';
        }

        $profile->set_boolean_preference(%$prefs);

        foreach (keys %$prefs) {
            cmp_ok($profile->get_preference($_), "eq", $expected->{$_},
                   "$_ pref is formatted correctly");
        }
    }

  PACK_AND_UNPACK: {
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

        foreach (keys %$expected) {
            my $value = $expected->{$_};
            cmp_ok($userjs, "=~", qr/$value\);/,
                   "$_ preference is formatted properly after packing and unpacking");
        }
    }
}

CROAKING: {
    my $profile = Selenium::Remote::Driver::Firefox::Profile->new;
    {
        eval {
            $profile->add_extension('t/00-load.t');
        };
        cmp_ok($@, '=~', qr/xpi format/i, "caught invalid extension filetype");
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
