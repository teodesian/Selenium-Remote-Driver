
use Test::Tester;
use Test::More;
use Test::MockObject::Extends;

use Test::Selenium::Remote::WebElement;

# Start off by faking a bunch of Selenium::Remote::WebElement calls succeeding
my $successful_element = Test::Selenium::Remote::WebElement->new;
$successful_element = Test::MockObject::Extends->new($successful_element);

$successful_element->set_true(
    qw/
      clear
      click
      submit
      is_selected
      is_enabled
      is_displayed
      send_keys
      /
);

$successful_element->mock( 'get_tag_name', sub {'iframe'} );
$successful_element->mock( 'get_value',    sub {'my_value'} );
$successful_element->mock( 'get_text',     sub {"my_text\nis fantastic"} );

# Given input 'foo' to 'get_attribute', return 'my_foo';
$successful_element->mock( 'get_attribute', sub { 'my_' . $_[1] } );

check_test(
  sub { $successful_element->clear_ok },
  {
    ok => 1,
    name => "clear",
    diag => "",
  }
);

check_test(
  sub { $successful_element->clear_ok('test_name') },
  {
    ok => 1,
    name => "test_name",
    diag => "",
  }
);

check_test(
  sub { $successful_element->click_ok },
  {
    ok => 1,
    name => "click",
    diag => "",
  }
);

check_test(
  sub { $successful_element->submit_ok },
  {
    ok => 1,
    name => "submit",
    diag => "",
  }
);

check_test(
  sub { $successful_element->is_selected_ok },
  {
    ok => 1,
    name => "is_selected",
    diag => "",
  }
);

check_test(
  sub { $successful_element->is_enabled_ok },
  {
    ok => 1,
    name => "is_enabled",
    diag => "",
  }
);

check_test(
  sub { $successful_element->is_displayed_ok },
  {
    ok => 1,
    name => "is_displayed",
    diag => "",
  }
);

check_test(
  sub { $successful_element->send_keys_ok('Hello World', 'I sent keys') },
  {
    ok => 1,
    name => "I sent keys",
    diag => "",
  }
);

# tag_name_*
{
    check_test(
        sub {
            $successful_element->tag_name_is( 'iframe', 'Got an iframe tag?' );
        },
        {   ok   => 1,
            name => "Got an iframe tag?",
            diag => "",
        }
    );

    check_test(
        sub { $successful_element->tag_name_isnt( 'BOOM', 'Not BOOM.' ) },
        {   ok   => 1,
            name => "Not BOOM.",
            diag => "",
        }
    );

    check_test(
        sub {
            $successful_element->tag_name_like( qr/frame/,
                'Matches iframe tag?' );
        },
        {   ok   => 1,
            name => "Matches iframe tag?",
            diag => "",
        }
    );

    check_test(
        sub {
            $successful_element->tag_name_unlike( qr/BOOM/,
                "tag_name doesn't match BOOM" );
        },
        {   ok   => 1,
            name => "tag_name doesn't match BOOM",
            diag => "",
        }
    );
}

# value_*
{
    check_test(
        sub {
            $successful_element->value_is( 'my_value',
                'Got an my_value value?' );
        },
        {   ok   => 1,
            name => "Got an my_value value?",
            diag => "",
        }
    );

    check_test(
        sub { $successful_element->value_isnt( 'BOOM', 'Not BOOM.' ) },
        {   ok   => 1,
            name => "Not BOOM.",
            diag => "",
        }
    );

    check_test(
        sub {
            $successful_element->value_like( qr/val/,
                'Matches my_value value?' );
        },
        {   ok   => 1,
            name => "Matches my_value value?",
            diag => "",
        }
    );

    check_test(
        sub {
            $successful_element->value_unlike( qr/BOOM/,
                "value doesn't match BOOM" );
        },
        {   ok   => 1,
            name => "value doesn't match BOOM",
            diag => "",
        }
    );
}

# text_*
{
    check_test(
        sub {
            $successful_element->text_is( "my_text\nis fantastic",
                'Got an my_text value?' );
        },
        {   ok   => 1,
            name => "Got an my_text value?",
            diag => "",
        }
    );

    check_test(
        sub { $successful_element->text_isnt( 'BOOM', 'Not BOOM.' ) },
        {   ok   => 1,
            name => "Not BOOM.",
            diag => "",
        }
    );

    check_test(
        sub {
            $successful_element->text_like( qr/tex/,
                'Matches my_text value?' );
        },
        {   ok   => 1,
            name => "Matches my_text value?",
            diag => "",
        }
    );

    check_test(
        sub {
            $successful_element->text_unlike( qr/BOOM/,
                "text doesn't match BOOM" );
        },
        {   ok   => 1,
            name => "text doesn't match BOOM",
            diag => "",
        }
    );

}
{ 
    check_test(
        sub {
            $successful_element->attribute_is( 'foo', 'my_foo',
                'attribute_is matched' );
        },
        {   ok   => 1,
            name => "attribute_is matched",
            diag => "",
        }
    );

    check_test(
        sub {
            $successful_element->attribute_isnt( 'foo', 'not_foo',
                'attribute_is not_foo' );
        },
        {   ok   => 1,
            name => "attribute_is not_foo",
            diag => "",
        }
    );

    check_test(
        sub {
            $successful_element->attribute_like( 'foo',qr/foo/,
                'Matches my_attribute' );
        },
        {   ok   => 1,
            name => "Matches my_attribute",
            diag => "",
        }
    );

    check_test(
        sub {
            $successful_element->attribute_unlike( 'bar',qr/foo/,
                "Attribute does not match foo" );
        },
        {   ok   => 1,
            name => "Attribute does not match foo",
            diag => "",
        }
    );
}



#  css_attribute_is($attr_name,$match_str,$test_name);
#  css_attribute_isnt($attr_name,$match_str,$test_name);
#  css_attribute_like($attr_name,$match_re,$test_name);
#  css_attribute_unlike($attr_name,$match_re,$test_name);


done_testing();
