package Selenium::Remote::Driver::CanSetWebdriverContext;

# ABSTRACT: Customize the webdriver context prefix for various drivers

use strict;
use warnings;

use Moo::Role;

=head1 DESCRIPTION

Some drivers don't use the typical C</wd/hub> context prefix for the
webdriver HTTP communication. For example, the newer versions of the
Firefox driver extension use the context C</hub> instead. This role
just has the one attribute with a default webdriver context prefix,
and is consumed in L<Selenium::Remote::Driver> and
L<Selenium::Remote::RemoteConnection>.

If you're new to webdriver, you probably want to head over to
L<Selenium::Remote::Driver>'s docs; this package is more of an
internal-facing concern.

=cut

has 'wd_context_prefix' => (
    is      => 'lazy',
    default => sub { '/wd/hub' }
);

1;
