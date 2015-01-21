package Test::Selenium::Remote::Role::DoesTesting;
# ABSTRACT: Role to cope with everything that is related to testing (could
# be reused in both testing classes)

use Moo::Role;
use Test::Builder;
use Try::Tiny;
use List::MoreUtils qw/any/;
use namespace::clean;

requires qw(func_list has_args);

has _builder => (
    is      => 'lazy',
    builder => sub { return Test::Builder->new() },
    handles => [qw/is_eq isnt_eq like unlike ok croak/],
);


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
# TODO: maybe simplify a bit the logic 

sub _check_ok {
    my $self   = shift;
    my $method = shift;
    my $real_method = '';
    my @args   = @_;
    my ($rv, $num_of_args, @r_args);
    try {
        $num_of_args = $self->has_args($method);
        @r_args = splice( @args, 0, $num_of_args );
        if ($method =~ m/^find(_no)?_element/) { 
            # case find_element_ok was called with no arguments    
            if (scalar(@r_args) == 1) { 
                push @r_args, $self->default_finder; 
            }
            else { 
                if (scalar(@r_args) == 2) { 
                    # case find_element was called with no finder but
                    # a test description
                    my $finder = $r_args[1]; 
                    my @FINDERS = keys (%{$self->FINDERS});
                    unless ( any { $finder eq $_ } @FINDERS) { 
                        $r_args[1] = $self->default_finder; 
                        push @args, $finder; 
                    }
                }
            }
        }
        if ($method =~ m/^find_child_element/) { 
            # case find_element_ok was called with no arguments    
            if (scalar(@r_args) == 2) { 
                push @r_args, $self->default_finder; 
            }
            else { 
                if (scalar(@r_args) == 3) { 
                    # case find_element was called with no finder but
                    # a test description
                    my $finder = $r_args[2]; 
                    my @FINDERS = keys (%{$self->FINDERS});
                    unless ( any { $finder eq $_ } @FINDERS) { 
                        $r_args[2] = $self->default_finder; 
                        push @args, $finder; 
                    }
                }
            }
        }
        if ($method eq 'find_no_element_ok') { 
            $real_method = $method;
            $method = 'find_element'; 
        }
        $rv = $self->$method(@r_args);
    }
    catch {
        if ($real_method) {
            $method = $real_method;
            $rv     = 1;
        }
        else {
            $self->croak($_);
        }
    };

    my $default_test_name = $method;
    $default_test_name .= "'" . join("' ", @r_args) . "'"
        if $num_of_args > 0;

    my $test_name = pop @args // $default_test_name;
    return $self->ok( $rv, $test_name);
}


# build the subs with the correct arg set

sub _build_sub {
    my $self      = shift;
    my $meth_name = shift;
    my @func_args;
    my $comparators = {
        is     => 'is_eq',
        isnt   => 'isnt_eq',
        like   => 'like',
        unlike => 'unlike',
    };
    my @meth_elements = split( '_', $meth_name );
    my $meth          = '_check_ok';
    my $meth_comp     = pop @meth_elements;
    if ( $meth_comp eq 'ok' ) {
        push @func_args, join( '_', @meth_elements );
    }
    else {
        if ( defined( $comparators->{$meth_comp} ) ) {
            $meth = '_check_method';
            push @func_args, join( '_', @meth_elements ),
              $comparators->{$meth_comp};
        }
        else {
            return sub {
                my $self = shift;
                $self->croak("Sub $meth_name could not be defined");
              }
        }
    }

    return sub {
        my $self = shift;
        local $Test::Builder::Level = $Test::Builder::Level + 2;
        $self->$meth( @func_args, @_ );
    };

}

1;


=head1 NAME

Selenium::Remote::Role::DoesTesting - Role implementing the common logic used for testing

=cut
