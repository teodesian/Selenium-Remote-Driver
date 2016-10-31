package Test::Selenium::Remote::Driver;

# ABSTRACT: Useful testing subclass for Selenium::Remote::Driver

use Moo;
use Test::Selenium::Remote::WebElement;
use Test::LongString;
use IO::Socket;
use Sub::Install;
use Try::Tiny;

extends 'Selenium::Remote::Driver';

# move_mouse_to_location_ok # TODO # move_to_ok # TODO
has func_list => (
    is      => 'lazy',
    builder => sub {
        return [
            'alert_text_is',     'alert_text_isnt', 'alert_text_like',
            'alert_text_unlike', 'current_window_handle_is',
            'current_window_handle_isnt',   'current_window_handle_like',
            'current_window_handle_unlike', 'window_handles_is',
            'window_handles_isnt',          'window_handles_like',
            'window_handles_unlike', 'window_size_is', 'window_size_isnt',
            'window_size_like', 'window_size_unlike', 'window_position_is',
            'window_position_isnt', 'window_position_like',
            'window_position_unlike', 'current_url_is',     'current_url_isnt',
            'current_url_like',       'current_url_unlike', 'title_is',
            'title_isnt', 'title_like', 'title_unlike', 'active_element_is',
            'active_element_isnt',   'active_element_like',
            'active_element_unlike', 'send_keys_to_active_element_ok',
            'send_keys_to_alert_ok', 'send_keys_to_prompt_ok',
            'send_modifier_ok', 'accept_alert_ok', 'dismiss_alert_ok',
            'get_ok', 'go_back_ok', 'go_forward_ok', 'add_cookie_ok',
            'get_page_source_ok', 'find_element_ok', 'find_elements_ok',
            'find_child_element_ok', 'find_child_elements_ok',
            'find_no_element_ok',
            'compare_elements_ok', 'click_ok', 'double_click_ok',
            'body_like',
        ];
    },
);

sub has_args {
    my $self          = shift;
    my $fun_name      = shift;
    my $hash_fun_args = {
        'find_element'        => 2,
        'find_no_element'     => 2,
        'find_child_element'  => 3,
        'find_child_elements' => 3,
        'find_element'        => 2,
        'find_elements'       => 2,
        'compare_elements'    => 2,
        'get'                 => 1,
    };
    return ( $hash_fun_args->{$fun_name} // 0 );
}

with 'Test::Selenium::Remote::Role::DoesTesting';

has verbose => (
    is => 'rw',
);


sub BUILD {
    my $self = shift;
    foreach my $method_name ( @{ $self->func_list } ) {
        unless ( defined( __PACKAGE__->can($method_name) ) ) {
            my $sub = $self->_build_sub($method_name);
            Sub::Install::install_sub(
                {   code => $sub,
                    into => __PACKAGE__,
                    as   => $method_name
                }
            );
        }
    }
}

=head1 NAME

Test::Selenium::Remote::Driver

=head1 DESCRIPTION

A subclass of L<Selenium::Remote::Driver>.  which provides useful testing
functions.

This is an I<experimental> addition to the Selenium::Remote::Driver
distribution, and some interfaces may change.

=head1 Methods

=head2 new ( %opts )

This will create a new Test::Selenium::Remote::Driver object, which subclasses
L<Selenium::Remote::Driver>.  This subclass provides useful testing
functions.  It is modeled on L<Test::WWW::Selenium>.

Environment vars can be used to specify options to pass to
L<Selenium::Remote::Driver>. ENV vars are prefixed with C<TWD_>.
( After the old fork name, "Test::WebDriver" )

Set the Selenium server address with C<$TWD_HOST> and C<$TWD_PORT>.

Pick which browser is used using the  C<$TWD_BROWSER>, C<$TWD_VERSION>,
C<$TWD_PLATFORM>, C<$TWD_JAVASCRIPT>, C<$TWD_EXTRA_CAPABILITIES>.

See L<Selenium::Driver::Remote> for the meanings of these options.

=cut

sub BUILDARGS {
    my ( $class, %p ) = @_;

    for my $opt (
        qw/remote_server_addr port browser_name version platform
        javascript auto_close extra_capabilities/
      )
    {
        $p{$opt} //= $ENV{ 'TWD_' . uc($opt) };
    }
    $p{browser_name}       //= $ENV{TWD_BROWSER};                      # ykwim
    $p{remote_server_addr} //= $ENV{TWD_HOST};                         # ykwim
    $p{webelement_class}   //= 'Test::Selenium::Remote::WebElement';
    return \%p;
}

=head2 server_is_running( $host, $port )

Returns true if a Selenium server is running.  The host and port
parameters are optional, and default to C<localhost:4444>.

Environment vars C<TWD_HOST> and C<TWD_PORT> can also be used to
determine the server to check.

=cut

sub server_is_running {
    my $class_or_self = shift;
    my $host          = $ENV{TWD_HOST} || shift || 'localhost';
    my $port          = $ENV{TWD_PORT} || shift || 4444;

    return ( $host, $port )
      if IO::Socket::INET->new(
        PeerAddr => $host,
        PeerPort => $port,
      );
    return;

}

=head2 error_handler

As for L<Selenium::Remote::Driver>, this class also supports adding an
optional C<error_handler> attribute during instantiation :

    my $test_driver = Test::Selenium::Remote::Driver->new(
        error_handler => sub { print $_[1]; croak 'goodbye'; }
    );

Additionally, you can set and/or clear it at any time on an
already-instantiated driver:

    # later, change the error handler to something else
    $driver->error_handler( sub { print $_[1]; croak 'hello'; } );

    # stop handling errors manually and use the default S:R:D behavior
    # (we will croak about the exception)
    $driver->clear_error_handler;

Your error handler will receive two arguments,
The first argument is the C<$driver> object itself.
Due to some specificities of this class, the second argument passed to the
handler can be:

=over

=item the error message from the Webdriver

This is the case when the error message is raised by a WebDriver failure

=item "Failed to find ..."

This message is raised when the Webdriver call is successful but the failure
occurs on the test performed aftwerwards. This is the case for functions like
C<body_text_like>, C<body_text_unlike>, C<body_text_contains>, C<body_text_lacks>,
C<content_like>, C<content_unlike>, C<content_contains>, C<content_lacks>.

=back

If you set your own handler, you should not rely that much on the message returned.
You should also remember that you are entirely responsible for handling exceptions,
which means that should the error handler be called, it means that the test you are
doing has failed, so you should croak.

You should also call fail() in your handler, in case the function called raised a
webdriver error, because, as exceptions are not caught anymore when you specify a
handler, the function will not fail anymore, which translates to a 'ok' in your TAP
output if you do not handle it properly.


=head1 Testing Methods

The following testing methods are available. For
more documentation, see the related test methods in L<Selenium::Remote::Driver>
(And feel free to submit a patch to flesh out the documentation for these here).

    alert_text_is
    alert_text_isnt
    alert_text_like
    alert_text_unlike

    current_window_handle_is
    current_window_handle_isnt
    current_window_handle_like
    current_window_handle_unlike

    window_handles_is
    window_handles_isnt
    window_handles_like
    window_handles_unlike

    window_size_is
    window_size_isnt
    window_size_like
    window_size_unlike

    window_position_is
    window_position_isnt
    window_position_like
    window_position_unlike

    current_url_is
    current_url_isnt
    current_url_like
    current_url_unlike

    title_is
    title_isnt
    title_like
    title_unlike


    active_element_is
    active_element_isnt
    active_element_like
    active_element_unlike

    # Basically the same as 'content_like()', but content_like() supports multiple regex's.
    page_source_is
    page_source_isnt
    page_source_like
    page_source_unlike

    send_keys_to_active_element_ok
    send_keys_to_alert_ok
    send_keys_to_prompt_ok
    send_modifier_ok

    accept_alert_ok
    dismiss_alert_ok

    move_mouse_to_location_ok # TODO
    move_to_ok # TODO

    get_ok
    go_back_ok
    go_forward_ok
    add_cookie_ok
    get_page_source_ok

    find_element_ok($search_target)
    find_element_ok($search_target)

    find_elements_ok
    find_child_element_ok
    find_child_elements_ok

    compare_elements_ok

    click_ok
    double_click_ok

=cut


# function composing a find_element with locator with a webelement test

sub _find_element_with_action {
    my $self   = shift;
    my $method = shift;
    my ( $locator, $locator_strategy, $params, $desc ) = @_;

    # case 4 args
    if ($desc) {
        $self->croak('Invalid locator strategy')
          unless ( $self->FINDERS->{$locator_strategy} );
    }
    else {
        if ($params) {

            # means that we called it the 'old way' (no locator strategy)
            if ( !defined( $self->FINDERS->{$locator_strategy} ) ) {
                $desc   = $params;
                $params = $locator_strategy;
                $locator_strategy =
                  $self->_get_finder_key( $self->default_finder );
            }
        }
        else {
            # means it was called with no locator strategy and no desc
            if ($locator_strategy) {
                if ( !defined( $self->FINDERS->{$locator_strategy} ) ) {
                    $params = $locator_strategy;
                    $locator_strategy =
                      $self->_get_finder_key( $self->default_finder );
                }
            }
            else {
                $self->croak('Not enough arguments');
            }
        }
    }
    unless ($desc) {
        $desc = $method;
        $desc .= "'" . join( " ", ( $params // '' ) ) . "'";
    }
    return $self->find_element( $locator, $locator_strategy )
      ->$method( $params, $desc );
}


=head2 $twd->type_element_ok($search_target [,$locator], $keys, [, $desc ]);

   $twd->type_element_ok( $search_target [,$locator], $keys [, $desc ] );

Use L<Selenium::Remote::Driver/find_element> to resolve the C<$search_target>
to a web element and an optional locator, and then type C<$keys> into it, providing an optional test
label.


=cut

sub type_element_ok {
    my $self   = shift;
    my $method = 'send_keys_ok';
    return $self->_find_element_with_action( $method, @_ );
}


=head2 $twd->element_text_is($search_target[,$finder],$expected_text [,$desc]);

    $twd->element_text_is($search_target[,$finder],$expected_text [,$desc]);

=cut

sub element_text_is {
    my $self   = shift;
    my $method = 'text_is';
    return $self->_find_element_with_action( $method, @_ );
}

=head2 $twd->element_value_is($search_target[,$finder],$expected_value [,$desc]);

    $twd->element_value_is($search_target[,$finder],$expected_value [,$desc]);

=cut

sub element_value_is {
    my $self   = shift;
    my $method = 'value_is';
    return $self->_find_element_with_action( $method, @_ );
}

=head2 $twd->click_element_ok($search_target [,$finder ,$desc]);

    $twd->click_element_ok($search_target [,$finder ,$desc]);

Find an element and then click on it.

=cut

sub click_element_ok {
    my $self   = shift;
    my $method = 'click_ok';
    return $self->_find_element_with_action( $method, @_ );
}

=head2 $twd->clear_element_ok($search_target [,$finder ,$desc]);

    $twd->clear_element_ok($search_target [,$finder ,$desc]);

Find an element and then clear on it.

=cut

sub clear_element_ok {
    my $self   = shift;
    my $method = 'clear_ok';
    return $self->_find_element_with_action( $method, @_ );
}

=head2 $twd->is_element_displayed_ok($search_target [,$finder ,$desc]);

    $twd->is_element_displayed_ok($search_target [,$finder ,$desc]);

Find an element and check to confirm that it is displayed. (visible)

=cut

sub is_element_displayed_ok {
    my $self   = shift;
    my $method = 'is_displayed_ok';
    return $self->_find_element_with_action( $method, @_ );
}

=head2 $twd->is_element_enabled_ok($search_target [,$finder ,$desc]);

    $twd->is_element_enabled_ok($search_target [,$finder ,$desc]);

Find an element and check to confirm that it is enabled.

=cut

sub is_element_enabled_ok {
    my $self   = shift;
    my $method = 'is_enabled_ok';
    return $self->_find_element_with_action( $method, @_ );
}


=head2 $twd->find_element_ok($search_target [,$finder, $desc ]);

   $twd->find_element_ok( $search_target [,$finder, $desc ] );

Returns true if C<$search_target> is successfully found on the page. C<$search_target>
is passed to L<Selenium::Remote::Driver/find_element> using a finder or the C<default_finder>
if none passed.
See there for more details on the format for C<find_element_ok()>.

=cut


=head2 $twd->find_no_element_ok($search_target [,$finder, $desc ]);

   $twd->find_no_element_ok( $search_target [,$finder, $desc ] );

Returns true if C<$search_target> is I<not> found on the page. C<$search_target>
is passed to L<Selenium::Remote::Driver/find_element> using a finder or the
C<default_finder> if none passed. See there for more details on the format for C<find_no_element_ok()>.

=cut


=head2 $twd->content_like( $regex [, $desc ] )

   $twd->content_like( $regex [, $desc ] )
   $twd->content_like( [$regex_1, $regex_2] [, $desc ] )

Tells if the content of the page matches I<$regex>. If an arrayref of regex's
are provided, one 'test' is run for each regex against the content of the
current page.

A default description of 'Content is like "$regex"' will be provided if there
is no description.

=cut

sub content_like {
    my $self  = shift;
    my $regex = shift;
    my $desc  = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $content = $self->get_page_source();
    my $ret;

    if ( not ref $regex eq 'ARRAY' ) {
        $desc = qq{Content is like "$regex"} if ( not defined $desc );
        $ret = like_string( $content, $regex, $desc );
        if ( !$ret && $self->has_error_handler ) {
            $self->error_handler->($self,"Failed to find $regex");
        }
        return $ret;
    }
    elsif ( ref $regex eq 'ARRAY' ) {
        for my $re (@$regex) {
            $desc = qq{Content is like "$re"} if ( not defined $desc );
            $ret = like_string( $content, $re, $desc );
            if ( !$ret && $self->has_error_handler ) {
                $self->error_handler->($self,"Failed to find $re");
            }
        }
    }
}

=head2 $twd->content_unlike( $regex [, $desc ] )

   $twd->content_unlike( $regex [, $desc ] )
   $twd->content_unlike( [$regex_1, $regex_2] [, $desc ] )

Tells if the content of the page does NOT match I<$regex>. If an arrayref of regex's
are provided, one 'test' is run for each regex against the content of the
current page.

A default description of 'Content is unlike "$regex"' will be provided if there
is no description.

=cut

sub content_unlike {
    my $self  = shift;
    my $regex = shift;
    my $desc  = shift;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $content = $self->get_page_source();
    my $ret;

    if ( not ref $regex eq 'ARRAY' ) {
        $desc = qq{Content is unlike "$regex"} if ( not defined $desc );
        $ret = unlike_string( $content, $regex, $desc );
        if ( !$ret && $self->has_error_handler ) {
            $self->error_handler->($self,"Failed to find $regex");
        }
    }
    elsif ( ref $regex eq 'ARRAY' ) {
        for my $re (@$regex) {
            $desc = qq{Content is unlike "$re"} if ( not defined $desc );
            $ret = unlike_string( $content, $re, $desc );
            if ( !$ret && $self->has_error_handler ) {
                $self->error_handler->($self,"Failed to find $re");
            }
        }
    }
}


=head2 $twd->body_text_like( $regex [, $desc ] )

   $twd->body_text_like( $regex [, $desc ] )
   $twd->body_text_like( [$regex_1, $regex_2] [, $desc ] )

Tells if the text of the page (as returned by C<< get_body() >>)  matches
I<$regex>. If an arrayref of regex's are provided, one 'test' is run for each
regex against the content of the current page.

A default description of 'Content is like "$regex"' will be provided if there
is no description.

To also match the HTML see, C<< content_unlike() >>.

=cut

sub body_text_like {
    my $self  = shift;
    my $regex = shift;
    my $desc  = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $text = $self->get_body();
    my $ret;

    if ( not ref $regex eq 'ARRAY' ) {
        $desc = qq{Text is like "$regex"} if ( not defined $desc );
        $ret = like_string( $text, $regex, $desc );
        if ( !$ret && $self->has_error_handler ) {
            $self->error_handler->($self,"Failed to find $regex");
        }
        return $ret;
    }
    elsif ( ref $regex eq 'ARRAY' ) {
        for my $re (@$regex) {
            $desc = qq{Text is like "$re"} if ( not defined $desc );
            $ret = like_string( $text, $re, $desc );
            if ( !$ret && $self->has_error_handler ) {
                $self->error_handler->($self,"Failed to find $re");
            }
        }
    }
}

=head2 $twd->body_text_unlike( $regex [, $desc ] )

   $twd->body_text_unlike( $regex [, $desc ] )
   $twd->body_text_unlike( [$regex_1, $regex_2] [, $desc ] )

Tells if the text of the page (as returned by C<< get_body() >>)
 does NOT match I<$regex>. If an arrayref of regex's
are provided, one 'test' is run for each regex against the content of the
current page.

A default description of 'Text is unlike "$regex"' will be provided if there
is no description.

To also match the HTML see, C<< content_unlike() >>.

=cut

sub body_text_unlike {
    my $self  = shift;
    my $regex = shift;
    my $desc  = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $text = $self->get_body();
    my $ret;

    if ( not ref $regex eq 'ARRAY' ) {
        $desc = qq{Text is unlike "$regex"} if ( not defined $desc );
        $ret = unlike_string( $text, $regex, $desc );
        if ( !$ret && $self->has_error_handler ) {
            $self->error_handler->($self,"Failed to find $regex");
        }
        return $ret;

    }
    elsif ( ref $regex eq 'ARRAY' ) {
        for my $re (@$regex) {
            $desc = qq{Text is unlike "$re"} if ( not defined $desc );
            $ret = unlike_string( $text, $re, $desc );
            if ( !$ret && $self->has_error_handler ) {
                $self->error_handler->($self,"Failed to find $re");
            }
        }
    }
}

#####

=head2 $twd->content_contains( $str [, $desc ] )

   $twd->content_contains( $str [, $desc ] )
   $twd->content_contains( [$str_1, $str_2] [, $desc ] )

Tells if the content of the page contains I<$str>. If an arrayref of strngs's
are provided, one 'test' is run for each string against the content of the
current page.

A default description of 'Content contains "$str"' will be provided if there
is no description.

=cut

sub content_contains {
    my $self = shift;
    my $str  = shift;
    my $desc = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $content = $self->get_page_source();
    my $ret;

    if ( not ref $str eq 'ARRAY' ) {
        $desc = qq{Content contains "$str"} if ( not defined $desc );
        $ret = contains_string( $content, $str, $desc );
        if ( !$ret && $self->has_error_handler ) {
            $self->error_handler->($self,"Failed to find $str");
        }
        return $ret;
    }
    elsif ( ref $str eq 'ARRAY' ) {
        for my $s (@$str) {
            $desc = qq{Content contains "$s"} if ( not defined $desc );
            $ret = contains_string( $content, $s, $desc );

            if ( !$ret && $self->has_error_handler ) {
                $self->error_handler->($self,"Failed to find $s");
            }
        }
    }
}

=head2 $twd->content_lacks( $str [, $desc ] )

   $twd->content_lacks( $str [, $desc ] )
   $twd->content_lacks( [$str_1, $str_2] [, $desc ] )

Tells if the content of the page does NOT contain I<$str>. If an arrayref of strings
are provided, one 'test' is run for each string against the content of the
current page.

A default description of 'Content lacks "$str"' will be provided if there
is no description.

=cut

sub content_lacks {
    my $self = shift;
    my $str  = shift;
    my $desc = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $content = $self->get_page_source();
    my $ret;

    if ( not ref $str eq 'ARRAY' ) {
        $desc = qq{Content lacks "$str"} if ( not defined $desc );
        $ret = lacks_string( $content, $str, $desc );
        if ( !$ret && $self->has_error_handler ) {
            $self->error_handler->($self,"Failed to find $str");
        }
        return $ret;
    }
    elsif ( ref $str eq 'ARRAY' ) {
        for my $s (@$str) {
            $desc = qq{Content lacks "$s"} if ( not defined $desc );
            $ret = lacks_string( $content, $s, $desc );
            if ( !$ret && $self->has_error_handler ) {
                $self->error_handler->($self,"Failed to find $s");
            }
        }
    }
}


=head2 $twd->body_text_contains( $str [, $desc ] )

   $twd->body_text_contains( $str [, $desc ] )
   $twd->body_text_contains( [$str_1, $str_2] [, $desc ] )

Tells if the text of the page (as returned by C<< get_body() >>) contains
I<$str>. If an arrayref of strings are provided, one 'test' is run for each
regex against the content of the current page.

A default description of 'Text contains "$str"' will be provided if there
is no description.

To also match the HTML see, C<< content_uncontains() >>.

=cut

sub body_text_contains {
    my $self = shift;
    my $str  = shift;
    my $desc = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $text = $self->get_body();
    my $ret;

    if ( not ref $str eq 'ARRAY' ) {
        $desc = qq{Text contains "$str"} if ( not defined $desc );
        $ret = contains_string( $text, $str, $desc );
        if ( !$ret && $self->has_error_handler ) {
            $self->error_handler->($self,"Failed to find $str");
        }
        return $ret;
    }
    elsif ( ref $str eq 'ARRAY' ) {
        for my $s (@$str) {
            $desc = qq{Text contains "$s"} if ( not defined $desc );
            $ret = contains_string( $text, $s, $desc );
            if ( !$ret && $self->has_error_handler ) {
                $self->error_handler->($self,"Failed to find $s");
            }
        }
    }
}

=head2 $twd->body_text_lacks( $str [, $desc ] )

   $twd->body_text_lacks( $str [, $desc ] )
   $twd->body_text_lacks( [$str_1, $str_2] [, $desc ] )

Tells if the text of the page (as returned by C<< get_body() >>)
 does NOT contain I<$str>. If an arrayref of strings
are provided, one 'test' is run for each regex against the content of the
current page.

A default description of 'Text lacks "$str"' will be provided if there
is no description.

To also match the HTML see, C<< content_lacks() >>.

=cut

sub body_text_lacks {
    my $self = shift;
    my $str  = shift;
    my $desc = shift;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $text = $self->get_body();
    my $ret;

    if ( not ref $str eq 'ARRAY' ) {
        $desc = qq{Text lacks "$str"} if ( not defined $desc );
        $ret = lacks_string( $text, $str, $desc );
        if ( !$ret && $self->has_error_handler ) {
            $self->error_handler->($self,"Failed to find $str");
        }
        return $ret;
    }
    elsif ( ref $str eq 'ARRAY' ) {
        for my $s (@$str) {
            $desc = qq{Text lacks "$s"} if ( not defined $desc );
            $ret = lacks_string( $text, $s, $desc );
            if ( !$ret && $self->has_error_handler ) {
                $self->error_handler->($self,"Failed to find $s");
            }
        }
    }
}


1;

__END__

=head1 NOTES

This module was forked from Test::WebDriver 0.01.

For Best Practice - I recommend subclassing Test::Selenium::Remote::Driver for your application,
and then refactoring common or app specific methods into MyApp::WebDriver so that
your test files do not have much duplication.  As your app changes, you can update
MyApp::WebDriver rather than all the individual test files.

=head1 AUTHORS

=over 4

=item *

Created by: Luke Closs <lukec@cpan.org>, but inspired by
 L<Test::WWW::Selenium> and its authors.

=back

=head1 CONTRIBUTORS

Test::WebDriver work was sponsored by Prime Radiant, Inc.
Mark Stosberg <mark@stosberg.com> forked it as Test::Selenium::Remote::Driver
and significantly expanded it.

=head1 COPYRIGHT AND LICENSE

Parts Copyright (c) 2012 Prime Radiant, Inc.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
