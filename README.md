# Selenium::Remote::Driver

[![Build Status](https://travis-ci.org/gempesaw/Selenium-Remote-Driver.svg?branch=master)](https://travis-ci.org/gempesaw/Selenium-Remote-Driver)

[Selenium WebDriver][wd] is a test tool that allows you to write
automated web application UI tests in any programming language against
any HTTP website using any mainstream JavaScript-enabled browser. This
module is a Perl implementation of the client for the Webdriver
[JSONWireProtocol that Selenium provides.][jsonwire]

This module sends commands directly to the server using HTTP. Using
this module together with the Selenium Server, you can automatically
control any supported browser. To use this module, you need to have
already downloaded and started the
[standalone Selenium Server][standalone].

[wd]: https://code.google.com/p/selenium/
[jsonwire]: https://code.google.com/p/selenium/wiki/JsonWireProtocol
[standalone]: http://selenium-release.storage.googleapis.com/index.html

## Installation

It's probably easiest to use the `cpanm` or `CPAN` commands:

```bash
$ cpanm Selenium::Remote::Driver
```

If you want to install from this repository, you have a few options;
see the [installation docs][] for more details.

[installation docs]: /INSTALL.md

## Usage

You can either use this module with the standalone java server, or use
it to directly start the webdriver binaries for you. Note that the
latter option does _not_ require the JRE/JDK to be installed, nor does
it require the selenium standalone server (despite the name of the
main module!).

### with a standalone server

Download the standalone server and have it running on port 4444; then
the following should start up Firefox for you:

#### Locally

```perl
use strict;
use warnings;
use Selenium::Remote::Driver;

my $driver = Selenium::Remote::Driver->new;
$driver->get('http://www.google.com');
print $driver->get_title . "\n"; # "Google"

my $query = $driver->find_element('q', 'name');
$query->send_keys('CPAN Selenium Remote Driver');

my $send_search = $driver->find_element('btnG', 'name');
$send_search->click;

# make the find_element blocking for a second to allow the title to change
$driver->set_implicit_wait_timeout(2000);
my $results = $driver->find_element('search', 'id');

print $driver->get_title . "\n"; # CPAN Selenium Remote Driver - Google Search
$driver->quit;
```

#### Saucelabs

```perl
use Selenium::Remote::Driver;

my $user = $ENV{SAUCE_USERNAME};
my $key = $ENV{SAUCE_ACCESS_KEY};

my $driver = Selenium::Remote::Driver->new(
    remote_server_addr => $user . ':' . $key . '@ondemand.saucelabs.com',
    port => 80
);

$driver->get('http://www.google.com');
print $driver->get_title();
$driver->quit();
```

There are additional usage examples on [metacpan][meta], and also
[in this project's wiki][wiki], including
[setting up the standalone server][setup], running tests on
[Internet Explorer][ie], [Chrome][chrome], [PhantomJS][pjs], and other
useful [example snippets][ex].

[wiki]: https://github.com/gempesaw/Selenium-Remote-Driver/wiki
[setup]: https://github.com/gempesaw/Selenium-Remote-Driver/wiki/Getting-Started-with-Selenium%3A%3ARemote%3A%3ADriver
[ie]: https://github.com/gempesaw/Selenium-Remote-Driver/wiki/IE-browser-automation
[chrome]: https://github.com/gempesaw/Selenium-Remote-Driver/wiki/Chrome-browser-automation
[pjs]: https://github.com/gempesaw/Selenium-Remote-Driver/wiki/PhantomJS-Headless-Browser-Automation
[ex]:
https://github.com/gempesaw/Selenium-Remote-Driver/wiki/Example-Snippets

### no standalone server

- _Firefox_: simply have the browser installed in the normal place
for your OS.

- _Chrome_: install the Chrome browser, [download Chromedriver][dcd]
and get it in your `$PATH`:

- _PhantomJS_: install the PhantomJS binary and get it in your `$PATH`

As long as the proper binary is available in your path, you should be
able to do the following:

```perl
my $firefox = Selenium::Firefox->new;
$firefox->get('http://www.google.com');

my $chrome = Selenium::Chrome->new;
$chrome->get('http://www.google.com');

my $ghost = Selenium::PhantomJS->new;
$ghost->get('http://www.google.com');
```

Note that you can also pass a `binary` argument to any of the above
classes to manually specify what binary to start:

```perl
my $chrome = Selenium::Chrome->new(binary => '~/Downloads/chromedriver');
```

See the pod for the different modules for more details.

[dcd]: https://sites.google.com/a/chromium.org/chromedriver/downloads

## Support and Documentation

There is a new mailing list available at

https://groups.google.com/forum/#!forum/selenium-remote-driver

for usage questions and ensuing discussions. If you've come across a
bug, please open an issue in the [Github issue tracker][issue]. The
POD is available in the usual places, including [metacpan][meta], and
in your shell via `perldoc`.

```bash
$ perldoc Selenium::Remote::Driver
$ perldoc Selenium::Remote::WebElement
```

[issue]: https://github.com/gempesaw/Selenium-Remote-Driver/issues
[meta]: https://metacpan.org/pod/Selenium::Remote::Driver

## Contributing

Thanks for considering contributing! The contributing guidelines are
[also in the wiki][contrib]. The documentation there also includes
information on generating new recordings via

```bash
$ perl t/bin/record.pl
```

[contrib]: https://github.com/gempesaw/Selenium-Remote-Driver/wiki/Contribution-Guide

## Copyright and License

Copyright (c) 2010-2011 Aditya Ivaturi, Gordon Child

Copyright (c) 2014 Daniel Gempesaw

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
