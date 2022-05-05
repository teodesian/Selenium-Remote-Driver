use strict;
use warnings;

use Test::More;
use Test::MockModule;

use Test::Selenium::Remote::Driver;
use Selenium::Remote::Mock::RemoteConnection;

$Selenium::Remote::Driver::FORCE_WD2 = 1;

use FindBin;
use lib $FindBin::Bin . '/lib';
use TestHarness;

my $harness = TestHarness->new(
    this_file => $FindBin::Script
);
my %selenium_args = %{ $harness->base_caps };

my $selfmock = Test::MockModule->new('Selenium::Remote::Driver');
$selfmock->mock('new_session', sub { my $self = shift; $self->{session_id} = "58aff7be-e46c-42c0-ae5e-571ea1c1f466"  });

# Try to find
my $t = Test::Selenium::Remote::Driver->new(
    %selenium_args
);
$t->get_ok('http://www.google.com');
$t->title_like(qr/Google/, 'head retrieved');
$t->body_like(qr/Google/, 'body retrieved');

done_testing();
