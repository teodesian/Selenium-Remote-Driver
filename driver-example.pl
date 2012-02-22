#!/usr/bin/perl
use Selenium::Remote::Driver;
use Test::More tests=>4;
use Data::Dumper;

my $driver = Selenium::Remote::Driver->new;
$driver->get("http://www.google.com");
$driver->find_element('q','name')->send_keys("Hello WebDriver!");

ok($driver->get_title =~ /Google/,"title matches google");
is($driver->get_title,'Google',"Title is google");
ok($driver->get_title eq 'Google','Title equals google');
like($driver->get_title,qr/Google/,"Title matches google");

print $driver->set_window_position(100,100);
print Dumper($driver->get_window_position());

$driver->quit();
