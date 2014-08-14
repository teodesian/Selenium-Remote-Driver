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


$s->get_ok('http://perl.org/');
$s->title_is('The Perl Programming Language - www.perl.org');
my $old_handles = $s->get_window_handles;
is scalar(@$old_handles), 1;

$s->execute_script(q{$(window.open('http://cpan.org/'))});
$s->title_is('The Perl Programming Language - www.perl.org');

my $handles = $s->get_window_handles;
is scalar(@$handles), 2;

diag explain $handles;
my @titles;
foreach my $h (@$handles) {
    $s->switch_to_window($h);
    diag $s->get_title;
    push @titles, $s->get_title;
}

my $current_title = $s->get_title;
foreach my $t (@titles) {
	TODO: {
		local $TODO = 'switching window by title';
    	eval {
    	    $s->switch_to_window($t);
    	};
    	is $@, undef, 'exception switching';
    	is $s->get_title, $t, 'title';
	}
}
