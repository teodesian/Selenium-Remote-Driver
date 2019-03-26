package Selenium::Remote::Finders;

use strict;
use warnings;

# ABSTRACT: Handle construction of generic parameter finders
use Try::Tiny;
use Carp qw/carp/;
use Moo::Role;
use namespace::clean;

=head1 DESCRIPTION

This package just takes care of setting up parameter finders - that
is, the C<find_element_by_.*> versions of the find element
functions. You probably don't need to do anything with this package;
instead, see L<Selenium::Remote::Driver/find_element> documentation
for the specific finder functions.

=cut

sub _build_find_by {
    my ( $self, $by ) = @_;

    return sub {
        my ( $driver, $locator ) = @_;
        my $strategy = $by;

        return try {
            return $driver->find_element( $locator, $strategy );
        }
        catch {
            carp $_;
            return 0;
        };
      }
}

1;
