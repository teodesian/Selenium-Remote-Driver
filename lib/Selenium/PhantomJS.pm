package Selenium::PhantomJS;

# ABSTRACT: A convenience package for creating a PhantomJS instance
use Moo;
extends 'Selenium::Remote::Driver';

=head1 SYNOPSIS

    my $driver = Selenium::PhantomJS->new;

=cut

has '+browser_name' => (
    is => 'ro',
    default => sub { 'phantomjs' }
);

1;
