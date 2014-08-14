use strict;
use warnings;
use 5.010;

use Test::More;
use Test::Selenium::Remote::Driver;

if (not Test::Selenium::Remote::Driver->server_is_running()) {
    plan skip_all => 'The Selenium server must be running for this test';
}

plan tests => 9;

my $s = Test::Selenium::Remote::Driver->new(
    default_finder => 'css',
    javascript     => 1,
);

my $perl_title = 'The Perl Programming Language - www.perl.org';
my $cpan_title = 'The Comprehensive Perl Archive Network - www.cpan.org';

$s->get_ok('http://perl.org/');
$s->title_is($perl_title);
my $old_handles = $s->get_window_handles;
is scalar(@$old_handles), 1;
my $perl_handle = $old_handles->[0];
# setting the window.name manually
$s->execute_script(q{return window.name = 'perlorg';});

# setting the window.name when opening the other window
$s->execute_script(q{$(window.open('http://cpan.org/', 'cpanorg'))});
$s->title_is($perl_title);

my $handles = $s->get_window_handles;
is scalar(@$handles), 2;
# We don't assume any order in the @$handles array:
my $cpan_handle = $perl_handle eq $handles->[0] ? $handles->[1] : $handles->[0];
diag explain $handles;

$s->switch_to_window($cpan_handle);
$s->title_is($cpan_title);

$s->switch_to_window($perl_handle);
$s->title_is($perl_title);

$s->switch_to_window('cpanorg');
$s->title_is($cpan_title);

$s->switch_to_window('perlorg');
$s->title_is($perl_title);

