package Selenium::Firefox::Profile;

# ABSTRACT: Use custom profiles with Selenium::Remote::Driver
# TODO: convert this to Moo!

use strict;
use warnings;

use Archive::Zip qw( :ERROR_CODES );
use Carp qw(croak);
use Cwd qw(abs_path);
use File::Copy qw(copy);
use File::Temp;
use File::Basename qw(dirname);
use IO::Uncompress::Unzip 2.030 qw($UnzipError);
use JSON qw(decode_json);
use MIME::Base64;
use Scalar::Util qw(blessed looks_like_number);
use XML::Simple;

=head1 DESCRIPTION

You can use this module to create a custom Firefox Profile for your
Selenium tests. Currently, you can set browser preferences and add
extensions to the profile before passing it in the constructor for a
new L<Selenium::Remote::Driver> or L<Selenium::Firefox>.

=head1 SYNPOSIS

    use Selenium::Remote::Driver;
    use Selenium::Firefox::Profile;

    my $profile = Selenium::Firefox::Profile->new;
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

=head1 CONSTRUCTOR

=head2 new (%args)

profile_dir - <string> directory to look for the firefox profile. Defaults to a Tempdir.

=cut

sub new {
    my $class = shift;
    my %args  = @_;

    my $profile_dir;
    if ( $args{profile_dir} && -d $args{profile_dir} ) {
        $profile_dir = $args{profile_dir};
    }
    else {
        $profile_dir = File::Temp->newdir();
    }

    # TODO: accept user prefs, boolean prefs, and extensions in
    # constructor
    my $self = {
        profile_dir => $profile_dir,
        user_prefs  => {},
        extensions  => []
    };
    bless $self, $class or die "Can't bless $class: $!";

    return $self;
}

=head1 METHODS

=head2 set_preference

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
    my ( $self, %prefs ) = @_;

    foreach ( keys %prefs ) {
        my $value       = $prefs{$_};
        my $clean_value = '';

        if ( JSON::is_bool($value) ) {
            $self->set_boolean_preference( $_, $value );
            next;
        }
        elsif ( $value =~ /^(['"]).*\1$/ or looks_like_number($value) ) {

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

=head2 set_boolean_preference

Set preferences that require boolean values of 'true' or 'false'. You
can set multiple preferences at once. For string or integer
preferences, use C<set_preference()>.

    $profile->set_boolean_preference("false.pref" => 0);
    # user_pref("false.pref", false);

    $profile->set_boolean_preference("true.pref" => 1);
    # user_pref("true.pref", true);

=cut

sub set_boolean_preference {
    my ( $self, %prefs ) = @_;

    foreach ( keys %prefs ) {
        my $value = $prefs{$_};

        $self->{user_prefs}->{$_} = $value ? 'true' : 'false';
    }
}

=head2 get_preference

Retrieve the computed value of a preference. Strings will be double
quoted and boolean values will be single quoted as "true" or "false"
accordingly.

    $profile->set_boolean_preference("true.pref" => 1);
    print $profile->get_preference("true.pref") # true

    $profile->set_preference("string.pref" => "an extra set of quotes");
    print $profile->get_preference("string.pref") # "an extra set of quotes"

=cut

sub get_preference {
    my ( $self, $pref ) = @_;

    return $self->{user_prefs}->{$pref};
}

=head2 add_extension

Add an existing C<.xpi> to the profile by providing its path. This
only works with packaged C<.xpi> files, not plain/un-packed extension
directories.

    $profile->add_extension('t/www/redisplay.xpi');

=cut

sub add_extension {
    my ( $self, $xpi ) = @_;

    croak 'File not found: ' . $xpi unless -e $xpi;
    my $xpi_abs_path = abs_path($xpi);
    croak '$xpi_abs_path: extensions must be in .xpi format'
      unless $xpi_abs_path =~ /\.xpi$/;

    push( @{ $self->{extensions} }, $xpi_abs_path );
}

=head2 add_webdriver

Primarily for internal use, we set the appropriate firefox preferences
for a new geckodriver session.

=cut

sub add_webdriver {
    my ( $self, $port, $is_marionette ) = @_;

    my $prefs              = {};
    my $current_user_prefs = $self->{user_prefs};

    $self->set_preference(
        # having the user prefs here allows them to overwrite the
        # mutable loaded prefs
        %{$current_user_prefs},

        # but the frozen ones cannot be overwritten
        'webdriver_firefox_port' => $port
    );

    if ( !$is_marionette ) {
        $self->_add_webdriver_xpi;
    }

    return $self;
}


=head2 add_webdriver_xpi

Primarily for internal use. This adds the fxgoogle .xpi that is used
for webdriver communication in FF47 and older. For FF48 and newer, the
old method using an extension to orchestrate the webdriver
communication with the Firefox browser has been obsoleted by the
introduction of C<geckodriver>.

=cut

sub _add_webdriver_xpi {
    my ($self) = @_;

    my $this_dir            = dirname( abs_path(__FILE__) );
    my $webdriver_extension = $this_dir . '/webdriver.xpi';

    $self->add_extension($webdriver_extension);
}

=head2 add_marionette

Primarily for internal use, configure Marionette to the
current Firefox profile.

=cut

sub add_marionette {
    my ( $self, $port ) = @_;
    return if !$port;
    $self->set_preference( 'marionette.defaultPrefs.port', $port );
}

sub _encode {
    my $self = shift;

    # The remote webdriver accepts the Firefox profile as a base64
    # encoded zip file
    $self->_layout_on_disk();

    my $zip = Archive::Zip->new();
    $zip->addTree( $self->{profile_dir} );

    my $string = "";
    open( my $fh, ">", \$string );
    binmode($fh);
    unless ( $zip->writeToFileHandle($fh) == AZ_OK ) {
        die 'write error';
    }

    return encode_base64( $string, '' );
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
    open( my $fh, ">>", $userjs )
      or die "Cannot open $userjs for writing preferences: $!";

    foreach ( keys %{ $self->{user_prefs} } ) {
        print $fh 'user_pref("'
          . $_ . '", '
          . $self->get_preference($_) . ');' . "\n";
    }
    close($fh);
}

sub _install_extensions {
    my $self          = shift;
    my $extension_dir = $self->{profile_dir} . "/extensions/";
    mkdir $extension_dir unless -d $extension_dir;

    # TODO: handle extensions that need to be unpacked
    foreach my $xpi ( @{ $self->{extensions} } ) {

        # For Firefox to recognize the extension, we have to put the
        # .xpi in the /extensions/ folder and change the filename to
        # its id, which is found in the install.rdf in the root of the
        # zip.

        my $rdf_string = $self->_extract_install_rdf($xpi);
        my $rdf        = XMLin($rdf_string);
        my $name       = $rdf->{Description}->{'em:id'};

        my $xpi_dest = $extension_dir . $name . ".xpi";
        copy( $xpi, $xpi_dest )
          or croak "Error copying $_ to $xpi_dest : $!";
    }
}

sub _extract_install_rdf {
    my ( $self, $xpi ) = @_;

    my $unzipped = IO::Uncompress::Unzip->new($xpi)
      or die "Cannot unzip $xpi: $UnzipError";

    my $install_rdf = '';
    while ( $unzipped->nextStream ) {
        my $filename = $unzipped->getHeaderInfo->{Name};
        if ( $filename eq 'install.rdf' ) {
            my $buffer;
            while ( ( my $status = $unzipped->read($buffer) ) > 0 ) {
                $install_rdf .= $buffer;
            }
            return $install_rdf;
        }
    }

    croak
      'Invalid Firefox extension: could not find install.rdf in the .XPI at: '
      . $xpi;
}

1;

__END__

=head1 SEE ALSO

http://kb.mozillazine.org/About:config_entries
https://developer.mozilla.org/en-US/docs/Mozilla/Preferences/A_brief_guide_to_Mozilla_preferences
