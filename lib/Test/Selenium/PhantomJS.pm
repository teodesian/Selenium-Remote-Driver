package Test::Selenium::PhantomJS;

use Moo;
extends 'Selenium::PhantomJS', 'Test::Selenium::Remote::Driver';

1;

__END__

=head1 NAME

Test::Selenium::PhantomJS

=head1 SYNOPSIS

    my $test_driver = Test::Selenium::PhantomJS->new;
    $test_driver->get_ok('https://duckduckgo.com', "PhantomJS can load page");
	$test_driver->quit();

=head1 DESCRITION

A subclass of L<Selenium::PhantomJS> which provides useful testing functions.  Please see L<Selenium::PhantomJS> and L<Test::Selenium::Remote::Driver> for usage information.


