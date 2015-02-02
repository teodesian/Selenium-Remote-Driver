package Selenium::Firefox;

# ABSTRACT: A convenience package for creating a Firefox instance
use Moo;
extends 'Selenium::Remote::Driver';

=head1 SYNOPSIS

    my $driver = Selenium::Firefox->new;

=cut

has '+browser_name' => (
    is => 'ro',
    default => sub { 'firefox' }
);

1;
