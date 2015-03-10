package Selenium::PhantomJS;

# ABSTRACT: A convenience package for creating a PhantomJS instance
use Selenium::Binary qw/start_binary_on_port/;
use Moo;
use namespace::clean;
extends 'Selenium::Remote::Driver';

=head1 SYNOPSIS

    my $driver = Selenium::PhantomJS->new;

=cut

use constant PHANTOMJS_PORT => 8910;

has '+browser_name' => (
    is => 'ro',
    default => sub { 'phantomjs' }
);

# By shadowing the parent's port function, we can set the port in
# _build_binary_mode's builder
has '+port' => (
    is => 'lazy'
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
            my $port = start_binary_on_port('phantomjs', PHANTOMJS_PORT);
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

sub DEMOLISH {
    my ($self) = @_;

    if ($self->binary_mode) {

        my $port = $self->port;
        my $ua = LWP::UserAgent->new;

        $ua->get('127.0.0.1:' . $port . '/wd/hub/shutdown');
    }
}

1;
