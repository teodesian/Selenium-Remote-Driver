#!/usr/bin/env perl
use Test::More;
use Test::Exception;
use Test::Selenium::Remote::Driver;
use Selenium::Remote::WebElement;
use Selenium::Remote::Mock::Commands;
use Selenium::Remote::Mock::RemoteConnection;

my $spec = {
    findElement => sub {
        my (undef,$searched_item) = @_;
        return { status => 'OK', return => { ELEMENT => '123456' } }
          if ( $searched_item->{value} eq 'q' );
        return { status => 'NOK', return => 0, error => 'element not found' };
    },
    getPageSource => sub { return 'this output matches regex'},
    findElements => sub { 
        my (undef,$searched_expr) = @_;
        if ($searched_expr) { 
            return { status => 'OK', return => [ { ELEMENT => '123456' }, { ELEMENT => '12341234' } ] }
        }
    },
};
my $mock_commands = Selenium::Remote::Mock::Commands->new;

my $successful_driver =
  Test::Selenium::Remote::Driver->new(
    remote_conn => Selenium::Remote::Mock::RemoteConnection->new( spec => $spec, mock_cmds => $mock_commands ),
    commands => $mock_commands,
);
$successful_driver->find_element_ok('q','find_element_ok works');
dies_ok { $successful_driver->find_element_ok('notq') } 'find_element_ok dies if element not found';
$successful_driver->find_no_element_ok('notq','find_no_element_ok works');
$successful_driver->content_like( qr/matches/, 'content_like works');
$successful_driver->content_unlike( qr/nomatch/, 'content_unlike works');
$successful_driver->find_elements_ok('abc','find_elements_ok works');

done_testing();
