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

our %one_arg = map { $_ => 1 } qw(
    get_attribute
    send_keys

);
sub one_arg {
    my $self   = shift;
    my $method = shift;
    return $one_arg{$method};
}

our %no_arg = map { $_ => 1 } qw(
    clear
    click
    get_value
    get_tag_name
    is_enabled
    is_selected
    submit
    );

sub no_arg {
    my $self   = shift;
    my $method = shift;
    return $no_arg{$method};
}

our %no_return = map { $_ => 1 } qw(send_keys click clear submit);

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
        my $getter = "get_$1";
        my $comparator = $comparator{lc $2};
 
        $sub = sub {
            my( $self, $str, $name ) = @_;
            # There is no verbose option currently
            #diag "Test::Selenium::Remote::WebElement running $getter (@_[1..$#_])" if $self->{verbose};
            $name = "$getter, '$str'" if !defined $name;
            no strict 'refs';
            return $Test->$comparator( $self->$getter, $str, $name );
        };
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

            if (!defined $name) {
                $name = $cmd;
                $name .= ", $arg1" if defined $arg1;
                $name .= ", $arg2" if defined $arg2;
            }
            # There is no verbose option currently
            # diag "Test::Selenium::Remote::WebElement running $cmd (@_[1..$#_])" if $self->{verbose};
 
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
        # try to pass through to Selenium::Remote::WebElement
        my $sel = 'Selenium::Remote::WebElement';
        my $sub = "${sel}::${name}";
        goto &$sub if exists &$sub;
        my ($package, $filename, $line) = caller;
        die qq(Can't locate object method "$name" via package ")
            . __PACKAGE__
            . qq(" (also tried "$sel") at $filename line $line\n);
    }
}

1;

__END__

=head1 NAME

Test::Selenium::Remote::WebElement

=head1 DESCRIPTION

A sub-class of L<Selenium::Remote::WebElement>, with several test-specific method additions.

=head1 METHODS

All methods from L<Selenium::Remote::WebElement> are available through this
module, as well as the following test-specific methods. All test names are optional.

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
