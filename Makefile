prefix = /usr/local
datadir = ${prefix}/share
SHELL=/bin/sh
OS := $(shell uname -s)
GPP=/usr/bin/clang++
INSTALL_DIR=$(DESTDIR)/usr/local
MAN_DIR=$(DESTDIR)/usr/local/share
######
HAS_NDPI=$(shell pkg-config --exists libndpi; echo $$?)
ifeq ($(HAS_NDPI), 0)
    NDPI_INC = $(shell pkg-config --cflags libndpi | sed -e 's/\(-I[^ \t]*\)/\1\/libndpi/g')
    NDPI_LIB = $(shell pkg-config --libs libndpi)
    NDPI_LIB_DEP =
else
    NDPI_INC=-I./nDPI/src/include
    NDPI_LIB=./nDPI/src/lib/.libs/libndpi.a
    NDPI_LIB_DEP=$(NDPI_LIB)
endif
######
LIBPCAP=-lpcap
LIBRABBITMQ=-lrabbitmq

######
MONGOOSE_HOME=./third-party/mongoose
MONGOOSE_INC=-I$(MONGOOSE_HOME)
######
HAS_LUAJIT=$(shell pkg-config --exists luajit; echo $$?)
ifeq ($(HAS_LUAJIT), 0)
	LUAJIT_INC = $(shell pkg-config --cflags luajit)
	LUAJIT_LIB = $(shell pkg-config --libs luajit)
else
	LUAJIT_HOME=./third-party/LuaJIT-2.0.3
	LUAJIT_INC=-I$(LUAJIT_HOME)/src
	LUAJIT_LIB=$(LUAJIT_HOME)/src/libluajit.a
endif
######
LIBRRDTOOL_HOME=third-party/rrdtool-1.4.8
HAS_LIBRRDTOOL=$(shell pkg-config --exists librrd; echo $$?)
ifeq ($(HAS_LIBRRDTOOL), 0)
	LIBRRDTOOL_INC = $(shell pkg-config --cflags librrd)
	LIBRRDTOOL_LIB = $(shell pkg-config --libs librrd)
else
	LIBRRDTOOL_INC=-I$(LIBRRDTOOL_HOME)/src/
	LIBRRDTOOL_LIB=$(LIBRRDTOOL_HOME)/src/.libs/librrd_th.a
endif
######
HTTPCLIENT_INC=third-party/http-client-c/src/
######
HAS_JSON=$(shell pkg-config --exists json-c; echo $$?)
ifeq ($(HAS_JSON), 0)
	JSON_INC = $(shell pkg-config --cflags json-c)
	JSON_LIB = $(shell pkg-config --libs json-c)
else
	JSON_HOME=third-party/json-c
	JSON_INC=-I$(JSON_HOME)
	JSON_LIB=$(JSON_HOME)/.libs/libjson-c.a
endif
######
HAS_ZEROMQ=$(shell pkg-config --exists libzmq; echo $$?)
ifeq ($(HAS_ZEROMQ), 0)
	ZEROMQ_INC = $(shell pkg-config --cflags libzmq)
	ZMQ_STATIC=/usr/local/lib/libzmq.a
	ifeq ($(wildcard $(ZMQ_STATIC)),)
		ZEROMQ_LIB = $(shell pkg-config --libs libzmq)
	else
		ZEROMQ_LIB = $(ZMQ_STATIC)
	endif
else
	ZEROMQ_HOME=./third-party/zeromq-3.2.4
	ZEROMQ_INC=-I$(ZEROMQ_HOME)/include
	ZEROMQ_LIB=$(ZEROMQ_HOME)/src/.libs/libzmq.a
endif
######
EWH_HOME=third-party/EWAHBoolArray
EWH_INC=$(EWH_HOME)/headers
######
TARGET = ntopng
LIBS = $(NDPI_LIB) $(LIBRABBITMQ) $(LIBPCAP) $(LUAJIT_LIB) $(LIBRRDTOOL_LIB) $(ZEROMQ_LIB) $(JSON_LIB)  -lsqlite3 -pagezero_size 10000 -image_base 100000000   -L/usr/local/lib -ldl -lcurl -lm -lpthread
CPPFLAGS = -g -Wall  -I/usr/local/include -I ./third-party/hiredis $(MONGOOSE_INC) $(JSON_INC) $(NDPI_INC) $(LUAJIT_INC) $(LIBRRDTOOL_INC) $(ZEROMQ_INC)  -I/usr/local/include -I$(HTTPCLIENT_INC) -I$(EWH_INC) -DDATA_DIR='"$(datadir)"'  # -D_GLIBCXX_DEBUG
######
# ntopng-1.0_1234.x86_64.rpm
PLATFORM = `uname -p`
REVISION = 1.2.2
PACKAGE_VERSION = 1.2.2
NTOPNG_VERSION = 1.2.2
RPM_PKG = $(TARGET)-$(NTOPNG_VERSION)-$(REVISION).$(PLATFORM).rpm
RPM_DATA_PKG = $(TARGET)-data-$(NTOPNG_VERSION)-$(REVISION).noarch.rpm
######

ifeq ($(OS),Darwin)
LIBS += -lstdc++.6
endif

LIB_TARGETS =

ifneq ($(HAS_LUAJIT), 0)
LIB_TARGETS += $(LUAJIT_LIB)
 endif

ifneq ($(HAS_ZEROMQ), 0)
LIB_TARGETS += $(ZEROMQ_LIB)
endif

ifneq ($(HAS_LIBRRDTOOL), 0)
LIB_TARGETS += $(LIBRRDTOOL_LIB)
endif

ifneq ($(HAS_JSON), 0)
LIB_TARGETS += $(JSON_LIB)
endif

.PHONY: default all clean docs test

.NOTPARALLEL: default all

default: $(NDPI_LIB_DEP) $(LIB_TARGETS) $(TARGET)

all: default

OBJECTS = $(patsubst %.cpp, %.o, $(wildcard *.cpp))
HEADERS = $(wildcard *.h)

%.o: %.c $(HEADERS) Makefile
	$(GPP) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

%.o: %.cpp $(HEADERS) Makefile
	$(GPP) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

.PRECIOUS: $(TARGET) $(OBJECTS)

$(TARGET): $(OBJECTS) $(LIBRRDTOOL) Makefile
	$(GPP) $(OBJECTS) -Wall $(LIBS) -o $@

$(NDPI_LIB): nDPI
	cd nDPI; if test ! -f Makefile; then ./autogen.sh ; ./configure; fi; make

nDPI:
	svn co https://svn.ntop.org/svn/ntop/trunk/nDPI/

$(LUAJIT_LIB):
	cd $(LUAJIT_HOME); make

$(ZEROMQ_LIB):
	cd $(ZEROMQ_HOME); ./configure --without-documentation; make

$(LIBRRDTOOL_LIB):
	cd $(LIBRRDTOOL_HOME); ./configure --disable-rrd_graph --disable-libdbi --disable-libwrap --disable-rrdcgi --disable-libtool-lock --disable-nls --disable-rpath --disable-perl --disable-ruby --disable-lua --disable-tcl --disable-python --disable-dependency-tracking; cd src; make librrd_th.la

$(JSON_LIB):
	cd $(JSON_HOME); ./autogen.sh; ./configure; make

clean:
	-rm -f *.o *~ svn-commit.* #config.h
	-rm -f $(TARGET)

cert:
	openssl req -new -x509 -sha1 -extensions v3_ca -nodes -days 365 -out cert.pem
	cat privkey.pem cert.pem > httpdocs/ssl/ntopng-cert.pem
	/bin/rm -f privkey.pem cert.pem

veryclean:
	-rm -rf nDPI


geoip:
	@if test -d ~/dat_files ; then \
	  cp ~/dat_files/* httpdocs/geoip; gunzip -f httpdocs/geoip/*.dat.gz ; \
	else \
	  cd httpdocs/geoip; \
	  wget -nc http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz; \
	  wget -nc http://geolite.maxmind.com/download/geoip/database/GeoLiteCityv6-beta/GeoLiteCityv6.dat.gz; \
	  wget -nc http://download.maxmind.com/download/geoip/database/asnum/GeoIPASNum.dat.gz; \
	  wget -nc http://download.maxmind.com/download/geoip/database/asnum/GeoIPASNumv6.dat.gz; \
	  gunzip -f *.dat.gz ; \
	fi

# Do NOT build package as root (http://wiki.centos.org/HowTos/SetupRpmBuildEnvironment)
#	mkdir -p $(HOME)/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
#	echo '%_topdir %(echo $HOME)/rpmbuild' > ~/.rpmmacros

build-rpm: geoip build-rpm-ntopng build-rpm-ntopng-data


build-rpm-ntopng:
	rm -rf ntopng-1.2.2
	mkdir ntopng-1.2.2
	cp -r doc *.cpp *.h configure COPYING README.* *.in ntopng.8 httpdocs scripts packages third-party ntopng-1.2.2
	find ntopng-1.2.2 -name ".svn" | xargs /bin/rm -rf
	-rm ntopng-1.2.2/httpdocs/geoip/*
	cd ntopng-1.2.2; svn co https://svn.ntop.org/svn/ntop/trunk/nDPI/; cd ..
	tar cvfz ntopng-1.2.2.tgz ntopng-1.2.2
	#
	rm -f $(HOME)/rpmbuild/RPMS/$(PLATFORM)/$(RPM_PKG)
	cp ntopng-1.2.2.tgz $(HOME)/rpmbuild/SOURCES/
	#
	rpmbuild -bb ./packages/ntopng.spec
	@./packages/rpm-sign.exp $(HOME)/rpmbuild/RPMS/$(PLATFORM)/$(RPM_PKG)
	@echo ""
	@echo "Package contents:"
	@rpm -qpl $(HOME)/rpmbuild/RPMS/$(PLATFORM)/$(RPM_PKG)
	@echo "The package is now available in $(HOME)/rpmbuild/RPMS/$(PLATFORM)/$(RPM_PKG)"
	-rm -rf ntopng-1.2.2 ntopng_1.2.2.tgz
	#

build-rpm-ntopng-data:
	rm -rf ntopng-data-1.2.2
	mkdir -p ntopng-data-1.2.2/usr/share/ntopng/httpdocs/geoip/
	@if test -d ~/dat_files ; then \
	  cp ~/dat_files/* ntopng-data-1.2.2/usr/share/ntopng/httpdocs/geoip/; \
	else \
	  cp ./httpdocs/geoip/* ntopng-data-1.2.2/usr/share/ntopng/httpdocs/geoip/ ;\
	fi
	#gunzip ntopng-data-1.2.2/usr/local/share/ntopng/httpdocs/geoip/*.gz
	tar cvfz ntopng-data-1.2.2.tgz ntopng-data-1.2.2
	#
	rm -f $(HOME)/rpmbuild/RPMS/noarch/$(RPM_DATA_PKG)
	cp ntopng-data-1.2.2.tgz $(HOME)/rpmbuild/SOURCES/
	cd $(HOME)/rpmbuild/SOURCES;tar xvfz $(HOME)/rpmbuild/SOURCES/ntopng-data-1.2.2.tgz
	rpmbuild -bb ./packages/ntopng-data.spec
	@./packages/rpm-sign.exp $(HOME)/rpmbuild/RPMS/noarch/$(RPM_DATA_PKG)
	@echo ""
	@echo "Package contents:"
	@rpm -qpl $(HOME)/rpmbuild/RPMS/noarch/$(RPM_DATA_PKG)
	@echo "The package is now available in $(HOME)/rpmbuild/RPMS/noarch/$(RPM_DATA_PKG)"
	-rm -rf ntopng-data-1.2.2 ntopng-data_1.2.2.tgz

docs:
	cd doc && doxygen doxygen.conf

dist:
	rm -rf ntopng-1.2.2
	mkdir ntopng-1.2.2
	cd ntopng-1.2.2; svn co https://svn.ntop.org/svn/ntop/trunk/ntopng/; cd ntopng; svn co https://svn.ntop.org/svn/ntop/trunk/nDPI/; cd ..; find ntopng -name .svn | xargs rm -rf ; mv ntopng ntopng-1.2.2; tar cvfz ../ntopng-1.2.2.tgz ntopng-1.2.2

install: ntopng
	@echo "Make sure you have already run 'make geoip' to also install geoip dat files"
	@echo "While we provide you an install make target, we encourage you"
	@echo "to create a package and install that"
	@echo "rpm - do 'make build-rpm'"
	@echo "deb - do 'cd packages/ubuntu;./configure;make"
	mkdir -p $(INSTALL_DIR)/share/ntopng $(MAN_DIR)/man/man8 $(INSTALL_DIR)/bin
	cp ntopng $(INSTALL_DIR)/bin
	cp ./ntopng.8 $(MAN_DIR)/man/man8
	cp -r ./httpdocs $(INSTALL_DIR)/share/ntopng
	cp -r ./scripts $(INSTALL_DIR)/share/ntopng
	find $(INSTALL_DIR)/share/ntopng -name "*~"   | xargs /bin/rm -f
	find $(INSTALL_DIR)/share/ntopng -name ".svn" | xargs /bin/rm -rf

uninstall:
	if test -f $(INSTALL_DIR)/bin/ntopng; then rm $(INSTALL_DIR)/bin/ntopng; fi;
	if test -f $(MAN_DIR)/man/man8/ntopng.8; then rm $(MAN_DIR)/man/man8/ntopng.8; fi;
	if test -d $(INSTALL_DIR)/share/ntopng; then rm -r $(INSTALL_DIR)/share/ntopng; fi;

Makefile: 
	@echo ""
	@echo "Re-running configure as the SVN release has changed"
	@echo ""
	./configure

changelog:
	echo "Generating changelog for recent activites..."
	@./tools/svn2changelog.py > Changelog
	echo "Changelog file is ready"

cppcheck:
	cppcheck --template='{file}:{line}:{severity}:{message}' --quiet --enable=all --force -I ./third-party/hiredis $(MONGOOSE_INC) $(JSON_INC) $(NDPI_INC) $(LUAJIT_INC) $(LIBRRDTOOL_INC) $(ZEROMQ_INC) -I$(EWH_INC) *.cpp

test: test_version

test_version:
	./ntopng --version
