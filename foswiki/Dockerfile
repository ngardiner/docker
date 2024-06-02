FROM ubuntu:22.04

LABEL maintainer="ngardiner@gmail.com"

RUN apt-get -y update

RUN apt-get -y install apache2 bzip2 ca-certificates diffutils findutils rcs sendmail wget
RUN apt-get -y install libapache-htpasswd-perl libapache2-mod-perl2 libapache-session-perl libcgi-pm-perl libfile-copy-recursive-perl libfile-listing-perl liblocale-gettext-perl liblocale-codes-perl libemail-mime-perl libhtml-entities-numbered-perl libhtml-parser-perl libhtml-tree-perl libwww-perl libnet-ldap-perl libauthen-sasl-perl libi18n-charset-perl libunicode-maputf8-perl liberror-perl libjson-perl libcgi-session-perl libalgorithm-diff-perl libalgorithm-diff-perl 

COPY server.conf /etc/apache2/sites-enabled/000-default.conf

RUN a2enmod cgid
RUN a2enmod rewrite

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
