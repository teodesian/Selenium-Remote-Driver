package Selenium::Remote::Driver::Firefox::Profile;

# ABSTRACT: Use custom profiles with Selenium::Remote::Driver

use strict;
use warnings;

use Archive::Zip qw( :ERROR_CODES );
use Archive::Extract;
use Carp qw(croak);
use Cwd qw(abs_path);
use File::Copy qw(copy);
use File::Temp;
use MIME::Base64;
use Scalar::Util qw(blessed looks_like_number);

sub new {
    my $class = shift;

    # TODO: add handling for a pre-existing profile folder passed into
    # the constructor
    my $self = {
        profile_dir => File::Temp->newdir(),
        user_prefs => {},
        extensions => []
      };
    bless $self, $class or die "Can't bless $class: $!";

    return $self;
}

sub set_preference {
    my ($self, %prefs) = @_;

    foreach (keys %prefs) {
        my $value = $prefs{$_};
        my $clean_value = '';

        if (blessed($value) and $value->isa("JSON::Boolean")) {
            $clean_value = $value ? "true" : "false";
        }
        elsif ($value =~ /^(['"]).*\1$/ or looks_like_number($value)) {
            $clean_value = $value;
        }
        else {
            $clean_value = '"' . $value . '"';
        }

        $self->{user_prefs}->{$_} = $clean_value;
    }
}

sub set_preferences {
    my ($self, %prefs) = @_;
    $self->set_preference(%prefs);
}

sub get_preference {
    my ($self, $pref) = @_;

    return $self->{user_prefs}->{$pref};
}

sub add_extension {
    my ($self, $xpi) = @_;

    my $xpi_abs_path = abs_path($xpi);
    croak "$xpi_abs_path: extensions must be in .xpi format" unless $xpi_abs_path =~ /\.xpi$/;

    push (@{$self->{extensions}}, $xpi_abs_path);
}

sub path {
    my $self = shift;
    return $self->{profile_dir};
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
        or croak "Cannot open $userjs for writing preferences: $!";

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
        my $ae = Archive::Extract->new( archive => $_,
                                        type => "zip");

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

=head1 SYNPOSIS

    use Selenium::Remote::Driver;
    use Selenium::Remote::Driver::Firefox::Profile;

    my $profile = Selenium::Remote::Driver::Firefox::Profile->new();
    $profile->set_preference(
        "browser.startup.homepage" => "http://www.google.com"
       );

    $profile->add_extension('t/www/redisplay.xpi');

    my $driver = Selenium::Remote::Driver->new(
        extra_capabilities => {
            firefox_profile => $profile
        });
    $driver->get("http://www.google.com");

    print $driver->get_title();


=head1 DESCRIPTION

You can use this module to create a custom Firefox Profile for your
Selenium tests. Currently, you can set browser preferences and add
extensions to the profile before passing it in the constructor for a
new Selenium::Remote::Driver.
