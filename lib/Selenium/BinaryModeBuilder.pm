package Selenium::BinaryModeBuilder;

# ABSTRACT: Teach a WebDriver how to start its own binary aka no JRE!
use File::Which qw/which/;
use IO::Socket::INET;
use Selenium::Waiter qw/wait_until/;
use Selenium::Firefox::Binary qw/firefox_path setup_firefox_binary_env/;
use Selenium::Firefox::Profile;
use Try::Tiny;
use Moo::Role;

has 'binary_mode' => (
    is => 'ro',
    init_arg => undef,
    builder => 1
);

sub _build_binary_mode {
    my ($self) = @_;

    if (! $self->has_remote_server_addr && ! $self->has_port) {
        try {
            my $port = start_binary_on_port($self->binary_name, $self->binary_port);
            $self->port($port);
            return 1;
        }
        catch {
            warn $_;
            return 0;
        }
    }
    else {
        return 0;
    }
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
    my ($process, $port) = @_;

    my $executable = _find_executable($process);
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

sub _find_executable {
    my ($binary) = @_;

    if ($binary eq 'firefox') {
        return firefox_path();
    }
    else {
        my $executable = which($binary);

        if (not defined $executable) {
            die qq(Unable to find the $binary binary in your \$PATH. We'll try falling back to standard Remote Driver);
        }
        else {
            return $executable;
        }
    }
}

sub _construct_command {
    my ($executable, $port) = @_;

    my %args;
    if ($executable =~ /chromedriver$/) {
        %args = (
            port => $port,
            'base-url' => 'wd/hub'
        );
    }
    elsif ($executable =~ /phantomjs$/) {
        %args = (
            webdriver => '127.0.0.1:' . $port
        );
    }
    elsif ($executable =~ /firefox/i) {
        $executable .= ' -no-remote ';
    }

    my @args = map { '--' . $_ . '=' . $args{$_} } keys %args;

    return join(' ', ($executable, @args, '> /dev/null 2>&1 &') );
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
