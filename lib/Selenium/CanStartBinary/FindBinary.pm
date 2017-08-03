package Selenium::CanStartBinary::FindBinary;

use strict;
use warnings;

# ABSTRACT: Coercions for finding webdriver binaries on your system
use Cwd qw/abs_path/;
use File::Which qw/which/;
use IO::Socket::INET;
use Selenium::Firefox::Binary qw/firefox_path/;

require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/coerce_simple_binary coerce_firefox_binary/;

use constant IS_WIN => $^O eq 'MSWin32';

=for Pod::Coverage *EVERYTHING*

=cut

sub coerce_simple_binary {
    my ($executable) = @_;

    my $manual_binary = _validate_manual_binary($executable);
    if ($manual_binary) {
        return $manual_binary;
    }
    else {
        return _naive_find_binary($executable);
    }
}

sub coerce_firefox_binary {
    my ($executable) = @_;

    my $manual_binary = _validate_manual_binary($executable);
    if ($manual_binary) {
        return $manual_binary;
    }
    else {
        return firefox_path();
    }
}

sub _validate_manual_binary {
    my ($executable) = @_;

    my $abs_executable = eval {
        my $path = abs_path($executable);
        die unless -e $path;
        $path
    };

    if ( $abs_executable ) {
        if ( -x $abs_executable || IS_WIN ) {
            return $abs_executable;
        }
        else {
            die 'The binary at ' . $executable . ' is not executable. Choose the correct file or chmod +x it as needed.';
        }
    }
}

sub _naive_find_binary {
    my ($executable) = @_;

    my $naive_binary = which($executable);
    if (defined $naive_binary) {
        return $naive_binary;
    }
    else {
        warn qq(Unable to find the $executable binary in your \$PATH.);
        return;
    }
}
