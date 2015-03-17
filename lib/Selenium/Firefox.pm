package Selenium::Firefox;

# ABSTRACT: A convenience package for creating a Firefox instance
use Selenium::Binary qw/_find_open_port_above _probe_port/;
use Selenium::Firefox::Binary qw/firefox_path/;
use Selenium::Firefox::Profile;
use Selenium::Waiter qw/wait_until/;
use Moo;
use namespace::clean;
extends 'Selenium::Remote::Driver';

=head1 SYNOPSIS

my $driver = Selenium::Firefox->new;

=cut

use constant FIREFOX_PORT => 9090;

has '+browser_name' => (
    is => 'ro',
    default => sub { 'firefox' }
);

# By shadowing the parent's port, we can set it in _build_binary_mode properly
has '+port' => (
    is => 'lazy',
    default => sub { 4444 }
);

has '+firefox_profile' => (
    is => 'ro',
    lazy => 1,
    coerce => sub {
        my ($profile) = @_;
        die unless $profile->isa('Selenium::Firefox::Profile');
        my $port = _find_open_port_above(FIREFOX_PORT);
        $profile->add_webdriver($port);

        return $profile;
    },
    default => sub { Selenium::Firefox::Profile->new }
);

has 'binary_mode' => (
    is => 'ro',
    init_arg => undef,
    builder => sub {
        my ($self) = @_;

        my $profile = Selenium::Firefox::Profile->new;

        my $port = _find_open_port_above(FIREFOX_PORT);
        $profile->add_webdriver($port);

        $ENV{'XRE_PROFILE_PATH'} = $profile->_layout_on_disk;
        $ENV{'MOZ_NO_REMOTE'} = '1'; # able to launch multiple instances
        $ENV{'MOZ_CRASHREPORTER_DISABLE'} = '1'; # disable breakpad
        $ENV{'NO_EM_RESTART'} = '1'; # prevent the binary from detaching from the console.log

        my $binary = firefox_path();
        system( $binary . ' -no-remote > /dev/null 2>&1 & ');

        my $success = wait_until { _probe_port($port) } timeout => 10;
        if ($success) {
            $self->port($port);
            return 1
        }
        else {
            return 0;
        }
    }
);

1;
