package Selenium::CanStartBinary;

# ABSTRACT: Teach a WebDriver how to start its own binary aka no JRE!
use File::Spec;
use Selenium::CanStartBinary::ProbePort qw/find_open_port_above probe_port/;
use Selenium::Firefox::Binary qw/setup_firefox_binary_env/;
use Selenium::Waiter qw/wait_until/;
use Moo::Role;

=head1 SYNOPSIS

    package My::Selenium::Chrome {
        use Moo;
        extends 'Selenium::Remote::Driver';

        has 'binary' => ( is => 'ro', default => 'chromedriver' );
        has 'binary_port' => ( is => 'ro', default => 9515 );
        has '_binary_args' => ( is => 'ro', default => sub {
            return ' --port=' . shift->port . ' --url-base=wd/hub ';
        });
        with 'Selenium::CanStartBinary';
        1
    };

    my $chrome_via_binary = My::Selenium::Chrome->new;
    my $chrome_with_path  = My::Selenium::Chrome->new(
        binary => './chromedriver'
    );

=head1 DESCRIPTION

This role takes care of the details for starting up a Webdriver
instance. It does not do any downloading or installation of any sort -
you're still responsible for obtaining and installing the necessary
binaries into your C<$PATH> for this role to find. You may be
interested in L<Selenium::Chrome>, L<Selenium::Firefox>, or
L<Selenium::PhantomJS> if you're looking for classes that already
consume this role.

The role determines whether or not it should try to do its own magic
based on whether the consuming class is instantiated with a
C<remote_server_addr> and/or C<port>.

    # We'll start up the Chrome binary for you
    my $chrome_via_binary = Selenium::Chrome->new;

    # Look for a selenium server running on 4444.
    my $chrome_via_server = Selenium::Chrome->new( port => 4444 );

If they're missing, we assume the user wants to use a webdriver
directly and act accordingly. We handle finding the proper associated
binary (or you can specify it with L</binary>), figuring out what
arguments it wants, setting up any necessary environments, and
starting up the binary.

There's a number of TODOs left over - namely Windows support is
severely lacking, and we're pretty naive when we attempt to locate the
executables on our own.

In the following documentation, C<required> refers to when you're
consuming the role, not the C<required> when you're instantiating a
class that has already consumed the role.

=attr binary

Required: Specify the path to the executable in question, or the name
of the executable for us to find via L<File::Which/which>.

=cut

requires 'binary';

=attr binary_port

Required: Specify a default port that for the webdriver binary to try
to bind to. If that port is unavailable, we'll probe above that port
until we find a valid one.

=cut

requires 'binary_port';

=attr _binary_args

Required: Specify the arguments that the particular binary needs in
order to start up correctly. In particular, you may need to tell the
binary about the proper port when we start it up, or that it should
use a particular prefix to match up with the behavior of the Remote
Driver server.

If your binary doesn't need any arguments, just have the default be an
empty string.

=cut

requires '_binary_args';

=attr port

The role will attempt to determine the proper port for us. Consuming
roles should set a default port in L</binary_port> at which we will
begin searching for an open port.

Note that if we cannot locate a suitable L</binary>, port will be set
to 4444 so we can attempt to look for a Selenium server at
C<127.0.0.1:4444>.

=cut

has '+port' => (
    is => 'lazy',
    builder => sub {
        my ($self) = @_;

        if ($self->binary) {
            return find_open_port_above($self->binary_port);
        }
        else {
            return 4444
        }
    }
);

=attr binary_mode

Mostly intended for internal use, its builder coordinates all the side
effects of interacting with the binary: locating the executable,
finding an open port, setting up the environment, shelling out to
start the binary, and ensuring that the webdriver is listening on the
correct port.

If all of the above steps pass, it will return truthy after
instantiation. If any of them fail, it should return falsy and the
class should attempt normal L<Selenium::Remote::Driver> behavior.

=cut

has 'binary_mode' => (
    is => 'lazy',
    init_arg => undef,
    builder => 1,
    predicate => 1
);

has 'try_binary' => (
    is => 'lazy',
    default => sub { 0 },
    trigger => sub {
        my ($self) = @_;
        $self->binary_mode if $self->try_binary;
    }
);

=attr window_title

Intended for internal use: this will build us a unique title for the
background binary process of the Webdriver. Then, when we're cleaning
up, we know what the window title is that we're going to C<taskkill>.

=cut

has 'window_title' => (
    is => 'lazy',
    init_arg => undef,
    builder => sub {
        my ($self) = @_;
        my (undef, undef, $file) = File::Spec->splitpath( $self->binary );
        my $port = $self->port;

        return $file . ':' . $port;
    }
);

use constant IS_WIN => $^O eq 'MSWin32';

sub BUILDARGS {
    # There's a bit of finagling to do to since we can't ensure the
    # attribute instantiation order. To decide whether we're going into
    # binary mode, we need the remote_server_addr and port. But, they're
    # both lazy and only instantiated immediately before S:R:D's
    # remote_conn attribute. Once remote_conn is set, we can't change it,
    # so we need the following order:
    #
    #     parent: remote_server_addr, port
    #     role:   binary_mode (aka _build_binary_mode)
    #     parent: remote_conn
    #
    # Since we can't force an order, we introduced try_binary which gets
    # decided during BUILDARGS to tip us off as to whether we should try
    # binary mode or not.
    my ( $class, %args ) = @_;

    if ( ! exists $args{remote_server_addr} && ! exists $args{port} ) {
        $args{try_binary} = 1;

        # Windows may throw a fit about invalid pointers if we try to
        # connect to localhost instead of 127.1
        $args{remote_server_addr} = '127.0.0.1';
    }
    else {
        $args{try_binary} = 0;
        $args{binary_mode} = 0;
    }

    return { %args };
}

sub _build_binary_mode {
    my ($self) = @_;

    # We don't know what to do without a binary driver to start up
    return unless $self->binary;

    # Either the user asked for 4444, or we couldn't find an open port
    my $port = $self->port + 0;
    return if $port == 4444;

    if ($self->isa('Selenium::Firefox')) {
        my @args = ($port);

        if ($self->has_firefox_profile) {
            push @args, $self->firefox_profile;
        }

        setup_firefox_binary_env(@args);
    }

    my $command = $self->_construct_command;
    system($command);

    my $success = wait_until { probe_port($port) } timeout => 16;
    if ($success) {
        return 1;
    }
    else {
        die 'Unable to connect to the ' . $self->binary . ' binary on port ' . $port;
    }
}

sub shutdown_binary {
    my ($self) = @_;

    if ( $self->auto_close && defined $self->session_id ) {
        $self->quit();
    }

    if ($self->has_binary_mode && $self->binary_mode) {
        # Tell the binary itself to shutdown
        my $port = $self->port;
        my $ua = $self->ua;
        my $res = $ua->get('http://127.0.0.1:' . $port . '/wd/hub/shutdown');

        # Close the orphaned command windows on windows
        $self->shutdown_windows_binary;
    }
}

sub shutdown_windows_binary {
    my ($self) = @_;

    if (IS_WIN) {
        if ($self->isa('Selenium::Firefox')) {
            # FIXME: Blech, handle a race condition that kills the
            # driver before it's finished cleaning up its sessions. In
            # particular, when the perl process ends, it wants to
            # clean up the temp directory it created for the Firefox
            # profile. But, if the Firefox process is still running,
            # it will have a lock on the temp profile directory, and
            # perl will get upset. This "solution" is _very_ bad.
            sleep(2);
            # Firefox doesn't have a Driver/Session architecture - the
            # only thing running is Firefox itself, so there's no
            # other task to kill.
            return;
        }
        else {
            my $kill = 'taskkill /FI "WINDOWTITLE eq ' . $self->window_title . '" > nul 2>&1';
            system($kill);
        }
    }
}

# We want to do things before the DEMOLISH phase, as during DEMOLISH
# we apparently have no guarantee that anything is still around
before DEMOLISH => sub {
    my ($self) = @_;
    $self->shutdown_binary;
};

sub _construct_command {
    my ($self) = @_;
    my $executable = $self->binary;

    # Executable path names may have spaces
    $executable = '"' . $executable . '"';

    # The different binaries take different arguments for proper setup
    $executable .= $self->_binary_args;

    # Handle Windows vs Unix discrepancies for invoking shell commands
    my ($prefix, $suffix) = ($self->_cmd_prefix, $self->_cmd_suffix);
    return join(' ', ($prefix, $executable, $suffix) );
}

sub _cmd_prefix {
    my ($self) = @_;

    if (IS_WIN) {
        my $prefix = 'start "' . $self->window_title . '"';

        # Let's minimize the command windows for the drivers that have
        # separate binaries - but let's not minimize the Firefox
        # window itself.
        if (! $self->isa('Selenium::Firefox')) {
            $prefix .= ' /MIN ';
        }
        return $prefix;
    }
    else {
        return '';
    }
}

sub _cmd_suffix {
    # TODO: allow users to specify whether & where they want driver
    # output to go

    if (IS_WIN) {
        return ' > /nul 2>&1 ';
    }
    else {
        return ' > /dev/null 2>&1 &';
    }
}

=head1 SEE ALSO

Selenium::Chrome
Selenium::Firefox
Selenium::PhantomJS

=cut

1;
