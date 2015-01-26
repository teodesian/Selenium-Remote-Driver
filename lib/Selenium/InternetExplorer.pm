package Selenium::InternetExplorer;

use Moo;
extends 'Selenium::Remote::Driver';

has '+browser_name' => (
    is => 'ro',
    default => sub { 'internet_explorer' }
);

has '+platform' => (
    is => 'ro',
    default => sub { 'WINDOWS' }
);

1;
