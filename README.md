MyStalker
=========

See a live summary of mysql queries on the wire.

Motivation and Overview
-----------------------

[mytop](http://jeremy.zawodny.com/mysql/mytop/) rocks, but it is only a snapshot of the moment.  While great for identifying slow queries, it isn't very useful for identifying queries that are too prevelant.  mystalker tries to group queries and provide lives statistics on queries in the last 5 seconds, last minute, and since the tool was turned on.

It works by parsing input provided from the network interface (like wireshark). This is done so you don't have to modify your mysql server settings in order to use this tool. (restarting even a slave can be painful).  Then providing a summary of the total number of calls, calls during the last minute, calls during the last 5 seconds.  Allowing you to find those pesky queries that should be rewritten out of your app.

Requirements
------------

* ruby
* rubygems
* ruby's ncurses gem
* mysql log provided by [querysniffer](http://iank.org/querysniffer/)

Usage
-----

Use querysniffer to grab live mysql from the wire on database server or appservers, then pipe it into mystalker.rb

  perl mysqlsniff-0.10.pl eth1 | ruby mystalker.rb 

Output
------

    total |   minute |    5 sec | query
       44 |        2 |        0 | SELECT * FROM comments.boards
       12 |        8 |        2 | SELECT * FROM points.points
       79 |        2 |        0 | SELECT * FROM ratings.items
       42 |        1 |        0 | SELECT * FROM app.app_descriptions
      133 |       81 |        2 | SELECT * FROM app.notifications
        1 |        1 |        0 | SELECT * FROM app.users
       80 |       10 |        2 | SELECT * FROM app.users_emails
       10 |        3 |        0 | SELECT * FROM app.users_facebook
      193 |       31 |        2 | SELECT * FROM global.ads
      421 |       32 |        2 | SELECT * FROM global.featured
       12 |        8 |        1 | SELECT * FROM app2.feed_specific
       81 |       22 |        2 | SELECT * FROM app2.feed_tapulous_viewed
       14 |        4 |        0 | SELECT * FROM app2.songsDefs
      121 |       48 |        2 | SELECT * FROM app2.themes
       25 |        1 |        0 | SELECT * FROM app2.rounds
       11 |        2 |        0 | SELECT * FROM app3.featured
    18806 |    18806 |     2031 | SELECT is_authentic FROM app.users_authentic

FIXME
-----

This tool is very new, and has issues (such as never releasing memory used for counting requests).  Better code and algorithms are needed.  Patches welcome :)

The code is undocumented since it is exploratory programming.  It is only a couple hundred lines so hopefully it isn't too hard to follow.

Ideas for improvements include:

* support non-SELECT queries (eg, more than readonly slaves)
* allow filtering out of groups
* allow selecting a group to see individual queries in that group
* better algorithm to store/calculate counts (currently storing time for each query)
* better ncurses code (don't wrap, deal with too many query groups)
* ability to combine queries groups

Copyright & Thanks
------------------

This code was written while helping [tapulous](http://www.tapulous.com) scale their backend to support their popular iPhone games.

Copyright (c) 2009 Jesse Andrews, Tapulous Inc.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

