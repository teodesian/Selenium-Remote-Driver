package Selenium::Firefox::Profile;

# ABSTRACT: Use custom profiles with Selenium::Remote::Driver

use strict;
use warnings;

use Archive::Zip qw( :ERROR_CODES );
use Archive::Extract;
use Carp qw(croak);
use Cwd qw(abs_path);
use File::Copy qw(copy);
use File::Temp;
use File::Basename qw(dirname);
use JSON qw/decode_json/;
use MIME::Base64;
use Scalar::Util qw(blessed looks_like_number);

=head1 DESCRIPTION

You can use this module to create a custom Firefox Profile for your
Selenium tests. Currently, you can set browser preferences and add
extensions to the profile before passing it in the constructor for a
new Selenium::Remote::Driver.

=head1 SYNPOSIS

    use Selenium::Remote::Driver;
    use Selenium::Remote::Driver::Firefox::Profile;

    my $profile = Selenium::Remote::Driver::Firefox::Profile->new;
    $profile->set_preference(
        'browser.startup.homepage' => 'http://www.google.com',
        'browser.cache.disk.capacity' => 358400
    );

    $profile->set_boolean_preference(
        'browser.shell.checkDefaultBrowser' => 0
    );

    $profile->add_extension('t/www/redisplay.xpi');

    my $driver = Selenium::Remote::Driver->new(
        'firefox_profile' => $profile
    );

    $driver->get('http://www.google.com');
    print $driver->get_title();

=cut

sub new {
    my $class = shift;

    # TODO: add handling for a pre-existing profile folder passed into
    # the constructor

    # TODO: accept user prefs, boolean prefs, and extensions in
    # constructor
    my $self = {
        profile_dir => File::Temp->newdir(),
        user_prefs => {},
        extensions => []
      };
    bless $self, $class or die "Can't bless $class: $!";

    return $self;
}

=method set_preference

Set string and integer preferences on the profile object. You can set
multiple preferences at once. If you need to set a boolean preference,
either use JSON::true/JSON::false, or see C<set_boolean_preference()>.

    $profile->set_preference("quoted.integer.pref" => '"20140314220517"');
    # user_pref("quoted.integer.pref", "20140314220517");

    $profile->set_preference("plain.integer.pref" => 9005);
    # user_pref("plain.integer.pref", 9005);

    $profile->set_preference("string.pref" => "sample string value");
    # user_pref("string.pref", "sample string value");

=cut

sub set_preference {
    my ($self, %prefs) = @_;

    foreach (keys %prefs) {
        my $value = $prefs{$_};
        my $clean_value = '';

        if ( JSON::is_bool($value) ) {
            $self->set_boolean_preference($_, $value );
            next;
        }
        elsif ($value =~ /^(['"]).*\1$/ or looks_like_number($value)) {
            # plain integers: 0, 1, 32768, or integers wrapped in strings:
            # "0", "1", "20140204". in either case, there's nothing for us
            # to do.
            $clean_value = $value;
        }
        else {
            # otherwise it's hopefully a string that we'll need to
            # quote on our own
            $clean_value = '"' . $value . '"';
        }

        $self->{user_prefs}->{$_} = $clean_value;
    }
}

=method set_boolean_preference

Set preferences that require boolean values of 'true' or 'false'. You
can set multiple preferences at once. For string or integer
preferences, use C<set_preference()>.

    $profile->set_boolean_preference("false.pref" => 0);
    # user_pref("false.pref", false);

    $profile->set_boolean_preference("true.pref" => 1);
    # user_pref("true.pref", true);

=cut

sub set_boolean_preference {
    my ($self, %prefs) = @_;

    foreach (keys %prefs) {
        my $value = $prefs{$_};

        $self->{user_prefs}->{$_} = $value ? 'true' : 'false';
    }
}

=method get_preference

Retrieve the computed value of a preference. Strings will be double
quoted and boolean values will be single quoted as "true" or "false"
accordingly.

    $profile->set_boolean_preference("true.pref" => 1);
    print $profile->get_preference("true.pref") # true

    $profile->set_preference("string.pref" => "an extra set of quotes");
    print $profile->get_preference("string.pref") # "an extra set of quotes"

=cut

sub get_preference {
    my ($self, $pref) = @_;

    return $self->{user_prefs}->{$pref};
}

=method add_extension

Add an existing C<.xpi> to the profile by providing its path. This
only works with packaged C<.xpi> files, not plain/un-packed extension
directories.

    $profile->add_extension('t/www/redisplay.xpi');

=cut

sub add_extension {
    my ($self, $xpi) = @_;

    croak 'File not found: ' . $xpi unless -e $xpi;
    my $xpi_abs_path = abs_path($xpi);
    croak '$xpi_abs_path: extensions must be in .xpi format' unless $xpi_abs_path =~ /\.xpi$/;

    push (@{$self->{extensions}}, $xpi_abs_path);
}

=method add_webdriver

Primarily for internal use, we add the webdriver extension to the
current Firefox profile.

=cut

sub add_webdriver {
    my ($self, $port) = @_;

    my $this_dir = dirname(abs_path(__FILE__));
    my $webdriver_extension = $this_dir . '/webdriver.xpi';
    my $default_prefs_filename = $this_dir . '/webdriver_prefs.json';

    my $json;
    {
        local $/;
        open (my $fh, '<', $default_prefs_filename);
        $json = <$fh>;
        close ($fh);
    }
    my $webdriver_prefs = decode_json($json);

    # TODO: Let the user's mutable preferences persist instead of
    # overwriting them here.
    $self->set_preference(%{ $webdriver_prefs->{mutable} });
    $self->set_preference(%{ $webdriver_prefs->{frozen} });

    $self->add_extension($webdriver_extension);
    $self->set_preference('webdriver_firefox_port', $port);
}

sub _encode {
    my $self = shift;

    # The remote webdriver accepts the Firefox profile as a base64
    # encoded zip file
    $self->_layout_on_disk();

    my $zip = Archive::Zip->new();
    my $dir_member = $zip->addTree( $self->{profile_dir} );

    my $string = "";
    open (my $fh, ">", \$string);
    binmode($fh);
    unless ( $zip->writeToFileHandle($fh) == AZ_OK ) {
        die 'write error';
    }

    return encode_base64($string);
}

sub _layout_on_disk {
    my $self = shift;

    $self->_write_preferences();
    $self->_install_extensions();

    return $self->{profile_dir};
}

sub _write_preferences {
    my $self = shift;

    my $userjs = $self->{profile_dir} . "/user.js";
    open (my $fh, ">>", $userjs)
        or die "Cannot open $userjs for writing preferences: $!";

    foreach (keys %{$self->{user_prefs}}) {
        print $fh 'user_pref("' . $_ . '", ' . $self->get_preference($_) . ');' . "\n";
    }
    close ($fh);
}

sub _install_extensions {
    my $self = shift;
    my $extension_dir = $self->{profile_dir} . "/extensions/";
    mkdir $extension_dir unless -d $extension_dir;

    # TODO: handle extensions that need to be unpacked
    foreach (@{$self->{extensions}}) {
        # For Firefox to recognize the extension, we have to put the
        # .xpi in the /extensions/ folder and change the filename to
        # its id, which is found in the install.rdf in the root of the
        # zip.
        my $ae = Archive::Extract->new(
            archive => $_,
            type => "zip"
        );

        $Archive::Extract::PREFER_BIN = 1;
        my $tempDir = File::Temp->newdir();
        $ae->extract( to => $tempDir );
        my $install = $ae->extract_path();
        $install .= '/install.rdf';

        open (my $fh, "<", $install)
            or croak "No install.rdf inside $_: $!";
        my (@file) = <$fh>;
        close ($fh);

        my @name = grep { chomp; $_ =~ /<em:id>[^{]/ } @file;
        $name[0] =~ s/.*<em:id>(.*)<\/em:id>.*/$1/;

        my $xpi_dest = $extension_dir . $name[0] . ".xpi";
        copy($_, $xpi_dest)
            or croak "Error copying $_ to $xpi_dest : $!";
    }
}

1;

__END__

=head1 SEE ALSO

http://kb.mozillazine.org/About:config_entries
https://developer.mozilla.org/en-US/docs/Mozilla/Preferences/A_brief_guide_to_Mozilla_preferences
