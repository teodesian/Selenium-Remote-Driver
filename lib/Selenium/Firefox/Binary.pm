package Selenium::Firefox::Binary;

# ABSTRACT: Portable handler to start the firefox binary
use File::Which qw/which/;

require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/path/;

sub _windows_path {
    # TODO: make this slightly less dumb
    return which('firefox');
}

sub _darwin_path {
    my $default_firefox = '/Applications/Firefox.app/Contents/MacOS/firefox-bin';

    if (-e $default_firefox) {
        return $default_firefox
    }
    else {
        return which('firefox-bin');
    }
}

sub _unix_path {
    # TODO: maybe which('firefox3'), which('firefox2') ?
    return which('firefox') || '/usr/bin/firefox';
}

sub path {
    if ($^O eq 'MSWin32') {
        return _windows_path();
    }
    elsif ($^O eq 'darwin') {
        return _darwin_path();
    }
    else {
        return _unix_path;
    }
}

1;
