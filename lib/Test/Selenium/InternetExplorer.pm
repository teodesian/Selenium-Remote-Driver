package Test::Selenium::InternetExplorer;

use Moo;
extends 'Selenium::InternetExplorer', 'Test::Selenium::Remote::Driver';

has 'webelement_class' => (
    is      => 'rw',
    default => sub { 'Test::Selenium::Remote::WebElement' },
);

1;

__END__

=head1 NAME

Test::Selenium::InternetExplorer - Test using Selenium::InternetExplorer

=head1 SYNOPSIS

    my $test_driver = Test::Selenium::InternetExplorer->new;
    $test_driver->get_ok('https://duckduckgo.com', "InternetExplorer can load page");
    $test_driver->quit();

=head1 DESCRIPTION

A subclass of L<Selenium::InternetExplorer> which provides useful testing functions.  Please see L<Selenium::InternetExplorer> and L<Test::Selenium::Remote::Driver> for usage information.


