package Test::Selenium::Firefox;

use Moo;
extends 'Selenium::Firefox', 'Test::Selenium::Remote::Driver';

has 'webelement_class' => (
    is      => 'rw',
    default => sub { 'Test::Selenium::Remote::WebElement' },
);

1;

__END__

=head1 NAME

Test::Selenium::Firefox - Test using Test::Selenium

=head1 SYNOPSIS

    my $test_driver = Test::Selenium::Firefox->new;
    $test_driver->get_ok('https://duckduckgo.com', "Firefox can load page");
    $test_driver->quit();

=head1 DESCRIPTION

A subclass of L<Selenium::Firefox> which provides useful testing functions.  Please see L<Selenium::Firefox> and L<Test::Selenium::Remote::Driver> for usage information.

