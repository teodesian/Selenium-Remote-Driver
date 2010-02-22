package Selenium::Remote::Commands;

use strict;
use warnings;

use String::TT qw/tt/;

sub new {
    my $class = shift;
    my $self = {
        'addCookie' => {
                        'method' => 'POST',
                        'url' => "session/[% session_id %]/[% context %]/cookie"
        },
        'goBack' => {
                      'method' => 'POST',
                      'url'    => "session/[% session_id %]/[% context %]/back"
        },
        'clearElement' => {
               'method' => 'POST',
               'url' =>
                 "session/[% session_id %]/[% context %]/element/[% id %]/clear"
        },
        'clickElement' => {
               'method' => 'POST',
               'url' =>
                 "session/[% session_id %]/[% context %]/element/[% id %]/click"
        },
        'close' => {
                     'method' => 'DELETE',
                     'url'    => "session/[% session_id %]/[% context %]/window"
        },
        'getCurrentUrl' => {
                           'method' => 'GET',
                           'url' => "session/[% session_id %]/[% context %]/url"
        },
        'deleteAllCookies' => {
                        'method' => 'DELETE',
                        'url' => "session/[% session_id %]/[% context %]/cookie"
        },
        'deleteCookie' => {
             'method' => 'DELETE',
             'url' => "session/[% session_id %]/[% context %]/cookie/[% name %]"
        },
        'dragElement' => {
                'method' => 'POST',
                'url' =>
                  "session/[% session_id %]/[% context %]/element/[% id %]/drag"
        },
        'elementEquals' => {
            'method' => 'GET',
            'url' =>
"session/[% session_id %]/[% context %]/element/[% id %]/equals/[% other %]"
        },
        'executeScript' => {
                       'method' => 'POST',
                       'url' => "session/[% session_id %]/[% context %]/execute"
        },
        'findElement' => {
                       'method' => 'POST',
                       'url' => "session/[% session_id %]/[% context %]/element"
        },
        'findElements' => {
                      'method' => 'POST',
                      'url' => "session/[% session_id %]/[% context %]/elements"
        },
        'findChildElement' => {
            'method' => 'POST',
            'url' =>
"session/[% session_id %]/[% context %]/element/[% id %]/element/[% using %]"
        },
        'findChildElements' => {
            'method' => 'POST',
            'url' =>
"session/[% session_id %]/[% context %]/element/[% id %]/elements/[% using %]"
        },
        'goForward' => {
                       'method' => 'POST',
                       'url' => "session/[% session_id %]/[% context %]/forward"
        },
        'get' => {
                   'method' => 'POST',
                   'url'    => "session/[% session_id %]/[% context %]/url"
        },
        'getActiveElement' => {
                'method' => 'POST',
                'url' => "session/[% session_id %]/[% context %]/element/active"
        },
        'getAllCookies' => {
                        'method' => 'GET',
                        'url' => "session/[% session_id %]/[% context %]/cookie"
        },
        'getCurrentWindowHandle' => {
                 'method' => 'GET',
                 'url' => "session/[% session_id %]/[% context %]/window_handle"
        },
        'getElementAttribute' => {
            'method' => 'GET',
            'url' =>
"session/[% session_id %]/[% context %]/element/[% id %]/attribute/[% name %]"
        },
        'getElementLocation' => {
            'method' => 'GET',
            'url' =>
              "session/[% session_id %]/[% context %]/element/[% id %]/location"
        },
        'getElementSize' => {
                'method' => 'GET',
                'url' =>
                  "session/[% session_id %]/[% context %]/element/[% id %]/size"
        },
        'getElementText' => {
                'method' => 'GET',
                'url' =>
                  "session/[% session_id %]/[% context %]/element/[% id %]/text"
        },
        'getElementValue' => {
               'method' => 'GET',
               'url' =>
                 "session/[% session_id %]/[% context %]/element/[% id %]/value"
        },
        'getSpeed' => {
                        'method' => 'GET',
                        'url' => "session/[% session_id %]/[% context %]/speed"
        },
        'getElementTagName' => {
                'method' => 'GET',
                'url' =>
                  "session/[% session_id %]/[% context %]/element/[% id %]/name"
        },
        'getTitle' => {
                        'method' => 'GET',
                        'url' => "session/[% session_id %]/[% context %]/title"
        },
        'getElementValueOfCssProperty' => {
            'method' => 'GET',
            'url' =>
"session/[% session_id %]/[% context %]/element/[% id %]/css/[% property_name %]"
        },
        'getVisible' => {
                       'method' => 'GET',
                       'url' => "session/[% session_id %]/[% context %]/visible"
        },
        'getWindowHandles' => {
                'method' => 'GET',
                'url' => "session/[% session_id %]/[% context %]/window_handles"
        },
        'hoverOverElement' => {
               'method' => 'POST',
               'url' =>
                 "session/[% session_id %]/[% context %]/element/[% id %]/hover"
        },
        'isElementDisplayed' => {
            'method' => 'GET',
            'url' =>
"session/[% session_id %]/[% context %]/element/[% id %]/displayed"
        },
        'isElementEnabled' => {
             'method' => 'GET',
             'url' =>
               "session/[% session_id %]/[% context %]/element/[% id %]/enabled"
        },
        'isElementSelected' => {
            'method' => 'GET',
            'url' =>
              "session/[% session_id %]/[% context %]/element/[% id %]/selected"
        },
        'newSession' => {
                          'method' => 'POST',
                          'url'    => 'session'
        },
        'getPageSource' => {
                        'method' => 'GET',
                        'url' => "session/[% session_id %]/[% context %]/source"
        },
        'quit' => {
                    'method' => 'DELETE',
                    'url'    => "session/[% session_id %]"
        },
        'refresh' => {
                       'method' => 'POST',
                       'url' => "session/[% session_id %]/[% context %]/refresh"
        },
        'screenshot' => {
                    'method' => 'GET',
                    'url' => "session/[% session_id %]/[% context %]/screenshot"
        },
        'sendKeysToElement' => {
               'method' => 'POST',
               'url' =>
                 "session/[% session_id %]/[% context %]/element/[% id %]/value"
        },
        'setElementSelected' => {
            'method' => 'POST',
            'url' =>
              "session/[% session_id %]/[% context %]/element/[% id %]/selected"
        },
        'setSpeed' => {
                        'method' => 'POST',
                        'url' => "session/[% session_id %]/[% context %]/speed"
        },
        'setVisible' => {
                       'method' => 'POST',
                       'url' => "session/[% session_id %]/[% context %]/visible"
        },
        'submitElement' => {
              'method' => 'POST',
              'url' =>
                "session/[% session_id %]/[% context %]/element/[% id %]/submit"
        },
        'switchToFrame' => {
                'method' => 'POST',
                'url' => "session/[% session_id %]/[% context %]/frame/[% id %]"
        },
        'switchToWindow' => {
             'method' => 'POST',
             'url' => "session/[% session_id %]/[% context %]/window/[% name %]"
        },
        'toggleElement' => {
              'method' => 'POST',
              'url' =>
                "session/[% session_id %]/[% context %]/element/[% id %]/toggle"
        },
    };

    bless $self, $class or die "Can't bless $class: $!";
    return $self;
}

# This method will replace the template & return
sub getParams {
    my ($self, $command, $args) = @_;
    if (!(defined $args->{'session_id'})) {
        return;
    }
    my $data = {};

    # TT does lexical template replacement, so we need exact name of the vars.
    my $session_id = $args->{'session_id'};
    my $context = (defined $args->{'context'}) ? $args->{'context'} : 'context';
    my $id      = $args->{'id'};
    my $name    = $args->{'name'};
    my $using   = $args->{'using'};

    $data->{'method'} = $self->{$command}->{'method'};
    $data->{'url'}    = tt $self->{$command}->{'url'};

    return $data;
}

1;

__END__

=head1 SEE ALSO

For more information about Selenium , visit the website at
L<http://code.google.com/p/selenium/>.

=head1 BUGS

The Selenium issue tracking system is available online at
L<http://code.google.com/p/selenium/issues/list>.

=head1 AUTHOR

Perl Bindings for Remote Driver by Aditya Ivaturi <ivaturi@gmail.com>

=head1 LICENSE

Copyright (c) 2010 Juniper Networks, Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
