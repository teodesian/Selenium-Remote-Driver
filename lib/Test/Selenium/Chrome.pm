package Test::Selenium::Chrome;

use Moo;
extends 'Selenium::Chrome', 'Test::Selenium::Remote::Driver';

has 'webelement_class' => (
    is      => 'rw',
    default => sub { 'Test::Selenium::Remote::WebElement' },
);

1;

__END__

=head1 NAME

Test::Selenium::Chrome

=head1 SYNOPSIS

    my $test_driver = Test::Selenium::Chrome->new;
    $test_driver->get_ok('https://duckduckgo.com', "Chrome can load page");
    $test_driver->quit();

=head1 DESCRIPTION

A subclass of L<Selenium::Chrome> which provides useful testing functions.  Please see L<Selenium::Chrome> and L<Test::Selenium::Remote::Driver> for usage information.

