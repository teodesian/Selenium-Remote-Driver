use strict;
use warnings;

# TODO: find another way to do this checking, this is so fragile
use Selenium::Remote::Commands;
use Test::More;

unless($ENV{RELEASE_TESTING}) {
  plan(skip_all=>"Author tests not required for installation.");
}

my $comm = Selenium::Remote::Commands->new->get_cmds;
for my $command (keys %{$comm}) {
  my $found_command = 0;
  for my $file (
    qw{lib/Selenium/Remote/Driver.pm
    lib/Selenium/Remote/WebElement.pm
    lib/Selenium/Firefox.pm}
    ) {
    open(my $fh, '<', $file) or die "Couldn't open file $file";
    for (<$fh>) {
      if (/'?command'?\s*=>\s*'$command'/
       or /{'?commands'?}->{'?$command'?}/) {
        pass("find $command");
        $found_command = 1;
      }
    }
  }
  if (!$found_command) {
    fail("find $command");
  }
}

done_testing;

1;
