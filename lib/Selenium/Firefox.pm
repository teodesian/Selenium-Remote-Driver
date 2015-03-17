package Selenium::Firefox;

# ABSTRACT: A convenience package for creating a Firefox instance
use Moo;
extends 'Selenium::Remote::Driver';
with 'Selenium::BinaryModeBuilder';

=head1 SYNOPSIS

my $driver = Selenium::Firefox->new;

=cut

use constant FIREFOX_PORT => 9090;

has '+browser_name' => (
    is => 'ro',
    default => sub { 'firefox' }
);

# By shadowing the parent's port, we can set it in _build_binary_mode properly
has '+port' => (
    is => 'lazy',
    default => sub { 4444 }
);

has 'binary_mode' => (
    is => 'ro',
    init_arg => undef,
    builder => 1
);

has 'binary_name' => (
    is => 'lazy',
    default => sub { 'firefox' }
);

has 'binary_port' => (
    is => 'lazy',
    default => sub { 9090 }
);

1;
