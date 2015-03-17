package Selenium::Firefox;

# ABSTRACT: A convenience package for creating a Firefox instance
use Selenium::Binary qw/start_binary_on_port/;
use Try::Tiny;
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
    builder => 1
);

sub _build_binary_mode {
    my ($self) = @_;

    if (! $self->has_remote_server_addr && ! $self->has_port) {
        try {
            my $port = start_binary_on_port('firefox', FIREFOX_PORT);
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


1;
