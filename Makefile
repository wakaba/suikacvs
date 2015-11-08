all:

WGET = wget
CURL = curl
GIT = git

updatenightly: local/bin/pmbp.pl
	$(CURL) -s -S -L https://gist.githubusercontent.com/wakaba/34a71d3137a52abb562d/raw/gistfile1.txt | sh
	$(GIT) add modules
	perl local/bin/pmbp.pl --update
	$(GIT) add config

## ------ Setup ------

deps: deps-server deps-data

deps-server: git-submodules pmbp-install viewvc suika-viewvc deps-server-main

viewvc:
	mkdir -p local
	$(WGET) -O local/viewvc.tar.gz https://github.com/wakaba/suikacvs/blob/master/viewvc-1.1.24.tar.gz?raw=true
	cd local && tar zxf viewvc.tar.gz
	mv local/viewvc-* local/viewvc

suika-viewvc:
	git clone https://bitbucket.org/wakabatan/suika-viewvc suika-viewvc

deps-server-main:
	mkdir -p local/bin local/conf
	cat local/viewvc/bin/cgi/viewvc.cgi | sed -e 's/CONF_PATHNAME = None/CONF_PATHNAME = r"'`pwd | sed -e 's/\\//\\\\\\//g'`'\/local\/conf\/viewvc.conf"/' > local/bin/viewvc.cgi
	cat config/viewvc.conf | sed -e 's/@@ROOT@@/'`pwd | sed -e 's/\\//\\\\\\//g'`'/g' > local/conf/viewvc.conf

git-submodules:
	$(GIT) submodule update --init

PMBP_OPTIONS=

local/bin/pmbp.pl:
	mkdir -p local/bin
	$(CURL) -s -S -L https://raw.githubusercontent.com/wakaba/perl-setupenv/master/bin/pmbp.pl > $@
pmbp-upgrade: local/bin/pmbp.pl
	perl local/bin/pmbp.pl $(PMBP_OPTIONS) --update-pmbp-pl
pmbp-update: git-submodules pmbp-upgrade
	perl local/bin/pmbp.pl $(PMBP_OPTIONS) --update
pmbp-install: pmbp-upgrade
	perl local/bin/pmbp.pl $(PMBP_OPTIONS) --install \
            --create-perl-command-shortcut @perl \
            --create-perl-command-shortcut @prove \
            --create-perl-command-shortcut @plackup=perl\ modules/twiggy-packed/script/plackup

deps-data: deps-data-misc deps-data-sw

deps-data-misc:
	mkdir -p local
	$(WGET) -O local/cvs-pub.tar.gz https://www.dropbox.com/s/5oujy6bzvm176ih/cvs-pub.tar.gz?dl=1
	$(WGET) -O local/cvs-suikacvs-misc.tar.gz https://www.dropbox.com/s/tprmwtbecx09r77/cvs-suikacvs-misc.tar.gz?dl=1
	$(WGET) -O local/cvs-suikacvs-webroot.tar.gz https://www.dropbox.com/s/8ma5xw7cb0qe4fs/cvs-suikacvs-webroot.tar.gz?dl=1
	$(WGET) -O local/cvs-suikawiki.tar.gz https://www.dropbox.com/s/5p4xsdl2z4d7bux/cvs-suikawiki.tar.gz?dl=1
	cd local && tar zxf cvs-pub.tar.gz
	cd local && tar zxf cvs-suikacvs-misc.tar.gz
	cd local && tar zxf cvs-suikacvs-webroot.tar.gz
	cd local && tar zxf cvs-suikawiki.tar.gz
	rm -fr local/data1/cvs/suikacvs/serverconf
	mv local/data1/cvs local/cvsrepo

deps-data-sw:
	git clone https://github.com/suikawiki/suikawiki-data
	mv suikawiki-data/sw3cvs local/cvsrepo/pub/suikawiki/wikidata
	mv suikawiki-data/sw4cvs local/cvsrepo/pub/suikawiki/sw4data

## ------ Tests ------

PROVE = ./prove

test: test-deps test-main

test-deps: deps

test-main:
	#$(PROVE) t/*.t

## License: Public Domain.
