package Selenium::Remote::Driver::CanSetWebdriverContext;

# ABSTRACT: Customize the webdriver context prefix for various drivers
use Moo::Role;

has 'wd_context_prefix' => (
    is => 'lazy',
    default => sub { '/wd/hub' }
);

1;
