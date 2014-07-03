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

It's probably easiest to use cpanm:

```bash
$ cpanm Selenium::Remote::Driver
```

If you want to install from this repository, you have a few options:

### With Dist::Zilla

If you have Dist::Zilla, it's straightforward:

```bash
$ dzil listdeps --missing | cpanm
$ dzil install
```

### Without Dist::Zilla

If you don't want to use Dist::Zilla, we maintain a `cpan` branch that
has a `Makefile.PL` that `cpanm` can install from:

```bash
$ cpanm -v git://github.com/gempesaw/Selenium-Remote-Driver.git@cpan
```

Or, if the `git://` protocol is blocked or you don't want to use `cpanm`

```bash
$ git clone https://github.com/gempesaw/Selenium-Remote-Driver
$ cd Selenium-Remote-Driver
$ git checkout -b cpan origin/cpan
$ perl Makefile.PL
```

### Viewing dependencies

You can also use `cpanm` to help you with dependencies after you've
cloned the repository:

```bash
$ cpanm --showdeps .
```


## Usage

You'll need a Remote WebDriver Server running somewhere. You can
download a [selenium-standalone-server.jar][standalone] and run one
locally, or you can point your driver somewhere like [Saucelabs][s].

[s]: http://saucelabs.com

### Locally

```perl
use Selenium::Remote::Driver;

my $driver = Selenium::Remote::Driver->new;
$driver->get('http://www.google.com');
print $driver->get_title();
$driver->quit();
```

### Saucelabs

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

#### NB: Problems with Webdriver 2.42.x ?

It appears that the standalone webdriver API for no-content successful
responses changed slightly in 2.42.x versions, breaking things like
`get_ok` and `set_window_size`. Your options for fixes are:

* Upgrade your version of S::R::D via your preferred method! We've
  released v0.2002 of S::R::D to CPAN, which contains the fixes to
  address this.
* Or, stick with v2.41.0 of the Selenium standalone server or lower
  for your tests. v0.2001 of S::R::D still works with v2.41.0 of the
  standalone server.

## Support and Documentation

Check out [metacpan][meta] for the POD; alternatively, after
installing, you can find documentation for this module with the
`perldoc` command.

```bash
$ perldoc Selenium::Remote::Driver
$ perldoc Selenium::Remote::WebElement
```

Please file all bugs in the [Github issue tracker][issue].

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
