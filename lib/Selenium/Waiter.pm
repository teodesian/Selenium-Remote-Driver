package Selenium::Waiter;

use strict;
use warnings;

# ABSTRACT: Provides a utility wait_until function
use Try::Tiny;
require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT = qw/wait_until/;

=head1 SYNOPSIS

    use Selenium::Waiter qw/wait_until/;
    my $d = Selenium::Remote::Driver->new;

    my $div = wait_until { $d->find_element('div', 'css') };

=head1 FUNCTIONS

=head2 wait_until

Exported by default, it takes a BLOCK (required) and optionally a
hash of configuration params. It uses a prototype to take its
arguments, so usage looks look like:

    use Selenium::Waiter;
    my $div = wait_until { $driver->find_element('div', 'css') };

The above snippet will search for C<css=div> for thirty seconds; if it
ever finds the element, it will immediately return. More generally,
Once the BLOCK returns anything truthy, the C<wait_until> will stop
evaluating and the return of the BLOCK will be returned to you. If the
BLOCK never returns a truthy value, we'll wait until the elapsed time
has increased past the timeout and then return an empty string C<''>.

B<Achtung!> Please make sure that the BLOCK you pass in can be
executed in a timely fashion. For Webdriver, that means that you
should set the appropriate C<implicit_wait> timeout low (a second or
less!)  so that we can rerun the assert sub repeatedly. We don't do
anything fancy behind the scenes: we just execute the BLOCK you pass
in and sleep between iterations. If your BLOCK actively blocks for
thirty seconds, like a C<find_element> would do with an
C<implicit_wait> of 30 seconds, we won't be able to help you at all -
that blocking behavior is on the webdriver server side, and is out of
our control. We'd run one iteration, get blocked for thirty seconds,
and return control to you at that point.

=head4 Dying

PLEASE check the return value before proceeding, as we unwisely
suppress any attempts your BLOCK may make to die or croak. The BLOCK
you pass is called in a L<Try::Tiny/try>, and if any of the
invocations of your function throw and the BLOCK never becomes true,
we'll carp exactly once at the end immediately before returning
false. We overwrite the death message from each iteration, so at the
end, you'll only see the most recent death message.

    # warns once after thirty seconds: "kept from dying";
    wait_until { die 'kept from dying' };

The output of C<die>s from each iteration can be exposed if you wish
to see the massacre:

    # carps: "kept from dying" once a second for thirty seconds
    wait_until { die 'kept from dying' } debug => 1;

=head4 Timeouts and Intervals

You can also customize the timeout, and/or the retry interval between
iterations.

    # prints hi three four times at 0, 3, 6, and 9 seconds
    wait_until { print 'hi'; '' } timeout => 10, interval => 3;

=cut

sub wait_until (&%) {
    my $assert = shift;
    my $args = {
        timeout => 30,
        interval => 1,
        debug => 0,
        @_
    };

    my $start = time;
    my $timeout_not_elapsed = sub {
        my $elapsed = time - $start;
        return $elapsed < $args->{timeout};
    };

    my $exception = '';
    while ($timeout_not_elapsed->()) {
        my $assert_ret;
        my $try_ret = try {
            $assert_ret = $assert->();
            return $assert_ret if $assert_ret;
        }
        catch {
            $exception = $_;
            warn $_ if $args->{debug};
            return '';
        }
        finally {
            if (! $assert_ret) {
                sleep($args->{interval});
            }
        };

        return $try_ret if $try_ret;
    }

    # No need to repeat ourselves if we're already debugging.
    warn $exception if $exception && ! $args->{debug};
    return '';
}

1;
