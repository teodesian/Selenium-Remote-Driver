use strict;
use warnings;

use Selenium::Waiter;

use FindBin;
use lib $FindBin::Bin . '/lib';
use Test::More;

my $res;

subtest 'basic' => sub {
    $res = wait_until { 1 };
    is $res, 1, 'right return value';

    $res = wait_until { 0 } timeout => 1;
    is $res, '', 'right return value';
};

subtest 'exception' => sub {
    my @warning;
    local $SIG{__WARN__} = sub { push( @warning, $_[0] ) };

    $res = wait_until { die 'case1' } debug => 0, timeout => 1;
    is $res, '', 'right return value';
    is( scalar @warning, 1, 'right number of warnings' );
    like( $warning[0], qr{^case1}, 'right warning' );

    @warning = ();
    eval {
        $res = wait_until { die 'case2' } die => 1, timeout => 1;
    };
    like $@, qr{case2}, 'right error';
    is $res, '',        'right return value';
    is( scalar @warning, 0, 'right number of warnings' );

    @warning = ();
    $res     = wait_until { 0 } debug => 1, timeout => 1;
    is $res, '', 'right return value';
    is( scalar @warning, 1, 'right number of warnings' );
    like( $warning[0], qr{timeout}i, 'timeout is reported' );
};

done_testing;
