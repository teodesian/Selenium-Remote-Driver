package Selenium::InternetExplorer;

# ABSTRACT: A convenience package for creating a IE instance
use Moo;
extends 'Selenium::Remote::Driver';

=head1 SYNOPSIS

    my $driver = Selenium::InternetExplorer->new;

=cut

has '+browser_name' => (
    is => 'ro',
    default => sub { 'internet_explorer' }
);

has '+platform' => (
    is => 'ro',
    default => sub { 'WINDOWS' }
);

1;
