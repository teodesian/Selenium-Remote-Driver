package Selenium::Remote::ErrorHandler;

use strict;
use warnings;

use Data::Dumper;
use Carp qw(croak);

# We're going to handle only codes that are errors.
use constant STATUS_CODE => {
                    7 => {
                            'code' => 'NO_SUCH_ELEMENT',
                            'msg'  => 'An element could not be located on the page using the given search parameters.',
                         },
                    8 => {
                            'code' => 'NO_SUCH_FRAME',
                            'msg'  => 'A request to switch to a frame could not be satisfied because the frame could not be found.',
                         },
                    9 => {
                            'code' => 'UNKNOWN_COMMAND',
                            'msg'  => 'The requested resource could not be found, or a request was received using an HTTP method that is not supported by the mapped resource.',
                         },
                    10 => {
                            'code' => 'STALE_ELEMENT_REFERENCE',
                            'msg'  => 'An element command failed because the referenced element is no longer attached to the DOM.',
                         },
                    11 => {
                            'code' => 'ELEMENT_NOT_VISIBLE',
                            'msg'  => 'An element command could not be completed because the element is not visible on the page.',
                         },
                    12 => {
                            'code' => 'INVALID_ELEMENT_STATE',
                            'msg'  => 'An element command could not be completed because the element is in an invalid state (e.g. attempting to click a disabled element).',
                         },
                    13 => {
                            'code' => 'UNKNOWN_ERROR',
                            'msg'  => 'An unknown server-side error occurred while processing the command.',
                         },
                    15 => {
                            'code' => 'ELEMENT_IS_NOT_SELECTABLE',
                            'msg'  => 'An attempt was made to select an element that cannot be selected.',
                         },
                    19 => {
                            'code' => 'XPATH_LOOKUP_ERROR',
                            'msg'  => 'An error occurred while searching for an element by XPath.',
                         },
                    23 => {
                            'code' => 'NO_SUCH_WINDOW',
                            'msg'  => 'A request to switch to a different window could not be satisfied because the window could not be found.',
                         },
                    24 => {
                            'code' => 'INVALID_COOKIE_DOMAIN',
                            'msg'  => 'An illegal attempt was made to set a cookie under a different domain than the current page.',
                         },
                    25 => {
                            'code' => 'UNABLE_TO_SET_COOKIE',
                            'msg'  => 'A request to set a cookie\'s value could not be satisfied.',
                         },
};

sub new {
    my ($class) = @_;
    
    my $self = {};
    bless $self, $class or die "Can't bless $class: $!";
    
    return $self;
}

sub process_error {
    my ($self, $resp) = @_;
    # TODO: Handle screen if it sent back with the response.
    
    my $ret;
    $ret->{'stackTrace'} = $resp->{'value'}->{'stackTrace'};
    $ret->{'error'} = $self->STATUS_CODE->{$resp->{'status'}};

    return $ret;
}

1;
