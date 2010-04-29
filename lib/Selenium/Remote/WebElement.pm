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





1;
