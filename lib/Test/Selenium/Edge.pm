package Test::Selenium::Edge;

use Moo;
extends 'Selenium::Edge', 'Test::Selenium::Remote::Driver';

has 'webelement_class' => (
    is      => 'rw',
    default => sub { 'Test::Selenium::Remote::WebElement' },
);

1;

__END__

=head1 NAME

Test::Selenium::Edge

=head1 SYNOPSIS

    my $test_driver = Test::Selenium::Edge->new;
    $test_driver->get_ok('https://duckduckgo.com', "MS Edge can load page");
    $test_driver->quit();

=head1 DESCRIPTION

A subclass of L<Selenium::Edge> which provides useful testing functions.  Please see L<Selenium::Edge> and L<Test::Selenium::Remote::Driver> for usage information.

