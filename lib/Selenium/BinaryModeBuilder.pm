package Selenium::BinaryModeBuilder;

# ABSTRACT: Role to teach a class how to enable its binary
use Selenium::Binary qw/start_binary_on_port/;
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

1;
