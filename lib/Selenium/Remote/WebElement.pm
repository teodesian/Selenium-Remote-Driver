package Selenium::Remote::WebElement;

use strict;
use warnings;
use Data::Dumper;

# This is the already instantiated Driver object, which will be passed to the
# constructor when this class is instantiated.
my $driver;

sub new {
    my ($class, $id, $parent) = @_;
    $driver = $parent;
    my $self = {
        id => $id,
    };
    bless $self, $class or die "Can't bless $class: $!";
    return $self;
}

sub click {
    my ($self) = @_;
    my $res = { 'command' => 'clickElement', 'id' => $self->{id} };
    return $driver->_execute_command($res);
}

sub get_value {
    my ($self) = @_;
    my $res = { 'command' => 'getElementValue', 'id' => $self->{id} };
    return $driver->_execute_command($res);
}

sub submit {
    my ($self) = @_;
    my $res = { 'command' => 'submitElement', 'id' => $self->{id} };
    return $driver->_execute_command($res);
}

sub send_keys {
    my ($self, $string) = @_;
    my $res = { 'command' => 'sendKeysToElement', 'id' => $self->{id} };
    my $params = {
        'value' => $string
    };
    return $driver->_execute_command($res, $params);
}

sub is_selected {
    my ($self) = @_;
    my $res = { 'command' => 'isElementSelected', 'id' => $self->{id} };
    return $driver->_execute_command($res);
}

sub set_selected {
    my ($self) = @_;
    my $res = { 'command' => 'setElementSelected', 'id' => $self->{id} };
    return $driver->_execute_command($res);
}

sub toggle {
    my ($self) = @_;
    my $res = { 'command' => 'toggleElement', 'id' => $self->{id} };
    return $driver->_execute_command($res);
}

sub is_enabled {
    my ($self) = @_;
    my $res = { 'command' => 'isElementEnabled', 'id' => $self->{id} };
    return $driver->_execute_command($res);
}

sub get_element_location {
    my ($self) = @_;
    my $res = { 'command' => 'getElementLocation', 'id' => $self->{id} };
    return $driver->_execute_command($res);
}

sub get_element_location_in_view {
    my ($self) = @_;
    my $res = { 'command' => 'getElementLocationInView', 'id' => $self->{id} };
    return $driver->_execute_command($res);
}

sub get_tag_name {
    my ($self) = @_;
    my $res = { 'command' => 'getElementTagName', 'id' => $self->{id} };
    return $driver->_execute_command($res);
}

sub clear {
    my ($self) = @_;
    my $res = { 'command' => 'clearElement', 'id' => $self->{id} };
    return $driver->_execute_command($res);
}

sub get_attribute {
    my ($self, $attr_name) = @_;
    if (not defined $attr_name) {
        return 'Attribute name not provided';
    }
    my $res = {'command' => 'getElementAttribute',
               'id' => $self->{id},
               'name' => $attr_name,
               };
    return $driver->_execute_command($res);
}

sub is_displayed {
    my ($self) = @_;
    my $res = { 'command' => 'isElementDisplayed', 'id' => $self->{id} };
    return $driver->_execute_command($res);
}

sub drag {
    my ($self, $x, $y) = @_;
    if ((not defined $x) || (not defined $y)){
        return 'X & Y pixel coordinates not provided';
    }
    my $res = {'command' => 'dragElement','id' => $self->{id}};
    my $params = {
        'x' => $x,
        'y' => $y,
    };
    return $driver->_execute_command($res, $params);
}

sub get_size {
    my ($self) = @_;
    my $res = { 'command' => 'getElementSize', 'id' => $self->{id} };
    return $driver->_execute_command($res);
}

sub get_text {
    my ($self) = @_;
    my $res = { 'command' => 'getElementText', 'id' => $self->{id} };
    return $driver->_execute_command($res);
}

sub get_css_attribute {
    my ($self, $attr_name) = @_;
    if (not defined $attr_name) {
        return 'CSS attribute name not provided';
    }
    my $res = {'command' => 'getElementValueOfCssProperty',
               'id' => $self->{id},
               'property_name' => $attr_name,
               };
    return $driver->_execute_command($res);
}

sub hover {
    my ($self) = @_;
    my $res = { 'command' => 'hoverOverElement', 'id' => $self->{id} };
    return $driver->_execute_command($res);
}


1;

=head1 SEE ALSO

For more information about Selenium , visit the website at
L<http://code.google.com/p/selenium/>.

=head1 BUGS

The Selenium issue tracking system is available online at
L<http://code.google.com/p/selenium/issues/list>.

=head1 AUTHOR

Perl Bindings for Remote Driver by Aditya Ivaturi <ivaturi@gmail.com>

=head1 LICENSE

Copyright (c) 2010 Aditya Ivaturi

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
