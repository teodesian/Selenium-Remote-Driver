package Test::Selenium::Remote::Role::DoesTesting; 
# ABSTRACT: Role to cope with everything that is related to testing (could
# be reused in both testing classes) 
use Moo::Role;
use Test::Builder;
use Try::Tiny;
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

    # +2 because of the delegation on _builder
    local $Test::Builder::Level = $Test::Builder::Level + 2;
    return $self->$method_to_test( $rv, @args );
}

# main method for _ok tests

sub _check_ok {
    my $self      = shift;
    my $method      = shift;
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

    # +2 because of the delegation on _builder
    local $Test::Builder::Level = $Test::Builder::Level + 2;
    $DB::single = 1;
    my $test_name = pop @args // $method;
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
        $self->$meth( @func_args, @_ );
    };

}

1;
