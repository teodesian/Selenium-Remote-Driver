#!/usr/bin/env perl
use Test::Tester;
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use Test::Selenium::Remote::Driver;
use Selenium::Remote::WebElement;

# Temporarily override the 'new()' in the parent class, so that it doesn't try to make network connections.
sub Selenium::Remote::Driver::new {
    my ( $class, %args ) = @_;

    my $self = {
        remote_server_addr => delete $args{remote_server_addr}        || 'localhost',
        browser_name       => delete $args{browser_name}              || 'firefox',
        platform           => delete $args{platform}                  || 'ANY',
        port               => delete $args{port}                      || '4444',
        version            => delete $args{version}                   || '',
        webelement_class   => delete $args{webelement_class}          || "Selenium::Remote::WebElement",
        default_finder     => delete $args{default_finder}            || 'xpath',
        session_id         => undef,
        remote_conn        => undef,
        auto_close         => 1, # by default we will close remote session on DESTROY
        pid                => $$
    };
    bless $self, $class or die "Can't bless $class: $!";
}


# Start off by faking a bunch of Selenium::Remote::Driver calls succeeding
my $successful_driver = Test::Selenium::Remote::Driver->new;
$successful_driver =  Test::MockObject::Extends->new( $successful_driver );

my $element = Test::Selenium::Remote::WebElement->new(
    id => '1342835311100',
    parent => $successful_driver,
);


# find_element_ok
{
    $successful_driver->mock('find_element', sub { $element } );
    check_tests(
      sub {
          my $rc = $successful_driver->find_element_ok('q', 'find_element_ok works');
          is($rc,1,'returns true');
      },
      [
          {
            ok => 1,
            name => "find_element_ok works",
            diag => "",
          },
          {
            ok => 1,
            name => "returns true",
            diag => "",
          },
      ]
    );

    $successful_driver->mock('find_element', sub { 0 } );
    check_tests(
      sub {
          my $rc = $successful_driver->find_element_ok('q', 'find_element_ok works, falsey test');
          is($rc,0,'returns false');
      },
      [
          {
            ok => 0,
            name => "find_element_ok works, falsey test",
            diag => "",
          },
          {
            ok => 1,
            name => "returns false",
            diag => "",
          },
      ]
    );
}

# find_no_element_ok
{
    $successful_driver->mock('find_element', sub { die } );
    check_tests(
      sub {
          my $rc = $successful_driver->find_no_element_ok('BOOM', 'find_no_element_ok works, expecting to find nothing.');
          is($rc,1,'returns true');
      },
      [
          {
            ok => 1,
            name => "find_no_element_ok works, expecting to find nothing.",
            diag => "",
          },
          {
            ok => 1,
            name => "returns true",
            diag => "",
          },
      ]
    );

}



done_testing();
