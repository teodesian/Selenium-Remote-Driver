package Selenium::Direct;

use strict;
use warnings;

# ABSTRACT: Use the Selenium JAR atomically without a running Selenium server
use Moo;
use Carp;

use Selenium::CanStartBinary::FindBinary qw/coerce_simple_binary/;
use File::Which qw{which};

extends 'Selenium::Remote::Driver';

=head1 SYNOPSIS

    my $driver = Selenium::Direct->new();

    #Do stuff...

    #Optional, happens in DESTROY
    $driver->shutdown_binary;

=for Pod::Coverage has_binary

=head1 DESCRIPTION

Basically runs

    java -Dwebdriver.$browser.driver=path-to-driver ... -Dport=some_random_port -jar selenium.jar

with every available driver known by the other direct driver modules like L<Selenium::Firefox>, L<Selenium::Chrome>, L<Selenium::Edge> et cetera.

Looks for the selenium JAR within the existing PATH or CLASSPATH.
It must be +x (executable) and named exactly:

    selenium.jar

=attr binary

Optional: specify the path to the java binary to use.

=cut

has 'binary' => (
    is => 'lazy',
    coerce => \&coerce_simple_binary,
    default => sub {
        my $java = which 'java';
        croak "Can't find a java executable in your PATH!" unless $java;
        $java;
    },
    predicate => 1
);

=attr binary_port

Optional: specify the port that we should bind to. If you don't
specify anything, we'll default to the driver's default port. Since
there's no a priori guarantee that this will be an open port, this is
_not_ necessarily the port that we end up using - if the port here is
already bound, we'll search above it until we find an open one.

See L<Selenium::CanStartBinary/port> for more details, and
L<Selenium::Remote::Driver/port> after instantiation to see what the
actual port turned out to be.

=cut

has 'binary_port' => (
    is => 'lazy',
    default => sub {
        '4445'
    }
);

sub _binary_args {
    my ($self) = @_;

    my @args;

    my $geckodriver  = which 'geckodriver';
    my $chromedriver = which 'chromedriver';
    my $iedriver     = which 'internetexplorerdriver';
    my $edgedriver   = which 'microsoftedgedriver';

    push(@args,qq{-Dwebdriver.gecko.driver=$geckodriver})   if $geckodriver;
    push(@args,qq{-Dwebdriver.chrome.driver=$chromedriver}) if $chromedriver;
    push(@args,qq{-Dwebdriver.iedriver.driver=$iedriver})   if $iedriver;  #XXX maybe wrong?
    push(@args,qq{-Dwebdriver.edge.driver=$edgedriver})     if $edgedriver;

    push(@args, qq{-Dwebdriver.port=}.$self->port());

    $ENV{PATH} = $ENV{PATH}.":".$ENV{CLASSPATH};
    my $jar_binks = which 'selenium.jar';
    croak "Can't find a selenium.jar that's in \$PATH or \$CLASSPATH that's -x!" unless $jar_binks;

    push(@args, '-jar', $jar_binks);

    return @args;
}

has '+wd_context_prefix' => (
    is => 'ro',
    default => sub {
        '/hub';
    }
);

with 'Selenium::CanStartBinary';

=attr custom_args

Optional: specify any additional command line arguments you'd like
invoked during the java binary startup. See
L<Selenium::CanStartBinary/custom_args> for more information.

=attr startup_timeout

Optional: specify how long to wait for the binary to start itself and
listen on its port. The default duration is arbitrarily 10 seconds. It
accepts an integer number of seconds to wait: the following will wait
up to 20 seconds:

    Selenium::Firefox->new( startup_timeout => 20 );

See L<Selenium::CanStartBinary/startup_timeout> for more information.

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

=attr fixed_ports

Optional: Throw instead of searching for additional ports; see
L<Selenium::CanStartBinary/fixed_ports> for more info.

=cut

1;
