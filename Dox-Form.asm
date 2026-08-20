; Minimal FrogFind-compatible GET form fixture.  This is intentionally byte-for-
; byte compatible with the GB-proxy CTRL contract used by SymZilla.

db "INFO"
dw frminfe-frminf,0
frminf
db "FrogFind!",0
db "GB-proxy",0
db "SymbOS",0
db "1",0
db 0
db "Web page",0
db "Internet",0
frminfe

db "HEAD"
dw 6,0
dw 200,600
db 0,2

db "TEXT"
dw frmtxte-frmtxt,0
frmtxt
db 8,3,"Leap to: "
db 10,7,1,#80,0,1,5,1
db " "
db 10,7,2,#80,0,1,5,1
db " Australia "
db 8,3,4,2,1,1,0,-1
frmtxte

db "GRPH"
dw 1,0
db 0

db "LINK"
dw frmlnke-frmlnk,0
frmlnk
db 1
dw frmlnk1e-frmlnk1
frmlnk1 db 0,"http://192.168.68.223:5001/u/frogfixture",0
frmlnk1e
frmlnke

db "CTRL"
dw frmctre-frmctr,0
frmctr
dw frmrecs_e-frmrecs,frmstrs_e-frmstrs
frmrecs
db 2
dw frmrec1e-frmrec1,frmrec2e-frmrec2
frmrec1 db 1,32,160,12
        dw 1,2
        db 63
frmrec1e
frmrec2 db 1,16,80,12
        dw -1,3
frmrec2e
frmrecs_e
frmstrs
frmstr1 dw frmstr1e-frmstr1
        db "q",0
frmstr1e
frmstr2 dw frmstr2e-frmstr2
        ds 64
frmstr2e
frmstr3 dw frmstr3e-frmstr3
        db "Ribbbit!",0
frmstr3e
        dw 0
frmstrs_e
frmctre

db "ENDF"
dw 0,0
