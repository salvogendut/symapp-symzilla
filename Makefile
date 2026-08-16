SJASMPLUS ?= sjasmplus
SYMBOS_SDK ?= ../SymbOS-ASM-Developer-kit

BUILD_DIR := build
APP := $(BUILD_DIR)/symzilla.exe
FIXTURE := $(BUILD_DIR)/test3.dox
SYMBOLS := $(BUILD_DIR)/symzilla.sym

.PHONY: all clean check

all: $(APP) $(FIXTURE)

$(APP) $(FIXTURE) &: App-Zilla1.asm App-Zilla.asm Dox-Test3.asm
	@test -x "$$(command -v $(SJASMPLUS))" || { echo "sjasmplus not found: $(SJASMPLUS)" >&2; exit 1; }
	@test -f "$(SYMBOS_SDK)/LIB/SymbOS-Constants.asm" || { echo "SymbOS SDK not found: $(SYMBOS_SDK)" >&2; exit 1; }
	@mkdir -p $(BUILD_DIR)
	@rm -f $(APP) $(FIXTURE) $(SYMBOLS)
	@$(SJASMPLUS) --nologo --cleanonerror \
		-I"$(SYMBOS_SDK)/LIB" \
		--sym=$(SYMBOLS) App-Zilla1.asm

check: all
	@test "$$(dd if=$(APP) bs=1 skip=48 count=8 2>/dev/null)" = "SymExe10"
	@test "$$(od -An -t x1 -j 88 -N 2 $(APP) | tr -d ' \n')" = "0003"
	@test "$$(dd if=$(FIXTURE) bs=1 count=4 2>/dev/null)" = "INFO"
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
		test "$$((cfghom - cfgbeg))" -eq 0; \
		test "$$((favanz - cfgbeg))" -eq 128; \
		test "$$((favmem - cfgbeg))" -eq 129; \
		test "$$((cfgnav - cfgbeg))" -eq 1665; \
		test "$$((cfglnk - cfgbeg))" -eq 1666; \
		test "$$((cfgsta - cfgbeg))" -eq 1667; \
		test "$$((cfgproxy - cfgbeg))" -eq 1668; \
		test "$$((cfgend - cfgbeg))" -eq 1732
	@set -eu; \
		sym() { \
			awk -v symbol="$$1:" \
				'$$1 == symbol && $$2 == "EQU" { print $$3; found = 1; exit } \
				 END { if (!found) exit 1 }' $(SYMBOLS); \
		}; \
		for symbol in netdox netabort nettmpdel nettmppth; do \
			value=$$(sym "$$symbol"); \
			test "$$((value))" -ne 0 || { echo "unresolved network symbol: $$symbol" >&2; exit 1; }; \
		done
	@grep -aqF 'Accept: application/x-symbos-dox' $(APP)
	@grep -aqF 'X-GB-SGX: ' $(APP)
	@grep -aqF 'Accept-Encoding: identity' $(APP)
	@grep -aqF 'Connection: close' $(APP)
	@echo "SymZilla build checks passed"

clean:
	rm -rf $(BUILD_DIR)
