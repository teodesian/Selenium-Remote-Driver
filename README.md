# Selenium::Remote::Driver

[Selenium WebDriver][1] is an open source project that exposes an API
for browser automation. Selenium::Remote::Driver is a set of
Perl bindings to that API that allow you to write automated browser
tests in Perl, taking advantage of Selenium's strong ecosystem.

[1]: https://code.google.com/p/selenium/

## Installation

    cpanm Selenium::Remote::Driver

To install from this repository, clone the repo, get Dist::Zilla, and:

    dzil installdeps --missing | cpanm
    dzil install

## Usage

You'll need a Remote WebDriver Server running somewhere. You can
download a [selenium-standalone-server.jar][j] and run one locally, or
you can point your job at Saucelabs and let them handle the Remote
WebDriver.

### Locally

    use Selenium::Remote::Driver;

    my $driver = Selenium::Remote::Driver->new;
    $driver->get('http://www.google.com');
    print $driver->get_title();
    $driver->quit();

[j]: http://selenium-release.storage.googleapis.com/index.html

## Unit Tests

This module uses LWP::Protocol::PSGI to facilitate unit
tests. LWP::Protocol::PSGI overrides the LWP HTTP/HTTPS & this allows
us to "mock" the interaction with WebDriver Server. In regular
instances you should be running the tests against the mocked
recording, which are stored in t/mock-recordings. If you want to run
the tests live against the WebDriver server, set an environment
variable WD_MOCKING_RECORD to 1. This will force the unit tests to run
tests against the WebDriver server & also save the traffic
(request/response) in t/mock-recordings.  Either reset the environment
variable or set it to 0 to revert to mocking the traffic.

## Support and Documentation

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Selenium::Remote::Driver
    perldoc Selenium::Remote::WebElement

Please file all bugs for this module at:

    https://github.com/gempesaw/Selenium-Remote-Driver/issues

You can also find some supporting docs at:

    https://github.com/gempesaw/Selenium-Remote-Driver/wiki

## LICENSE AND COPYRIGHT

Copyright (c) 2010-2011 Aditya Ivaturi, Gordon Child

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
