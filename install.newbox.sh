#!/bin/sh

# http://wiki.nginx.org/Install
aptitude install nginx
aptitude install gcc make cpanminus
aptitude install libclass-dbi-pg-perl
aptitude install libdbd-pg-perl libev-perl
aptitude install libssl-dev libio-socket-ssl-perl libexpat1-dev

sudo cpanm App::cpanminus
sudo cpanm Carton
