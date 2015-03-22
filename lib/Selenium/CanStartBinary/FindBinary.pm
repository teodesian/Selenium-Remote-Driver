package Selenium::CanStartBinary::FindBinary;

use File::Which qw/which/;
use Cwd qw/abs_path/;
use File::Which qw/which/;
use IO::Socket::INET;
use Selenium::Firefox::Binary qw/firefox_path/;

require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/coerce_simple_binary coerce_firefox_binary/;

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

    my $abs_executable = eval { abs_path($executable) };
    if ( $abs_executable ) {
        if ( -x $abs_executable ) {
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
        warn qq(Unable to find the $naive_binary binary in your \$PATH. We'll try falling back to standard Remote Driver);
        return;
    }
}
