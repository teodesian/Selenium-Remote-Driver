package Selenium::Remote::Driver::ActionChains; 
# ABSTRACT: Action chains for Selenium::Remote::Driver
use Moo; 

has 'driver' => ( 
    is => 'rw', 
);

has 'actions' => ( 
    is => 'lazy', 
    builder => sub { [] },
    clearer => 1,
);

sub perform { 
    my $self = shift; 
    foreach my $action (@{$self->actions}) { 
        $action->();
    }
}

sub click { 
    my $self = shift; 
    my $element = shift; 
    if ($element) { 
       $self->move_to_element($element); 
    }
    # left click
    push @{$self->actions}, sub { $self->driver->click('LEFT') };
    $self; 
}

sub click_and_hold { 
    my $self = shift; 
    my $element = shift; 
    if ($element) { 
       $self->move_to_element($element); 
    }
    push @{$self->actions}, sub { $self->driver->button_down };
    $self; 
}

sub context_click { 
    my $self = shift; 
    my $element = shift; 
    if ($element) { 
       $self->move_to_element($element); 
    }
    # right click
    push @{$self->actions}, sub { $self->driver->click('RIGHT') }; 
    $self; 
}


sub double_click { 
    my $self = shift; 
    my $element = shift; 
    if ($element) { 
       $self->move_to_element($element); 
    }
    push @{$self->actions}, sub { $self->driver->double_click };
    $self; 
}

sub release { 
    my $self = shift; 
    my $element = shift; 
    if ($element) { 
       $self->move_to_element($element); 
    }
    push @{$self->actions}, sub { $self->driver->button_up };
    $self; 
}

sub drag_and_drop { 
    my $self = shift; 
    my ($source,$target) = @_;
    $self->click_and_hold($source);
    $self->release($target);
    $self; 
}

sub drag_and_drop_by_offset { 
    my $self = shift; 
    my ($source,$xoffset,$yoffset) = @_;
    $self->click_and_hold($source); 
    $self->move_by_offset($xoffset,$yoffset);
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
        $self->driver->move_to( element => $element, xoffset => $xoffset,
            yoffset => $yoffset );
    };
    $self;
}

sub key_down { 
    my $self = shift; 
    my ($value ,$element) = @_;
    if (defined($element)) { 
        $self->click($element);
    }
    push @{ $self->actions }, sub { $self->driver->send_keys_to_active_element(@$value) };
    $self;
}

sub key_up { 
    my $self = shift; 
    my ($value ,$element) = @_;
    if (defined($element)) { 
        $self->click($element);
    }
    push @{ $self->actions }, sub { $self->driver->send_keys_to_active_element(@$value) };
    $self;
}

sub send_keys { 
    my $self = shift; 
    my $keys = shift; 
    push @{ $self->actions} , sub { $self->driver->get_active_element->send_keys($keys) };
    $self;
}

sub send_keys_to_element { 
    my $self = shift; 
    my ($element,$keys) = @_;
    push @{ $self->actions }, sub { $element->send_keys($keys) };
    $self;
}



1;
