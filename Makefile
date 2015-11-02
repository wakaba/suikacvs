all:

WGET = wget
CURL = curl
GIT = git

updatenightly: local/bin/pmbp.pl
	$(CURL) -s -S -L https://gist.githubusercontent.com/wakaba/34a71d3137a52abb562d/raw/gistfile1.txt | sh
	$(GIT) add modules t_deps/modules
	perl local/bin/pmbp.pl --update
	$(GIT) add config

## ------ Setup ------

deps: deps-server deps-data

deps-server: git-submodules pmbp-install

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
            --create-perl-command-shortcut @prove

deps-data:
	mkdir -p local
	$(WGET) -O local/cvs-pub.tar.gz https://www.dropbox.com/s/5p4xsdl2z4d7bux/cvs-pub.tar.gz?dl=1
	$(WGET) -O local/cvs-suikacvs-misc.tar.gz https://www.dropbox.com/s/5p4xsdl2z4d7bux/cvs-suikacvs-misc.tar.gz?dl=1
	$(WGET) -O local/cvs-suikacvs-webroot.tar.gz https://www.dropbox.com/s/5p4xsdl2z4d7bux/cvs-suikacvs-webroot.tar.gz?dl=1
	$(WGET) -O local/cvs-suikawiki.tar.gz https://www.dropbox.com/s/5p4xsdl2z4d7bux/cvs-suikawiki.tar.gz?dl=1
	cd local && tar xf cvs-pub.tar.gz
	cd local && tar xf cvs-suikacvs-misc.tar.gz
	cd local && tar xf cvs-suikacvs-webroot.tar.gz
	cd local && tar xf cvs-suikawiki.tar.gz
	mkdir -p local/data
	mv local/data1/cvs/pub local/data

## ------ Tests ------

PROVE = ./prove

test: test-deps test-main

test-deps: deps

test-main:
	#$(PROVE) t/*.t

## License: Public Domain.
