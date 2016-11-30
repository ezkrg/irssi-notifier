use strict;
use Redis;
use JSON;
use Irssi;
use vars qw($VERSION %IRSSI $redis);

# Dev. info ^_^
$VERSION = "0.01";
%IRSSI = (
  authors     => "ezkrg",
  name        => "Notifier",
  description => "Simple script that will store messages in Redis",
  license     => "GPL",
  changed     => "Wed Nov 30 14:01:10 CET 2016"
);

sub setup_redis {
  my $redis_server = Irssi::settings_get_str('notifier_redis_server');
  my $redis_password = Irssi::settings_get_str('notifier_redis_password');

  if ( $redis_password eq '' ) {
    $redis = Redis->new(
      server 	=> $redis_server,
      debug	=> 0
    );
  } else {
    $redis = Redis->new(
      server 	=> $redis_server,
      password	=> $redis_password,
      debug	=> 0
    );
  }
}

# All the works
sub do_notifier {
  my ($server, $title, $data) = @_;

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
  $year += 1900;
  $mon += 1;
  my $lsec = sprintf("%02d", $sec);
  my $lmin = sprintf("%02d", $min);
  my $lhour = sprintf("%02d", $hour);
  my $lmday = sprintf("%02d", $mday);
  my $lmon = sprintf("%02d", $mon);
  my $date = $year . "-" . $lmon . "-" . $lmday . " " . $lhour . ":" . $lmin . ":" . $lsec;

  $data =~ s/["';]//g;

  &setup_redis;

  $redis->rpush( "irssi", JSON->new->utf8(0)->encode( { "from" => $title, "date" => $date, "message" => $data } ));
  $redis->quit();

  return 1
}

sub notifier_it {
    my ($server, $title, $data, $channel, $nick) = @_;

    my $filter = Irssi::settings_get_str('notifier_on_regex');
    my $channel_filter = Irssi::settings_get_str('notifier_channel_regex');
    my $off_filter = Irssi::settings_get_str('notifier_off_regex');
    my $off_title_filter = Irssi::settings_get_str('notifier_off_sender_regex');

    if($off_title_filter) {
      return 0 if $title =~ /$off_title_filter/;
    }
    if($filter) {
      return 0 if $data !~ /$filter/;
    }
    if($off_filter) {
      return 0 if $data =~ /$off_filter/;
    }
   
    if($channel_filter && $server->ischannel($channel)) {
      return 0 if $channel !~ /$channel_filter/;
    }

    $title = $title . " " . $channel;
    do_notifier($server, $title, $data);
}

# All the works
sub notifier_message {
  my ($server, $data, $nick, $mask, $target) = @_;
    notifier_it($server, $nick, $data, $target, $nick);
}

sub notifier_join {
  my ($server, $channel, $nick, $address) = @_;
    notifier_it($server, "Join", "$nick has joined", $channel, $nick);
}

sub notifier_part {
  my ($server, $channel, $nick, $address) = @_;
    notifier_it($server, "Part", "$nick has parted", $channel, $nick);
}

sub notifier_quit {
  my ($server, $nick, $address, $reason) = @_;
    notifier_it($server, "Quit", "$nick has quit: $reason", $address, $nick);
}

sub notifier_invite {
  my ($server, $channel, $nick, $address) = @_;
    notifier_it($server, "Invite", "$nick has invited you on $channel", $channel, $nick);
}

sub notifier_topic {
  my ($server, $channel, $topic, $nick, $address) = @_;
    notifier_it($server, "Topic: $topic", "$nick has changed the topic to $topic on $channel", $channel, $nick);
}

sub notifier_privmsg {
  my ($server, $data, $nick, $host) = @_;
    my ($target, $text) = split(/ :/, $data, 2);
    if (Irssi::settings_get_str('notifier_on_privmsg') == 1) {
        notifier_it($server, $nick, $data, $target, $nick); 
    }
}

Irssi::settings_add_str('notifier', 'notifier_on_regex', 0);      # false
Irssi::settings_add_str('notifier', 'notifier_channel_regex', 0); # false
Irssi::settings_add_str('notifier', 'notifier_on_privmsg', 0);    # false
Irssi::settings_add_str('notifier', 'notifier_off_regex', 0);
Irssi::settings_add_str('notifier', 'notifier_off_sender_regex', 0);
Irssi::settings_add_str('notifier', 'notifier_redis_server', '127.0.0.1:6379');
Irssi::settings_add_str('notifier', 'notifier_redis_password', '');
Irssi::signal_add_last('message public', 'notifier_message');
Irssi::signal_add_last('message private', 'notifier_message');
Irssi::signal_add_last('message join', 'notifier_join');
Irssi::signal_add_last('message part', 'notifier_part');
Irssi::signal_add_last('message quit', 'notifier_quit');
Irssi::signal_add_last('message invite', 'notifier_invite');
Irssi::signal_add_last('message topic', 'notifier_topic');
Irssi::signal_add_last('event privmsg', 'notifier_privmsg');
