# Use Linux headers specified in config.mak

DIST=${PWD}/dist
DIST_ARCHIVE=${TARGET}.tar.xz
DIST_ARCHIVE_HASH=${DIST_ARCHIVE}.sha1

include config.mak

LINUX_HEADERS = linux-headers-${LINUX_VER}
LINUX_HEADERS_ARCHIVE = linux-${LINUX_VER}.tar.xz

$(info - using ${LINUX_HEADERS})
$(info - OUTPUT is ${OUTPUT})

HASH = hashes/${LINUX_HEADERS_ARCHIVE}.sha1

.PHONY: use install dist

use: ${HASH}
	@echo '- $@ built prerequisites: $^'
	@${MAKE} -f original.mak

dist: ${DIST} manifest.txt
	@echo '- $@ built prerequisites: $^'

manifest.txt:
	@echo '- building $@...'
	@printf 'binutils=%s\ngcc=%s\ngmp=%s\nisl=%s\nheaders=%s\nmusl=%s\nmpc=%s\nmprf=%s\nOUTPUT_DIR=%s\nDIST_DIR=%s\n' \
	 ${BINUTILS_VER} ${GCC_VER} ${GMP_VER} ${ISL_VER} ${LINUX_HEADERS} ${MUSL_VER} ${MPC_VER} ${MPFR_VER} ${OUTPUT} ${DIST}	\
	 > $@

${DIST}:
	@echo '- building $@...'
	@mkdir -p $@; cd ${OUTPUT}; \
		tar -cJf ${DIST_ARCHIVE} bin include lib libexec share x86_64-linux-musl; \
		cd $@; mv ${OUTPUT}/${DIST_ARCHIVE} .; \
		sha1sum -b ${DIST_ARCHIVE} > ${DIST_ARCHIVE_HASH}

install: ${OUTPUT}
	@echo '- $@ built prerequisites: $^'

${OUTPUT}:
	@echo '- building $@...'
	@${MAKE} -f original.mak install

${HASH}: /usr/src/${LINUX_HEADERS_ARCHIVE}
	@echo '- $@ built prerequisites: $^'
	@echo '- building $@...'
	@sha1sum -b $< > $@
	
/usr/src/${LINUX_HEADERS_ARCHIVE}:
	@echo '- building $@...'
	@cd /usr/src; sudo tar -cJf ${LINUX_HEADERS_ARCHIVE} ${LINUX_HEADERS}
