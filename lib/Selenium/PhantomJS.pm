package Selenium::PhantomJS;

use Moo;
extends 'Selenium::Remote::Driver';

has '+browser_name' => (
    is => 'ro',
    default => sub { 'phantomjs' }
);

1;
