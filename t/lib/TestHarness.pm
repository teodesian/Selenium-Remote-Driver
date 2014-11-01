package TestHarness;

# ABSTRACT: Take care of set up for recording/replaying mocks
use Moo;
use FindBin;
use Selenium::Remote::Mock::RemoteConnection;

=head1 SYNOPSIS

    my $harness = TestHarness->new(
        this_file => $FindBin::Script
    );
    my %selenium_args = %{ $harness->base_caps };
    unless ($harness->mocks_exist_for_platform) {
        plan skip_all => "Mocking of tests is not been enabled for this platform";
    }

=attr this_file

Required. Pass in the short name of the test file in use so we can
figure out where the corresponding recording belongs. For a test file
named C<t/01-driver.t>, we'd expect this argument to be
C<01-driver.t>.

=cut

has calling_file => (
    is => 'ro',
    init_arg => 'this_file',
    required => 1
);

has record => (
    is => 'ro',
    init_args => undef,
    default => sub {
        if (defined $ENV{WD_MOCKING_RECORD}
              && $ENV{WD_MOCKING_RECORD} == 1) {
            return 1;
        }
        else {
            return 0;
        }
    }
);

has os => (
    is => 'ro',
    init_args => undef,
    default => sub {
        my $os  = $^O;
        if ($os =~ m/(aix|freebsd|openbsd|sunos|solaris)/) {
            $os = 'linux';
        }

        return $os;
    }
);

has base_caps => (
    is => 'rw',
    lazy => 1,
    default => sub {
        my ($self) = @_;
        my $args = {
            browser_name => 'firefox',
            remote_conn => $self->mock_remote_conn
        };

        return $args;
    }
);

has mock_remote_conn => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        my ($self) = @_;
        if ($self->record) {
            return Selenium::Remote::Mock::RemoteConnection->new(
                record => 1
            );
        }
        else {
            return Selenium::Remote::Mock::RemoteConnection->new(
                replay      => 1,
                replay_file => $self->mock_file
            );
        }
    }
);

has mock_file => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        my ($self) = @_;

        # Since FindBin uses a Begin block, and we're using it in the
        # tests themselves, $FindBin::Bin will already be initialized
        # to the folder that the *.t files live in - that is, `t`.
        my $mock_folder = $FindBin::Bin . '/mock-recordings/';

        my $test_name = lc($self->calling_file);
        $test_name =~ s/\.t$//;

        return $mock_folder . $test_name . '-mock-' . $self->os . '.json';
    }
);

sub mocks_exist_for_platform {
    my ($self) = @_;
    if ($self->record) {
        return 1;
    }
    else {
        # When we're replaying a test, we need recordings to be able
        # to do anything
        return -e $self->mock_file;
    }
}

sub DEMOLISH {
    my ($self) = @_;
    if ($self->record) {
        $self->mock_remote_conn->dump_session_store($self->mock_file);
    }
}

1;
