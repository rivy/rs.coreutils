####

OSID := $(or $(and $(filter .exe,$(patsubst %.exe,.exe,$(subst $() $(),_,${SHELL}))),$(filter win,${OS:Windows_NT=win})),nix)## OSID == [nix,win]
# for Windows OS, set SHELL to `%ComSpec%` or `cmd` (note: environment/${OS}=="Windows_NT" for XP, 2000, Vista, 7, 10 ...)
# * `make` may otherwise use an incorrect shell (eg, `bash`), if found; "syntax error: unexpected end of file" error output is indicative
ifeq (${OSID},win)
# use case and location fallbacks; note: assumes *no spaces* within ${ComSpec}, ${SystemRoot}, or ${windir}
COMSPEC := $(or ${ComSpec},${COMSPEC},${comspec})
SystemRoot := $(or ${SystemRoot},${SYSTEMROOT},${systemroot},${windir})
SHELL := $(firstword $(wildcard ${COMSPEC} ${SystemRoot}/System32/cmd.exe) cmd)
endif

####

# Config options
PROFILE         ?= debug
MULTICALL       ?= n
INSTALL         ?= install
ifneq (,$(filter install, $(MAKECMDGOALS)))
override PROFILE:=release
endif

PROFILE_CMD :=
ifeq ($(PROFILE),release)
	PROFILE_CMD = --release
endif

RM := rm -rf

# Binaries
CARGO  ?= cargo
CARGOFLAGS ?=

# Install directories
PREFIX ?= /usr/local
DESTDIR ?=
BINDIR ?= /bin
MANDIR ?= /man/man1

INSTALLDIR_BIN=$(DESTDIR)$(PREFIX)$(BINDIR)
INSTALLDIR_MAN=$(DESTDIR)$(PREFIX)/share/$(MANDIR)
$(shell test -d $(INSTALLDIR_MAN))
ifneq ($(.SHELLSTATUS),0)
override INSTALLDIR_MAN=$(DESTDIR)$(PREFIX)$(MANDIR)
endif

#prefix to apply to uutils binary and all tool binaries
PROG_PREFIX ?=

# This won't support any directory with spaces in its name, but you can just
# make a symlink without spaces that points to the directory.
BASEDIR       ?= $(shell pwd)
BUILDDIR      := $(BASEDIR)/target/${PROFILE}
PKG_BUILDDIR  := $(BUILDDIR)/deps
DOCSDIR       := $(BASEDIR)/docs

BUSYBOX_ROOT := $(BASEDIR)/tmp
BUSYBOX_VER  := 1.24.1
BUSYBOX_SRC  := $(BUSYBOX_ROOT)/busybox-$(BUSYBOX_VER)

# Possible programs
PROGS_windows  := $(shell util/show-utils.sh --features windows)
PROGS_unix     := $(shell util/show-utils.sh --features unix)

PROGS := $(PROGS_windows)
ifneq ($(OS),Windows_NT)
#	PROGS    := $(PROGS) $(UNIX_PROGS)
	PROGS    := $(PROGS_unix)
endif

UTILS ?= $(PROGS)

# Programs with usable tests
TEST_PROGS  := ${PROGS}

# $(info PROGS="${PROGS}")
# $(info UTILS="${UTILS}")
# $(info SKIP_UTILS="${SKIP_UTILS}")
# $(info TEST_PROGS="${TEST_PROGS}")

TESTS       := \
	$(sort $(filter $(UTILS),$(filter-out $(SKIP_UTILS),$(TEST_PROGS))))

TEST_NO_FAIL_FAST :=
TEST_SPEC_FEATURE :=
ifneq ($(SPEC),)
TEST_NO_FAIL_FAST :=--no-fail-fast
TEST_SPEC_FEATURE := test_unimplemented
endif

define TEST_BUSYBOX
test_busybox_$(1):
	(cd $(BUSYBOX_SRC)/testsuite && bindir=$(BUILDDIR) ./runtest $(RUNTEST_ARGS) $(1) )
endef

# Output names
EXES        := \
	$(sort $(filter $(UTILS),$(filter-out $(SKIP_UTILS),$(PROGS))))

INSTALLEES  := ${EXES}
ifeq (${MULTICALL}, y)
INSTALLEES  := ${INSTALLEES} uutils
endif

# Shared library extension
SYSTEM := $(shell uname)
DYLIB_EXT :=
ifeq ($(SYSTEM),Linux)
	DYLIB_EXT    := so
	DYLIB_FLAGS  := -shared
endif
ifeq ($(SYSTEM),Darwin)
	DYLIB_EXT    := dylib
	DYLIB_FLAGS  := -dynamiclib -undefined dynamic_lookup
endif

all: build ## Build

do_install = $(INSTALL) ${1}
use_default := 1

build-pkgs: ## Build packages
ifneq (${MULTICALL}, y)
	${CARGO} build ${CARGOFLAGS} ${PROFILE_CMD} $(foreach pkg,$(EXES),-p $(pkg))
endif

build-uutils: ## Build coreutils
	${CARGO} build ${CARGOFLAGS} --features "${EXES}" ${PROFILE_CMD} --no-default-features

build-manpages:
	cd $(DOCSDIR) && $(MAKE) man

build: build-uutils build-pkgs build-manpages

$(foreach test,$(filter-out $(SKIP_UTILS),$(PROGS)),$(eval $(call TEST_BUSYBOX,$(test))))

test: ## Test
	${CARGO} test ${CARGOFLAGS} --features "$(TESTS) $(TEST_SPEC_FEATURE)" --no-default-features $(TEST_NO_FAIL_FAST)

busybox-src:
	if [ ! -e $(BUSYBOX_SRC) ]; then \
	mkdir -p $(BUSYBOX_ROOT); \
	wget https://busybox.net/downloads/busybox-$(BUSYBOX_VER).tar.bz2 -P $(BUSYBOX_ROOT); \
	tar -C $(BUSYBOX_ROOT) -xf $(BUSYBOX_ROOT)/busybox-$(BUSYBOX_VER).tar.bz2; \
	fi; \

# This is a busybox-specific config file their test suite wants to parse.
$(BUILDDIR)/.config: $(BASEDIR)/.busybox-config
	cp $< $@

# Test under the busybox testsuite
$(BUILDDIR)/busybox: busybox-src build-uutils $(BUILDDIR)/.config
	cp $(BUILDDIR)/uutils $(BUILDDIR)/busybox; \
	chmod +x $@;

ifeq ($(EXES),)
busytest:
else
busytest: $(BUILDDIR)/busybox $(addprefix test_busybox_,$(filter-out $(SKIP_UTILS),$(EXES)))
endif

clean: ## Clean
	$(RM) $(BUILDDIR)
	cd $(DOCSDIR) && $(MAKE) clean

distclean: clean
	$(CARGO) clean $(CARGOFLAGS) && $(CARGO) update $(CARGOFLAGS)

install: build ## Install
	mkdir -p $(INSTALLDIR_BIN)
	mkdir -p $(INSTALLDIR_MAN)
ifeq (${MULTICALL}, y)
	$(INSTALL) $(BUILDDIR)/uutils $(INSTALLDIR_BIN)/$(PROG_PREFIX)uutils
	cd $(INSTALLDIR_BIN) && $(foreach prog, $(filter-out uutils, $(INSTALLEES)), \
		ln -fs $(PROG_PREFIX)uutils $(PROG_PREFIX)$(prog) &&) :
	cat $(DOCSDIR)/_build/man/uutils.1 | gzip > $(INSTALLDIR_MAN)/$(PROG_PREFIX)uutils.1.gz
else
	$(foreach prog, $(INSTALLEES), \
		$(INSTALL) $(BUILDDIR)/$(prog) $(INSTALLDIR_BIN)/$(PROG_PREFIX)$(prog);)
endif
	$(foreach man, $(filter $(INSTALLEES), $(basename $(notdir $(wildcard $(DOCSDIR)/_build/man/*)))), \
		cat $(DOCSDIR)/_build/man/$(man).1 | gzip > $(INSTALLDIR_MAN)/$(PROG_PREFIX)$(man).1.gz &&) :

uninstall: ## Un-install
ifeq (${MULTICALL}, y)
	rm -f $(addprefix $(INSTALLDIR_BIN)/,$(PROG_PREFIX)uutils)
endif
	rm -f $(addprefix $(INSTALLDIR_MAN)/,$(PROG_PREFIX)uutils.1.gz)
	rm -f $(addprefix $(INSTALLDIR_BIN)/$(PROG_PREFIX),$(PROGS))
	rm -f $(addprefix $(INSTALLDIR_MAN)/$(PROG_PREFIX),$(addsuffix .1.gz,$(PROGS)))

.PHONY: all build build-uutils build-pkgs build-docs test distclean clean busytest install uninstall

####

# require at least `make` v4.0 (minimum needed for correct path functions)
MAKE_VERSION_major := $(word 1,$(subst ., ,${MAKE_VERSION}))
MAKE_VERSION_minor := $(word 2,$(subst ., ,${MAKE_VERSION}))
MAKE_VERSION_fail := $(filter ${MAKE_VERSION_major},3 2 1 0)
ifeq (${MAKE_VERSION_major},4)
MAKE_VERSION_fail := $(filter ${MAKE_VERSION_minor},)
endif
$(call %debug_var,MAKE_VERSION)
$(call %debug_var,MAKE_VERSION_major)
$(call %debug_var,MAKE_VERSION_minor)
$(call %debug_var,MAKE_VERSION_fail)
ifneq (${MAKE_VERSION_fail},)
$(call %error,`make` v4.0+ required (currently using v${MAKE_VERSION}))
endif

####

makefile_path := $(lastword ${MAKEFILE_LIST})
makefile_abs_path := $(abspath ${makefile_path})
makefile_dir := $(abspath $(dir ${makefile_abs_path}))
current_dir := ${CURDIR}
make_invoke_alias ?= $(if $(call %eq,Makefile,${makefile_path}),make,make -f "${makefile_path}")

$(call %debug_var,makefile_path)
$(call %debug_var,makefile_abs_path)
$(call %debug_var,makefile_dir)
$(call %debug_var,current_dir)
$(call %debug_var,current_dir)

####

devnull := $(if $(filter win,${OSID}),NUL,/dev/null)
int_max := 2147483647## largest signed 32-bit integer; used as arbitrary max expected list length

NULL := $()
BACKSLASH := $()\$()
COMMA := ,
DOT := .
ESC := $()$()## literal ANSI escape character (required for ANSI color display output; also used for some string matching)
HASH := \#
PAREN_OPEN := $()($()
PAREN_CLOSE := $())$()
SLASH := /
SPACE := $() $()

%tr = $(strip $(if ${1},$(call %tr,$(wordlist 2,$(words ${1}),${1}),$(wordlist 2,$(words ${2}),${2}),$(subst $(firstword ${1}),$(firstword ${2}),${3})),${3}))

ifeq (${OSID},win)
%shell_quote = $(call %tr,^ | < > %,^^ ^| ^< ^> ^%,${1})
else
%shell_quote = '$(call %tr,','"'"',${1})'
endif

####

color_black := $(if $(call %is_truthy,${COLOR}),${ESC}[0;30m,)
color_blue := $(if $(call %is_truthy,${COLOR}),${ESC}[0;34m,)
color_cyan := $(if $(call %is_truthy,${COLOR}),${ESC}[0;36m,)
color_green := $(if $(call %is_truthy,${COLOR}),${ESC}[0;32m,)
color_magenta := $(if $(call %is_truthy,${COLOR}),${ESC}[0;35m,)
color_red := $(if $(call %is_truthy,${COLOR}),${ESC}[0;31m,)
color_yellow := $(if $(call %is_truthy,${COLOR}),${ESC}[0;33m,)
color_white := $(if $(call %is_truthy,${COLOR}),${ESC}[0;37m,)
color_reset := $(if $(call %is_truthy,${COLOR}),${ESC}[0m,)
#
color_success := ${color_green}
color_debug := ${color_cyan}
color_info := ${color_blue}
color_warning := ${color_yellow}
color_error := ${color_red}

%error_text = ${color_error}ERR!:${color_reset} ${1}
%debug_text = ${color_debug}debug:${color_reset} ${1}
%info_text = ${color_info}info:${color_reset} ${1}
%success_text = ${color_success}SUCCESS:${color_reset} ${1}
%warning_text = ${color_warning}WARN:${color_reset} ${1}
%error = $(error $(call %error_text,${1}))
%debug = $(if $(call %is_truthy,${MAKEFLAGS_debug}),$(info $(call %debug_text,${1})),)
%info = $(info $(call %info_text,${1}))
%success = $(info $(call %success_text,${1}))
%warning = $(warning $(call %warning_text,${1}))

%debug_var = $(call %debug,${1}="${${1}}")

####

ifeq (${OSID},win)
OSID_name  := windows
OS_PREFIX  := win.
EXEEXT     := .exe
#
AWK        := gawk ## from `scoop install gawk`; or "goawk" from `go get github.com/benhoyt/goawk`
CAT        := "${SystemRoot}\System32\findstr" /r .*
CP         := copy /y
ECHO       := echo
GREP       := grep ## from `scoop install grep`
MKDIR      := mkdir
RM         := del
RM_r       := $(RM) /s
RMDIR      := rmdir /s/q
FIND       := "${SystemRoot}\System32\find"
FINDSTR    := "${SystemRoot}\System32\findstr"
MORE       := "${SystemRoot}\System32\more"
SORT       := "${SystemRoot}\System32\sort"
WHICH      := where
#
ECHO_newline := echo.
else
OSID_name  ?= $(shell uname | tr '[:upper:]' '[:lower:]')
OS_PREFIX  := ${OSID_name}.
EXEEXT     := $()
#
AWK        := awk
CAT        := cat
CP         := cp
ECHO       := echo
GREP       := grep
MKDIR      := mkdir -p
RM         := rm
RM_r       := ${RM} -r
RMDIR      := ${RM} -r
SORT       := sort
WHICH      := which
#
ECHO_newline := echo
endif

####

.PHONY: help
help: ## Display help
	@${ECHO} $(call %shell_quote,`${make_invoke_alias}`)
	@${ECHO} $(call %shell_quote,Usage: `${make_invoke_alias} [ARCH=..] [CC_DEFINES=..] [COLOR=..] [DEBUG=..] [STATIC=..] [TARGET=..] [VERBOSE=..] [MAKE_TARGET...]`)
	@${ECHO} $(call %shell_quote,Builds '...' within "$(current_dir)")
	@${ECHO_newline}
	@${ECHO} $(call %shell_quote,MAKE_TARGETs:)
	@${ECHO_newline}
ifeq (${OSID},win)
	@${FINDSTR} "^[a-zA-Z-]*:.*${HASH}${HASH}" "${makefile_path}" | ${SORT} | for /f "tokens=1-2,* delims=:${HASH}" %%g in ('${MORE}') do @(@call set "t=%%g                " & @call echo ${color_success}%%t:~0,15%%${color_reset} ${color_info}%%i${color_reset})
else
	@${GREP} -P "(?i)^[[:alpha:]-]+:" "${makefile_path}" | ${SORT} | ${AWK} 'match($$0,"^([[:alpha:]]+):.*?${HASH}${HASH}\\s*(.*)$$",m){ printf "${color_success}%-10s${color_reset}\t${color_info}%s${color_reset}\n", m[1], m[2] }END{printf "\n"}'
endif
