package t::lib::MockSeleniumWebDriver;
use strict;
use warnings;

use LWP::Protocol::PSGI 0.04;
use JSON;

our $MockSeleniumWebDriverObj;

sub save_recording {
  my ($self) = @_;
  open(my $fh, '>', $self->{file});
  print $fh encode_json($self->{req_resp});
  close $fh;
}

sub load_recording {
  my ($self) = @_;
  open(my $fh, '<', $self->{file});
  my @lines = <$fh>;
  $self->{req_resp} = decode_json(join('', @lines));
  close $fh;
}

sub register {
  my $record = shift;
  $record = 0 if !defined $record;
  my $file = shift;
  my $self = {record => $record,
              req_index => 0,
              file => $file};
  bless $self,__PACKAGE__;
  if ($record) {
    require LWP::UserAgent;
    require HTTP::Headers;
    require HTTP::Request;
    $self->{req_resp} = [];
  } else {
    $self->load_recording;
  }
  LWP::Protocol::PSGI->register(\&t::lib::MockSeleniumWebDriver::psgi_app);
  $MockSeleniumWebDriverObj = $self;
}

sub psgi_app {
  my $env = shift;
  my $self = $MockSeleniumWebDriverObj;
  my $uri =
      $env->{'psgi.url_scheme'} . '://'
    . $env->{SERVER_NAME} . ':'
    . $env->{SERVER_PORT}
    . $env->{REQUEST_URI};
  my $content = '';
  my $s;
  while (read($env->{'psgi.input'}, $s, 100)) {
    $content .= $s;
  }
  my $req_index = \$self->{req_index};
  if (!$self->{record}) {
    my $expected = $self->{req_resp}->[$$req_index]->{request}->{content};
    $expected = $expected eq "" ? $expected : decode_json($expected);
    my $actual = $content eq "" ? $content : decode_json($content);

    if (  $self->{req_resp}->[$$req_index]->{request}->{verb} eq $env->{REQUEST_METHOD}
      and $self->{req_resp}->[$$req_index]->{request}->{uri} eq $uri
      and (   $self->{req_resp}->[$$req_index]->{request}->{content} eq $content
           or deeply_equal($expected, $actual)))  {
      return $self->{req_resp}->[$$req_index++]->{response};
    } else {
      die
"Request information has changed since recording... do you need to record webdriver responses again?";
    }
  } else {
    my $ua = LWP::UserAgent->new;
    my $h  = HTTP::Headers->new;
    $h->header('Content-Type' => $env->{CONTENT_TYPE});
    $h->header('Accept'       => $env->{HTTP_ACCEPT});
    my $req = HTTP::Request->new($env->{REQUEST_METHOD}, $uri, $h, $content);
    LWP::Protocol::PSGI->unregister;
    my $res = $ua->request($req);
    LWP::Protocol::PSGI->register(\&psgi_app);
    my $head    = $res->{_headers}->clone;
    my $newhead = [];

    for my $key (keys %{$head}) {
      push @{$newhead}, $key;
      push @{$newhead}, $head->{$key};
    }
    my $response = [$res->code, $newhead, [$res->content]];
    my $request = {
      verb    => $env->{REQUEST_METHOD},
      uri     => $uri,
      content => $content
    };
    push @{$self->{req_resp}}, {request => $request, response => $response};
    return $response;
  }
}

sub deeply_equal {
  my ( $a_ref, $b_ref ) = @_;

  local $Storable::canonical = 1;
  return Storable::freeze( $a_ref ) eq Storable::freeze( $b_ref );
}

sub DESTROY {
  my ($self) = @_;
  if($self->{record}) {
    $self->save_recording;
  }
}

1;
