package Test::Selenium::Remote::Role::DoesTesting;

# ABSTRACT: Role to cope with everything that is related to testing (could
# be reused in both testing classes)

use Moo::Role;
use Test::Builder;
use Try::Tiny;
use Scalar::Util 'blessed';
use List::Util qw/any/;
use namespace::clean;

requires qw(func_list has_args);

has _builder => (
    is      => 'lazy',
    builder => sub { return Test::Builder->new() },
    handles => [qw/is_eq isnt_eq like unlike ok croak/],
);

# get back the key value from an already coerced finder (default finder)

sub _get_finder_key {
    my $self         = shift;
    my $finder_value = shift;

    foreach my $k ( keys %{ $self->FINDERS } ) {
        return $k if ( $self->FINDERS->{$k} eq $finder_value );
    }

    return;
}

# main method for non ok tests

sub _check_method {
    my $self           = shift;
    my $method         = shift;
    my $method_to_test = shift;
    $method = "get_$method";
    my @args = @_;
    my $rv;
    try {
        my $num_of_args = $self->has_args($method);
        my @r_args = splice( @args, 0, $num_of_args );
        $rv = $self->$method(@r_args);
    }
    catch {
        $self->croak($_);
    };

    return $self->$method_to_test( $rv, @args );
}

# main method for _ok tests
# a bit hacked so that find_no_element_ok can also be processed

sub _check_ok {
    my $self        = shift;
    my $method      = shift;

    my @args        = @_;
    my ( $rv, $num_of_args, @r_args );
    try {
        $num_of_args = $self->has_args($method);
        @r_args = splice( @args, 0, $num_of_args );
        if ( $method =~ m/^find(_no|_child)?_element/ ) {

            # case find_element_ok was called with no arguments
            if ( scalar(@r_args) - $num_of_args == 1 ) {
                push @r_args, $self->_get_finder_key( $self->default_finder );
            }
            else {
                if ( scalar(@r_args) == $num_of_args ) {

                    # case find_element was called with no finder but
                    # a test description
                    my $finder  = $r_args[ $num_of_args - 1 ];
                    my @FINDERS = keys( %{ $self->FINDERS } );
                    unless ( any { $finder eq $_ } @FINDERS ) {
                        $r_args[ $num_of_args - 1 ] =
                          $self->_get_finder_key( $self->default_finder );
                        push @args, $finder;
                    }
                }
            }
        }

        # quick hack to fit 'find_no_element' into check_ok logic
        if ( $method eq 'find_no_element' ) {
            # If we use `find_element` and find nothing, the error
            # handler is incorrectly invoked. Doing a `find_elements`
            # and checking that it returns an empty array does not
            # invoke the error_handler. See
            # https://github.com/gempesaw/Selenium-Remote-Driver/issues/253
            my $elements = $self->find_elements(@r_args);
            if ( @{$elements} ) {
                $rv = $elements->[0];
            }
            else {
                $rv = 1; # empty list means success
            }
        }
        else {
            $rv = $self->$method(@r_args); # a true $rv means success
        }
    }
    catch {
        if ($method eq 'find_no_element') {
            $rv = 1; # an exception from find_elements() means success
        }
        else {
            $self->croak($_);
        }
    };

    # test description might have been explicitly passed
    my $test_name = pop @args;

    # generic test description when no explicit test description was passed
    if ( ! defined $test_name ) {
        $test_name = $num_of_args  > 0 ?
            join( ' ', $method, map { q{'$_'} } @r_args )
            :
            $method;
    }

    # case when find_no_element found an element, we should croak
    if ( $method eq 'find_no_element' ) {
        if ( blessed($rv) && $rv->isa('Selenium::Remote::WebElement') ) {
            $self->croak($test_name);
        }
    }

    return $self->ok( $rv, $test_name );
}

# build the subs with the correct arg set

sub _build_sub {
    my $self      = shift;
    my $meth_name = shift;

    # e.g. for $meth_name =  'find_no_element_ok':
    #   $meth_comp         = 'ok'
    #   $meth_without_comp = 'find_no_element'
    my @meth_elements     = split '_', $meth_name;
    my $meth_comp         = pop @meth_elements;
    my $meth_without_comp = join '_', @meth_elements;

    # handle the ok testing methods
    if ( $meth_comp eq 'ok' ) {
        return sub {
            my $self = shift;

            local $Test::Builder::Level = $Test::Builder::Level + 2;

            return $self->_check_ok($meth_without_comp, @_);
        };
    }

    # find the Test::More comparator method
    my %comparators = (
        is     => 'is_eq',
        isnt   => 'isnt_eq',
        like   => 'like',
        unlike => 'unlike',
    );

    # croak on unknown comparator methods
    if ( ! exists $comparators{$meth_comp} ) {
        return sub {
            my $self = shift;

            return $self->croak("Sub $meth_name could not be defined");
        };
    }

    # handle check in _check_method()
    return sub {
        my $self = shift;

        local $Test::Builder::Level = $Test::Builder::Level + 2;

        return $self->_check_method( $meth_without_comp, $comparators{$meth_comp}, @_ );
    };
}

1;

=head1 NAME

Selenium::Remote::Role::DoesTesting - Role implementing the common logic used for testing

=cut
