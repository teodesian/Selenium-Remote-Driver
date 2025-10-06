package Selenium::ActionChains;

use strict;
use warnings;

# ABSTRACT: Action chains for Selenium::Remote::Driver
use Moo;

=for Pod::Coverage driver

=cut

has 'driver' => ( is => 'ro', );

has 'actions' => (
    is      => 'lazy',
    builder => sub { [] },
    clearer => 1,
);

sub perform {
    my $self = shift;
    foreach my $action ( @{ $self->actions } ) {
        $action->();
    }
}

sub click {
    my $self    = shift;
    my $element = shift;
    if ($element) {
        $self->move_to_element($element);
    }

    # left click
    push @{ $self->actions }, sub { $self->driver->click('LEFT') };
    $self;
}

sub click_and_hold {
    my $self    = shift;
    my $element = shift;
    if ($element) {
        $self->move_to_element($element);
    }
    push @{ $self->actions }, sub { $self->driver->button_down };
    $self;
}

sub context_click {
    my $self    = shift;
    my $element = shift;
    if ($element) {
        $self->move_to_element($element);
    }

    # right click
    push @{ $self->actions }, sub { $self->driver->click('RIGHT') };
    $self;
}

sub double_click {
    my $self    = shift;
    my $element = shift;
    if ($element) {
        $self->move_to_element($element);
    }
    push @{ $self->actions }, sub { $self->driver->double_click };
    $self;
}

sub release {
    my $self    = shift;
    my $element = shift;
    if ($element) {
        $self->move_to_element($element);
    }
    push @{ $self->actions }, sub { $self->driver->button_up };
    $self;
}

sub drag_and_drop {
    my $self = shift;
    my ( $source, $target ) = @_;
    $self->click_and_hold($source);
    $self->release($target);
    $self;
}

sub drag_and_drop_by_offset {
    my $self = shift;
    my ( $source, $xoffset, $yoffset ) = @_;
    $self->click_and_hold($source);
    $self->move_by_offset( $xoffset, $yoffset );
    $self->release($source);
    $self;
}

sub move_to_element {
    my $self    = shift;
    my $element = shift;
    push @{ $self->actions },
      sub { $self->driver->move_to( element => $element ) };
    $self;
}

sub move_by_offset {
    my $self = shift;
    my ( $xoffset, $yoffset ) = @_;
    push @{ $self->actions }, sub {
        $self->driver->move_to( xoffset => $xoffset, yoffset => $yoffset );
    };
    $self;
}

sub move_to_element_with_offset {
    my $self = shift;
    my ( $element, $xoffset, $yoffset ) = @_;
    push @{ $self->actions }, sub {
        $self->driver->move_to(
            element => $element,
            xoffset => $xoffset,
            yoffset => $yoffset
        );
    };
    $self;
}

sub key_down {
    my ( $self, $value, $element ) = @_;

    #DWIM
    $value = [$value] unless ref $value eq 'ARRAY';

    $self->click($element) if defined $element;
    foreach my $v (@$value) {
        push @{ $self->actions },
          sub { $self->driver->general_action( actions => [ { type => 'key', id => 'key', actions => [ { type => 'keyDown', value => $v } ] } ] ) };
    }
    return $self;
}

sub key_up {
    my ( $self, $value, $element ) = @_;

    #DWIM
    $value = [$value] unless ref $value eq 'ARRAY';

    $self->click($element) if defined $element;
    foreach my $v (@$value) {
        push @{ $self->actions },
          sub { $self->driver->general_action( actions => [ { type => 'key', id => 'key', actions => [ { type => 'keyUp', value => $v } ] } ] ) };
    }
    return $self;
}

sub send_keys {
    my ($self,$keys) =@_;

    # Do nothing if there are no keys to send
    return unless $keys;

    # DWIM
    $keys = [split('',$keys)] unless ref $keys eq 'ARRAY';

    push @{ $self->actions },
      sub {
          foreach my $key (@$keys) {
              $self->key_down($key, $self->driver->get_active_element);
              $self->key_up($key, $self->driver->get_active_element);
          }
      };
    $self;
}

sub send_keys_to_element {
    my ($self, $element, $keys) =@_;

    # Do nothing if there are no keys to send
    return unless $keys;

    # DWIM
    $keys = [split('',$keys)] unless ref $keys eq 'ARRAY';

    push @{ $self->actions },
        sub {
            foreach my $key (@$keys) {
                $self->key_down($key,$element);
                $self->key_up($key,$element);
            }
        };
    $self;
}

1;

__END__

=pod

=head1 SYNOPSIS

    use Selenium::Remote::Driver;
    use Selenium::ActionChains;

    my $driver = Selenium::Remote::Driver->new;
    my $action_chains = Selenium::ActionChains->new(driver => $driver);

    $driver->get("http://www.some.web/site");
    my $elt_1 = $driver->find_element("//*[\@id='someid']");
    my $elt_2 = $driver->find_element("//*[\@id='someotherid']");
    $action_chains->send_keys_to_element($elt_1)->click($elt_2)->perform;

=head1 DESCRIPTION

This module implements ActionChains for Selenium, which is a way of automating
low level interactions like mouse movements, mouse button actions , key presses and
context menu interactions.
The code was inspired by the L<Python implementation|http://selenium.googlecode.com/svn/trunk/docs/api/py/_modules/selenium/webdriver/common/action_chains.html#ActionChains>.


=head1 DRAG AND DROP IS NOT WORKING !

The implementation contains a drag_and_drop function, but due to Selenium limitations, it is L<not working|https://code.google.com/p/selenium/issues/detail?id=3604>.

Nevertheless, we decided to implement the function, because eventually one day it will work.

In the meantime, there are workarounds that can be used to simulate drag and drop, like L<this StackOverflow post|http://stackoverflow.com/questions/29381233/how-to-simulate-html5-drag-and-drop-in-selenium-webdriver-in-python>.

=head1 FUNCTIONS

=head2 new

Creates a new ActionChains object. Requires a Selenium::Remote::Driver as a mandatory parameter:

    my $driver = Selenium::Remote::Driver->new;
    my $action_chains = Selenium::ActionChains->new(driver => $driver);

=head2 perform

Performs all the actions stored in the ActionChains object in the order they were called:

    Args: None

    Usage:
        my $action_chains = Selenium::ActionChains->new(driver => $driver);
        # assuming that $some_element and $other_element are valid
        # Selenium::Remote::WebElement objects
        $action_chains->click($some_element);
        $action_chains->move_to_element($other_element);
        $action_chains->click($other_element);
        # click some_element, move to other_element, then click other_element
        $action_chains->perform;



=head2 click

Clicks an element. If none specified, clicks on current mouse position.

    Args: A Selenium::Remote::WebElement object

    Usage:
        my $element = $driver->find_element("//div[\@id='some_id']");
        $action_chains->click($element);


=head2 click_and_hold

Holds down the left mouse button on an element. If none specified, clicks on current
mouse position.

    Args: A Selenium::Remote::WebElement object

    Usage:
        my $element = $driver->find_element("//div[\@id='some_id']");
        $action_chains->click_and_hold($element);

=head2 context_click

Right clicks an element. If none specified, right clicks on current mouse
position.

    Args: A Selenium::Remote::WebElement object

    Usage:
        my $element = $driver->find_element("//div[\@id='some_id']");
        $action_chains->context_click($element);



=head2 double_click

Double clicks an element. If none specified, double clicks on current mouse
position.

    Args: A Selenium::Remote::WebElement object

    Usage:
        my $element = $driver->find_element("//div[\@id='some_id']");
        $action_chains->double_click($element);

=head2 drag_and_drop - NOT WORKING

Holds down the left mouse button on the source element, then moves to the target
element and releases the mouse button. IT IS NOT WORKING DUE TO CURRENT SELENIUM
LIMITATIONS.

    Args:
       A source Selenium::Remote::WebElement object
       A target Selenium::Remote::WebElement object

    Usage:
        my $src_element = $driver->find_element("//*[\@class='foo']");
        my $tgt_element = $driver->find_element("//*[\@class='bar']");
        $action_chains->drag_and_drop($src_element,$tgt_element);

=head2 drag_and_drop_by_offset - NOT WORKING

Holds down the left mouse button on the source element, then moves to the offset
specified and releases the mouse button. IT IS NOT WORKING DUE TO CURRENT SELENIUM
LIMITATIONS.

    Args:
       A source Selenium::Remote::WebElement object
       An integer X offset
       An integer Y offset

    Usage:
        my $src_element = $driver->find_element("//*[\@class='foo']");
        my $xoffset = 10;
        my $yoffset = 10;
        $action_chains->drag_and_drop($src_element,$xoffset,$yoffset);


=head2 key_down

Sends key presses only, without releasing them.
Useful when modifier keys are required

Will DWIM your input and accept either a string or ARRAYREF of keys.

    Args:
        An array ref to keys to send. Use the KEY constant from Selenium::Remote::WDKeys
        The element to send keys to. If none, sends keys to the current focused element

    Usage:
        use Selenium::Remote::WDKeys 'KEYS';
        # DEFINITELY cut and paste this in without looking
        $action_chains->key_down( [ KEYS->{'alt'}, KEYS->{'F4'} ] );


=head2 key_up

Releases prior key presses.
Useful when modifier keys are required

Will DWIM your input and accept either a string or ARRAYREF of keys.

    Args:
        An array ref to keys to send. Use the KEY constant from Selenium::Remote::WDKeys
        The element to send keys to. If none, sends keys to the current focused element

    Usage:
        use Selenium::Remote::WDKeys 'KEYS';
        # Fullscreen the foo element
        my $element = $driver->find_element('foo','id');
        $action_chains->key_down( [ KEYS->{'alt'}, KEYS->{'enter'} ], $element );
        $action_chains->key_up( [ KEYS->{'alt'}, KEYS->{'enter'} ],   $element);


=head2 move_by_offset

Moves the mouse to an offset from current mouse position.

    Args:
        An integer X offset
        An integer Y offset

    Usage:
        $action_chains->move_by_offset(10,100);

=head2 move_to_element

Moves the mouse to the middle of an element

    Args:
        A Selenium::Remote::WebElement to move to

    Usage:
        my $element = $driver->find_element('foo','id');
        $action_chains->move_to_element($element);



=head2 move_to_element_with_offset

Moves the mouse by an offset of the specified element.
Offsets are relative to the top-left corner of the element

    Args:
        A Selenium::Remote::WebElement
        An integer X offset
        An integer Y offset

    Usage:
        my $element = $driver->find_element('foo','id');
        $action_chains->move_to_element_with_offset($element,10,10);


=head2 release

Releases a held mouse_button

    Args:
        A Selenium::Remote::WebElement, the element to mouse up

    Usage:
        my $element = $driver->find_element('foo','id');
        $action_chains->release($element);

=head2 send_keys

Sends keys to the currently focused element.
Essentially an alias around key_down then key_up.

Will DWIM your input and accept either a string or ARRAYREF of keys.

    Args:
        The keys to send

    Usage:
        $action_chains->send_keys('abcd');

=head2 send_keys_to_element

Sends keys to an element in much the same fashion as send_keys.

Will DWIM your input and accept either a string or ARRAYREF of keys.

    Args:
        A Selenium::Remote::WebElement
        The keys to send

    Usage:
        my $element = $driver->find_element('foo','id');
        $action_chains->send_keys_to_element($element,'abcd');


=cut
