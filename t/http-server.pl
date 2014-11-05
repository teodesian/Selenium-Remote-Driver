# This is by no means any where close to a real web server but a rather quick
# solution for testing purposes.

use warnings;
use strict;
use IO::Socket;
use FindBin;
use File::stat;
use File::Basename;

my $server = IO::Socket::INET->new(
    Proto     => 'tcp',
    Listen    => SOMAXCONN,
    LocalPort => 63636,
    ReuseAddr => 1
);

my $server_root = $FindBin::Bin . '/';

die "Server failed.\n" unless $server;

while ( my $client = $server->accept() ) {
    $client->autoflush(1);

    my $request = <$client>;

    my $filename;
    my $filesize;
    my $content_type;
    my $success = 1;

    if ( $request =~ m|^GET /(.+) HTTP/1.| || $request =~ m|^GET / HTTP/1.| ) {
        if ( $1 && -e $server_root . 'www/' . $1 ) {
            $filename = $server_root . 'www/' . $1;
        }
        else {
            $success  = 0;
            $filename = $server_root . 'www/404.html';
        }

        my ( undef, undef, $ftype ) = fileparse( $filename, qr/\.[^.]*/ );

        $filesize = stat($filename)->size;
        $content_type = "text/html";

        if ($success) {
            print $client
"HTTP/1.1 200 OK\nContent-Type: $content_type; charset=utf-8\nContent-Length: $filesize\nServer: \n\n";
        }
        else {
            print $client
"HTTP/1.1 404 Not Found\nContent-Type: $content_type; charset=utf-8\nContent-Length: $filesize\nServer: Perl Test Server\n\n";
        }

        open( my $f, "<$filename" );
        while (<$f>) { print $client $_ }
    }
    else {
        print $client 'HTTP/1.1 400 Bad Request\n';
    }

    close $client;
}
