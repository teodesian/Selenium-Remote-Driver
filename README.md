# Selenium::Remote::Driver

[![Build Status](https://travis-ci.org/gempesaw/Selenium-Remote-Driver.svg?branch=master)](https://travis-ci.org/gempesaw/Selenium-Remote-Driver)

[Selenium WebDriver][1] is an open source project that exposes an API
for browser automation, among other things. `Selenium::Remote::Driver`
is a set of Perl bindings to that API that allow you to write
automated browser tests in Perl, taking advantage of Selenium's strong
ecosystem.

[1]: https://code.google.com/p/selenium/

## Installation

```bash
$ cpanm Selenium::Remote::Driver
```

To install from this repository, clone it, get `Dist::Zilla`, and:

```bash
$ dzil installdeps --missing | cpanm
$ dzil install
```

## Usage

You'll need a Remote WebDriver Server running somewhere. You can
download a [selenium-standalone-server.jar][j] and run one locally, or
you can point your driver at [Saucelabs][s] and
let them handle the it.

### Locally

```perl
use Selenium::Remote::Driver;

my $driver = Selenium::Remote::Driver->new;
$driver->get('http://www.google.com');
print $driver->get_title();
$driver->quit();
```

[j]: http://selenium-release.storage.googleapis.com/index.html
[s]: https://saucelabs.com

## Unit Tests

This module uses `LWP::Protocol::PSGI` to facilitate unit
tests. `LWP::Protocol::PSGI` overrides the LWP HTTP/HTTPS & this allows
us to "mock" the interaction with WebDriver Server. In regular
instances you should be running the tests against the mocked
recording, which are stored in t/mock-recordings. If you want to run
the tests live against the WebDriver server, set an environment
variable WD\_MOCKING\_RECORD to 1. This will force the unit tests to run
tests against the WebDriver server & also save the traffic
(request/response) in `t/mock-recordings`.

There is a short script that will handle the environment variable and
generate recordings for you:

```bash
$ perl t/bin/generate-recordings.pl
```

## Support and Documentation

After installing, you can find documentation for this module with the
perldoc command.

```bash
$ perldoc Selenium::Remote::Driver
$ perldoc Selenium::Remote::WebElement
```

Please file all bugs in the [Github issue tracker][issue].

You can also find some supporting docs in the [Github Wiki][wiki].

[issue]: https://github.com/gempesaw/Selenium-Remote-Driver/issues
[wiki]: https://github.com/gempesaw/Selenium-Remote-Driver/wiki

## License and Copyright

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
