use Selenium::Remote::Driver;

#my $driver = new Selenium::Remote::Driver;
my $driver = new Selenium::Remote::Driver(browser_name => 'internet explorer',
                                          platform => 'WINDOWS');
$driver->get("http://www.google.com");
print $driver->get_title();
$driver->quit();
