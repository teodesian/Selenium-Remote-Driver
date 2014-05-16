package Test::Selenium::Remote::WebElement;
# ABSTRACT: A sub-class of L<Selenium::Remote::WebElement>, with several test-specific method additions.

use Moo;
use Sub::Install;
extends 'Selenium::Remote::WebElement';


# list of test functions to be built

has func_list => (
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

with 'Test::Selenium::Remote::Role::DoesTesting';

# helper so we could specify the num of args a method takes (if any)

sub has_args {
    my $self          = shift;
    my $fun_name      = shift;
    my $hash_fun_args = {
        'get_attribute' => 1,
        'send_keys'     => 1,
    };
    return ( $hash_fun_args->{$fun_name} // 0 );
}


# install the test methods into the class namespace

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


1;

__END__

=head1 DESCRIPTION

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
