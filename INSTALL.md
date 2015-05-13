## Installation

It's probably easiest to use the `cpanm` or `CPAN` commands:

```bash
$ cpanm Selenium::Remote::Driver
```

If you want to install from this repository, you have a few options;
see the [installation docs][] for more details.

[installation docs]: /install.md

### With Dist::Zilla

If you have Dist::Zilla, it's straightforward:

```bash
$ dzil listdeps --missing | cpanm
$ dzil install
```

### Without Dist::Zilla

We maintain two branches that have `Makefile.PL`:
[`cpan`][cpan-branch] and [`build/master`][bm-branch]. The `cpan`
branch is only updated every time we release to the CPAN, and it is
not kept up to date with master. The `build/master` branch is an
up-to-date copy of the latest changes in master, and will usually
contain changes that have not made it to a CPAN release yet.

To get either of these, you can use the following, (replacing
"build/master" with "cpan" if desired):

```bash
$ cpanm -v git://github.com/gempesaw/Selenium-Remote-Driver.git@build/master
```

Or, without `cpanm` and/or without the `git://` protocol:

```bash
$ git clone https://github.com/gempesaw/Selenium-Remote-Driver --branch build/master --single-branch --depth 1
$ cd Selenium-Remote-Driver
$ perl Makefile.PL
```

Note that due to POD::Weaver, the line numbers between these generated
branches and the master branch are unfortunately completely
incompatible.

[cpan-branch]: https://github.com/gempesaw/Selenium-Remote-Driver/tree/cpan
[bm-branch]: https://github.com/gempesaw/Selenium-Remote-Driver/tree/build/master

### Viewing dependencies

You can also use `cpanm` to help you with dependencies after you've
cloned the repository:

```bash
$ cpanm --showdeps .
```
