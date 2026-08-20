SJASMPLUS ?= sjasmplus
SYMBOS_SDK ?= ../SymbOS-ASM-Developer-kit

BUILD_DIR := build
APP := $(BUILD_DIR)/symzilla.exe
FIXTURE := $(BUILD_DIR)/test3.dox
FORM_FIXTURE := $(BUILD_DIR)/form-test.dox
SYMBOLS := $(BUILD_DIR)/symzilla.sym

.PHONY: all clean check

all: $(APP) $(FIXTURE) $(FORM_FIXTURE)

$(APP) $(FIXTURE) $(FORM_FIXTURE) &: App-Zilla1.asm App-Zilla.asm Dox-Test3.asm Dox-Form.asm
	@test -x "$$(command -v $(SJASMPLUS))" || { echo "sjasmplus not found: $(SJASMPLUS)" >&2; exit 1; }
	@test -f "$(SYMBOS_SDK)/LIB/SymbOS-Constants.asm" || { echo "SymbOS SDK not found: $(SYMBOS_SDK)" >&2; exit 1; }
	@mkdir -p $(BUILD_DIR)
	@rm -f $(APP) $(FIXTURE) $(FORM_FIXTURE) $(SYMBOLS)
	@$(SJASMPLUS) --nologo --cleanonerror \
		-I"$(SYMBOS_SDK)/LIB" \
		--sym=$(SYMBOLS) App-Zilla1.asm

check: all
	@test "$$(dd if=$(APP) bs=1 skip=48 count=8 2>/dev/null)" = "SymExe10"
	@test "$$(od -An -t x1 -j 88 -N 2 $(APP) | tr -d ' \n')" = "0003"
	@test "$$(dd if=$(FIXTURE) bs=1 count=4 2>/dev/null)" = "INFO"
	@test "$$(dd if=$(FORM_FIXTURE) bs=1 count=4 2>/dev/null)" = "INFO"
	@test "$$(stat -c %s $(FORM_FIXTURE))" -eq 311
	@test "$$(sha256sum $(FORM_FIXTURE) | cut -d' ' -f1)" = "9681aff760eb25bb134468ca8006fc5bdef442bb361fc31898d33cc7e044ede5"
	@set -eu; \
		set -- $$(od -An -t u2 -N 10 $(APP)); \
		static_size=$$(($$1 + $$2 + $$3)); \
		header_count=$$5; \
		table_bytes=$$(($$(stat -c %s $(APP)) - static_size)); \
		test $$((table_bytes % 2)) -eq 0; \
		actual_count=$$((table_bytes / 2)); \
		test "$$header_count" -eq "$$actual_count" || { \
			echo "relocation count mismatch: header=$$header_count table=$$actual_count" >&2; \
			exit 1; \
		}
	@set -eu; \
		sym() { \
			awk -v symbol="$$1:" \
				'$$1 == symbol && $$2 == "EQU" { print $$3; found = 1; exit } \
				 END { if (!found) exit 1 }' $(SYMBOLS); \
		}; \
		cfgbeg=$$(sym cfgbeg); \
		cfghom=$$(sym cfghom); \
		favanz=$$(sym favanz); \
		favmem=$$(sym favmem); \
		cfgnav=$$(sym cfgnav); \
		cfglnk=$$(sym cfglnk); \
		cfgsta=$$(sym cfgsta); \
		cfgproxy=$$(sym cfgproxy); \
		cfgend=$$(sym cfgend); \
		ctrmax=$$(sym ctrmax); \
		ctrmemmax=$$(sym ctrmemmax); \
		ctrextlen=$$(sym ctrextlen); \
		test "$$((cfghom - cfgbeg))" -eq 0; \
		test "$$((favanz - cfgbeg))" -eq 128; \
		test "$$((favmem - cfgbeg))" -eq 129; \
		test "$$((cfgnav - cfgbeg))" -eq 1665; \
		test "$$((cfglnk - cfgbeg))" -eq 1666; \
		test "$$((cfgsta - cfgbeg))" -eq 1667; \
		test "$$((cfgproxy - cfgbeg))" -eq 1668; \
		test "$$((cfgend - cfgbeg))" -eq 1732; \
		test "$$((ctrmax))" -eq 16; \
		test "$$((ctrmemmax))" -eq 2048; \
		test "$$((ctrextlen))" -eq 15
	@set -eu; \
		sym() { \
			awk -v symbol="$$1:" \
				'$$1 == symbol && $$2 == "EQU" { print $$3; found = 1; exit } \
				 END { if (!found) exit 1 }' $(SYMBOLS); \
		}; \
		for symbol in netdox netabort nettmpdel nettmppth netgetbyte netrxpending nettimeini nettick \
			lodctl ctrgetrec ctractval brwlnkget ctrclk ctrencode; do \
			value=$$(sym "$$symbol"); \
			test "$$((value))" -ne 0 || { echo "unresolved required symbol: $$symbol" >&2; exit 1; }; \
		done
	@if grep -q '^SyNet_TCPRLN:' $(SYMBOLS); then \
		echo "unexpected TCPRLN dependency in SymZilla" >&2; \
		exit 1; \
	fi
	@grep -aqF 'Accept: application/x-symbos-dox' $(APP)
	@grep -aqF 'X-GB-SGX: ' $(APP)
	@grep -aqF 'Accept-Encoding: identity' $(APP)
	@grep -aqF 'Connection: close' $(APP)
	@grep -aqF 'CTRL' $(APP)
	@grep -aqF 'Ribbbit!' $(FORM_FIXTURE)
	@echo "SymZilla build checks passed"

clean:
	rm -rf $(BUILD_DIR)
