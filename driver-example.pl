#!/usr/bin/perl
use Selenium::Remote::Driver;

my $driver = Selenium::Remote::Driver->new;
$driver->get("http://www.google.com");
my $element = $driver->find_element('q','name');
$element->send_keys("Hello WebDriver!");
$element->submit;

print $driver->get_title() . "\n";

$driver->quit();
