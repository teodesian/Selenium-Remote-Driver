#!/usr/bin/env perl
use Test::More;
use Test::Fatal;
use Test::Selenium::Remote::Driver;
use Test::Builder::Tester;
use Selenium::Remote::WebElement;
use Selenium::Remote::Mock::Commands;
use Selenium::Remote::Mock::RemoteConnection;
use Carp;

my $find_element = sub {
    my ( undef, $searched_item ) = @_;
    if ( $searched_item->{value} eq 'q' ) {
        return { status => 'OK', return => { ELEMENT => '123456' } };
    }
    if (   $searched_item->{value} eq 'p'
        && $searched_item->{using} eq 'class name' )
    {
        return { status => 'OK', return => { ELEMENT => '123457' } };
    }
    if ( $searched_item->{value} eq '//body' && $searched_item->{using} eq 'xpath') {
        return { status => 'OK', return => { ELEMENT => '123458' } };
    }
    return { status => 'NOK', return => 0, error => 'element not found' };
};
my $find_child_element = sub {
    my ( $session_object, $searched_item ) = @_;
    my $elem_id = $session_object->{id};
    if ( $elem_id == 1 && $searched_item->{value} eq 'p' ) {
        if ( $searched_item->{using} eq 'class name' ) {
            return { status => 'OK', return => { ELEMENT => '11223344' } };
        }

        if ( $searched_item->{using} eq 'xpath' ) {
            return { status => 'OK',
                return => [ { ELEMENT => '112' }, { ELEMENT => '113' } ] };
        }
    }

    return {
        status => 'NOK', return => 0,
        error  => 'child element not found'
    };
};

my $find_elements = sub {
    my ( undef, $searched_expr ) = @_;
    if (   $searched_expr->{value} eq 'abc'
        && $searched_expr->{using} eq 'xpath' )
    {
        return { status => 'OK',
            return => [ { ELEMENT => '123456' }, { ELEMENT => '12341234' } ] };
    }
};

my $send_keys = sub {
    my ( $session_object, $val ) = @_;
    my $keys = shift @{ $val->{value} };
    return { status => 'OK', return => 1 } if ( $keys =~ /abc|def/ );
    return { status => 'NOK', return => 0, error => 'cannot send keys' };
};

my $get_text = sub {
    my ($session_object) =@_;
    return 'abc' if ($session_object->{id} eq '123456');
    return 'def' if ($session_object->{id} eq '123457');
    return 'this output matches' if ($session_object->{id} eq '123458');
    return;
};

my $get_attr = sub {
    my ($session_object) = @_;
    return 'foo';
};

my $spec = {
    findElement => $find_element,
    findChildElement => $find_child_element,
    getPageSource => sub { return 'this output matches regex'},
    findElements => $find_elements,
    findChildElements => $find_child_element,
    getElementText => $get_text,
    sendKeysToElement => $send_keys,
    getElementAttribute => $get_attr,
    clickElement => sub { return { status => 'OK', return => 1 }; },
    clearElement =>  sub { return { status => 'OK', return => 1 }; },
    isElementDisplayed =>  sub { return { status => 'OK', return => 1 }; },
    isElementEnabled =>  sub { return { status => 'OK', return => 1 }; },
};

my $mock_commands = Selenium::Remote::Mock::Commands->new;

my $successful_driver =
  Test::Selenium::Remote::Driver->new(
    remote_conn => Selenium::Remote::Mock::RemoteConnection->new( spec => $spec, mock_cmds => $mock_commands ),
    commands => $mock_commands,
);
$successful_driver->error_handler(sub { my ($self,$msg) = @_; croak "Got message: $msg";}); 

# find element ok tests
$successful_driver->find_element_ok('q','find_element_ok works');
$successful_driver->default_finder('class');
$successful_driver->find_element_ok('p','find_element_ok with a locator works');
$successful_driver->default_finder('xpath');
ok( exception { $successful_driver->find_element_ok('notq') }, 'find_element_ok dies if element not found' );
$successful_driver->find_elements_ok('abc','find_elements_ok works');

# find child element ok tests
$successful_driver->find_child_elements_ok({id => 1},'p','find_child_elements_ok works');
$successful_driver->find_child_element_ok({id => 1},'p','class','find_child_element_ok with a locator works');
ok( exception { $successful_driver->find_child_element_ok({id => 1200}) }, 'find_child_element_ok dies if the element is not found' );

# find no element ok test

$successful_driver->find_no_element_ok('notq','xpath','find_no_element_ok works');
ok(exception { $successful_driver->find_no_element_ok('q','xpath','find_no_element_ok works') }, 'find no element dies when an element is found');

# body and content function family
$successful_driver->content_like( qr/matches/, 'content_like works');
$successful_driver->content_unlike( qr/nomatch/, 'content_unlike works');
$successful_driver->content_contains( 'matches', 'content_contains works');
$successful_driver->content_lacks( 'nomatch', 'content_lacks works');
$successful_driver->body_text_contains( ['match','output'], 'body_text_contains works');
$successful_driver->body_text_lacks( 'nomatch', 'body_text_lacks works');
$successful_driver->body_text_like( qr/this/, 'body_text_like works');
$successful_driver->body_text_unlike( qr/notthis/, 'body_text_unlike works');

$successful_driver->type_element_ok('q','abc');
$successful_driver->default_finder('class');
$successful_driver->type_element_ok('p','def','type_element_ok works with a locator');

$successful_driver->element_text_is('q','abc','element has a correct text');
$successful_driver->element_text_is('p','class','def');

$successful_driver->element_value_is('p','class','foo');
$successful_driver->click_element_ok('p','class','click_element_ok works');
$successful_driver->clear_element_ok('q','element is cleared ok');
$successful_driver->is_element_enabled_ok('p','class','element is enabled');
$successful_driver->is_element_displayed_ok('q','element is displayed');

test_out('not ok 1 - Content is ok'."\n".'ok 2 - Error callback triggered');
like(exception { $successful_driver->content_like( qr/nomatch/, 'Content is ok') },qr/^Got message/,'Error callback triggered');
test_test(title => "Error handler works with 'content_like'",skip_err => 1);

test_out('not ok 1 - Content is ok'."\n".'ok 2 - Error callback triggered');
like(exception { $successful_driver->content_unlike(qr/matches/, 'Content is ok') },qr/^Got message/,'Error callback triggered');
test_test(title => "Error handler works with 'content_unlike'",skip_err => 1);

test_out('not ok 1 - Content is ok'."\n".'ok 2 - Error callback triggered');
like(exception { $successful_driver->content_contains('blah', 'Content is ok') },qr/^Got message/,'Error callback triggered');
test_test(title => "Error handler works with 'content_contains'",skip_err => 1);

test_out('not ok 1 - Content is ok'."\n".'ok 2 - Error callback triggered');
like(exception { $successful_driver->content_lacks('matches', 'Content is ok') },qr/^Got message/,'Error callback triggered');
test_test(title => "Error handler works with 'content_lacks'",skip_err => 1);

test_out('not ok 1 - Body is ok'."\n".'ok 2 - Error callback triggered');
like(exception { $successful_driver->body_text_like( qr/nomatch/, 'Body is ok') },qr/^Got message/,'Error callback triggered');
test_test(title => "Error handler works with 'body_text_like'",skip_err => 1);

test_out('not ok 1 - Body is ok'."\n".'ok 2 - Error callback triggered');
like(exception { $successful_driver->body_text_unlike(qr/matches/, 'Body is ok') },qr/^Got message/,'Error callback triggered');
test_test(title => "Error handler works with 'body_text_unlike'",skip_err => 1);

test_out('not ok 1 - Text contains "nomatch"'."\n".'ok 2 - Error callback triggered');
like(exception { $successful_driver->body_text_contains('nomatch') },qr/^Got message/,'Error callback triggered');
test_test(title => "Error handler works with 'body_text_contains'",skip_err => 1);

test_out('not ok 1 - Text lacks "match"'."\n".'ok 2 - Error callback triggered');
like(exception { $successful_driver->body_text_lacks(['match','bar']) },qr/^Got message/,'Error callback triggered');
test_test(title => "Error handler works with 'body_text_lacks'",skip_err => 1);


done_testing();
