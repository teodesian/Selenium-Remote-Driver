use strict;
use warnings;
use Test::More;

{
    package SetWebdriverContext;
    use Moo;
    with 'Selenium::Remote::Driver::CanSetWebdriverContext';

}

my $prefix = SetWebdriverContext->new;
ok($prefix->can('wd_context_prefix'), 'role grants wd context prefix attr');
is($prefix->wd_context_prefix, '/wd/hub', 'role has proper default webdriver context');

done_testing;
