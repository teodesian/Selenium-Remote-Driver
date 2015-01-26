package Selenium::Remote::Finders;

use Try::Tiny;
use Carp qw/carp/;
use Moo::Role;
use namespace::clean;

sub _build_find_by {
    my ($self, $by) = @_;

    return sub {
        my ($driver, $locator) = @_;
        my $strategy = $by;

        return try {
            return $driver->find_element($locator, $strategy);
        }
        catch {
            carp $_;
            return 0;
        };
    }
}

1;
