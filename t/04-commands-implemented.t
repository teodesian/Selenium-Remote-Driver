use strict;
use warnings;

use Test::More tests => 3 + 1;
use Test::NoWarnings;

require_ok( "Selenium::Remote::Commands" ) || die "Module couldn't be loaded, can't continue with testing!";

subtest "All implemented commands are found" => sub {
  plan skip_all => "Author tests not required for installation." unless $ENV{'RELEASE_TESTING'};
  my @cmds2see = keys( %{ Selenium::Remote::Commands->new->get_cmds } );
  # You won't find the Gecko command in Selenium::Rmeote::Commands. This is intentional, so remove it from consideration.
  @cmds2see = grep { $_ !~ /Gecko/ } @cmds2see;
  plan 'tests' => scalar( @cmds2see );
  my @files = map { _get_file_contents($_) } qw{lib/Selenium/Remote/Driver.pm lib/Selenium/Remote/WebElement.pm lib/Selenium/Firefox.pm};
  for my $command (@cmds2see) {
    my $detector = q/['"]?command['"]?\s*[=-]{1}>\s*\{?['"]/ . $command . q/['"]\}?/;
    my $found = grep { my $contents = $_; grep { $_ =~ qr/$detector/ } @$contents } @files;
    ok( $found, "Found $command" );
  }
};

sub _get_file_contents {
  my $file = shift;
  my @contents;
  open(my $fh, '<', $file) or die "Couldn't open file $file";
  for (<$fh>) { push( @contents, $_ ) }
  return \@contents;
}

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
