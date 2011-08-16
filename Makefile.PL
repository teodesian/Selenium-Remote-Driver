use inc::Module::Install;

name     'Selenium-Remote-Driver';
all_from 'lib/Selenium/Remote/Driver.pm';
author   q{"Aditya Ivaturi" <"ivaturi@gmail.com">};
license  'perl';

build_requires 'Test::More';
build_requires 'LWP::UserAgent';
build_requires 'LWP::Protocol::PSGI';
build_requires 'HTTP::Headers';
build_requires 'HTTP::Request';
build_requires 'Carp';
build_requires 'JSON';
build_requires 'Net::Ping';

auto_install;

WriteAll;

