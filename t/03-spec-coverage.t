#!perl
use strict;
use warnings;

use Test::More;

unless($ENV{RELEASE_TESTING}) {
  plan(skip_all=>"Author tests not required for installation.");
}

eval {use LWP::Simple;};
plan skip_all => "need LWP::Simple" if $@;
use Selenium::Remote::Commands;

my $uri  = "http://selenium.googlecode.com/svn/wiki/JsonWireProtocol.wiki";
my $data = get($uri);
plan skip_all => "need internet connection to run spec test" if !$data;

my $todo_list = {
   'GET session/:sessionId/orientation'                    => 1,
   'POST session/:sessionId/orientation'                   => 1,
   'POST session/:sessionId/ime/deactivate'                => 1,
   'GET session/:sessionId/ime/activated'                  => 1,
   'POST session/:sessionId/ime/activate'                  => 1,
   'GET session/:sessionId/ime/active_engine'              => 1,
   'GET session/:sessionId/ime/available_engines'          => 1,
   'POST session/:sessionId/touch/click'                   => 1,
   'POST session/:sessionId/touch/down'                    => 1,
   'POST session/:sessionId/touch/up'                      => 1,
   'GET sessions'                                          => 1,
   'POST session/:sessionId/window/:windowHandle/size'     => 1,
   'GET session/:sessionId/window/:windowHandle/size'      => 1,
   'POST session/:sessionId/window/:windowHandle/position' => 1,
   'GET session/:sessionId/window/:windowHandle/position'  => 1,
   'POST session/:sessionId/keys'                          => 1,
   'GET session/:sessionId/location'                       => 1,
   'POST session/:sessionId/location'                      => 1,
   'GET session/:sessionId/local_storage'                  => 1,
   'POST session/:sessionId/local_storage'                 => 1,
   'DELETE session/:sessionId/local_storage'               => 1,
   'GET session/:sessionId/local_storage/key/:key'         => 1,
   'DELETE session/:sessionId/local_storage/key/:key'      => 1,
   'GET session/:sessionId/local_storage/size'             => 1,
   'GET session/:sessionId/session_storage'                => 1,
   'POST session/:sessionId/session_storage'               => 1,
   'DELETE session/:sessionId/session_storage'             => 1,
   'GET session/:sessionId/session_storage/key/:key'       => 1,
   'DELETE session/:sessionId/session_storage/key/:key'    => 1,
   'GET session/:sessionId/session_storage/size'           => 1,
   'POST session/:sessionId/log'                           => 1,
   'GET session/:sessionId/log/types'                      => 1,
   'GET session/:sessionId/application_cache/status'       => 1,
};
my @lines = split(/\n/, $data);
my @methods;

for my $line (@lines) {
  if ($line =~
/\|\|\s*(GET|POST|DELETE)\s*\|\|\s*\[\S*\s+\/([^\]]*)\]\s*\|\|\s*([^\|]*?)\s*\|\|/
    ) {
    my $method = {method => $1, path => $2, desc => $3};
    push @methods, $method;
  }
}
my $commands = Selenium::Remote::Commands->new->get_cmds;
SOURCE_COMMAND: for my $method_source (@methods) {
  my $command = "$method_source->{method} $method_source->{path}";
  my $msg     = "Looking for '$command'";
  for my $method_local (values %{$commands}) {
    if (  $method_local->{url} eq $method_source->{path}
      and $method_local->{method} eq $method_source->{method}) {
      pass($msg);
      next SOURCE_COMMAND;
    }
  }
TODO: {
    local $TODO = "need to create command" if $todo_list->{$command};
    fail($msg);
    diag("Add this to lib/Selenium/Remote/Commands.pm:

#        '$method_source->{path}'     => {
#                          'method' => '$method_source->{method}',
#                          'url'    => '$method_source->{path}'
#        },

or add this to t/03-spec-coverage.t, to the hash %todo_list:

# '$command' => 1,

\n");
  }
}

LOCAL_COMMAND: for my $method_local (values %{$commands}) {
  my $msg = "extra command $method_local->{method} $method_local->{url}";
  for my $method_source (@methods) {
    if (  $method_local->{url} eq $method_source->{path}
      and $method_local->{method} eq $method_source->{method}) {
      next LOCAL_COMMAND;
    }
  }
TODO: {
    local $TODO = "Investigate extra methods";
    fail($msg);
  }
}

done_testing;
