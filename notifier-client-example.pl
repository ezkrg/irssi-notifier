#!/usr/bin/perl

use strict;
use Redis;
use JSON;

my $redis = Redis->new(
  server	=> 'A.B.C.D:6379',
  #password	=> '',
  debug		=> 0
);

sub do_notifier {
    my $json = $redis->lpop('irssi');
    print $json . "\n";
    my $message = JSON->new->utf8(1)->decode($json);
    $message->{'message'} =~ s/["';]//g;
    $message->{'message'} =~ s/</\\</g;
    # terminal-notifier -title title -message message -subtitle subtitle -contentImage https://upload.wikimedia.org/wikipedia/commons/thumb/e/ed/Irssi_logo.svg/1000px-Irssi_logo.svg.png
    system("terminal-notifier -message \"$message->{'message'}\" -title \"$message->{'from'}\" -subtitle \"$message->{'date'}\" -appIcon https://upload.wikimedia.org/wikipedia/commons/thumb/e/ed/Irssi_logo.svg/1000px-Irssi_logo.svg.png");
}

while ( my $llen = $redis->llen('irssi') > 0 ) {
	&do_notifier;
}

exit 0
