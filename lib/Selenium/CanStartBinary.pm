package Selenium::CanStartBinary;

# ABSTRACT: Teach a WebDriver how to start its own binary aka no JRE!
use File::Which qw/which/;
use IO::Socket::INET;
use Selenium::Waiter qw/wait_until/;
use Selenium::Firefox::Binary qw/firefox_path setup_firefox_binary_env/;
use Selenium::Firefox::Profile;
use Moo::Role;

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

sub BUILDARGS {
    my ( $class, %args ) = @_;

    if ( ! exists $args{remote_server_addr} && ! exists $args{port} ) {
        $args{try_binary} = 1;

        # Windows may throw a fit about invalid pointers if we try to
        # connect to localhost instead of 127.1
        $args{remote_server_addr} = '127.0.0.1';

    }

    return { %args };
}

sub _build_binary_mode {
    my ($self) = @_;

    my $port = $self->start_binary_on_port(
        $self->binary_name,
        $self->binary_port
    );
    $self->port($port);
    return 1;
}

sub probe_port {
    my ($port) = @_;

    return IO::Socket::INET->new(
        PeerAddr => '127.0.0.1',
        PeerPort => $port,
        Timeout => 3
    );
}

sub start_binary_on_port {
    my ($self, $process, $port) = @_;

    my $executable = $self->_find_executable($process);
    $port = _find_open_port_above($port);
    if ($process eq 'firefox') {
        setup_firefox_binary_env($port);
    }
    my $command = _construct_command($executable, $port);

    system($command);
    my $success = wait_until { probe_port($port) } timeout => 10;
    if ($success) {
        return $port;
    }
    else {
        die 'Unable to connect to the ' . $executable . ' binary on port ' . $port;
    }
}

sub shutdown_binary {
    my ($self) = @_;

    if ($self->has_binary_mode && $self->binary_mode) {
        my $port = $self->port;
        my $ua = $self->ua;

        $ua->get('127.0.0.1:' . $port . '/wd/hub/shutdown');
    }
}

sub _find_executable {
    my ($self, $binary) = @_;

    if ($self->has_binary_path) {
        if (-x $self->binary_path) {
            return $self->binary_path;
        }
        else {
            die 'The binary at "' . $self->binary_path . '" is not executable. Fix the path or chmod +x it as needed.';
        }
    }

    if ($binary eq 'firefox') {
        return firefox_path();
    }
    else {
        my $executable = which($binary);

        if (not defined $executable) {
            warn qq(Unable to find the $binary binary in your \$PATH. We'll try falling back to standard Remote Driver);
        }
        else {
            return $executable;
        }
    }
}

sub _construct_command {
    my ($executable, $port) = @_;

    my %args;
    if ($executable =~ /chromedriver(\.exe)?$/i) {
        %args = (
            port => $port,
            'url-base' => 'wd/hub'
        );
    }
    elsif ($executable =~ /phantomjs(\.exe)?$/i) {
        %args = (
            webdriver => '127.0.0.1:' . $port
        );
    }
    elsif ($executable =~ /firefox/i) {
        $executable .= ' -no-remote ';
    }

    my @args = map { '--' . $_ . '=' . $args{$_} } keys %args;

    # Handle Windows vs Unix discrepancies for invoking shell commands
    my ($prefix, $suffix) = (_command_prefix(), _command_suffix());
    return join(' ', ($prefix, $executable, @args, $suffix) );
}

sub _command_prefix {
    if ($^O eq 'MSWin32') {
        return 'start /MAX '
    }
    else {
        return '';
    }
}

sub _command_suffix {
    if ($^O eq 'MSWin32') {
        return ' > /nul 2>&1 ';
    }
    else {
        # TODO: allow users to specify whether & where they want
        # driver output to go
        return ' > /dev/null 2>&1 &';
    }
}

sub _find_open_port_above {
    my ($port) = @_;

    my $free_port = wait_until {
        if ( probe_port($port) ) {
            $port++;
            return 0;
        }
        else {
            return $port;
        }
    };

    return $free_port;
}

1;
