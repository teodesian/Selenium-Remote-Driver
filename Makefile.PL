use inc::Module::Install;

name     'Selenium-Remote-Driver';
all_from 'lib/Selenium/Remote/Driver.pm';
author   q{"Aditya Ivaturi" <"ivaturi@gmail.com">};
license  'apache';

build_requires 'LWP::Protocol::PSGI';
build_requires 'Test::More';
requires 'LWP::UserAgent';
requires 'HTTP::Headers';
requires 'HTTP::Request';
requires 'Carp';
requires 'JSON';
requires 'Net::Ping';

resources 'bugtracker' => 'https://github.com/aivaturi/Selenium-Remote-Driver/issues';
resources 'repository' => {
    type => 'git',
    url => 'git://github.com/aivaturi/Selenium-Remote-Driver.git',
    web => 'https://github.com/aivaturi/Selenium-Remote-Driver',
};

auto_install;

WriteAll;

