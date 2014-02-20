package Test::Selenium::Remote::WebElement;
use parent 'Selenium::Remote::WebElement';
use Moo;
use Test::Builder;

has _builder => (
    is      => 'lazy',
    builder => sub { return Test::Builder->new() },
    handles => [qw/is_eq isnt_eq like unlike/],
);


sub _check_main_method {
    my $self           = shift;
    my $method         = shift;
    my $method_to_test = shift;
    $method = "get_$method";
    my $rv = $self->$method();

    # +2 because of the delegation on _builder
    local $Test::Builder::Level = $Test::Builder::Level + 2;
    return $self->$method_to_test( $rv, @_ );
}


sub text_is {
    my $self = shift;
    return $self->_check_main_method( 'text', 'is_eq', @_ );
}

sub text_isnt {
    my $self = shift;
    return $self->_check_main_method( 'text', 'isnt_eq', @_ );
}

sub text_like {
    my $self = shift;
    return $self->_check_main_method( 'text', 'like', @_ );
}

sub text_unlike {
    my $self = shift;
    return $self->_check_main_method( 'text', 'unlike', @_ );
}

sub tag_name_is {
    my $self = shift;
    return $self->_check_main_method( 'tag_name', 'is_eq', @_ );
}

sub tag_name_isnt {
    my $self = shift;
    return $self->_check_main_method( 'tag_name', 'isnt_eq', @_ );
}

sub tag_name_like {
    my $self = shift;
    return $self->_check_main_method( 'tag_name', 'like', @_ );
}

sub tag_name_unlike {
    my $self = shift;
    return $self->_check_main_method( 'tag_name', 'unlike', @_ );
}

sub value_is {
    my $self = shift;
    return $self->_check_main_method( 'value', 'is_eq', @_ );
}

sub value_isnt {
    my $self = shift;
    return $self->_check_main_method( 'value', 'isnt_eq', @_ );
}

sub value_like {
    my $self = shift;
    return $self->_check_main_method( 'value', 'like', @_ );
}

sub value_unlike {
    my $self = shift;
    return $self->_check_main_method( 'value', 'unlike', @_ );
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

  attribute_is($attr_name,$match_str,$test_name); # TODO
  attribute_isnt($attr_name,$match_str,$test_name); # TODO
  attribute_like($attr_name,$match_re,$test_name); # TODO
  attribute_unlike($attr_name,$match_re,$test_name); # TODO

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
