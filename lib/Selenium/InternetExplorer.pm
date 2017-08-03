package Selenium::InternetExplorer;

use strict;
use warnings;

# ABSTRACT: A convenience package for creating a IE instance
use Moo;
extends 'Selenium::Remote::Driver';

=head1 SYNOPSIS

    my $driver = Selenium::InternetExplorer->new;
    # when you're done
    $driver->shutdown_binary;

=cut

has '+browser_name' => (
    is => 'ro',
    default => sub { 'internet_explorer' }
);

has '+platform' => (
    is => 'ro',
    default => sub { 'WINDOWS' }
);

=method shutdown_binary

Call this method instead of L<Selenium::Remote::Driver/quit> to ensure
that the binary executable is also closed, instead of simply closing
the browser itself. If the browser is still around, it will call
C<quit> for you. After that, it will try to shutdown the browser
binary by making a GET to /shutdown and on Windows, it will attempt to
do a C<taskkill> on the binary CMD window.

    $self->shutdown_binary;

It doesn't take any arguments, and it doesn't return anything.

We do our best to call this when the C<$driver> option goes out of
scope, but if that happens during global destruction, there's nothing
we can do.

=cut

1;
