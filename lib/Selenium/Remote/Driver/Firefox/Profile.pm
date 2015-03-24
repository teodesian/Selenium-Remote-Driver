package Selenium::Remote::Driver::Firefox::Profile;

# ABSTRACT: Use custom profiles with Selenium::Remote::Driver
use strict;
use warnings;
use Selenium::Firefox::Profile;

BEGIN {
    push our @ISA, 'Selenium::Firefox::Profile';
}

=head1 DESCRIPTION

We've renamed this class to the slightly less wordy
L<Selenium::Firefox::Profile>. This is only around as an alias to
hopefully prevent old code from breaking.

=cut

1;

=head1 SEE ALSO

Selenium::Firefox::Profile
http://kb.mozillazine.org/About:config_entries
https://developer.mozilla.org/en-US/docs/Mozilla/Preferences/A_brief_guide_to_Mozilla_preferences
