; WinAPE source compatibility for SjAsmPlus.
    DEFINE write OUTPUT
    DEFINE READ INCLUDE
    DEFINE nolist OPT listoff
    OPT --syntax=abfw --dirbol

nolist

write "build/symzilla.exe"
org #1000
READ "SymbOS-Constants.asm"
READ "App-Zilla.asm"

write "build/test3.dox"
org #0000
READ "Dox-Test3.asm"

write "build/form-test.dox"
org #0000
READ "Dox-Form.asm"
