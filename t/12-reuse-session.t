use strict;
use warnings;

use Test::More;
use Test::MockModule;
use Test::Selenium::Remote::Driver;
use Selenium::Remote::Mock::RemoteConnection;

use FindBin;
use lib $FindBin::Bin . '/lib';
use TestHarness;

$Selenium::Remote::Driver::FORCE_WD2 = 1;

my $harness = TestHarness->new(
    this_file => $FindBin::Script
);

my @browsers = qw/chrome/;

foreach (@browsers) {
    my @mock_session_ids = qw{2257c1cf-17d9-401a-a13b-fc7a279d7db5 dddddddd-17d9-401a-a13b-fc7a279d7db5 17c83f3a-3f23-4ffc-a50f-06ba5f5202d1};

    my $mock = Test::MockModule->new('Selenium::Remote::Driver');
    $mock->redefine('new_session', sub { my $s = shift; $s->{session_id} //= shift @mock_session_ids } );


    my %selenium_args = (
        default_finder => 'css',
        javascript     => 1,
        %{ $harness->base_caps },
        browser_name   => $_,
    );

    my $s1 = Test::Selenium::Remote::Driver->new(
        %selenium_args
    );
    my $s2 = Test::Selenium::Remote::Driver->new(
        %selenium_args,
        auto_close => 0,
        session_id => $s1->session_id,
    );

    my $s3 = Test::Selenium::Remote::Driver->new(
        %selenium_args,
    );

    is($s1->session_id, $s2->session_id, "session_id is reused when specified");
    isnt($s1->session_id, $s3->session_id, "session_id not reused");
    pass("session_id.1=". $s2->session_id);
    pass("session_id.2=". $s2->session_id);
    pass("session_id.3=". $s3->session_id);

    my $perl_title = 'The Perl Programming Language - www.perl.org';
    my $cpan_title = 'The Comprehensive Perl Archive Network - www.cpan.org';

    $s1->get_ok('http://perl.org/');
    $s1->title_is($perl_title, 'perl.org title matches correctly');

    $s3->get_ok('http://perl.org/');
    $s3->title_is($perl_title, 'perl.org title matches correctly');
}

done_testing;
