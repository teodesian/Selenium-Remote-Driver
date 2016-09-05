# Selenium::Remote::Driver [![Build Status](https://travis-ci.org/gempesaw/Selenium-Remote-Driver.svg?branch=master)](https://travis-ci.org/gempesaw/Selenium-Remote-Driver)

[Selenium WebDriver][wd] is a test tool that allows you to write
automated web application UI tests in any programming language against
any HTTP website using any mainstream JavaScript-enabled browser. This
module is a Perl implementation of the client for the Webdriver
[JSONWireProtocol that Selenium provides.][jsonwire]

[wd]: http://www.seleniumhq.org/
[jsonwire]: https://code.google.com/p/selenium/wiki/JsonWireProtocol
[standalone]: http://selenium-release.storage.googleapis.com/index.html

## Installation

It's probably easiest to use the `cpanm` or `CPAN` commands:

```bash
$ cpanm Selenium::Remote::Driver
```

If you want to install from this repository, see the
[installation docs][] for more details.

[installation docs]: /INSTALL.md

## Usage

You can use this module to directly start the webdriver servers, after
[downloading the appropriate ones][dl] and putting the servers in your
`$PATH`. This method does not require the JRE/JDK to be installed, nor
does it require the standalone server jar, despite the name of the
module. In this case, you'll want to use the appropriate class for
driver construction: either [Selenium::Chrome][],
[Selenium::Firefox][], [Selenium::PhantomJS][], or
[Selenium::InternetExplorer][].

You can also use this module with the `selenium-standalone-server.jar`
to let it handle browser start up for you, and also manage Remote
connections where the server jar is not running on the same machine as
your test script is executing. The main class for this method is
[Selenium::Remote::Driver][].

Regardless of which method you use to construct your browser object,
all of the classes use the functions listed in the S::R::Driver POD
documentation, so interacting with the browser, the page, and its
elements would be the same.

[Selenium::Firefox]: https://metacpan.org/pod/Selenium::Firefox
[Selenium::Chrome]: https://metacpan.org/pod/Selenium::Chrome
[Selenium::PhantomJS]: https://metacpan.org/pod/Selenium::PhantomJS
[Selenium::InternetExplorer]: https://metacpan.org/pod/Selenium::InternetExplorer
[Selenium::Remote::Driver]: https://metacpan.org/pod/Selenium::Remote::Driver
[dl]: #no-standalone-server

### no standalone server

- _Firefox 48 & newer_: install the Firefox browser, download
  [geckodriver][gd] and [put it in your `$PATH`][fxpath]. If the
  Firefox browser binary is not in the default place for your OS and
  we cannot locate it via `which`, you may have to specify the binary
  location during startup. We also will need to locate the Firefox
  browser; if the Firefox browser isn't in the default location, you
  must provide it during startup in the `firefox_binary` attr.

- _Firefox 47 & older_: install the Firefox browser in the default
  place for your OS. If the Firefox browser binary is not in the
  default place for your OS, you may have to specify the
  `firefox_binary` constructor option during startup.

- _Chrome_: install the Chrome browser, [download Chromedriver][dcd]
  and get `chromedriver` in your `$PATH`.

- _PhantomJS_: install the PhantomJS binary and get `phantomjs` in
  your `$PATH`. The driver for PhantomJS, Ghostdriver, is bundled with
  PhantomJS.

When the browser(s) are installed and you have the appropriate binary
in your path, you should be able to do the following:

```perl
my $firefox = Selenium::Firefox->new;
$firefox->get('http://www.google.com');

my $chrome = Selenium::Chrome->new;
$chrome->get('http://www.google.com');

my $ghost = Selenium::PhantomJS->new;
$ghost->get('http://www.google.com');
```

Note that you can also pass a `binary` argument to any of the above
classes to manually specify what binary to start. Note that this
`binary` refers to the driver server, _not_ the browser executable.

```perl
my $chrome = Selenium::Chrome->new(binary => '~/Downloads/chromedriver');
```

See the pod for the different modules for more details.

[dcd]: https://sites.google.com/a/chromium.org/chromedriver/downloads
[fxpath]: https://developer.mozilla.org/en-US/docs/Mozilla/QA/Marionette/WebDriver#Add_executable_to_system_path
[gd]: https://github.com/mozilla/geckodriver/releases

#### Breaking Changes for Selenium::Firefox in v1.0+

There are breaking changes for Selenium::Firefox from v0.2701 of S:F
to v1.0+. This is because in FF47 and older, Firefox didn't have a
separate webdriver server executable - local startup was accomplished
by starting your actual Firefox browser with a webdriver
extension. However, in FF48 and newer, Mozilla have switched to using
`geckodriver` to handle the Webdriver communication. Accordingly,
v1.0+ of Selenium::Firefox assumes the geckodriver setup which only
works for FF48 and higher:

```perl
# marionette_enabled defaults to 1 === assumes you're running FF48
my $fx48 = Selenium::Firefox->new;
my $fx48 = Selenium::Firefox->new( marionette_enabled => 1 );
```

To drive FF47 with v1.0+ of Selenium::Firefox, you must manually
disable marionette:

```perl
my $fx47 = Selenium::Firefox->new( marionette_enabled => 0 );
```

Doing so will start up your Firefox browser with the webdriver
extension. Note that in our tests, doing the old
"webdriver-extension-startup" for Firefox 48 does not work. Likewise,
`geckodriver` does not work with FF47.

### with a standalone server

Download the [standalone server][] and have it running on port 4444:

    $ java -jar selenium-server-standalone-X.XX.X.jar

As before, have the browsers themselves installed on your machine, and
download the appropriate binary server, passing its location to the
server jar during startup.

[standalone server]: http://selenium-release.storage.googleapis.com/index.html

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

If using Saucelabs, there's no need to have the standalone server
running on a local port, since Saucelabs provides it.

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
[ex]: https://github.com/gempesaw/Selenium-Remote-Driver/wiki/Example-Snippets

## Selenium IDE Plugin

[ide-plugin.js](./ide-plugin.js) is a Selenium IDE Plugin which allows
you to export tests recorded in Selenium IDE to a perl script.

### Installation in Selenium IDE

  1. Open Selenium IDE
  2. Options >> Options
  3. Formats Tab
  4. Click Add at the bottom
  5. In the name field call it 'Perl-Webdriver'
  6. Paste this entire source in the main textbox
  7. Click 'Save'
  8. Click 'Ok'
  9. Close Selenium IDE and open it again.

## Support and Documentation

There is a mailing list available at

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
[in the wiki][contrib]. The documentation there also includes
information on generating new Linux recordings for Travis.

[contrib]: https://github.com/gempesaw/Selenium-Remote-Driver/wiki/Contribution-Guide

## Copyright and License

Copyright (c) 2010-2011 Aditya Ivaturi, Gordon Child

Copyright (c) 2014-2016 Daniel Gempesaw

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
