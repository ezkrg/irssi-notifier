Simple script for irssi to store messages in Redis
===

Requirements
---
* redis-server

Installation
---
Place notifier.pl in `~/.irssi/scripts/`.

    /script load notifier.pl

Configuration
---
    /SET notifier_on_regex [regex]
    /SET notifier_channel_regex [regex]
    /SET notifier_on_privmsg <0|1>
    /SET notifier_off_regex [regex]
    /SET notifier_off_sender_regex [regex]
    /SET notifier_redis_server 127.0.0.1:6379
    /SET notifier_redis_password [password]

Usage
---
 notifier on mynickname

    /SET notifier_on_regex mynickname

 notifier on everything

    /SET notifier_on_regex .*

 everything but jdewey

    /SET notifier_on_regex (?=^(?:(?!jdewey).)*$).*
    /SET notifier_off_regex jdewey

 only notifier things for mychannel1 and mychannel2

    /SET notifier_channel_regex (mychannel1|mychannel2)

 by default we don't send notifications for privmsgs you can enable this by setting this flag to 1

    /SET notifier_on_privmsg 1 

Author
---
ezkrg 2016

Forked from Nate Murray's [irssi-notifier](https://github.com/paddykontschak/irssi-notifier).
