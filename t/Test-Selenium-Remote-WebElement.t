use Test::More;
use Selenium::Remote::Mock::Commands;
use Selenium::Remote::Mock::RemoteConnection;
use Test::Selenium::Remote::Driver;
use Test::Selenium::Remote::WebElement;

# Start off by faking a bunch of Selenium::Remote::WebElement calls succeeding
my $mock_commands = Selenium::Remote::Mock::Commands->new;
my $spec = { };

foreach my $k (
    qw/clearElement clickElement submitElement sendKeysToElement isElementSelected isElementEnabled isElementDisplayed/
  ) {
      $spec->{$k} = sub { return { status => 'OK', return => 1 }};
}

$spec->{getElementTagName} = sub { return { status => 'OK', return => 'iframe' }};
$spec->{getElementValue} = sub { return { status => 'OK', return => 'my_value' }};
$spec->{getElementText} = sub { return { status => 'OK', return => "my_text\nis fantastic" }};
$spec->{getElementAttribute}  = sub { my @args = @_; my $name = $args[0]->{name};  return { status => 'OK', return => "my_$name" }};

my $driver = Test::Selenium::Remote::Driver->new(
    remote_conn => Selenium::Remote::Mock::RemoteConnection->new( spec => $spec, mock_cmds => $mock_commands ),
    commands => $mock_commands,
);


my $successful_element = Test::Selenium::Remote::WebElement->new(
    id => 'placeholder_id',
    driver => $driver
);
$successful_element->clear_ok;
$successful_element->click_ok;
$successful_element->submit_ok;
$successful_element->is_selected_ok;
$successful_element->is_enabled_ok;
$successful_element->is_displayed_ok;
$successful_element->send_keys_ok('Hello World');
$successful_element->tag_name_is( 'iframe', 'we got an iframe tag' );
$successful_element->tag_name_isnt( 'BOOM', 'tag name is not boom' );
$successful_element->tag_name_unlike( qr/BOOM/, "tag_name doesn't match BOOM" );
$successful_element->value_is( 'my_value', 'Got an my_value value?' );
$successful_element->value_isnt( 'BOOM', 'Not BOOM.' );
$successful_element->value_like( qr/val/, 'Matches my_value value?' );
$successful_element->value_unlike( qr/BOOM/, "value doesn't match BOOM" );
$successful_element->text_is( "my_text\nis fantastic", 'Got an my_text value?' );
$successful_element->text_isnt( 'BOOM', 'Not BOOM.' );
$successful_element->text_like( qr/tex/, 'Matches my_text value?' );
$successful_element->text_unlike( qr/BOOM/, "text doesn't match BOOM" );
$successful_element->attribute_is( 'foo', 'my_foo', 'attribute_is matched' );
$successful_element->attribute_isnt( 'foo', 'not_foo', 'attribute_is not_foo' );
$successful_element->attribute_like( 'foo',qr/foo/, 'Matches my_attribute' );
$successful_element->attribute_unlike( 'bar',qr/foo/, "Attribute does not match foo" );



#  css_attribute_is($attr_name,$match_str,$test_name);
#  css_attribute_isnt($attr_name,$match_str,$test_name);
#  css_attribute_like($attr_name,$match_re,$test_name);
#  css_attribute_unlike($attr_name,$match_re,$test_name);

done_testing();
