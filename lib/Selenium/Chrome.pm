package Selenium::Chrome;

use Moo;
extends 'Selenium::Remote::Driver';

has '+browser_name' => (
    is => 'ro',
    default => sub { 'chrome' }
);

1;
