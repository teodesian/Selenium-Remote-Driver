package Test::Selenium::Remote::WebElement;
use Moo; 
extends 'Selenium::Remote::WebElement';
use Test::Builder;
use Try::Tiny;
use Sub::Install;
use namespace::clean;

has _builder => (
    is      => 'lazy',
    builder => sub { return Test::Builder->new() },
    handles => [qw/is_eq isnt_eq like unlike ok croak/],
);

# list of test functions to be built

has _func_list => (
    is      => 'lazy',
    builder => sub {
        return [
            'clear_ok',     'click_ok',
            'send_keys_ok', 'is_displayed_ok',
            'is_enabled_ok', 'is_selected_ok', 'submit_ok',
            'text_is',          'text_isnt',      'text_like',  'text_unlike',
            'attribute_is',     'attribute_isnt', 'attribute_like',
            'attribute_unlike', 'value_is',       'value_isnt', 'value_like',
            'value_unlike', 'tag_name_is', 'tag_name_isnt', 'tag_name_like',
            'tag_name_unlike'
        ];
    }
);

# helper so we could specify the num of args a method takes (if any)

sub has_args {
    my $self          = shift;
    my $fun_name      = shift;
    my $hash_fun_args = {
        'get_attribute' => 1,
    };
    return ( $hash_fun_args->{$fun_name} // 0 );
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

    # +2 because of the delegation on _builder
    local $Test::Builder::Level = $Test::Builder::Level + 2;
    return $self->$method_to_test( $rv, @args );
}

# main method for _ok tests

sub _check_ok {
    my $self      = shift;
    my $meth      = shift;
    my $test_name = pop // $meth;
    my $rv;
    try {
        $rv = $self->$meth(@_);
    }
    catch {
        $self->croak($_);
    };

    # +2 because of the delegation on _builder
    local $Test::Builder::Level = $Test::Builder::Level + 2;
    return $self->ok( $rv, $test_name, @_ );
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

# install the test methods into the class namespace

sub BUILD {
    my $self = shift;
    foreach my $method_name ( @{ $self->_func_list } ) {
        my $sub = $self->_build_sub($method_name);
        unless (defined($self->can($method_name))) { 
            Sub::Install::install_sub(
                {   code => $sub,
                    into => ref($self),
                    as   => $method_name
                }
            );
        }
    }
}


1;

__END__

=head1 NAME

Test::Selenium::Remote::WebElement

=head1 DESCRIPTION

A sub-class of L<Selenium::Remote::WebElement>, with several test-specific method additions.

This is an I<experimental> addition to the Selenium::Remote::Driver
distribution, and some interfaces may change.

=head1 METHODS

All methods from L<Selenium::Remote::WebElement> are available through this
module, as well as the following test-specific methods. All test names are optional.

  text_is($match_str,$test_name);
  text_isnt($match_str,$test_name);
  text_like($match_re,$test_name);
  text_unlike($match_re,$test_name);

  tag_name_is($match_str,$test_name);
  tag_name_isnt($match_str,$test_name);
  tag_name_like($match_re,$test_name);
  tag_name_unlike($match_re,$test_name);

  value_is($match_str,$test_name);
  value_isnt($match_str,$test_name);
  value_like($match_re,$test_name);
  value_unlike($match_re,$test_name);

  clear_ok($test_name);
  click_ok($test_name);
  submit_ok($test_name);
  is_selected_ok($test_name);
  is_enabled_ok($test_name);
  is_displayed_ok($test_name);

  send_keys_ok($str)
  send_keys_ok($str,$test_name)

  attribute_is($attr_name,$match_str,$test_name); 
  attribute_isnt($attr_name,$match_str,$test_name);
  attribute_like($attr_name,$match_re,$test_name); 
  attribute_unlike($attr_name,$match_re,$test_name);

  css_attribute_is($attr_name,$match_str,$test_name); # TODO
  css_attribute_isnt($attr_name,$match_str,$test_name); # TODO
  css_attribute_like($attr_name,$match_re,$test_name); # TODO
  css_attribute_unlike($attr_name,$match_re,$test_name); # TODO

  element_location_is([x,y]) # TODO
  element_location_in_view_is([x,y]) # TODO

=head1 AUTHORS

=over 4

=item *

Created by: Mark Stosberg <mark@stosberg.org>, but inspired by
 L<Test::WWW::Selenium> and its authors.

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2013 Mark Stosberg

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
