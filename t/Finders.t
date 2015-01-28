#! /usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN: {
    unless (use_ok('Selenium::Remote::Driver')) {
        BAIL_OUT("Couldn't load Selenium::Remote::Driver");
        exit;
    }
}

use FindBin;
use lib $FindBin::Bin . '/lib';
use TestHarness;

my $harness = TestHarness->new(
    this_file => $FindBin::Script
);

my %selenium_args = %{ $harness->base_caps };

my $driver = Selenium::Remote::Driver->new(%selenium_args);
$driver->get('http://danielgempesaw.com/Selenium-Remote-Driver/xhtmlTest.html');

# This depends explicitly on the page we're visiting (xhtmlTest.html),
my %finders = (
    class => 'navigation',
    class_name => 'navigation',
    css => 'html',
    id => 'linkId',
    link => 'this goes to the same place',
    link_text => 'this goes to the same place',
    name => 'windowOne',
    partial_link_text => 'this goes to the same',
    tag_name => 'html',
    xpath => '//html'
);

foreach my $by (keys %finders) {
    my $locator = $finders{$by};
    my $method = 'find_element_by_' . $by;

    ok($driver->can($method), $method . ':  installed properly');
    my $elem = $driver->$method($locator);
    ok($elem, $method . ': finds an element properly');
    ok($elem->isa('Selenium::Remote::WebElement'), $method . ': element is a WebElement');
    {
        # Briefly suppress warning output for prettier tests
        my $warned = 0;
        local $SIG{__WARN__} = sub { $warned++ };
        ok(!$driver->$method('missing') , $method . ': does not croak on unavailable elements');
        ok($warned, $method . ': unavailable elements throw a warning');
    }
}
done_testing;
