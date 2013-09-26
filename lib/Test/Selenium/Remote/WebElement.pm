package Test::Selenium::Remote::WebElement;
use parent 'Selenium::Remote::WebElement';

use Test::More;
use Test::Builder;
 
our $AUTOLOAD;

our $Test = Test::Builder->new;
$Test->exported_to(__PACKAGE__);

our %comparator = (
    is     => 'is_eq',
    isnt   => 'isnt_eq',
    like   => 'like',
    unlike => 'unlike',
);

# These commands don't require a locator
# grep item lib/WWW/Selenium.pm | grep sel | grep \(\) | grep get
our %no_locator = map { $_ => 1 }
                qw( send_keys speed alert confirmation prompt location title
                    body_text all_buttons all_links all_fields
                    mouse_speed all_window_ids all_window_names
                    all_window_titles html_source cookie absolute_location );

sub no_locator {
    my $self   = shift;
    my $method = shift;
    return $no_locator{$method};
}
 
our %one_arg = map { $_ => 1 } qw(send_keys);

sub one_arg {
    my $self   = shift;
    my $method = shift;
    return $one_arg{$method};
}

our %no_arg = map { $_ => 1 } qw(click clear);

sub no_arg {
    my $self   = shift;
    my $method = shift;
    return $no_arg{$method};
}

our %no_return = map { $_ => 1 } qw(send_keys click clear);

sub no_return {
    my $self   = shift;
    my $method = shift;
    return $no_return{$method};
}

sub AUTOLOAD {
    my $name = $AUTOLOAD;
    $name =~ s/.*:://;
    return if $name eq 'DESTROY';
    my $self = $_[0];
 
    my $sub;
    if ($name =~ /(\w+)_(is|isnt|like|unlike)$/i) {
        my $getter = $1;
        my $comparator = $comparator{lc $2};
 
        # make a subroutine that will call Test::Builder's test methods
        # with selenium data from the getter
        if ($self->no_locator($1)) {
            $sub = sub {
                my( $self, $str, $name ) = @_;
                diag "Test::Selenium::Remote::Driver running $getter (@_[1..$#_])"
                    if $self->{verbose};
                $name = "$getter, '$str'"
                    if $self->{default_names} and !defined $name;
                no strict 'refs';
                my $rc = $Test->$comparator( $self->$getter, $str, $name );
                if (!$rc && $self->error_callback) {
                    &{$self->error_callback}( $name, $self );
                }
                return $rc;
            };
        }
        else {
            $sub = sub {
                my( $self, $locator, $str, $name ) = @_;
                diag "Test::Selenium::Remote::Driver running $getter (@_[1..$#_])"
                    if $self->{verbose};
                $name = "$getter, $locator, '$str'"
                    if $self->{default_names} and !defined $name;
                no strict 'refs';
                my $rc = $Test->$comparator( $self->$getter($locator), $str, $name );
                if (!$rc && $self->error_callback) {
                    &{$self->error_callback}( $name, $self );
                }
        return $rc;
            };
        }
    }
    elsif ($name =~ /(\w+?)_?ok$/i) {
        my $cmd = $1;
 
        # make a subroutine for ok() around the selenium command
        $sub = sub {
            my( $self, $arg1, $arg2, $name );
            $self = $_[0];
            if ($self->no_arg($cmd)) {
                $name = $_[1];
            }
            elsif ($self->one_arg($cmd)) {
                $arg1 = $_[1];
                $name = $_[2];
            }
            else {
                $arg1 = $_[1];
                $arg2 = $_[2];
                $name = $_[3];
            }

            if ($self->{default_names} and !defined $name) {
                $name = $cmd;
                $name .= ", $arg1" if defined $arg1;
                $name .= ", $arg2" if defined $arg2;
            }
            diag "Test::Selenium::Remote::Driver running $cmd (@_[1..$#_])"
                    if $self->{verbose};
 
            local $Test::Builder::Level = $Test::Builder::Level + 1;
            my $rc = '';
            eval { 
                if ($self->no_arg($cmd)) {
                    $rc = $self->$cmd();
                }
                elsif ($self->one_arg($cmd)) {
                    $rc = $self->$cmd( $arg1 );
                }
                else {
                    $rc = $self->$cmd( $arg1, $arg2 );
                }
            };
            die $@ if $@ and $@ =~ /Can't locate object method/;
            diag($@) if $@;
            if ($self->no_return($cmd)) {
                $rc = ok( 1, "$name... no return value" );
            }
            else {
                $rc = ok( $rc, $name );
            }
            if (!$rc && $self->error_callback) {
                &{$self->error_callback}( $name, $self );
            }
            return $rc;
        };
    }
 
    # jump directly to the new subroutine, avoiding an extra frame stack
    if ($sub) {
        no strict 'refs';
        *{$AUTOLOAD} = $sub;
        goto &$AUTOLOAD;
    }
    else {
        # try to pass through to Selenium::Remote::Driver
        my $sel = 'Selenium::Remote::Driver';
        my $sub = "${sel}::${name}";
        goto &$sub if exists &$sub;
        my ($package, $filename, $line) = caller;
        die qq(Can't locate object method "$name" via package ")
            . __PACKAGE__
            . qq(" (also tried "$sel") at $filename line $line\n);
    }
}

sub error_callback {
    my ($self, $cb) = @_;
    if (defined($cb)) {
        $self->{error_callback} = $cb;
    }
    return $self->{error_callback};
}

sub value_is_ok {
    my $self = shift;
    my $txt_compare = shift;
    my $desc = shift;

    return(is($self->get_value(), $txt_compare, $desc));
}

sub type_ok {
    my $e = shift;
    my $text = shift;
    my $desc = shift;

    $e->send_keys_ok($text, $desc);
    $e->value_is_ok($text, $desc);
}

1;
