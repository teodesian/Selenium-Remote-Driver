package Selenium::Firefox;

use Moo;
extends 'Selenium::Remote::Driver';

has '+browser_name' => (
    is => 'ro',
    default => sub { 'firefox' }
);

1;
