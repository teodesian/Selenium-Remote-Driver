requires "Archive::Extract" => "0";
requires "Archive::Zip" => "0";
requires "Carp" => "0";
requires "Cwd" => "0";
requires "Data::Dumper" => "0";
requires "Exporter" => "0";
requires "File::Copy" => "0";
requires "File::Temp" => "0";
requires "HTTP::Headers" => "0";
requires "HTTP::Request" => "0";
requires "IO::Compress::Zip" => "0";
requires "IO::Socket" => "0";
requires "JSON" => "0";
requires "LWP::UserAgent" => "0";
requires "MIME::Base64" => "0";
requires "Moo" => "0";
requires "Moo::Role" => "0";
requires "Net::Ping" => "0";
requires "Scalar::Util" => "0";
requires "Sub::Install" => "0";
requires "Test::Builder" => "0";
requires "Test::LongString" => "0";
requires "Try::Tiny" => "0";
requires "base" => "0";
requires "constant" => "0";
requires "namespace::clean" => "0";
requires "perl" => "5.010";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "File::Basename" => "0";
  requires "File::stat" => "0";
  requires "LWP::Protocol::PSGI" => "0.04";
  requires "LWP::Simple" => "0";
  requires "Test::LWP::UserAgent" => "0";
  requires "Test::MockObject" => "0";
  requires "Test::MockObject::Extends" => "0";
  requires "Test::More" => "0";
  requires "Test::Tester" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.30";
};

on 'develop' => sub {
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
};
