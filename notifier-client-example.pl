#!/usr/bin/perl

use strict;
use Redis;
use JSON;

my $redis = Redis->new(
  server	=> '192.168.13.1:6379',
  #password	=> '',
  debug		=> 0
);

my $lua_script = qq(-- script irssi-notifier
  local i = tonumber(ARGV[1])
  local res = {}
  local length = redis.call('llen', KEYS[1])
  if length < i then i = length end
  while (i > 0) do
    local item = redis.call("lpop", KEYS[1])
    if (not item) then
      break
    end
    table.insert(res, item)
    i = i-1
  end
  return res);

my ( $lua_script_sha1 ) = $redis->script_load($lua_script);

sub do_notifier {
    my @messages = $redis->evalsha($lua_script_sha1, 1, 'irssi', 10000)

    foreach my $message ( @messages ) {
	    print $json . "\n";
	    my $message = JSON->new->utf8(1)->decode($json);
	    $message->{'message'} =~ s/["';]//g;
	    $message->{'message'} =~ s/</\\</g;
	    # terminal-notifier -title title -message message -subtitle subtitle -contentImage https://upload.wikimedia.org/wikipedia/commons/thumb/e/ed/Irssi_logo.svg/1000px-Irssi_logo.svg.png
	    system("terminal-notifier -timeout 10 -message \"$message->{'message'}\" -title \"$message->{'from'}\" -subtitle \"$message->{'date'}\" -appIcon https://upload.wikimedia.org/wikipedia/commons/thumb/e/ed/Irssi_logo.svg/1000px-Irssi_logo.svg.png");
    }
}

while ( my $llen = $redis->llen('irssi') > 0 ) {
	&do_notifier;
}

exit 0
