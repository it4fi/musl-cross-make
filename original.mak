# Some locals {{{1
SOURCES = sources

CONFIG_SUB_REV = 3d5db9ebe860
CS_HOST = http://git.savannah.gnu.org/gitweb/
CS_PARMS = ?p=config.git;a=blob_plain;f=config.sub;hb=$(CONFIG_SUB_REV)
CONFIG_SUB_URL = ${CS_HOST}$(CS_PARMS)

# The current config.mak defines {{{2 \
TARGET = x86_64-linux-musl            \
DL_CMD = curl -C - -L -o

# From the current config.mak:                  
BINUTILS_VER = 2.31.1
GCC_VER = 9.3.0
MUSL_VER = 1.1.24
GMP_VER = 6.1.2
MPC_VER = 1.1.0
MPFR_VER = 4.0.2
ISL_VER = 0.19
LINUX_VER = 5.4.0-66 # }}}2

GNU_SITE = https://ftp.gnu.org/pub/gnu
GCC_SITE = $(GNU_SITE)/gcc
BINUTILS_SITE = $(GNU_SITE)/binutils
GMP_SITE = $(GNU_SITE)/gmp
MPC_SITE = $(GNU_SITE)/mpc
MPFR_SITE = $(GNU_SITE)/mpfr
ISL_SITE = http://isl.gforge.inria.fr/

MUSL_SITE = https://www.musl-libc.org/releases
MUSL_REPO = git://git.musl-libc.org/musl

LINUX_SITE = https://cdn.kernel.org/pub/linux/kernel
LINUX_HEADERS_SITE = http://ftp.barfooze.de/pub/sabotage/tarballs/

DL_CMD = wget --quiet -c -O
SHASUM = sha1sum

COWPATCH = $(PWD)/cowpatch.sh

HOST = $(if $(NATIVE),$(TARGET))
BUILD_DIR = build/$(if $(HOST),$(HOST),local)/$(TARGET)
OUTPUT = $(CURDIR)/output$(if $(HOST),-$(HOST))

REL_TOP = ../../..

-include config.mak

# More locals {{{1
SRC_DIRS = gcc-$(GCC_VER) binutils-$(BINUTILS_VER) musl-$(MUSL_VER) \
	$(if $(GMP_VER),gmp-$(GMP_VER)) \
	$(if $(MPC_VER),mpc-$(MPC_VER)) \
	$(if $(MPFR_VER),mpfr-$(MPFR_VER)) \
	$(if $(ISL_VER),isl-$(ISL_VER)) \
	$(if $(LINUX_VER),linux-$(LINUX_VER))

all: # the default target {{{1
	@echo '- no recipe for $@'

clean: # {{{1
	rm -rf gcc-* binutils-* musl-* zlib-* gmp-* mpc-* mpfr-* isl-* build build-* linux-*

distclean: clean # {{{1
	rm -rf sources


# Rules for downloading and verifying sources. {{{1
# Treat an external SOURCES path as immutable and do not try to download anything
# into it.

ifeq ($(SOURCES),sources)

# Target-specific variable SITE {{{2
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/gmp*)): SITE = $(GMP_SITE)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/mpc*)): SITE = $(MPC_SITE)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/mpfr*)): SITE = $(MPFR_SITE)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/isl*)): SITE = $(ISL_SITE)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/binutils*)): SITE = $(BINUTILS_SITE)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/gcc*)): SITE = $(GCC_SITE)/$(basename $(basename $(notdir $@)))
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/musl*)): SITE = $(MUSL_SITE)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/linux-5*)): SITE = $(LINUX_HEADERS_SITE)
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/linux-4*)): SITE = $(LINUX_SITE)/v4.x
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/linux-3*)): SITE = $(LINUX_SITE)/v3.x
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/linux-2.6*)): SITE = $(LINUX_SITE)/v2.6
$(patsubst hashes/%.sha1,$(SOURCES)/%,$(wildcard hashes/linux-headers-*)): SITE = $(LINUX_HEADERS_SITE) # }}}2

$(SOURCES):
	mkdir -p $@

$(SOURCES)/config.sub: | $(SOURCES)
	mkdir -p $@.tmp
	cd $@.tmp && $(DL_CMD) $(notdir $@) "$(CONFIG_SUB_URL)"
	cd $@.tmp && touch $(notdir $@)
	cd $@.tmp && $(SHASUM) -c $(CURDIR)/hashes/$(notdir $@).$(CONFIG_SUB_REV).sha1
	mv $@.tmp/$(notdir $@) $@
	rm -rf $@.tmp

$(SOURCES)/%: hashes/%.sha1 | $(SOURCES)
	@echo '- building $@...'
	mkdir -p $@.tmp
	cd $@.tmp && $(DL_CMD) $(notdir $@) $(SITE)/$(notdir $@)
	cd $@.tmp && touch $(notdir $@)
	cd $@.tmp && $(SHASUM) -c $(CURDIR)/hashes/$(notdir $@).sha1
	mv $@.tmp/$(notdir $@) $@
	rm -rf $@.tmp

endif

# Rules for extracting and patching sources, or checking them out from git. {{{1

musl-git-%: # {{{2
	rm -rf $@.tmp
	git clone -b $(patsubst musl-git-%,%,$@) $(MUSL_REPO) $@.tmp
	cd $@.tmp && git fsck
	mv $@.tmp $@

%.orig: $(SOURCES)/%.tar.gz # {{{2
	case "$@" in */*) exit 1 ;; esac
	rm -rf $@.tmp
	mkdir $@.tmp
	( cd $@.tmp && tar zxvf - ) < $<
	rm -rf $@
	touch $@.tmp/$(patsubst %.orig,%,$@)
	mv $@.tmp/$(patsubst %.orig,%,$@) $@
	rm -rf $@.tmp

%.orig: $(SOURCES)/%.tar.bz2 # {{{2
	case "$@" in */*) exit 1 ;; esac
	rm -rf $@.tmp
	mkdir $@.tmp
	( cd $@.tmp && tar jxvf - ) < $<
	rm -rf $@
	touch $@.tmp/$(patsubst %.orig,%,$@)
	mv $@.tmp/$(patsubst %.orig,%,$@) $@
	rm -rf $@.tmp

%.orig: $(SOURCES)/%.tar.xz # {{{2
	case "$@" in */*) exit 1 ;; esac
	rm -rf $@.tmp
	mkdir $@.tmp
	( cd $@.tmp && tar Jxvf - ) < $<
	rm -rf $@
	touch $@.tmp/$(patsubst %.orig,%,$@)
	mv $@.tmp/$(patsubst %.orig,%,$@) $@
	rm -rf $@.tmp

%: %.orig | $(SOURCES)/config.sub # {{{2
	case "$@" in */*) exit 1 ;; esac
	rm -rf $@.tmp
	mkdir $@.tmp
	( cd $@.tmp && find ../$< -path '*/*/*' -prune -exec sh -c 'ln -s "$$@" .' ':' {} + )
	test ! -d patches/$@ || cat patches/$@/* | ( cd $@.tmp && $(COWPATCH) -p1 )
	test ! -f $</config.sub || ( rm -f $@.tmp/config.sub && cp -f $(SOURCES)/config.sub $@.tmp/ && chmod +x $@.tmp/config.sub )
	rm -rf $@
	mv $@.tmp $@ # }}}2

# Add deps for all patched source dirs on their patchsets {{{1
$(foreach dir,$(notdir $(basename $(basename $(basename $(wildcard hashes/*))))),$(eval $(dir): $$(wildcard patches/$(dir) patches/$(dir)/*)))

extract_all: | $(SRC_DIRS)
	@echo '- $@ built order-only prerequisites: $|'

# Rules for building. {{{1

ifeq ($(TARGET),)

all:
	@echo TARGET must be set via config.mak or command line.
	@exit 1

else

$(BUILD_DIR):
	mkdir -p $@

$(BUILD_DIR)/Makefile: | $(BUILD_DIR)
	ln -sf $(REL_TOP)/litecross/Makefile $@

$(BUILD_DIR)/config.mak: | $(BUILD_DIR)
	printf >$@ '%s\n' \
	"TARGET = $(TARGET)" \
	"HOST = $(HOST)" \
	"MUSL_SRCDIR = $(REL_TOP)/musl-$(MUSL_VER)" \
	"GCC_SRCDIR = $(REL_TOP)/gcc-$(GCC_VER)" \
	"BINUTILS_SRCDIR = $(REL_TOP)/binutils-$(BINUTILS_VER)" \
	$(if $(GMP_VER),"GMP_SRCDIR = $(REL_TOP)/gmp-$(GMP_VER)") \
	$(if $(MPC_VER),"MPC_SRCDIR = $(REL_TOP)/mpc-$(MPC_VER)") \
	$(if $(MPFR_VER),"MPFR_SRCDIR = $(REL_TOP)/mpfr-$(MPFR_VER)") \
	$(if $(ISL_VER),"ISL_SRCDIR = $(REL_TOP)/isl-$(ISL_VER)") \
	$(if $(LINUX_VER),"LINUX_SRCDIR = $(REL_TOP)/linux-$(LINUX_VER)") \
	"-include $(REL_TOP)/config.mak"

all: | $(SRC_DIRS) $(BUILD_DIR) $(BUILD_DIR)/Makefile $(BUILD_DIR)/config.mak
	@echo '- $@ built order-only prerequisites: $|'
	cd $(BUILD_DIR) && $(MAKE) $@

install: | $(SRC_DIRS) $(BUILD_DIR) $(BUILD_DIR)/Makefile $(BUILD_DIR)/config.mak
	cd $(BUILD_DIR) && $(MAKE) OUTPUT=$(OUTPUT) $@

endif

# Note: .SECONDARY with no prerequisites causes all targets to be treated {{{1
# as secondary (i.e., no target is removed because it is considered intermediate). 
.SECONDARY:

# Notes {{{1
#
# - all built order-only prerequisites:
#     gcc-9.3.0
#     binutils-2.31.1
#     musl-1.1.24 gmp-6.1.2
#     mpc-1.1.0 mpfr-4.0.2
#     isl-0.19
#     linux-5.4.0-66-generic
#     build/local/x86_64-linux-musl
#     build/local/x86_64-linux-musl/Makefile
#     build/local/x86_64-linux-musl/config.mak
