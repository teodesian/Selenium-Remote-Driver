use strict;
use warnings;

use Selenium::Remote::Driver;
use Test::More;

use MIME::Base64 qw/decode_base64/;
use IO::Uncompress::Unzip qw(unzip $UnzipError);
use File::Temp;
use JSON;
use Selenium::Remote::Mock::RemoteConnection;
use Selenium::Remote::Driver::Firefox::Profile;

use FindBin;
use lib $FindBin::Bin . '/lib';
use TestHarness;

my $harness = TestHarness->new(
    this_file => $FindBin::Script
);
my %selenium_args = %{ $harness->base_caps };

my $fixture_dir = $FindBin::Bin . '/www/';

CUSTOM_EXTENSION_LOADED: {
    my $profile = Selenium::Remote::Driver::Firefox::Profile->new;
    my $domain = $harness->domain;
    my $website = $harness->website;
    my $mock_encoded_profile = $fixture_dir . 'encoded_profile.b64';
    my $encoded;

    # Set this to true to re-encode the profile. This should not need
    # to happen often.
    my $create_new_profile = 0;
    if ($create_new_profile) {
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
        $profile->add_extension($fixture_dir . 'redisplay.xpi');

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
    my %driver_args = %selenium_args;
    $driver_args{extra_capabilities} = { firefox_profile => $encoded };
    my $driver = Selenium::Remote::Driver->new(%driver_args);

    ok(defined $driver, "made a driver without dying");

    # We don't have to `$driver->get` because our extension should do
    # it for us. However, the initial automatic homepage load found in
    # the preference 'browser.startup.homepage' isn't blocking, so we
    # need to wait until the page is loaded (when we can find
    # elements)
    $driver->set_implicit_wait_timeout(30000);
    $driver->find_element("h1", "tag_name");
    cmp_ok($driver->get_current_url, '=~', qr/$domain/i,
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

        $profile->set_preference(
            'boolean.true.2' => JSON::true,
            'boolean.false.2' => JSON::false
        );
        is($profile->get_preference('boolean.true.2'), 'true',
           'format true booleans via set_preference & JSON::true');
        is($profile->get_preference('boolean.false.2'), 'false',
           'format false booleans via set_preference & JSON::false');
    }

  PACK_AND_UNPACK: {
        my $encoded = $profile->_encode();
        my $fh = File::Temp->new();
        print $fh decode_base64($encoded);
        close $fh;

        my $userjs;
        unzip $fh->filename => \$userjs, Name => "user.js"
          or die "unzip failed: $UnzipError\n";

        foreach (keys %$expected) {
            my $value = $expected->{$_};
            cmp_ok($userjs, "=~", qr/$value\);/,
                   "$_ preference is formatted properly after packing and unpacking");
        }
    }

  MUTABLE_WEBDRIVER: {
        my $prefs = {
            'browser.startup.homepage' => 'mutable!'
        };

        my $profile = Selenium::Firefox::Profile->new;
        $profile->set_preference(%$prefs);
        $profile->add_webdriver('port');

        my $homepage_pref = $profile->get_preference('browser.startup.homepage');
        is($homepage_pref, '"mutable!"', 'can mutate webdriver.json preferences');
    }
}

CROAKING: {
    my $profile = Selenium::Remote::Driver::Firefox::Profile->new;

    eval { $profile->add_extension('gibberish'); };
    cmp_ok($@, '=~', qr/File not found/i, 'throws on missing file');

    eval { $profile->add_extension($FindBin::Bin . '/00-load.t'); };
    cmp_ok($@, '=~', qr/xpi format/i, "caught invalid extension filetype");

    eval {
        $profile->add_extension($fixture_dir . 'invalid-extension.xpi') ;
        $profile->_encode;
    };
    ok($@ =~ /install\.rdf/i, "caught invalid extension structure");

    eval {
        my %driver_args = %selenium_args;
        $driver_args{firefox_profile} = 'clearly invalid';
        my $croakingDriver = Selenium::Remote::Driver->new(
            %driver_args
        );
    };
    ok ($@ =~ /coercion.*failed/, "caught invalid extension in driver constructor");
}

PROFILE_DIR: {
    my $tempdir = File::Temp->newdir;
    my $dirname = $tempdir->dirname;

    my $profile = Selenium::Firefox::Profile->new( profile_dir => $dirname );
    ok( $profile->{profile_dir} eq $dirname, "profile_dir passed to constructor" );

    $profile->_layout_on_disk;
    ok( -f $dirname . '/user.js', "wrote to profile_dir" );
}

done_testing;
