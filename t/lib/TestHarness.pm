package TestHarness;

# ABSTRACT: Take care of set up for recording/replaying mocks
use FindBin;
use Moo;
use Selenium::Remote::Mock::RemoteConnection;
use Test::More;

=head1 SYNOPSIS

    my $harness = TestHarness->new(
        this_file => $FindBin::Script
    );
    my %selenium_args = %{ $harness->base_caps };

=head1 DESCRIPTION

A setup class for all the repetitive things we need to do before
running tests. First, we're deciding whether the test is in C<record>
or C<replay> mode. If we're recording, we'll end up writing all the
HTTP request/response pairs out to L</mock_file>. If we're replaying,
we'll look for our OS-appropriate mock_file and try to read from it.

After we figure that out, we can instantiate our
Mock::RemoteConnection with the proper constructor arguments and
return that as our base_args for use in the tests! Finally, on
destruction, if we're recording, we make sure to dump out all of the
request/response pairs to the mock_file.

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

=attr record

Optional. Determines whether or not this test run should record new
mocks, or look up a previous recording to replay against them. If the
parameter is not used during construction, the default behavior is to
check for the environment variable WD_MOCKING_RECORD to be defined and
equal to 1.

=cut

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

        my $mock_file = $mock_folder . $test_name . '-mock-' . $self->os . '.json';

        # If we're replaying, we need a mock to read from. Otherwise,
        # we can't do anything
        if (not $self->record) {
            plan skip_all => "Mocking of tests is not been enabled for this platform"
              unless -e $mock_file;
        }

        return $mock_file;
    }
);

has website => (
    is => 'ro',
    default => sub {
        my ($self) = @_;
        my $port = 63636;

        return 'http://' . $self->domain . ':' . $port;
    }
);

has domain => (
    is => 'ro',
    default => sub { 'localhost' }
);

sub DEMOLISH {
    my ($self) = @_;
    if ($self->record) {
        $self->mock_remote_conn->dump_session_store($self->mock_file);
    }
}

1;
