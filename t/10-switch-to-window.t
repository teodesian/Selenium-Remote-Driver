use strict;
use warnings;

use Test::More;
use Test::Selenium::Remote::Driver;
use Selenium::Remote::Mock::RemoteConnection;

use FindBin;
use lib $FindBin::Bin . '/lib';
use TestHarness;

my $harness = TestHarness->new(
    this_file => $FindBin::Script
);

my @browsers = qw/chrome firefox/;

foreach (@browsers) {
    my %selenium_args = (
        default_finder => 'css',
        javascript     => 1,
        %{ $harness->base_caps },
        browser_name   => $_,
    );

    my $s = Test::Selenium::Remote::Driver->new(
        %selenium_args
    );

    my $perl_title = 'The Perl Programming Language - www.perl.org';
    my $cpan_title = 'The Comprehensive Perl Archive Network - www.cpan.org';

    $s->get_ok('http://perl.org/');
    $s->title_is($perl_title, 'perl.org title matches correctly');
    my $old_handles = $s->get_window_handles;
    is(scalar(@$old_handles), 1, 'got one window handle as expected');
    my $perl_handle = $old_handles->[0];
    # setting the window.name manually
    $s->execute_script(q{return window.name = 'perlorg';});

    # setting the window.name when opening the other window
    $s->execute_script(q{$(window.open('http://cpan.org/', 'cpanorg'))});
    $s->title_is($perl_title, 'creating a new window keeps us focused on the current window');

    my $handles = $s->get_window_handles;
    is(scalar(@$handles), 2, 'get_window_handles sees both of our browser windows');
    # We don't assume any order in the @$handles array:
    my $cpan_handle = $perl_handle eq $handles->[0] ? $handles->[1] : $handles->[0];

    $s->switch_to_window($cpan_handle);
    $s->get_ok('http://cpan.org');
    $s->title_is($cpan_title, 'can switch to window by handle');

    $s->switch_to_window($perl_handle);
    $s->title_is($perl_title, 'can switch back to main window by handle');

    if ($_ eq 'chrome') {
        $s->switch_to_window('cpanorg');
        $s->title_is($cpan_title, 'can switch to window by window title in chrome');

        $s->switch_to_window('perlorg');
        $s->title_is($perl_title, 'can switch to main window by window title in chrome');
    }
}

done_testing;
