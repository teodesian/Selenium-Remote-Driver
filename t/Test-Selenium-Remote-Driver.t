#!/usr/bin/env perl
use Test::Tester;
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use Test::Selenium::Remote::Driver;
use Selenium::Remote::WebElement;
use Carp;

my $successful_driver = Test::Selenium::Remote::Driver->new( testing => 1 );
$successful_driver = Test::MockObject::Extends->new($successful_driver);

my $element = Test::Selenium::Remote::WebElement->new(
    id     => '1342835311100',
    parent => $successful_driver,
);


# find_element_ok
{
    $successful_driver->mock( 'find_element', sub {$element} );
    check_tests(
        sub {
            my $rc = $successful_driver->find_element_ok( 'q',
                'find_element_ok works' );
            is( $rc, 1, 'returns true' );
        },
        [   {   ok   => 1,
                name => "find_element_ok works",
                diag => "",
            },
            {   ok   => 1,
                name => "returns true",
                diag => "",
            },
        ]
    );

    $successful_driver->mock( 'find_element', sub {0} );
    check_tests(
        sub {
            my $rc = $successful_driver->find_element_ok( 'q',
                'find_element_ok works, falsey test' );
            is( $rc, 0, 'returns false' );
        },
        [   {   ok   => 0,
                name => "find_element_ok works, falsey test",
                diag => "",
            },
            {   ok   => 1,
                name => "returns false",
                diag => "",
            },
        ]
    );
}

# find_no_element_ok
{
    $successful_driver->mock( 'find_element', sub { die $_[1] } );
    check_tests(
        sub {
            my $rc = $successful_driver->find_no_element_ok( 'BOOM',
                'find_no_element_ok works, expecting to find nothing.' );
            is( $rc, 1, 'returns true' );
        },
        [   {   ok   => 1,
                name => "find_no_element_ok works, expecting to find nothing.",
                diag => "",
            },
            {   ok   => 1,
                name => "returns true",
                diag => "",
            },
        ]
    );

    $successful_driver->mock( 'find_element', sub {$element} );
    check_tests(
        sub {
            my $rc =
              $successful_driver->find_no_element_ok( 'q',
                'find_no_element_ok works, expecting a false value if a element exists'
              );
            is( $rc, 0, 'returns false' );
        },
        [   {   ok => 0,
                name =>
                  "find_no_element_ok works, expecting a false value if a element exists",
                diag => "",
            },
            {   ok   => 1,
                name => "returns false",
                diag => "",
            },
        ]
    );


}


done_testing();
