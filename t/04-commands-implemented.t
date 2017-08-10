use strict;
use warnings;

use Test::More tests => 3 + 1;
use Test::NoWarnings;

# Assume we're not using dzil test unless we're doing that
if( !grep { index( $_, ".build" ) != -1 } @INC ) {
  require Cwd;
  require File::Basename;
  push( @INC, File::Basename::dirname(Cwd::abs_path(__FILE__)) . "/../lib" );
}

require_ok( "Selenium::Remote::Commands" ) || die;

subtest "All implemented commands are found" => sub {
  plan skip_all => "Author tests not required for installation." unless $ENV{'RELEASE_TESTING'};
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
        if ( /'?command'?\s*=>\s*'$command'/ or /{'?commands'?}->\{'?$command'?}/) {
          pass("find $command");
          $found_command = 1;
        }
      }
    }
    if (!$found_command && $command !~ /Gecko/) {
      fail("find $command");
    }
  }
};

subtest "get_params() works as intended" => sub {
  no warnings qw{redefine once};
  # I know this is somewhat whimsical as an URL, but hey, it is a test.
  local *Selenium::Remote::Commands::get_url = sub { return "http://foo.bar.baz:4444/session/:sessionId:id:name:propertyName:other:windowHandle" };
  local *Selenium::Remote::Commands::get_method = sub { return 'methodMan'; };
  local *Selenium::Remote::Commands::get_no_content_success = sub { return 'zippy' };
  my $model_return = {
    'method' => 'methodMan',
    'no_content_success' => 'zippy',
    'url' => 'http://foo.bar.baz:4444/session/12345'
  };
  my $bogus_obj = bless( {}, "Selenium::Remote::Commands" );
  is( Selenium::Remote::Commands::get_params( $bogus_obj ), undef, "We return early when session_id not passed in" );
  is_deeply( Selenium::Remote::Commands::get_params( $bogus_obj, { 'session_id' => "12345" } ), $model_return, "Expected data returned when minimal information input" );
};

1;
