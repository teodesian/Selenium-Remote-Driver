#!/usr/bin/env perl
use Test::Tester;
use Test::More;
use Test::Exception;
use Test::Selenium::Remote::Driver;
use Selenium::Remote::WebElement;
use Carp;

my $spec = {
    findElement => sub {
        my $searched_item = shift;
        return { status => 'OK', return => { ELEMENT => '123456' } }
          if ( $searched_item->{value} eq 'q' );
        return { status => 'NOK', return => 0, error => 'element not found' };
    },
    getPageSource => sub { return 'this output matches regex'},
};

my $successful_driver = Test::Selenium::Remote::Driver->new( testing => 1, spec => $spec);
$successful_driver->find_element_ok('q','find_element_ok works');
dies_ok { $successful_driver->find_element_ok('notq') } 'find_element_ok dies if element not found';
$successful_driver->find_no_element_ok('notq','find_no_element_ok works');
$successful_driver->content_like( qr/matches/, 'content_like works');
$successful_driver->content_unlike( qr/nomatch/, 'content_unlike works');

done_testing();
