package Selenium::Chrome;

# ABSTRACT: A convenience package for creating a Chrome instance
use Moo;
extends 'Selenium::Remote::Driver';

=head1 SYNOPSIS

    my $driver = Selenium::Chrome->new;

=cut

has '+browser_name' => (
    is => 'ro',
    default => sub { 'chrome' }
);

1;
