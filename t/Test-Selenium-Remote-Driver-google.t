#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Selenium::Remote::Driver;
use Selenium::Remote::Mock::RemoteConnection;

my $record = (defined $ENV{'WD_MOCKING_RECORD'} && ($ENV{'WD_MOCKING_RECORD'}==1))?1:0;
my $os  = $^O;
if ($os =~ m/(aix|freebsd|openbsd|sunos|solaris)/) {
    $os = 'linux';
}

my %selenium_args = ( 
    browser_name => 'firefox',
    javascript => 1
);

my $mock_file = "test-selenium-remote-driver-google-$os.json";
if (!$record && !(-e "t/mock-recordings/$mock_file")) {
    plan skip_all => "Mocking of tests is not been enabled for this platform";
}

if ($record) { 
    $selenium_args{remote_conn} = Selenium::Remote::Mock::RemoteConnection->new(record => 1);
}
else { 
    $selenium_args{remote_conn} =
      Selenium::Remote::Mock::RemoteConnection->new( replay => 1,
        replay_file => "t/mock-recordings/$mock_file" );
}

# Try to find
my $t = Test::Selenium::Remote::Driver->new(
    %selenium_args
);
$t->get_ok('http://www.google.com');
$t->title_like(qr/Google/);
$t->body_like(qr/Google/);

if ($record) { 
    $t->remote_conn->dump_session_store("t/mock-recordings/$mock_file");
}


done_testing();
