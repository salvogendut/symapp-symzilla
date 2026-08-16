;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@                                                                            @
;@                   S y m Z i l l a    (Internet Browser)                    @
;@                                                                            @
;@             (c) 2007-2010 by Prodatron / SymbiosiS (Jorn Mika)             @
;@                                                                            @
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

;todo
;- status bar korrekt an/aus
;+ DOX-aendern -> spalten-infos durfen keine 0en enthalten (z.b. unterstes und oberstes bit setzen und bitshift durchfuhren; multiplyer +1)
;+ xml2dox
;+ inline objects
;- caching/scroll in big dox files
;- row/colspan


;--- DOX-RENDERING-ENGINE (LOADER) --------------------------------------------
;>>> LODDOX -> Loads a new DOX document (and removes the old one, if existing)
;### LODINF -> Loads the info part of a DOX document
;### LODIDX -> Loads the index part of a DOX document
;### LODTXT -> Loads the text part of a DOX document
;### LODGFX -> Loads the graphic part of a DOX document
;>>> LODCLR -> Removes the current DOX document, if existing

;--- DOX-RENDERING-ENGINE (TEXT) ----------------------------------------------
;>>> RENINI -> Initialise rendering engine
;>>> RENSIZ -> test, if window width changes, and re-render the document if needed
;>>> RENDOX -> Renders a DOX document
;### RENPAR -> Renders one paragraph
;### RENCLM -> Renders one column
;### RENLIN -> Renders one line
;### RENCTL -> Handles control codes
;### RENJUS -> Justify current textline, if required
;### RENFNT -> Initialize selected font
;### RENCLC -> Calculates the width and size of a column depending on the screen width

;--- DOX-RENDERING-ENGINE (GRAPHICS) ------------------------------------------
;### GFXINF -> Get information about a graphic
;### GFXFET -> Fetches the next graphic from the left/right stack
;### GFXFIN -> Finish the remaining graphics
;### GFXEND -> Test, if old graphic is existing or has been passed
;### GFXNEW -> Test, if new graphic is available and add it
;### GFXCTL -> Adds a new graphic control, if necessary and possible

;--- DOX-RENDERING-ENGINE (SUBS) ----------------------------------------------
;### SYSCLL -> Call operating system function
;### CLCDI8 -> Divides two values (8bit)
;### CLCD16 -> Divides two values (16bit)
;### CLCDIV -> Divides two values (24bit)
;### CLCMUL -> Multiplies two values (24bit)


relocate_start

;==============================================================================
;### CODE-AREA ################################################################
;==============================================================================

;### PROGRAMM-KOPF ############################################################

prgdatcod       equ 0           ;Lange Code-Teil (Pos+Len beliebig; inklusive Kopf!)
prgdatdat       equ 2           ;Lange Daten-Teil (innerhalb 16K Block)
prgdattra       equ 4           ;Lange Transfer-Teil (ab #C000)
prgdatorg       equ 6           ;Original-Origin
prgdatrel       equ 8           ;Anzahl Eintrage Relocator-Tabelle
prgdatstk       equ 10          ;Lange Stack (Transfer-Teil beginnt immer mit Stack)
prgdatrs1       equ 12          ;*reserved* (3 bytes)
prgdatnam       equ 15          ;program name (24+1[0] chars)
prgdatflg       equ 40          ;flags (+1=16colour icon available)
prgdat16i       equ 41          ;file offset of 16colour icon
prgdatrs2       equ 43          ;*reserved* (5 bytes)
prgdatidn       equ 48          ;"SymExe10"
prgdatcex       equ 56          ;zusatzlicher Speicher fur Code-Bereich
prgdatdex       equ 58          ;zusatzlicher Speicher fur Data-Bereich
prgdattex       equ 60          ;zusatzlicher Speicher fur Transfer-Bereich
prgdatres       equ 62          ;*reserviert* (26 bytes)
prgdatver       equ 88          ;required OS version (1.0)
prgdatism       equ 90          ;Icon (klein)
prgdatibg       equ 109         ;Icon (gross)
prgdatlen       equ 256         ;Datensatzlange

prgpstdat       equ 6           ;Adresse Daten-Teil
prgpsttra       equ 8           ;Adresse Transfer-Teil
prgpstspz       equ 10          ;zusatzliche Prozessnummern (4*1)
prgpstbnk       equ 14          ;Bank (1-8)
prgpstmem       equ 48          ;zusatzliche Memory-Bereiche (8*5)
prgpstnum       equ 88          ;Programm-Nummer
prgpstprz       equ 89          ;Prozess-Nummer

prgcodbeg   dw prgdatbeg-prgcodbeg  ;Lange Code-Teil
            dw prgtrnbeg-prgdatbeg  ;Lange Daten-Teil
            dw prgtrnend-prgtrnbeg  ;Lange Transfer-Teil
prgdatadr   dw #1000                ;Original-Origin                    POST Adresse Daten-Teil
prgtrnadr   dw relocate_count       ;Anzahl Eintrage Relocator-Tabelle  POST Adresse Transfer-Teil
prgprztab   dw prgstk-prgtrnbeg     ;Lange Stack                        POST Tabelle Prozesse
            dw 0                    ;*reserved*
prgbnknum   db 0                    ;*reserved*                         POST bank number
            db "SymZilla Browser":ds 8:db 0 ;Name
            db 1                    ;flags (+1=16c icon)
            dw prgicn16c-prgcodbeg  ;16 colour icon offset
            ds 5                    ;*reserved*
prgmemtab   db "SymExe10"           ;SymbOS-EXE-Kennung                 POST Tabelle Speicherbereiche
            dw 0                            ;zusatzlicher Code-Speicher
            dw 16380-prgtrnbeg+prgdatbeg    ;zusatzlicher Data-Speicher
            dw renviwmax*24                 ;zusatzlicher Transfer-Speicher
            ds 26                   ;*reserviert*
            db 0,3                  ;required OS version (3.0, Network Daemon API)
prgicnsml   db 2,8,8,#30,#F0,#43,#2C,#53,#AC,#43,#2C,#53,#AC,#43,#2C,#53,#AC,#F0,#C0
prgicnbig   db 6,24,24
            db #00,#00,#00,#00,#01,#0E,#00,#00,#01,#0E,#7C,#F0,#00,#00,#13,#F8,#E7,#3E,#00,#00,#35,#F7,#97,#8F,#00,#00,#34,#F1,#9F,#E3,#00,#00,#34,#F6,#C7,#F9,#00,#00,#F9,#F7,#6F,#CB,#00,#32,#F6,#CF,#F9,#4F
            db #01,#FB,#1F,#DF,#78,#8F,#36,#8F,#0F,#6D,#6F,#CF,#63,#0F,#0F,#EB,#0F,#2F,#69,#0F,#1E,#D3,#0F,#3D,#69,#0F,#7C,#F0,#0F,#2D,#6F,#0F,#F0,#F1,#0F,#7D,#CF,#7C,#F4,#F1,#0F,#F9,#78,#F3,#F1,#EB,#0F,#BD
            db #72,#F8,#CF,#0F,#3F,#6F,#74,#C7,#7C,#CF,#E9,#4F,#32,#F2,#F0,#F0,#C3,#0F,#01,#78,#F7,#F8,#87,#0F,#00,#17,#0E,#34,#C3,#0F,#00,#00,#00,#10,#E7,#0F,#00,#00,#00,#01,#B7,#0F,#00,#00,#00,#00,#E9,#0F

;### PRGPRZ -> Programm-Prozess
dskprzn     db 2
sysprzn     db 3
windatprz   equ 3   ;Prozessnummer
windatsup   equ 51  ;Nummer des Superfensters+1 oder 0
prgwin      db 0    ;Nummer des Haupt-Fensters

prgprz  ld a,(prgprzn)
        ld (prgwindat+windatprz),a
        ld (configwin+windatprz),a
        ld (prgwinlnk+windatprz),a

        call SySystem_HLPINI
        call prgpar
        call cfgini
        call barini
        call renini
        call favini

        ld c,MSC_DSK_WINOPN
        ld a,(prgbnknum)
        ld b,a
        ld de,prgwindat
        call msgsnd             ;open window
prgprz1 call msgdsk
        cp MSR_DSK_WOPNER
        jp z,prgend             ;no memory for new window -> end
        cp MSR_DSK_WOPNOK
        jr nz,prgprz1
        ld a,(prgmsgb+4)
        ld (prgwin),a           ;window has been opend successfully -> store ID
        ld a,(prgparf)
        or a
        jp nz,brwopn
        jp navhom

prgprz0 ld hl,(rensiz+1)
        ld a,l
        or h
        jp z,rensiz
        call msgget
        cp MSR_DSK_WRESIZ       ;*** window has been resized
        jp z,rensiz
        cp MSR_DSK_CFOCUS       ;*** control focus changed
        jp z,favfoc
        cp MSR_SYS_SELOPN       ;*** browse windows has been closed
        jp z,brwsec
        cp MSR_DSK_WCLICK       ;*** window action
        jr nz,prgprz0
        ld a,(iy+2)
        cp DSK_ACT_CLOSE        ;*** close has been clicked
        jr nz,prgprz4
        ld e,(iy+1)
        ld a,(prgwin)
        cp e
        jr z,prgend
        ld a,(diawin)
        cp e
        jp z,cfgset1
        jp favman1
prgprz4 cp DSK_ACT_MENU         ;*** menu has been clicked
        jr z,prgprz2
        cp DSK_ACT_CONTENT      ;*** content has been clicked
        jr nz,prgprz0
prgprz2 ld l,(iy+8)
        ld a,(iy+9)
        cp 1
        jr c,prgprz3
        jp z,favjmp
        ld h,a
        ld a,(iy+3)             ;A=click type (0/1/2=mouse left/right/double, 7=keyboard)
        jp (hl)
prgprz3 inc l
        jr z,prgprz0
        dec l                   ;L=link (1-254)
        jr z,prgprz0
        jp brwlnk

;### PRGEND -> Exit program
prgend  call netabort           ;close an active download and remove its temp file
        call lodclr             ;remove current DOX
        ld a,(prgwin)           ;close window(s) to prevent the delay caused by config saving
        call diaclo0
        call favman0
        call cfgsav             ;save config
        ld a,(prgprzn)
        db #dd:ld l,a
        ld a,(sysprzn)
        db #dd:ld h,a
        ld iy,prgmsgb
        ld (iy+0),MSC_SYS_PRGEND
        ld a,(prgcodbeg+prgpstnum)
        ld (iy+1),a
        rst #10
prgend0 rst #30
        jr prgend0

;### PRGINF -> Info-Fenster anzeigen
prginf  ld hl,prgmsginf         ;*** Info-Fenster
        ld b,1+128
        call prginf0
        jp prgprz0
prginf0 ld (prgmsgb+1),hl
        ld a,(prgbnknum)
        ld c,a
        ld (prgmsgb+3),bc
        ld a,MSC_SYS_SYSWRN
        ld (prgmsgb),a
prginf2 ld a,(prgprzn)
        db #dd:ld l,a
        ld a,(sysprzn)
        db #dd:ld h,a
        ld iy,prgmsgb
        rst #10
        ret

;### PRGPAR -> Search for command line parameter (DOX file)
prgparf db 0                    ;flag, if command line parameter exists

prgpar  ld hl,(prgcodbeg)       ;search for command line parameter
        ld de,prgcodbeg
        dec h
        add hl,de               ;HL=code area end=path
        ld b,255
prgpar1 ld a,(hl)
        or a
        ret z
        cp 32
        jr z,prgpar2
        inc hl
        djnz prgpar1
        ret
prgpar2 ld (hl),0
        inc hl
        ld de,doxpth
        ld bc,255
        ld a,c
        ld (prgparf),a
        ldir
        ret


;==============================================================================
;### SUB-ROUTINES #############################################################
;==============================================================================

;### DIRLOC -> tests the location of a document
;### Input      HL=filename
;### Output     A=type (0=unknown, 1=file, 2=HTTP, 16=about blank, 17=about symzilla)
dirloci db "HTTP://???????",2
        db "HTTPS://??????",2
        db "?:\???????????",1
        db "?:/???????????",1
        db "ABOUT:BLANK",0,"??",16
        db "ABOUT:",0,"???????",17
        db "ABOUT:SYMZILLA",17

dirloc  ld de,dirloci
        ld c,7
dirloc1 push hl
        push de
        ld b,14
dirloc2 ld a,(de)
        inc de
        cp "?"
        jr z,dirloc3
        cp (hl)
        jr z,dirloc3
        call clclcs
        cp (hl)
        jr z,dirloc3
        pop hl
        ld de,15
        add hl,de
        ex de,hl
        pop hl
        dec c
        jr nz,dirloc1
        xor a
        ret
dirloc3 inc hl
        djnz dirloc2
        pop hl
        pop hl
        ld a,(de)
        ret

;### DIREND -> searches for the end of a path
;### Input      HL=path string, which may contain a filename
;### Output     DE=position of the first char behind the path-part, C=length
;### Destroyed
dirend  ld c,0
dirend0 ld e,l
        ld d,h
dirend1 ld a,(hl)
        inc hl
        or a
        ret z
        inc c
        cp "/"
        jr z,dirend0
        cp #5c
        jr z,dirend0
        cp ":"
        jr z,dirend0
        jr dirend1

;### DIRADD -> Adds a new path string to an existing one
;### Input      HL=new path string (terminated by 0), DE=existing path
;### Output     (existing path)=updated
diraddz dw 0            ;start of existing part
diradd  push hl
        push de
        call dirloc
        pop de
        pop hl
        or a
        jr z,diradd1
        ld bc,256           ;*** new protocol/device -> copy entire new path
        ldir
        ret
diradd1 push hl
        ex de,hl
        ld (diraddz),hl     ;(diraddz)=start of existing path
        call dirend         ;DE=position behind existing path, C=length of string before
        pop hl              ;HL=start of new path
        ld a,(hl)
        call diraddx
        jr nz,diradd4
        inc hl              ;*** root -> DE must be placed behind protocol+domain/device of existing path
        ld c,0
        ld de,(diraddz)
diradd2 ld a,(de)
        or a
        jr z,diradd4
        call diraddx
        jr z,diradd3
diraddc inc de
        inc c
        jr diradd2
diradd3 inc de
        inc c
        ld a,(de)
        call diraddx
        jr z,diraddc        ;DE=points behind protocol/device, C=updated
diradd4 ld a,(hl)           ;*** subdir loop
        cp "."
        jr nz,diradd9
        inc hl
        ld a,(hl)
        cp "."
        jr nz,diraddb
        inc hl
        ld a,(hl)
        or a
        jr z,diradd7
        call diraddx
        jr nz,diradd8
        inc hl
diradd7 dec de              ;*** move one dir down
        dec c               ;DE points on slash
        jr z,diradd6
diradd5 dec de              ;DE points in front of slash
        dec c
        jr z,diradd6
        ld a,(de)
        call diraddx
        jr nz,diradd5       ;until lower slash
diradd6 inc de
        inc c
        jr diradd4
diradd8 dec hl:dec hl
diradd9 ld a,(hl)           ;*** copy until next slash/zero
        ldi
        inc c:inc c
        jr z,diradda
        or a
        ret z
        call diraddx
        jr nz,diradd9
        jr diradd4
diradda dec de
        xor a
        ld (de),a
        ret
diraddb ld (de),a           ;*** maybe same dir
        or a
        ret z
        call diraddx
        dec hl
        jr nz,diradd9
        inc hl:inc hl
        jr diradd4
diraddx cp "/"
        ret z
        cp #5c
        ret

;### MSGGET -> Message fur Programm abholen
;### Ausgabe    IXH=Absender, (recmsgb)=Message, A=(recmsgb+0), IY=recmsgb
;### Veraendert 
msgget  ld a,(prgprzn)
        db #dd:ld l,a           ;IXL=Rechner-Prozess-Nummer
        db #dd:ld h,-1
        ld iy,prgmsgb           ;IY=Messagebuffer
        rst #08                 ;Message holen -> IXL=Status, IXH=Absender-Prozess
        or a
        db #dd:dec l
        jr nz,msgget
        ld iy,prgmsgb
        ld a,(iy+0)
        or a
        ret nz
        jp prgend

;### MSGDSK -> Message fur Programm von Desktop-Prozess abholen
;### Ausgabe    CF=0 -> keine Message vorhanden, CF=1 -> IXH=Absender, (recmsgb)=Message, A=(recmsgb+0), IY=recmsgb
;### Veraendert 
msgdsk  call msgget
        ld a,(dskprzn)
        db #dd:cp h
        jr nz,msgdsk            ;Message von anderem als Desktop-Prozess -> ignorieren
        ld a,(prgmsgb)
        ret

;### MSGSND -> Message an Desktop-Prozess senden
;### Eingabe    C=Kommando, B/E/D/L/H=Parameter1/2/3/4/5
msgsnd0 ld a,(prgwin)
        ld b,a
msgsnd2 ld c,MSC_DSK_WINDIN
msgsnd  ld a,(dskprzn)
msgsnd1 db #dd:ld h,a
        ld a,(prgprzn)
        db #dd:ld l,a
        ld iy,prgmsgb
        ld (iy+0),c
        ld (iy+1),b
        ld (iy+2),e
        ld (iy+3),d
        ld (iy+4),l
        ld (iy+5),h
        rst #10
        ret

;### CLCLCS -> Wandelt Gross- in Kleinbuchstaben um
;### Eingabe    A=Zeichen
;### Ausgabe    A=lcase(Zeichen)
;### Verandert  F
clclcs  cp "A"
        ret c
        cp "Z"+1
        ret nc
        add "a"-"A"
        ret

;### STRINP -> Initialisiert Textinput (abhangig vom String, den es bearbeitet)
;### Eingabe    IX=Control
;### Ausgabe    HL=Stringende (0), BC=Lange (maximal 255)
;### Verandert  AF
strinp  ld l,(ix+0)
        ld h,(ix+1)
        call strlen
        ld (ix+8),c
        ld (ix+4),c
        xor a
        ld (ix+2),a
        ld (ix+6),a
        ret

;### STRLEN -> Ermittelt Lange eines Strings
;### Eingabe    HL=String
;### Ausgabe    HL=Stringende (0), BC=Lange (maximal 255)
;### Verandert  -
strlen  push af
        xor a
        ld bc,255
        cpir
        ld a,254
        sub c
        ld c,a
        dec hl
        pop af
        ret

;### DIAOPN -> Opens dialogue window
diawin  db 0

diaopn  call diaopn0
        ret z
        ld (diawin),a           ;store window number
        inc a
        ld (prgwindat+windatsup),a
        ret
diaopn0 ld c,MSC_DSK_WINOPN     ;open window
        ld a,(prgbnknum)
        ld b,a
        call msgsnd
diaopn1 call msgdsk             ;get message -> IXL=status, IXH=sender
        cp MSR_DSK_WOPNER
        ret z                   ;no more window possible -> end
        cp MSR_DSK_WOPNOK
        jr nz,diaopn1           ;ignore other messages
        ld a,(prgmsgb+4)
        or a
        ret


;### DIACLO -> closes dialogue window
diaclo  ld a,(diawin)
diaclo0 ld b,a
        ld c,MSC_DSK_WINCLS
        jp msgsnd

SySystem_HLPFLG db 0    ;flag, if HLP-path is valid
SySystem_HLPPTH db "%help.exe "
SySystem_HLPPTH1 ds 128
SySHInX db ".HLP",0

SySystem_HLPINI
        ld hl,(prgcodbeg)
        ld de,prgcodbeg
        dec h
        add hl,de                   ;HL = CodeEnd = Command line
        ld de,SySystem_HLPPTH1
        ld bc,0
        db #dd:ld l,128
SySHIn1 ld a,(hl)
        or a
        jr z,SySHIn3
        cp " "
        jr z,SySHIn3
        cp "."
        jr nz,SySHIn2
        ld c,e
        ld b,d
SySHIn2 ld (de),a
        inc hl
        inc de
        db #dd:dec l
        ret z
        jr SySHIn1
SySHIn3 ld a,c
        or b
        ret z
        ld e,c
        ld d,b
        ld hl,SySHInX
        ld bc,5
        ldir
        ld a,1
        ld (SySystem_HLPFLG),a
        ret

hlpopn  ld a,(SySystem_HLPFLG)
        or a
        jp z,prgprz0
        ld a,(prgbnknum)
        ld d,a
        ld a,PRC_ID_SYSTEM
        ld c,MSC_SYS_PRGRUN
        ld hl,SySystem_HLPPTH
        ld b,l
        ld e,h
        call msgsnd1
        jp prgprz0


;==============================================================================
;### CONFIG ###################################################################
;==============================================================================

;### CFGSET -> config dialogue
cfgset  ld ix,configinp1
        call strinp
        ld ix,configinp2
        call strinp
        ld de,configwin
        call diaopn
        jp prgprz0
cfgset1 call diaclo
        jp prgprz0

;### CFGHOMx -> set current or blank page as home page
cfghomb db "about:blank",0

cfghom1 ld hl,doxpth
        jr cfghom3
cfghom2 ld hl,cfghomb
cfghom3 ld de,cfghom
        ld bc,127
        ldir
        ld ix,configinp1
        call strinp
        ld a,(diawin)
        ld b,a
        ld e,3
        call msgsnd2
        jp prgprz0

;### CFGINI -> Generates config path and loads configuration
cfgnam  db "appzilla.ini",0
cfgnam0:
cfgpth  dw 0
cfgfil  dw 0

cfgini  ld hl,(prgcodbeg)
        ld de,prgcodbeg
        dec h
        add hl,de           ;HL = CodeEnd = path
        ld (cfgpth),hl
        ld e,l
        ld d,h              ;DE=HL
        ld b,255
cfgini1 ld a,(hl)           ;search end of path
        or a
        jr z,cfgini2
        inc hl
        djnz cfgini1
        jr cfgini4
        ld a,255
        sub b
        jr z,cfgini4
        ld b,a
cfgini2 dec hl              ;search start of filename
        ld a,(hl)
        cp "/"
        jr z,cfgini3
        cp #5c
        jr z,cfgini3
        cp ":"
        jr z,cfgini3
        djnz cfgini2
        jr cfgini4
cfgini3 inc hl
        ex de,hl
cfgini4 ld (cfgfil),de
        ld hl,cfgnam        ;replace application filename with config filename
        ld bc,cfgnam0-cfgnam
        ldir
        ld hl,(cfgpth)      ;open config
        ld a,(prgbnknum)
        db #dd:ld h,a
        call syscll
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILOPN
        ret c
        ld de,(prgbnknum)   ;load config
        ld hl,cfgbeg
        ld bc,cfgend-cfgbeg
        push af
        call syscll
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILINP
        pop af              ;close config
        call syscll
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILCLO
        ret

;### CFGSAV -> saves config file
cfgsav  ld de,(cfgfil)      ;copy config filename
        ld hl,cfgnam
        ld bc,cfgnam0-cfgnam
        ldir
        ld hl,(cfgpth)      ;open config
        ld a,(prgbnknum)
        db #dd:ld h,a
        xor a
        call syscll
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILNEW
        jp c,prgprz0
        ld de,(prgbnknum)   ;save config
        ld hl,cfgbeg
        ld bc,cfgend-cfgbeg
        push af
        call syscll
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILOUT
        pop af              ;close config
        call syscll
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILCLO
        ret


;==============================================================================
;### FAVOURITES ###############################################################
;==============================================================================

favmax  equ 16
favwin  db -1

;### FAVINI -> Init favourites
favini  call favlnk
favini0 ld a,(favanz)
        add 3
        ld (prgwinmen5),a
        ret

;### FAVLNK -> Updates quicklink bar, and displays it, if visible
favlnk  ld a,(favanz)
        or a
        jr z,favlnk5
        cp 8+1
        jr c,favlnk1
        ld a,8
favlnk1 ld hl,favmem
        ld de,lnkmem
        db #dd:ld l,a
favlnk2 push hl
        push de
        ld bc,256*11+255
favlnk3 ld a,(hl)
        ldi
        jr z,favlnk4
        djnz favlnk3
        dec de
        ex de,hl
        ld (hl),".":inc hl
        ld (hl),".":inc hl
        ld (hl),".":inc hl
        ld (hl),0
favlnk4 pop hl
        ld bc,14
        add hl,bc
        ex de,hl
        pop hl
        ld bc,96
        add hl,bc
        db #dd:dec l
        jr nz,favlnk2
favlnk5 ld a,(cfglnk)
        or a
        ret z
        call barlnk6
        ld a,(cfgnav)
        or a
        ld hl,1+8
        jr z,favlnk6
        ld l,14+8
favlnk6 ld (prgmsgb+6),hl
        ld hl,10000
        ld (prgmsgb+8),hl
        ld hl,12
        ld (prgmsgb+10),hl
        ld l,h
        ld e,h
        ld c,MSC_DSK_WINPIN
        ld a,(prgwin)
        ld b,a
        call msgsnd
        ld de,objnumlnk*256+256-8
        jp msgsnd0

;### FAVMAN -> Open/close Favourites managing dialogue
favman  call favupd
        ld a,(favwin)
        ld b,a
        inc a
        jr z,favman2
        ld c,MSC_DSK_WINTOP
        call msgsnd
        jp prgprz0
favman2 ld de,prgwinlnk
        call diaopn0
        jp z,prgprz0
        ld (favwin),a
        jp prgprz0
favman1 call favman0
        jp prgprz0
favman0 ld hl,favwin
        ld a,(hl)
        cp -1
        ret z
        ld (hl),-1
        jp diaclo0

;### FAVCLK -> User clicked favourite entry
favclk  ld b,a
        ld a,(favanz)
        or a
        jp z,prgprz0
        push bc
        call favupd0
        ld a,(favwin)
        ld b,a
        ld de,256*10+256-2
        call msgsnd2
        pop af
        cp 2
        jp nz,prgprz0
        ld a,(prgwin)
        ld b,a
        ld c,MSC_DSK_WINTOP
        call msgsnd
        ld hl,(prgobjlnk1+12)
        jp favjmp

;### FAVMUP -> Move current entry up
favmup  ld a,(favanz)
        or a
        jp z,prgprz0
        ld hl,prgobjlnk1+12
        ld a,(hl)
        sub 1
        jp c,prgprz0
        ld (hl),a
favmup1 call favupd6
        ld hl,96
        ld b,l
        add hl,de
favmup2 ld a,(de)
        ld c,a
        ld a,(hl)
        ld (de),a
        ld (hl),c
        inc hl
        inc de
        djnz favmup2
        ld a,(favanz)
        ld c,a
        call favupd3
        jp favfoc2

;### FAVMDW -> Move current entry down
favmdw  ld a,(favanz)
        sub 1
        jp c,prgprz0
        ld hl,prgobjlnk1+12
        cp (hl)
        jp z,prgprz0
        ld a,(hl)
        inc (hl)
        jr favmup1

;### FAVDEL -> Delete current entry
favdel  ld hl,favanz
        ld a,(hl)
        or a
        jp z,prgprz0
        dec a
        ld (hl),a
        push af
        call favupd5
        ld a,(prgobjlnk1+12)
        ld b,a
        pop af
        sub b
        jr z,favdel1
        add a:add a:add a:add a
        ld l,a
        ld h,0
        add hl,hl
        ld c,l
        ld b,h
        add hl,hl
        add hl,bc
        ld c,l
        ld b,h
        ld hl,96
        add hl,de
favdel0 ldir
favdel1 call favupd
        jp prgprz0

;### FAVNEW -> Add new empty entry
favnewt db "New Bookmark",0
favnew  ld hl,favanz
        ld a,(hl)
        cp favmax
        jp z,prgprz0
        inc (hl)
        ld (prgobjlnk1+12),a
        call favupd5
        ld hl,favnewt
        ld bc,13
        ldir
        ld l,e
        ld h,d
        dec hl
        ld bc,96-13
        jr favdel0

;### FAVFOC -> Focus changed
favfocl db 0
favfoc  ld a,(favwin)
        cp -1
        jp z,prgprz0
        cp (iy+1)
        jp nz,prgprz0
        ld hl,favfocl
        ld a,(hl)
        ld b,(iy+2)
        ld (hl),b
        cp 10+1
        jp nz,prgprz0
favfoc2 ld a,(favwin)
        ld b,a
        ld e,1
        call msgsnd2
        call favlnk
        jp prgprz0

;### FAVUPD -> Updates Bookmark window (number of entries)
favupd  call favlnk
        call favini0
        sub 3
        ld c,a
        ld (prgobjlnk1),a
        call favupd3
        inc c:dec c
        ld a,64
        jr z,favupd4
        ld a,32
favupd4 ld (prgdatlnk1+02),a
        ld (prgdatlnk1+18),a
        call favupd0
        ld a,(favwin)
        ld b,a
        inc a
        ret z
        ld e,1
        push bc
        call msgsnd2
        pop bc
        ld de,256*9+256-3
        jp msgsnd2
favupd3 ld b,16
        ld hl,lnkentlst+1
        push hl
        ld de,4
favupd1 res 7,(hl)
        add hl,de
        djnz favupd1
        pop de
        ld a,(prgobjlnk1+12)
        cp c
        jr c,favupd2
        ld a,c
        sub 1
        ret c
        ld (prgobjlnk1+12),a
favupd2 add a
        add a
        ld l,a
        ld h,0
        add hl,de
        set 7,(hl)
        ret
favupd0 call favupd5
        ld (prgobjlnk2b),de
        ld hl,26
        add hl,de
        ld (prgobjlnk2d),hl
        ld ix,prgobjlnk2b
        call strinp
        ld ix,prgobjlnk2d
        jp strinp
favupd5 ld a,(prgobjlnk1+12)
favupd6 add a
        add a
        ld l,a
        ld h,0
        ld de,lnkentlst+2
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        ret

;### FAVADD -> Adds the current address to the favourites
favadd  ld hl,favanz
        ld a,(hl)
        cp favmax
        ret z
        inc (hl)
        call favjmp1
        ld bc,favmem
        add hl,bc
        ex de,hl
        ld hl,doxinf
        ld bc,25
        ldir
        inc de
        ld hl,doxpth
        ld bc,69
        ldir
        call favupd
        jp prgprz0

;### FAVJMP -> Jumps to favourite
;### Input      L=number
favjmp  ld a,l
        call favjmp1
        ld bc,favmem+26
        add hl,bc
        ld de,doxpth
        ld bc,79
        ldir
        ld (de),a
        jp brwopn
favjmp1 ld l,a
        xor a
        ld h,a
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        ld c,l
        ld b,h
        add hl,hl
        add hl,bc
        ret


;==============================================================================
;### BAR SWITCH ON/OFF ########################################################
;==============================================================================

;### BARINI -> prepares bars and menuflags
barini  ld hl,prgwinmen3+2
        ld de,cfgnav
        call barini1
        call barnav1
        ld hl,prgwinmen3+2+8
        ld de,cfglnk
        call barini1
        call barlnk1
        ld hl,prgwinmen3+2+16
        ld de,cfgsta
        call barini1
        jr barsta1
barini1 ld a,(de)
        res 1,(hl)
        or (hl)
        ld (hl),a
        and 2
        ret

;### BARSTA -> Switches the status bar on/off
barsta  ld hl,prgwinmen3+2+16
        ld de,cfgsta
        call barnav0
        call barsta1
        jr barnav4
barsta1 ld hl,prgwindat+1
        res 6,(hl)
        ret z
        set 6,(hl)
        ld de,10
        jr z,barsta2
        ld de,-10
barsta2 ld hl,(prgwindat+10)
        add hl,de
        ld (prgwindat+10),hl
        ret

;### BARNAV -> Switches the navigation bar on/off
barnav  ld hl,prgwinmen3+2
        ld de,cfgnav
        call barnav0
        call barnav1
barnav4 ld a,(prgwindat)
        cp 2
        ld c,MSC_DSK_WINMAX
        jr z,barnav3
        ld c,MSC_DSK_WINMID
barnav3 ld a,(prgwin)
        ld b,a
        call msgsnd
        jp prgprz0
barnav1 push af                 ;prepare controls
        call barnav6
        call barlnk4
        pop af
        ld c,64
        jr z,barnav7
        ld c,0
barnav7 ld hl,prgwinobj2+2
        ld b,10
        ld de,16
barnav2 ld a,(hl)
        and 63
        or c
        ld (hl),a
        add hl,de
        djnz barnav2
        ret
barnav0 ld a,(hl)               ;modify menu
        xor 2
        ld (hl),a
        and 2
        ld (de),a
        ret
barnav6 ld b,a
        jr z,barnav8
        ld b,13
barnav8 ld a,(cfglnk)
        or a
        jr z,barnav9
        ld a,13
barnav9 add b
        ld b,a
        inc a
        ld (prgwinclc1+4),a
        inc a
        ld (prgwinclc1+20),a
        ld a,254
        sub b
        ld (prgwinclc1+12),a
        sub 2
        ld (prgwinclc1+28),a
        ret

;### BARLNK -> Switches the link bar on/off
barlnk  ld hl,prgwinmen3+2+8
        ld de,cfglnk
        call barnav0
        call barlnk1
        jr barnav4
barlnk1 call barlnk6
        ld a,(cfgnav)
        or a
        call barnav6
barlnk4 ld hl,prgwinclc0+4
        ld b,8
        ld de,16
        ld a,(cfgnav)
        or a
        ld a,1
        jr z,barlnk5
        ld a,14
barlnk5 ld (hl),a
        add hl,de
        djnz barlnk5
        ret
barlnk6 ld b,8
        ld hl,prgwinobj3+2
        ld de,16
        jr z,barlnk2
        ld a,(favanz)
        cp 8+1
        jr c,barlnk2
        ld a,8
barlnk2 ld (hl),16
        dec a
        jp p,barlnk3
        ld (hl),64
barlnk3 add hl,de
        djnz barlnk2
        ret


;==============================================================================
;### BROWSER ROUTINES #########################################################
;==============================================================================

;### BRWFIL -> Opens the fileselector for loading a new DOX
brwfil  ld a,1
        ld hl,doxmsk
        call brwsel
        jp prgprz0

;### BRWSEL -> Open Browse-Window
;### Input      A=Type (1=DOX-File), HL=Textinput
brwseln db 0
brwsel  ld e,a
        ld a,(brwseln)
        or a
        ret nz
        ld a,e
        ld (brwseln),a
        ld (prgmsgb+8),hl
        ld hl,(prgbnknum)
        ld h,8
        ld (prgmsgb+6),hl
        ld hl,100
        ld (prgmsgb+10),hl
        ld hl,5000
        ld (prgmsgb+12),hl
        ld l,MSC_SYS_SELOPN
        ld (prgmsgb),hl
        jp prginf2

;### BRWSEC -> Close File-Browse-Window
;### Input      P1=Type (0=Ok, 1=Cancel, 2=Fileselector already in use, 3=memory full, 4=no more window available, -1=opened)
;###            P2=path length (P1=0) or window-number (P1=-1)
brwsec  ld hl,(prgmsgb+1)
        inc l
        jr z,brwsec1
        dec l
        ld hl,brwseln
        ld e,(hl)
        ld (hl),0
        jp nz,prgprz0
        jr brwopn
brwsec1 ld a,h
        ld (prgwindat+windatsup),a
        jp prgprz0

;### BRWOPN -> Opens a new document
;### Input      (doxpth)=path or URL
brwopnt db " - SymZilla",0

brwopn  call navadd
brwopn0 ld ix,prgobjinp1
        call strinp
        ld e,objnumadr
        call msgsnd0
        ld hl,2+256
        call brwsta
        ld hl,doxpth
        call dirloc                 ;test location type
        cp 1
        jr z,brwopn6
        cp 2
        jp z,brwopnb
        ld hl,prgmsgerr2b
        jp c,brwopn8
        cp 16
        jr nz,brwopna
        ld hl,mesaboblnx            ;** about blank
        call mesini
        ld a,8
        ld (renwinbgr),a
        ld hl,brwopnt+3
        ld de,prgwintit
        ld bc,9
        jr brwopn9
brwopna ld hl,mesabosymx            ;** about SymZilla
        call mesini
        ld hl,mesabotit
        jr brwopn4
brwopnb call netdox                 ;** HTTP - fetch a proxy-produced DOX file
        jp c,brwopn8
        ld a,(prgbnknum)
        ld c,a
        ld hl,nettmppth
        call loddox
        push af
        call nettmpdel
        pop af
        jr brwopnc
brwopn6 ld a,(prgbnknum)            ;** disc - load document
        ld c,a
        ld hl,doxpth
        call loddox                 ;CF=1 -> A=error code (1=file not found [L=fileman-errcode], 2=file corrupt, 3=error while loading [L=fileman-errcode], 4=memory full)
brwopnc
        jr nc,brwopn1
        cp 2
        jr c,brwopn7
        ld hl,meserrlodx
        jr z,brwopn5
        cp 4
        jr c,brwopn5
        ld hl,prgmsgerr2a
        jr brwopn8
brwopn7 ld hl,meserrfilx
brwopn5 call mesini                 ;error message (as document)
        ld hl,meserrtit
        jr brwopn4
brwopn1 ld hl,doxinf                ;prepare title
brwopn4 ld de,prgwintit
        ld bc,31*256+255
brwopn2 ld a,(hl)
        or a
        jr z,brwopn3
        ldi
        djnz brwopn2
brwopn3 ld hl,brwopnt
        ld bc,12
brwopn9 ldir
        ld a,(prgwin)               ;update title
        ld b,a
        ld c,MSC_DSK_WINTIT
        call msgsnd
        jp prgprz0
brwopn8 ld (prgmsgerra),hl          ;error message (as window)
        ld b,1
        ld hl,prgmsgerr
        call prginf0
        ld hl,1
        call brwsta
        jp prgprz0

;### BRWCLO -> Closes the current DOX file
brwclo  call netabort
        call lodclr
        jp prgprz0

;### BRWSTA -> Shows the current browser-status
;### Input  L=Message number (0=no update, 1=done, 2=loading, 3=rendering), H=Flag, if activity
brwstaa db 0        ;activity counter
brwstat dw gfxbrwac1,gfxbrwac2,gfxbrwac3,gfxbrwac4
brwstam dw 0,prgstadon,prgstalod,prgstaren

brwsta  ld a,h
        ld h,0
        add hl,hl
        ld bc,brwstam
        add hl,bc
        ld c,(hl)
        inc hl
        ld b,(hl)
        push bc
        ld hl,gfxbrwac0
        or a
        jr z,brwsta1
        ld hl,brwstaa
        ld a,(hl)
        inc (hl)
        and 3
        add a
        ld l,a
        ld h,0
        ld bc,brwstat
        add hl,bc
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a
brwsta1 ld (prgwinobj0+4),hl
        ld e,objnumact
        call msgsnd0
        pop hl
        ld a,l
        or h
        ret z
        ld (prgwindat0),hl
        ld a,(prgwindat+1)
        bit 6,a
        ret z
        ld a,(prgwin)
        ld b,a
        ld c,MSC_DSK_WINSTA
        jp msgsnd

;### BRWNEW -> starts a new instance of SymZilla
brwnewf db "appzilla.exe "
brwnewf0:
brwnew  ld de,(cfgfil)      ;copy application filename
        ld hl,brwnewf
        ld bc,brwnewf0-brwnewf
        ldir
        ld hl,(cfgpth)
        push hl
        ld bc,255
        add hl,bc
        sbc hl,de
        ld c,l
        ld b,h
        ld hl,doxpth
        ldir
        ld c,MSC_SYS_PRGRUN ;run program
        ld a,(prgbnknum)
        ld d,a
        pop hl
        ld b,l
        ld e,h
        ld a,(sysprzn)
        call msgsnd1
        jp prgprz0

;### BRWLNK -> loads the clicked link
;### Input      L=link number (1-254)
brwlnknum   db 0    ;number of links

brwlnk  ld a,(brwlnknum)
        cp l
        jp c,prgprz0            ;invalid link
        db #dd:ld l,a
        db #dd:ld h,0
        add ix,ix               ;ix=length of link length table
        ld a,(5*0+prgmemtab+0)
        ld de,(5*0+prgmemtab+1)
        inc de                  ;de=first entry in link length table
        add ix,de               ;ix=first link
        ex de,hl
brwlnk1 dec e
        jr z,brwlnk2
        rst #20:dw jmp_bnkrwd
        add ix,bc
        jr brwlnk1
brwlnk2 ld c,a
        ld a,(prgbnknum)
        add a:add a:add a:add a
        add c
        push ix
        pop hl
        ld de,doxinf
        push de
        ld bc,256
        rst #20:dw jmp_bnkcop
        pop hl
        ld a,(doxinf)           ;method byte: 0=GET, 1=POST
        or a
        jp nz,prgprz0           ;forms/POST are not implemented yet
        inc hl                  ;skip the method byte before resolving the URL
        ld de,doxpth
        call diradd
        jp brwopn


;==============================================================================
;### NAVIGATION ROUTINES ######################################################
;==============================================================================

navhismax   equ 8
navhisbuf   ds 128*navhismax
navhisbeg   db 0
navhislen   db 0
navhispos   db -1

;### NAVADD -> Adds the current address to the history
navadd  ld ix,prgobjinp1
        call strinp
        ld a,(prgobjinp1+8)
        or a
        ret z
        cp 128
        jr c,navadd1
        ld a,127                ;copy not more than 127 chars
navadd1 ld c,a
        ld a,(navhislen)
        or a
        jr z,navadd4
        ld a,(navhispos)
        call navadd0
        push bc
        ld de,doxpth            ;compare with last entry
        ld b,c
        inc b
navadd2 ld a,(de)
        cp (hl)
        jr nz,navadd3
        inc de
        inc hl
        djnz navadd2
navadd3 pop bc
        ret z                   ;the same -> don't add to history
navadd4 ld hl,navhispos         ;increase position
        call navadd5
        ld a,(navhislen)
        or a
        ld a,(hl)
        ld hl,navhisbeg
        jr z,navadd7
        cp (hl)
        call z,navadd5          ;prevent ring-buffer end/start collision
navadd7 ld c,a
        sub (hl)
        jr nc,navadd6
        add navhismax
navadd6 inc a
        ld (navhislen),a        ;store current buffer length
        ld a,c
        call navadd0
        ex de,hl
        ld hl,doxpth
        ld bc,127
        ldir                    ;store new line
        xor a
        ld (de),a
        ret
navadd0 ld h,a                  ;sub -> get line address inside buffer
        ld l,0
        srl h:rr l
        ld de,navhisbuf
        add hl,de
        ret
navadd5 inc (hl)                ;sub -> (hl)=((hl)+1) mod 8
        bit 3,(hl)
        ret z
        ld (hl),0
        ret

;### NAVFOR -> Navigation forward
navfor  ld hl,(navhisbeg)
        ld a,h
        or a
        jp z,prgprz0
        add l
        dec a
        and navhismax-1
        ld l,a
        ld a,(navhispos)
        cp l
        jp z,prgprz0
        inc a
        jr navbak1

;### NAVBAK -> Navigation backward
navbak  ld hl,(navhisbeg)
        inc h:dec h
        ret z
        ld a,(navhispos)
        cp l
        jp z,prgprz0
        dec a
navbak1 and navhismax-1
        ld (navhispos),a
navbak0 call navadd0
        ld bc,127
navbak2 ld de,doxpth
        ldir
        xor a
        ld (de),a
        jp brwopn0

;### NAVHOM -> Navigation home
navhom  ld hl,cfghom
        ld de,doxpth
        ld bc,128
        ldir
        jp brwopn

;### NAVREL -> Navigation reload
navrel  ld a,(navhislen)
        or a
        jp z,prgprz0
        ld a,(navhispos)
        jr navbak0

;### NAVSTP -> Navigation stop
navstp  call netabort
        jp prgprz0

;### NETDOX -> Fetches an HTTP URL as a temporary DOX document.
;### Input      (doxpth)=absolute URL
;### Output     CF=0 temporary file ready, CF=1 HL=error text
; The transport body is filled in below; these entry points are kept explicit
; because navigation, Stop and application shutdown all share their cleanup.
netdox  call netabort
        call netmkpth
        jr c,netdox0
        call netprxprs
        jr c,netdox0
        call netorgprs
        jr c,netdox0
        call SyNet_NETINI
        ld hl,netdmnerr
        jp c,netfail
        ld hl,netprxhost
        call SyNet_DNSRSV
        ld hl,netdnserr
        jp c,netfail
        ld hl,-1
        ld de,(netprxport)
        xor a
        call SyNet_TCPOPN
        ld hl,netconerr
        jp c,netfail
        ld (nethnd),a
        ld a,1
        ld (netsockflg),a
        call netwaitcon
        ld hl,netconerr
        jp c,netfail
        call netrequest
        ld hl,netreqerr
        jp c,netfail
        call netheaders
        ld hl,netrsperr
        jp c,netfail
		call netbody
		ld hl,netbodyerr
		jp c,netfail
		call netsockclo
		or a
		ret
netdox0 ld hl,netcfgerr
        scf
        ret

; Abort is idempotent.  A separate flag is mandatory because socket handle 0
; is valid in the Network Daemon API.
netabort
        call netsockclo
		jp nettmpdel
nettmpdel
		call netfileclo
		ld a,(nettmpflg)
		or a
		ret z
		ld hl,nettmppth
		ld a,(prgbnknum)
		db #dd:ld h,a
		call syscll
		db MSC_SYS_SYSFIL
		db FNC_FIL_DIRDEL
		ret c
		xor a
		ld (nettmpflg),a
		ret

netfail push hl
        call netabort
        pop hl
        scf
        ret

netsockclo
        ld a,(netsockflg)
        or a
        ret z
        xor a
        ld (netsockflg),a
        ld a,(nethnd)
        call SyNet_TCPSTA
        ret c                   ;the daemon has already released the socket
        ld a,l
        and 127
        cp 3
        ld a,(nethnd)
        jp c,SyNet_TCPDIS       ;locally terminate an opening/open socket
        jp SyNet_TCPCLO         ;the peer has already closed it

;### NETMKPTH -> Creates a fully-qualified, per-process 8.3 temporary path.
; cfgfil is the stable executable-filename boundary.  The code-end pathname
; tail is also used by New Window and may contain a URL, so never scan it for
; the last slash here.
netmkpth
		ld hl,(cfgfil)
		ld de,(cfgpth)
		or a
		sbc hl,de
		ld a,h
		or a
		jr nz,netmkpbad
		ld a,l
		or a
		jr z,netmkpbad
		cp 241                 ;leave room for SZxx.DOX and its terminator
		jr nc,netmkpbad
		ld c,l
		ld b,0
		ld hl,(cfgpth)
		ld de,nettmppth
		ldir
		ld a,"S"
        ld (de),a
        inc de
        ld a,"Z"
        ld (de),a
        inc de
        ld a,(prgprzn)
        rrca
        rrca
        rrca
        rrca
        and 15
        call nethex
        ld (de),a
        inc de
        ld a,(prgprzn)
        and 15
        call nethex
        ld (de),a
        inc de
        ld hl,nettmpext
		ld bc,5
		ldir
		or a
		ret
netmkpbad
		scf
		ret
nethex  add "0"
        cp "9"+1
        ret c
        add "A"-"9"-1
        ret

;### NETPRXPRS -> Parses cfgproxy without modifying the saved configuration.
; Accept hostname[:port] or http://hostname[:port]; port 5001 is the default.
netprxprs
        ld ix,cfgproxy
        ld a,(ix+0)
        and #df
        cp "H"
        jr nz,netprx0
        ld a,(ix+1)
        and #df
        cp "T"
        jr nz,netprx0
        ld a,(ix+2)
        and #df
        cp "T"
        jr nz,netprx0
        ld a,(ix+3)
        and #df
        cp "P"
        jr nz,netprx0
        ld a,(ix+4)
        cp ":"
        jr nz,netprx0
        ld a,(ix+5)
        cp "/"
        jr nz,netprx0
        ld a,(ix+6)
        cp "/"
        jr nz,netprx0
        ld de,7
        add ix,de
netprx0
        ld de,netprxhost
        ld b,63
        ld a,(ix+0)
        or a
        jr z,netprxbad
netprx1 ld a,(ix+0)
        or a
        jr z,netprx3
        cp ":"
        jr z,netprx4
        cp "/"
        jr z,netprxbad
        cp #5c
        jr z,netprxbad
        cp 33
        jr c,netprxbad
        ld (de),a
        inc de
        inc ix
        djnz netprx1
netprxbad
        scf
        ret
netprx3 xor a
        ld (de),a
        ld hl,5001
        ld (netprxport),hl
        or a
        ret
netprx4 xor a
        ld (de),a
        inc ix
        ld hl,0
        ld a,(ix+0)
        or a
        jr z,netprxbad
netprx5 ld a,(ix+0)
        or a
        jr z,netprx8
        sub "0"
        jr c,netprxbad
        cp 10
        jr nc,netprxbad
        ld c,a
        ld a,h                  ;65535/10=6553; final digit <=5
        cp #19
        jr c,netprx6
        jr nz,netprxbad
        ld a,l
        cp #99
        jr c,netprx6
        jr nz,netprxbad
        ld a,c
        cp 6
        jr nc,netprxbad
netprx6 add hl,hl               ;x2
        ld d,h
        ld e,l
        add hl,hl               ;x4
        add hl,hl               ;x8
        add hl,de               ;x10
        ld e,c
        ld d,0
        add hl,de
        inc ix
        jr netprx5
netprx8 ld a,h
        or l
        jr z,netprxbad
        ld (netprxport),hl
        or a
        ret

;### NETORGPRS -> Extracts the target authority for the HTTP Host header.
; The TCP connection still goes to cfgproxy; the absolute URL is sent intact.
netorgprs
        ld hl,doxpth
netorg0 ld a,(hl)
        or a
        jr z,netorg0a
        cp "#"
        jr z,netorgbad
		cp 33
		jr c,netorgbad
        inc hl
        jr netorg0
netorg0a
        ld hl,doxpth
        ld b,8
netorg1 ld a,(hl)
        or a
        jr z,netorgbad
        inc hl
        cp ":"
        jr z,netorg2
        djnz netorg1
netorgbad
        scf
        ret
netorg2 ld a,(hl)
        cp "/"
        jr nz,netorgbad
        inc hl
        ld a,(hl)
        cp "/"
        jr nz,netorgbad
        inc hl
        ld de,netorigin
        ld b,127
netorg3 ld a,(hl)
        or a
        jr z,netorg5
        cp "/"
        jr z,netorg5
        cp "?"
        jr z,netorg5
        cp "#"
        jr z,netorgbad
        cp "@"
        jr z,netorgbad
        cp 33
        jr c,netorgbad
        ld (de),a
        inc de
        inc hl
        djnz netorg3
        jr netorgbad
netorg5 ld hl,netorigin
        or a
        sbc hl,de
        jr z,netorgbad
        xor a
        ld (de),a
        ret

;### NETWAITCON -> Waits at most roughly 30 seconds for TCP establishment.
netwaitcon
        call nettimeini
netwcon1 call SyNet_NETEVT
        ld a,(nethnd)
        call SyNet_TCPSTA
        jr c,netwconbad
        bit 7,l
        jr nz,netwconok
        ld a,l
        and 127
        cp 2
        jr z,netwconok
        jr nc,netwconbad
netwcon4 rst #30
        call nettick
        jr nz,netwcon1
netwconbad
        scf
        ret
netwconok
        or a
        ret

nettimeini
        ld hl,1500
        ld (nettimer),hl
        ret
nettick ld hl,(nettimer)
        dec hl
        ld (nettimer),hl
        ld a,h
        or l
        ret

;### NETREQUEST -> Sends an HTTP/1.0 proxy request in bounded segments.
netrequest
        ld hl,netreqget
        call netsndz
        ret c
        ld hl,doxpth
        call netsndz
        ret c
        ld hl,netreqhost
        call netsndz
        ret c
        ld hl,netorigin
        call netsndz
        ret c
        ld hl,netreqhdr
        call netsndz
        ret c
        ld hl,jmp_scrget
        rst #28
        ld hl,netcap2
        ld a,d
        cp 16
        jr nc,netreq16
        cp 4
        jr c,netreqcap
        ld hl,netcap4
        jr netreqcap
netreq16
        ld hl,netcap16
netreqcap
        call netsndz
        ret c
        ld hl,netreqend
        jp netsndz

netsndz push hl
        call strlen
        pop hl
        jp netsend

; Partial sends are retried; a zero-progress send is bounded by nettimer.
netsend ld (netsndptr),hl
        ld (netsndlen),bc
        call nettimeini
netsend1
        ld bc,(netsndlen)
        ld a,b
        or c
        ret z
        ld hl,(netsndptr)
        ld a,(nethnd)
        ld de,(prgbnknum)
        call SyNet_TCPSND
        ret c
        push hl                 ;remaining byte count
        ld hl,(netsndptr)
        add hl,bc               ;advance by transferred byte count
        ld (netsndptr),hl
        pop hl
        ld (netsndlen),hl
        ld a,b
        or c
        jr z,netsend2
        call nettimeini
        jr netsend1
netsend2
        rst #30
        call nettick
        jr nz,netsend1
        scf
        ret

;### NETHEADERS -> Parses a complete HTTP response header.
; Any final 2xx-5xx status is accepted, including proxy-generated error pages,
; but only with the negotiated DOX MIME type and an exact, bounded length.
netheaders
        xor a
        ld (SyNet_TCPRLN_Length),a
        ld (netheadflg),a
        ld (netheadnum),a
        ld (netlength+0),a
        ld (netlength+1),a
        ld (netlength+2),a
        call netgetline
        ret c
		ld a,d
		cp 254
		jr nc,netheadbad
        call netstatus
        ret c
nethead1 call netgetline
        ret c
        ld a,d
        or a
        jr z,nethead8
        cp 254
        jr nc,netheadbad
        ld hl,netheadnum
        inc (hl)
        ld a,(hl)
        cp 65
        jr nc,netheadbad
        ld hl,netline
        ld de,netcltxt
        call netprefix
        jr z,netheadcl
        ld hl,netline
        ld de,netcttxt
        call netprefix
        jr z,netheadct
        ld hl,netline
        ld de,nettettxt
        call netprefix
        jr z,netheadbad         ;chunked/other transfer codings unsupported
        jr nethead1
netheadcl
        call netclprs
        jr c,netheadbad
        jr nethead1
netheadct
        call netctprs
        jr c,netheadbad
        jr nethead1
nethead8 ld a,(netheadflg)
        cp 3
        jr nz,netheadbad
        ld a,(netlength+0)      ;zero-length is never a valid DOX
        ld hl,(netlength+1)     ;bytes 1-2, used only for the zero test
        or l
        or h
        jr z,netheadbad
        or a
        ret
netheadbad
        scf
        ret

; ReceiveLine retains bytes following the blank line in its SDK buffer.  The
; SDK requires known socket data before it may fetch more, so only call it
; immediately when its private buffer already contains a complete line (or a
; full 254-byte fragment).  A trailing CR still needs the following byte to
; distinguish CRLF from a bare CR.
netgetline
        ld a,(SyNet_TCPRLN_Length)
        or a
        jr z,netgetwait
        ld c,a
        ld b,0
        ld hl,SyNet_TCPRLN_Buffer
        ld a,13
        cpir
        jr nz,netgetfull
        ld a,b
        or c
        jr nz,netgetcall
        jr netgetwait
netgetfull
        ld a,(SyNet_TCPRLN_Length)
        cp 254
        jr nc,netgetcall
netgetwait
        call netwaitdata
        ret c
netgetcall
        ld de,(prgbnknum)
        ld hl,netline
        ld a,(nethnd)
        call SyNet_TCPRLN
        ret c
        ret nz
        jr netgetline

; Wait for data while draining asynchronous events; TCPSTA covers data that
; was already queued before the event check.  Data+close is handled as data.
netwaitdata
        call nettimeini
netwait1 call SyNet_NETEVT
        ld a,(nethnd)
        call SyNet_TCPSTA
        jr c,netwaitbad
        bit 7,l
        jr nz,netwaitok
        ld a,l
        and 127
        cp 3
        jr nc,netwaitbad
netwait5 rst #30
        call nettick
        jr nz,netwait1
netwaitbad
        scf
        ret
netwaitok
        or a
        ret

; Validate the status line syntactically but deliberately do not require 200.
netstatus
        ld hl,netline
        ld de,nethttptxt
        call netprefix
        jr nz,netstatbad
        ld b,8
netstat1 ld a,(hl)
        or a
        jr z,netstatbad
        inc hl
        cp " "
        jr z,netstat2
        djnz netstat1
        jr netstatbad
netstat2 ld a,(hl)
        cp "2"
        jr c,netstatbad
        cp "6"
        jr nc,netstatbad
        inc hl
        ld b,2
netstat3 ld a,(hl)
        sub "0"
        jr c,netstatbad
        cp 10
        jr nc,netstatbad
        inc hl
        djnz netstat3
        ld a,(hl)
        or a
        ret z
        cp " "
        ret z
netstatbad
        scf
        ret

; Case-insensitive prefix comparison.  ZF means match and HL is advanced.
netprefix
        ld a,(de)
        or a
        ret z
        call netupper
        ld c,a
        ld a,(hl)
        call netupper
        cp c
        ret nz
        inc hl
        inc de
        jr netprefix
netupper cp "a"
        ret c
        cp "z"+1
        ret nc
        sub "a"-"A"
        ret
netspc  ld a,(hl)
        cp " "
        jr z,netspc1
        cp 9
        ret nz
netspc1 inc hl
        jr netspc

; Parse Content-Length as a bounded 24-bit decimal.  The pre-multiply bound
; 9830 plus final digit <=4 enforces the inclusive 96 KiB (98304-byte) cap.
netclprs
        ld a,(netheadflg)
        bit 0,a
        jp nz,netclbad
        call netspc
        push hl
        pop ix
        xor a
        ld (netdigits),a
netcl1 ld a,(ix+0)
        or a
        jr z,netclend
        cp " "
        jr z,netcltail
        cp 9
        jr z,netcltail
        sub "0"
        jr c,netclbad
        cp 10
        jr nc,netclbad
        ld (netdigit),a
        ld a,(netlength+2)
        or a
        jr nz,netclbad
        ld hl,(netlength)
        ld de,9830
        or a
        sbc hl,de
        jr c,netcl2
        jr nz,netclbad
        ld a,(netdigit)
        cp 5
        jr nc,netclbad
netcl2 ld de,(netlength)
        ld hl,0
        xor a
        ld b,10
netcl3 add hl,de
        adc a,0
        djnz netcl3
        ld c,a
        ld a,(netdigit)
        ld e,a
        ld d,0
        add hl,de
        ld (netlength),hl
        ld a,c
        adc a,0
        ld (netlength+2),a
        ld hl,netdigits
        inc (hl)
        inc ix
        jr netcl1
netcltail
        push ix
        pop hl
        call netspc
        ld a,(hl)
        or a
        jr nz,netclbad
netclend
        ld a,(netdigits)
        or a
        jr z,netclbad
        ld hl,netheadflg
        set 0,(hl)
        or a
        ret
netclbad
        scf
        ret

netctprs
        ld a,(netheadflg)
        bit 1,a
        jr nz,netctbad
        call netspc
        ld de,netmimetype
        call netprefix
        jr nz,netctbad
        ld a,(hl)
        or a
        jr z,netctok
        cp ";"
        jr z,netctok
        cp " "
        jr z,netcttail
        cp 9
        jr nz,netctbad
netcttail
        call netspc
        ld a,(hl)
        or a
        jr z,netctok
        cp ";"
        jr nz,netctbad
netctok ld hl,netheadflg
        set 1,(hl)
        or a
        ret
netctbad
        scf
        ret

;### NETBODY -> Streams exactly Content-Length bytes into a temporary DOX.
; Header parsing may have already buffered initial body bytes in TCPRLN.
netbody
		call netfilnew
		ret c
		ld hl,(netlength)
		ld (netremain),hl
		ld a,(netlength+2)
		ld (netremain+2),a
		ld a,(SyNet_TCPRLN_Length)
		or a
		jr z,netbody2
		ld c,a
		ld b,0
		ld hl,SyNet_TCPRLN_Buffer
		call netwrite
		ret c
		xor a
		ld (SyNet_TCPRLN_Length),a
netbody2
		ld a,(netremain+2)
		ld hl,(netremain)
		or h
		or l
		jr z,netbody8
		call netwaitdata
		ret c
		ld bc,1024
		ld a,(netremain+2)
		or a
		jr nz,netbody3
		ld hl,(netremain)
		ld a,h
		cp 4
		jr nc,netbody3
		ld b,h
		ld c,l
netbody3
		ld a,(nethnd)
		ld de,(prgbnknum)
		ld hl,netrcvbuf
		call SyNet_TCPRCV
		ret c
		ld a,b
		or c
		jr z,netbody2
		ld hl,netrcvbuf
		call netwrite
		ret c
		jr netbody2
netbody8
		call netfileclo
		ret

; File handle zero is valid, so open/existence state is tracked separately.
netfilnew
		ld hl,nettmppth
		ld a,(prgbnknum)
		db #dd:ld h,a
		xor a
		call syscll
		db MSC_SYS_SYSFIL
		db FNC_FIL_FILNEW
		ret c
		ld (netfilhnd),a
		ld a,1
		ld (netfileflg),a
		ld (nettmpflg),a
		or a
		ret

netfileclo
		ld a,(netfileflg)
		or a
		ret z
		xor a
		ld (netfileflg),a
		ld a,(netfilhnd)
		call syscll
		db MSC_SYS_SYSFIL
		db FNC_FIL_FILCLO
		ret

; Input HL=source, BC=length.  A write must fit the remaining count and the
; File Manager must report the full length; partial/disk-full writes fail.
netwrite
		ld (netwriteptr),hl
		ld (netwritelen),bc
		ld a,(netremain+2)
		or a
		jr nz,netwrite1
		ld hl,(netremain)
		or a
		sbc hl,bc
		ret c
netwrite1
		ld a,(netfilhnd)
		ld de,(prgbnknum)
		ld hl,(netwriteptr)
		ld bc,(netwritelen)
		call syscll
		db MSC_SYS_SYSFIL
		db FNC_FIL_FILOUT
		ret c
		or a
		jr nz,netwritebad
		ld hl,(netwritelen)
		or a
		sbc hl,bc
		jr nz,netwritebad
		ld bc,(netwritelen)
		ld hl,(netremain)
		or a
		sbc hl,bc
		ld (netremain),hl
		ld a,(netremain+2)
		sbc a,0
		ld (netremain+2),a
		ret nc
netwritebad
		scf
		ret


;==============================================================================
;### INTERNAL MESSAGES ########################################################
;==============================================================================

meserrtit   db "[Error]",0
mesabotit   db "About:",0

mesabosymx  dw mesabosym1-mesabosym0,mesabosym0-mesabosym
mesabosym   db 0,0, 255,1, 14, 0,0, #11,-1,2,2, #e1,3,1,1, 16*11+15, 16*0+3,16*3+1
            db 2,4,1, "SymZilla", 2,3,1, 8,3, 8,3
            db 1,16*3, "Version 0.3",8,3
            db 1,16*1, "HTTP requires Network Daemon and GB-proxy.",8,3
            db 0,-1
mesabosym0  db ".", 0,-1
mesabosym1

mesaboblnx  dw mesabobln1-mesabobln0,mesabobln0-mesabobln
mesabobln   db 0,-1
mesabobln0  db ".", 0,-1
mesabobln1

meserrfilx  dw meserrfil1-meserrfil0,meserrfil0-meserrfil
meserrfil   db 0,0, 255,1, 14, 0,0, #11,-1,2,2, #e1,3,1,1, 16*11+15, 16*0+3,16*3+1
            db 2,4,1, "File not found", 2,3,1, 8,3, 8,3
            db 1,16*3, "SymZilla can't find the file at",8,3
meserrfil0  db ".",8,3, 1,16*1, 2,1,1, 8,3
            db "* Check the file name for typing errors.",8,3
            db "* Check to see if the file was moved, renamed or deleted.",0,-1
meserrfil1

meserrurlx  dw meserrurl1-meserrurl0,meserrurl0-meserrurl
meserrurl   db 0,0, 255,1, 14, 0,0, #11,-1,2,2, #e1,3,1,1, 16*11+15, 16*0+3,16*3+1
            db 2,4,1, "Server not found", 2,3,1, 8,3, 8,3
            db 1,16*3, "SymZilla can't find the server at",8,3
meserrurl0  db ".",8,3, 1,16*1, 2,1,1, 8,3
            db "* Check the address for typing errors such as ",2,3,1,"ww",2,1,1,".example.com instead of ",2,3,1,"www",2,1,1,".example.com.",8,3
            db "* If you are unable to load any pages, check your computer's network connection.",0,-1
meserrurl1

meserrlodx  dw meserrlod1-meserrlod0,meserrlod0-meserrlod
meserrlod   db 0,0, 255,1, 14, 0,0, #11,-1,2,2, #e1,3,1,1, 16*11+15, 16*0+3,16*3+1
            db 2,4,1, "Error while loading", 2,3,1, 8,3, 8,3
            db 1,16*3, "SymZilla can't open the file at",8,3
meserrlod0  db ".",8,3, 1,16*1, 2,1,1, 8,3
            db "* Check to see if the file format is supported by SymZilla or if the file is corrupt.",8,3
            db "* Check your disc drive or hard disc.",0,-1
meserrlod1

;Input      HL=start, BC=length until path, DE=length from path to end
mesinid dw 240,1000,2*256+2

mesini  ld e,(hl):inc hl
        ld d,(hl):inc hl
        push de
        push hl
        call lodclr
        pop hl
        ld c,(hl):inc hl
        ld b,(hl):inc hl
        ld de,renviwtxt
        ldir
        push hl
        ld hl,doxpth
mesini1 ld a,(hl)
        ldi
        or a
        jr nz,mesini1
        dec de
        pop hl
        pop bc
        ldir
        ld hl,renviwtxt
        ld bc,5
        add hl,bc
        ex de,hl        ;DE=ziel+1
        sbc hl,de       ;HL=lange
        ex de,hl
        ld (hl),e
        inc hl
        ld (hl),d
        ld hl,mesinid
        ld de,renwinxmn
        ld bc,6
        ldir
        ret


;==============================================================================
;### DOX-RENDERING-ENGINE (LOADER) ############################################
;==============================================================================

;### LODDOX -> Loads a new DOX document (and removes the old one, if existing)
;### Input      C,HL=filename
;### Output     CF=0 -> ok, DOX file has been loaded, A=0
;###            CF=1 -> A=error code (1=file not found [L=fileman-errcode], 2=file corrupt, 3=error while loading [L=fileman-errcode], 4=memory full)
;### Destroyed  F,BC,DE,HL
loddoxhnd   db 0    ;file handler
loddoxbuf   ds 8    ;buffer for chunk-header
loddoxnxt   ds 4    ;position of the next chunk inside the file

lodtmpbuf   ds 11

loddoxnum   equ 7   ;number of possible chunks
loddoxtab           ;chunk-table
db "INFO":dw lodinf
db "INDX":dw lodidx
db "HEAD":dw lodhed
db "TEXT":dw lodtxt
db "GRPH":dw lodgfx
db "LINK":dw lodlnk
db "ENDF":dw 0
loddoxflg   db 0    ;flag, if the necessary parts of the DOX have been loaded

loddox  push bc                 ;** remove old DOX
        push hl
        call lodclr
        pop hl
        pop bc
        db #dd:ld h,c           ;** open file
        call syscll
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILOPN
        ld l,a
        ld a,1
        ret c
        xor a
        ld (loddoxflg),a
        ld h,a
        ld a,l
        ld l,h
        ld (loddoxnxt+0),hl
        ld (loddoxnxt+2),hl
        ld (loddoxhnd),a
loddox1 ld a,(loddoxhnd)        ;** chunk-loop
        ld ix,(loddoxnxt+0)
        ld iy,(loddoxnxt+2)
        ld c,0
        call syscll             ;move file pointer to the next chunk
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILPOI
        jr c,loddox0
        ld bc,8
        ld hl,loddoxbuf
        call loddox7            ;load chunk header
        jr nz,loddox5
        ld hl,(loddoxbuf+4)     ;calculate next chunk position
        ld bc,(loddoxnxt+0)
        add hl,bc
        ex de,hl
        ld hl,(loddoxbuf+6)
        ld bc,(loddoxnxt+2)
        adc hl,bc
        ex de,hl
        ld bc,8
        add hl,bc
        ld (loddoxnxt+0),hl
        ex de,hl
        ld c,0
        adc hl,bc
        ld (loddoxnxt+2),hl
        ld de,loddoxtab         ;identify chunk
        ld c,loddoxnum
loddox2 ld hl,loddoxbuf
        ld b,4
loddox3 ld a,(de)
        inc de
        cp (hl)
        jr nz,loddox4
        inc hl
        djnz loddox3
        ld a,(de)               ;found -> call routine
        ld l,a
        inc de
        ld a,(de)
        ld h,a
        or l
        jr z,loddox5
        ld bc,(loddoxbuf+4)
        ld de,(loddoxbuf+6)
        jp (hl)
loddox4 ld l,b                  ;no match -> try next or unknown chunk
        inc l
        ld h,0
        add hl,de
        ex de,hl
        dec c
        jr nz,loddox2
        jr loddox1
loddox5 ld a,(loddoxflg)        ;end of file reached
        or a
        ld a,2
        jr z,loddox0
        call loddox6
        xor a
        ret
loddox7 ld a,(prgbnknum)
        ld e,a
loddox8 ld a,(loddoxhnd)
        call syscll             ;load chunk header
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILINP
        ret nc
        pop hl
loddox0 push af                 ;** error -> cf=1 file loading error (A=error code), cf=0 memory full or file corrupt (A=2/4)
        call loddox6
        call lodclr
        pop af
        ld l,a
        ld a,3
        ret c
        ld a,l
        scf
        ret
loddox6 ld a,(loddoxhnd)
        call syscll
        db MSC_SYS_SYSFIL
        db FNC_FIL_FILCLO
        ret

;### LODINF -> Loads the info part of a DOX document
lodinft dw doxemp,doxemp,doxemp,doxemp,doxemp,doxemp,doxemp

lodinf  ld l,255
        call lodinf0
        ld (lodinf3+1),bc
        push bc
        ld de,doxinf
        ld hl,doxemp
        push de
        ld bc,8
        ldir
        ld hl,doxinf+7
        ld bc,255-8
        ldir
        pop hl
        pop bc
        ld a,b
        or c
        jp z,loddox1
        call loddox7
lodinf3 ld de,0
        ld hl,doxinf
        ld b,7
        ld ix,lodinft
lodinf1 ld a,e
        or d
        jp z,loddox1
        dec de
        xor a
        cp (hl)
        inc hl
        jr nz,lodinf1
        ld (ix+0),l
        ld (ix+1),h
        inc ix
        inc ix
        djnz lodinf1
        jp loddox1
lodinf0 ld a,e
        or d
        jr z,lodinf2
        ld bc,255
lodinf2 ld a,b
        or a
        jr z,lodinf4
        ld bc,255
lodinf4 ld a,c
        cp l
        ret c
        ld c,l
        ret

;### LODIDX -> Loads the index part of a DOX document
lodidx  ;...                    ;### not implemented yet ###
        jp loddox1

;### LODHED -> Loads the header part of a DOX document
lodhed  ld a,6
        call lodinf0
        ld a,b
        or c
        jp z,loddox1
        ld hl,renwinxmn
        call loddox7
        jp loddox1

;### LODTXT -> Loads the text part of a DOX document
lodtxt  ld a,e
        or d
        jr nz,lodtxt1
        ld hl,16380-prgtrnbeg+prgdatbeg
        sbc hl,bc
        jr nc,lodtxt2
lodtxt1 ld bc,16380-prgtrnbeg+prgdatbeg
lodtxt2 ld hl,renviwtxt
        call loddox7
        ld a,1
        ld (loddoxflg),a
        jp loddox1

;### LODGFX -> Loads the graphic part of a DOX document
lodgfxa equ lodtmpbuf       ;temp.number of total graphics
lodgfxh equ lodtmpbuf+1     ;temp.graphic header

lodgfx  ld bc,1                 ;load number of graphics
        ld hl,lodgfxa
        call loddox7
        jr z,lodgfx1
lodgfx0 ld a,2
        or a
        jp loddox0
lodgfx1 ld a,(lodgfxa)          ;load graphic length table
        add a
        jp z,loddox1
        ld c,a
        ld a,b
        adc b
        ld b,a
        ld hl,gfxtab+768
        call loddox7
        jr nz,lodgfx0
        ld ix,gfxtab
        ld iy,gfxtab+768
        ld a,(lodgfxa)
        ld b,a
lodgfx2 ld l,(iy+0)             ;graphic loading loop
        ld h,(iy+1)
        ld a,l
        or h
        jp z,lodgfx5
        push bc                 ;reserve memory
        push ix
        push iy
        inc hl:inc hl
        ld (ix+3),l
        ld (ix+4),h
        ld c,l
        ld b,h
        xor a
        ld e,1
        push bc
        rst #20:dw jmp_memget
        pop bc
        jr nc,lodgfx3
        xor a
        ld a,4
        jr lodgfx4
lodgfx3 ld (ix+0),a             ;store location and load SGX graphic
        ld (ix+1),l
        ld (ix+2),h
        ex de,hl
        ld hl,gfxanz
        inc (hl)
        ex de,hl
        inc hl:inc hl
        dec bc:dec bc
        push hl
        ld e,a
        call loddox8
        pop hl
        ld a,2
lodgfx4 pop iy
        pop ix
        pop bc
        jp nz,loddox0
        push bc
        push iy
        ld iy,lodgfxh
        ld a,(ix+0)
        ld e,l
        ld d,h
        dec de:dec de           ;DE=header address
        inc hl                  ;skip "64" ID-byte
        rst #20:dw jmp_bnkrbt
        ld (iy+9),b             ;encoding type
        rst #20:dw jmp_bnkrwd
        ld (iy+0),c             ;width  in bytes
        rst #20:dw jmp_bnkrwd
        ld (iy+1),c             ;width  in pixel
        rst #20:dw jmp_bnkrwd
        ld (iy+2),c             ;height in pixel
        pop iy
        ld (lodgfxh+3),hl       ;address of the encoding type byte
        dec hl
        ld (lodgfxh+5),hl       ;address of the graphic data
        ld c,(ix+3)
        ld b,(ix+4)
        ld hl,-10
        add hl,bc
        ld (lodgfxh+7),hl       ;length of the graphic data
        ld a,(ix+0)
        add a:add a:add a:add a
        ld hl,prgbnknum
        or (hl)
        ld hl,lodgfxh
        ld bc,10
        rst #20:dw jmp_bnkcop
        pop bc
        jr lodgfx6
lodgfx5 ld (ix+0),0
        ld (ix+3),0
        ld (ix+4),0
lodgfx6 ld de,5
        add ix,de
        inc iy
        inc iy
        dec b
        jp nz,lodgfx2
        jp loddox1

;### LODLNK -> Loads the link part of a DOX document
lodlnk  ld a,d
        or e
        jp nz,loddox1           ;link chunck too long or corrupt
        xor a
        ld e,a
        push bc
        rst #20:dw jmp_memget
        pop bc
        jp c,loddox1            ;no memory for links -> just skip them
        ld (5*0+prgmemtab+0),a
        ld (5*0+prgmemtab+1),hl
        ld (5*0+prgmemtab+3),bc
        ld e,a
        call loddox8            ;load links
        ld a,(5*0+prgmemtab+0)
        ld hl,(5*0+prgmemtab+1)
        rst #20:dw jmp_bnkrbt
        ld a,b
        ld (brwlnknum),a
        jp loddox1

;### LODCTL -> Loads the form-control part of a DOX document
lodctl  ld bc,4
        ld hl,lodtmpbuf
        call loddox7
        xor a
;lodctl  ld bc,(lodtmpbuf+0)
        ld e,2
        push af
        rst #20:dw jmp_memget
        pop bc
;        jr 

        ld a,d
        or e
        jp nz,loddox1           ;link chunck too long or corrupt
        xor a
        ld e,a
        push bc
        rst #20:dw jmp_memget
        pop bc
        jp c,loddox1            ;no memory for links -> just skip them
        ld (5*0+prgmemtab+0),a
        ld (5*0+prgmemtab+1),hl
        ld (5*0+prgmemtab+3),bc
        ld e,a
        call loddox8            ;load links
        ld a,(5*0+prgmemtab+0)
        ld hl,(5*0+prgmemtab+1)
        rst #20:dw jmp_bnkrbt
        ld a,b
        ld (brwlnknum),a
        jp loddox1

;### LODCLR -> Removes the current DOX document, if existing
lodclr  ld hl,200                   ;** reset document parameters
        ld (renwinxmn),hl
        ld hl,1000
        ld (renwinxmx),hl
        ld hl,2*256
        ld (renwinbgr),hl
        ld hl,0
        ld (prgsupobj+6),hl
        ld (prgsupobj+8),hl
        ld hl,256*255
        ld (renviwtxt),hl
        ;status done
        ld a,1
        ld (prgsupgrp),a
        ld hl,0
        ld (rensiz+1),hl
        ld hl,doxemp                ;** resets DOX information
        ld b,7
        ld ix,lodinft
lodclr0 ld (ix+0),l
        ld (ix+1),h
        inc ix
        inc ix
        djnz lodclr0
        ld hl,gfxanz                ;** release graphic memory
        ld b,(hl)
        xor a
        cp b
        ret z
        ld (hl),a
        ld ix,gfxtab
lodclr1 push bc
        call lodclr2
        pop bc
        djnz lodclr1
        ld ix,5*0+prgmemtab         ;** release link and form-control memory
        call lodclr2
        call lodclr2
lodclr2 ld a,(ix+0)
        or a
        jr z,lodclr3
        ld l,(ix+1)
        ld h,(ix+2)
        ld c,(ix+3)
        ld b,(ix+4)
        push ix
        rst #20:dw jmp_memfre
        pop ix
        ld (ix+0),0
        ld (ix+3),0
        ld (ix+4),0
lodclr3 ld bc,5
        add ix,bc
        ret


;==============================================================================
;### DOX-RENDERING-ENGINE (TEXT) ##############################################
;==============================================================================

rentst  ld a,(renwinbgr)
        ld (prgsupdat+4),a
        ld hl,(renwinspc)
        ld h,0
        push hl
        ld (rencuryps),hl
        ld iy,renviwobj
        ld hl,(renviwdat)
        ld ix,renviwtxt
        ld b,renviwmax
        call rendox
        ld a,b
        inc a
        ld (prgsupgrp),a
        ld hl,(prgwinobj1+12)
        ld c,l
        ld b,h
        ld hl,(renclmyps)
        pop de
        add hl,de
        ex de,hl
        ld l,c
        ld h,b
        or a
        sbc hl,de
        ex de,hl
        jr c,rentst1
        add hl,de
rentst1 ld (prgsupobj+4),hl
        ex de,hl
        ld hl,(prgsupobj+8)
        or a
        add hl,bc
        sbc hl,de
        ret c
        ex de,hl
        sbc hl,bc
        jr nc,rentst2
        ld hl,0
rentst2 ld (prgsupobj+8),hl
        ret

renviwmax   equ 240
renviwdat   dw 0

renfntadr   dw -1,fntita,fntbld,fntbig,#2ff
renfntwid   ds 5*128    ;charwidth lookup table, byte127=height

renfrmfnt   db 0,0      ;0=normal, 1=italic, 2=bold, 3=big
renfrmcol   db 0        ;Pen/Paper
renfrmuli   db 0        ;underline on/off
renfrmali   db 0        ;line alignment (0=left, 1=right, 2=center, 3=justified)
renfrmysp   db 0        ;additional space between current and next line

renoldfnt   dw 0        ;old font adr
renoldcol   db 0        ;old colour
renolduli   db 0        ;old underline flag

renclmxps   dw 0        ;xpos of the current column
renclmxsz   dw 0        ;xsiz of the current column
renclmyps   dw 0        ;ypos of the current column

renclmbxp   dw 0        ;xpos backup
renclmbxs   dw 0        ;xsiz backup

rencuryps   dw 0        ;current cursor ypos
renvisyps   dw 0        ;first visible ypos
renwinxsz   dw 300      ;window xsize

renwinxmn   dw 200      ;minimum xsize
renwinxmx   dw 1000     ;maximum xsize
renwinbgr   db 0        ;background colour
renwinspc   db 2        ;top/bottom y-spacing


;### RENINI -> Initialise rendering engine
renini  ld hl,renviwobj
        ld bc,renviwmax*16
        add hl,bc
        ld (renviwdat),hl
        ld e,8                  ;*** generate charwidth lookup tables
        ld hl,jmp_sysinf
        rst #28             ;DE=font adr
        xor a
        ex de,hl
        ld ix,renfntwid
        call renini1
        ld hl,0*128+renfntwid
        ld de,4*128+renfntwid
        ld bc,128
        ldir
        ld a,(prgbnknum)
        ld hl,fntita
        call renini1
        ld hl,fntbld
        call renini1
        ld hl,fntbig
renini1 rst #20:dw jmp_bnkrbt   ;*** read charsizes of one font
        ld (ix+127),b
        inc hl
        ld c,98
        ld de,15
renini2 rst #20:dw jmp_bnkrbt
        ld (ix+0),b
        inc ix
        add hl,de
        dec c
        jr nz,renini2
        ld de,128-98
        add ix,de
        ret

;### RENSIZ -> test, if window width changes, and re-render the document if needed
rensiz  ld hl,0
        ld de,(prgwinobj1+10)
        or a
        sbc hl,de
        jp z,prgprz0
        ld (rensiz+1),de
        ld hl,-8
        add hl,de
        push hl
        ex de,hl                ;DE=size of the current content display frame
        ld hl,(renwinxmx)
        or a
        sbc hl,de
        jr nc,rensiz1
        add hl,de               ;xmax is smaller -> use xmax
        ex de,hl
rensiz1 ld hl,(renwinxmn)
        or a
        sbc hl,de
        ex de,hl
        jr c,rensiz2
        add hl,de               ;xmin is bigger  -> use xmin
rensiz2 ld (renwinxsz),hl
        ld (prgsupobj+2),hl
        ex de,hl
        pop hl
        ld a,2
        or a
        sbc hl,de
        jr nc,rensiz3
        ld a,3
rensiz3 ld (prgsupobj+10),a
        ld hl,0
        ld (prgsupobj+6),hl
        ld hl,3+256
        call brwsta
        call rentst             ;##!!##
        ld hl,0+256
        call brwsta
        ld e,objnumviw
        call msgsnd0
        rst #30
        ld hl,1
        call brwsta
        jp prgprz0

;### RENDOX -> Renders a DOX document
;### Input      IX=DOX data, IY=control record, HL=control data, B=available records,
;###            (rencuryps)=cursor position, (renvisyps)=ystart for output, (renwinxsz)=window width
;### Output     B=used records, (renclmyps)=new cursor position, IX/IY/HL=next data, ZF=1 rendered until document end
;### Destroyed  AF,C,DE
rendoxa db 0
rendoxs db 1    ;session ID

rendox  ld a,(ix+1)
        inc a
        jr nz,rendox3
        ld de,(rencuryps)
        ld (renclmyps),de
        ld b,a
        ret
rendox3 xor a
        ld (rendoxa),a
        ld a,(rendoxs)
        inc a
        jr nz,rendox0
        ld a,2
rendox0 ld (rendoxs),a
rendox1 push bc
        call renpar
        ld a,b
        push af
        ld de,rendoxa
        ld a,(de)
        add b
        ld (de),a
        pop af
        pop bc
        scf
        jr nz,rendox2
        neg
        add b
        ccf
        jr c,rendox2
        scf
        jr z,rendox2
        ld b,a
        inc ix
        ld de,(renclmyps)
        ld (rencuryps),de
        ld a,(ix-1)
        or a
        jr z,rendox1
rendox2 ld a,(rendoxa)
        ld b,a
        ld a,0
        adc a
        ret

;### RENPAR -> Renders one paragraph
;### Input      IX=paragraph text data, IY=control record, HL=control data, B=available records,
;###            (rencuryps)=cursor position, (renvisyps)=ystart for output, (renwinxsz)=window width
;### Output     B=used records, (renclmyps)=new cursor position, IX/IY/HL=next data, ZF=1 rendered until paragraph end
;### Destroyed  AF,C,DE
renparrto   db 0        ;number of used records
renparrco   db 0        ;number of available records per column
renparfad   ds 15*2
renparfju   db 0        ;flag, if lower frame border adjustment
renparfmx   dw 3        ;maximum lower frame border
renparfnm   db 0        ;number of columns
renparend   db 0        ;flag, if one column didnt reach end
renparymx   dw 0        ;maximum ypos

renpar  ld a,(ix+0)
        add 1
        jp nc,renclm            ;*** no headers and only one column -> call column renderer directly
        ld de,3                 ;*** init variables
        ld (renparfmx),de
        xor a
        ld e,a
        ld (renparymx),de
        ld (renparrto),a
        ld (renparend),a
        inc ix
        ld c,(ix+0)
        bit 4,c
        res 4,c
        jr z,renpar1
        inc a
renpar1 ld (renparfju),a
        ld a,c
        ld (renparfnm),a
        call clcdi8         ;b=int(available records/number of columns)
        ld a,b
        ld b,0
        cp 2
        ret c
        ld (renparrco),a
        ld b,c
        inc ix
        ld de,renparfad
renpar3 push bc                 ;*** main loop
        push ix
        push de
        ld a,(renparrco)
        ld b,a
        scf
        call renclm         ;render one column
        ld a,b
        ex (sp),hl          ;save control data, get frame ysiz address table pointer
        ld bc,-1
        jr nc,renpar4       ;no frame -> skip
        push af
        ex de,hl
        ld ix,(renclmfca)   ;IX=frame data record
        ld c,(ix+12)
        ld b,(ix+13)        ;BC=frame ylen
        ld hl,(renparfmx)
        or a
        sbc hl,bc
        jr nc,renpar7
        ld (renparfmx),bc   ;BC>old max ylen -> save as new max ylen
renpar7 push ix
        pop bc
        ex de,hl
        pop af
renpar4 ld (hl),c           ;save frame data record address (or -1)
        inc hl
        ld (hl),b
        inc hl
        ex de,hl
        jr z,renpar5
        ld hl,renparend     ;no rendering until column end -> not enough records for the whole paragraph
        ld (hl),1
renpar5 ld hl,renparrto
        add (hl)
        ld (hl),a           ;increase number of used records
        ld hl,(renparymx)
        ld bc,(renclmyps)
        or a
        sbc hl,bc
        jr nc,renpara
        ld (renparymx),bc
renpara pop hl
        pop ix
        ld c,(ix+1)
        ld b,(ix+2)
        add ix,bc           ;IX=next column
        pop bc
        djnz renpar3
        ld a,(renparfju)        ;*** adjust lower frame borders, if required
        or a
        jr z,renpar8
        push ix
        push hl
        ld a,(renparfnm)
        ld b,a
        ld de,renparfad
        ld hl,(renparfmx)
renpar6 ld a,(de):db #dd:ld l,a:inc de
        ld c,a
        ld a,(de):db #dd:ld h,a:inc de
        and c
        inc a
        jr z,renpar9
        ld (ix+12),l
        ld (ix+13),h
renpar9 djnz renpar6
        pop hl
        pop ix
renpar8 ld de,(renparymx)
        ld (renclmyps),de
        ld a,(renparrto)
        ld b,a
        ld a,(renparend)
        or a
        ret

;### RENCLM -> Renders one column
;### Input      IX=column text data, CF=1 column header included, IY=control record, HL=control data, B=available records,
;###            (rencuryps)=cursor position, (renvisyps)=ystart for output, (renwinxsz)=window width
;### Output     B=used records, (renclmyps)=new cursor position, IX/IY/HL=next data, ZF=1 rendered until column end,
;###            CF=1 column contains frame, which ysize is stored at (renclmfca)+12/13
;### Destroyed  AF,C,DE
renclmcnt   db 0        ;number of available controls before
renclmcfr   db 0        ;number of available controls inside
renclmcpn   dw 0        ;pointer to the last used control

renclmfyp   dw 0        ;upper frame ypos (-1=no frame), frame control address
renclmfca   dw 0        ;frame control address
renclmfys   dw 0        ;frame yspacing

renclmglx   db 0        ;width of left-aligned graphic
renclmgly   dw 0        ;bottom ypos of left-aligned graphic (-1=not existing)
renclmglc   ds 15       ;control data for left-aligned graphic
renclmgrx   db 0        ;width of right-aligned graphic
renclmgry   dw 0        ;bottom ypos of right-aligned graphic (-1=not existing)
renclmgrc   ds 15       ;control data for right-aligned graphic

renclmlmp   db 0        ;left margin current position
renclmrmp   db 0        ;right margin current position
renclmlmd   dw 0        ;column xpos new difference
renclmrmd   dw 0        ;column xsiz new difference

renclm  ld de,-1
        ld (renclmfyp),de
        ld a,0
        ld (gfxtablft),a
        ld (gfxtabrgt),a
        ld a,b
        ld (renclmcnt),a
        jr c,renclm1
        ex de,hl            ;*** standard column sizes, no frame
        ld hl,(rencuryps)
        ld (renclmyps),hl
        ld hl,2
        ld (renclmxps),hl
        ld (renclmbxp),hl
        ld hl,(renwinxsz)
        ld bc,-4
        add hl,bc
        ld (renclmxsz),hl
        ld (renclmbxs),hl
        ex de,hl
        ld b,a
        jp renclm2
renclm1 push hl             ;*** column contains header with dimension parameters
        push bc
        push iy
        inc ix:inc ix:inc ix
        ld hl,(renwinxsz)
        push hl
        call renclc
        ex (sp),hl
        call renclc         ;HL=xsize
        pop de              ;DE=xpos
        pop iy
        ld a,(ix+1)
        bit 1,a
        jr z,renclm6
        ld (renclmfca),iy   ;* frame included
        and #f1
        rrca:rrca:rrca:rrca
        bit 4,a
        jr z,renclm7
        or 64
renclm7 and #4f
        or 128
        ld (iy+4),a
        ld a,(ix+2)
        ld (iy+5),a
        ld bc,(rencuryps)
        ld (renclmfyp),bc
        ld (iy+0),0
        ld (iy+1),0
        ld (iy+2),2
        ld (iy+3),255
        ld (iy+6),e
        ld (iy+7),d
        ld (iy+8),c
        ld (iy+9),b
        ld (iy+10),l
        ld (iy+11),h
        ld bc,16
        add iy,bc
        pop bc
        dec b
        push bc
renclm6 ld a,(ix+0)         ;* take border spacing into account
        and 15
        dec a
        ld c,a
        ld b,0
        sbc hl,bc
        sbc hl,bc
        ld (renclmxsz),hl
        ld (renclmbxs),hl
        ex de,hl
        add hl,bc
        ld (renclmxps),hl
        ld (renclmbxp),hl
        ld hl,(rencuryps)
        ld a,(ix+0)
        rrca:rrca:rrca:rrca
        and 15
        dec a
        ld c,a
        ld (renclmfys),bc
        add hl,bc
        ld (renclmyps),hl
        ld a,(ix-11)
        sub 11
        ld c,a
        add ix,bc
        pop bc
        pop hl

renclm2 xor a               ;*** initialise text formatting and graphics
        ld (renfrmfnt),a
        ld (renfrmuli),a
        ld (renfrmali),a
        ld (renfrmysp),a
        ld (renclmglx),a
        ld (renclmgrx),a
        ld (renclmlmp),a
        ld (renclmrmp),a
        push hl
        ld l,a
        ld h,a
        ld (renclmlmd),hl
        ld (renclmrmd),hl
        dec l
        dec h
        ld (renclmgly),hl
        ld (renclmgry),hl
        pop hl
        ld a,16*1+0
        ld (renfrmcol),a
renclm3 ld a,b              ;*** main line loop
        ld (renclmcfr),a
        ld (renclmcpn),iy
        ld (iy+0),0
        ld (iy+1),0
        ld (iy+2),6
        ld (iy+3),255
        ld (iy+4),l
        ld (iy+5),h
        push hl
        push hl
        call renlin         ;BC=text, DE=next text, IX=xsize, HL=number of chars, A=ysize, renoldXXX/renfrmali/renfrmysp=format
        ex (sp),hl
        ld (hl),c:inc hl    ;text address
        ld (hl),b:inc hl
        pop bc
        push de
        ld (hl),c:inc hl    ;number of chars
        ld (hl),b:inc hl
        ld bc,(renoldfnt)
        ld (hl),c:inc hl    ;font address
        ld (hl),b:inc hl
        ld bc,(renoldcol)
        ld (hl),c:inc hl    ;pen/paper
        ld (hl),b           ;underline
        ld hl,0
        ld e,a
        ld d,l
        ld a,(renfrmali)
        cp 3
        jr z,renclm4
        or a
        jr z,renclm4
        ld hl,(renclmxsz)
        db #dd:ld c,l
        db #dd:ld b,h
        sbc hl,bc
        dec a
        jr z,renclm4
        srl h:rr l
renclm4 ld bc,(renclmxps)
        add hl,bc
        ld (iy+6),l         ;xpos
        ld (iy+7),h
        call renilx         ;adjust xpos of inline objects
        ld hl,(renclmyps)
        ld (iy+8),l         ;ypos
        ld (iy+9),h
        ld (iy+12),e        ;ysize
        ld (iy+13),d
        add hl,de
        ld a,(renfrmysp)
        ld e,a
        add hl,de
        ld (renclmyps),hl   ;update ypos
        db #dd:ld a,l       ;xsize
        ld (iy+10),a
        db #dd:ld a,h
        ld (iy+11),a
        ld ix,renclmglx     ;** handle left-aligned graphic
        call gfxend
        jr nc,renclm9
        push bc
        ld hl,gfxtablft
        call gfxnew
        pop de
        ld hl,(renclmxps)
        or a
        sbc hl,de
        ld (renclmglc+1+6),hl
        add hl,bc
        ld (renclmxps),hl
renclm9 ld ix,renclmgrx     ;** handle right-aligned graphic
        call gfxend
        jr nc,renclma
        ld hl,gfxtabrgt
        call gfxnew
renclma ld hl,(renclmxps)   ;** handle left and right margins
        ld de,(renclmlmd)
        add hl,de
        ld (renclmxps),hl
        ld hl,(renclmxsz)
        ld de,(renclmrmd)
        or a
        sbc hl,de
        ld (renclmxsz),hl
        ld hl,0
        ld (renclmlmd),hl
        ld (renclmrmd),hl
renclmc ld iy,(renclmcpn)
        ld bc,16
        add iy,bc
        pop ix              ;IX=next textline
        pop hl
        ld c,8
        add hl,bc
        ld a,(renclmcfr)
        ld b,a
        ld de,renclmglc
        call gfxctl
        ld de,renclmgrc
        call gfxctl
        jr nc,renclmb
        push hl
        ld hl,(renclmxps)
        ld de,(renclmxsz)
        add hl,de
        ld de,(gfxctls)
        add hl,de
        ld (iy-16+6),l
        ld (iy-16+7),h
        pop hl
renclmb dec b
        ld a,(ix-1)
        or a
        jr z,renclm5
        inc b:dec b
        jp nz,renclm3
renclm5 push ix             ;*** finish graphics
        call gfxfin
        pop ix
        ld de,(renclmfyp)   ;*** finish frame, if existing
        inc de
        ld a,e
        or d
        jr z,renclm8
        dec de
        push hl
        ld hl,(renclmyps)
        push hl
        sbc hl,de
        ld de,(renclmfys)
        add hl,de
        push iy
        ld iy,(renclmfca)
        ld (iy+12),l
        ld (iy+13),h
        pop iy
        pop hl
        add hl,de
        ld (renclmyps),hl
        pop hl
        scf
renclm8 push af
        ld a,(renclmcnt)
        sub b
        ld b,a
        pop af
        inc (ix-1)
        dec (ix-1)
        ret

;### RENLIN -> Renders one line
;### Input      (renclmxsz)=maximum line width, IX=current textline, (renfrmfnt/renfrmuli/renfrmcol/renfrmali/renfrmysp)=current format
;### Output     BC=current textline, DE=next textline, IX=length in pixel, HL=length in chars, A=height of line
;###            (renoldXXX/renfrmali/renfrmysp)=current format, (renfrmfnt/renfrmuli/renfrmcol)=format for next line
;### Destroyed  AF
renlinw dw 0                ;address of the last wrapping possibility (0=not found)
renlinx dw 0                ;xsize of line at last wrap pos
renlinwcp   dw 0            ;free control pointer at last wrap pos
renlinwcf   db 0            ;free control number at last wrap pos

renliny db 0                ;ysize of line
renlins db 0                ;number of spaces in this line
renlint ds 256*2            ;addresse of spaces

renlin  xor a               ;init values
        ld (renliny),a
        ld (renlins),a
        ld (renilnnum),a
        ld l,a
        ld h,a
        ld (renlinw),hl
        call renfnt         ;setup new font
        ld hl,(renfrmfnt)   ;store start-fontadr
        add hl,hl
        ld de,renfntadr
        add hl,de
        ld e,(hl)
        inc hl
        ld d,(hl)
        ld (renoldfnt),de
        ld hl,(renfrmcol)   ;backup format information
        ld (renoldcol),hl
        push ix
        ld bc,0             ;BC=current xlen
renlin1 ld a,(ix+0)
        cp 12
        jp c,renctl
        cp 33
        jr nc,renlin2
        ld a,32                 ;*** space (wrap here)
        ld (ix+0),a
        ld (renlinw),ix
        ld (renlinx),bc
        ld hl,(renclmcpn)
        ld (renlinwcp),hl
        ld l,a
        ld a,(renclmcfr)
        ld (renlinwcf),a
        ld a,l
        ld hl,renlins       ;count space and store address
        inc (hl)
        ld l,(hl)
        dec l
        ld h,0
        add hl,hl
        ld de,renlint
        add hl,de
        db #dd:ld e,l:ld (hl),e:inc hl
        db #dd:ld e,h:ld (hl),e
renlin2 ld e,a                  ;*** printable char
        ld d,0
renlin3 ld hl,0
        add hl,de
        ld l,(hl)
        ld h,0              ;HL=charwidth
        add hl,bc
        ex de,hl            ;DE=new line xlen
        ld hl,(renclmxsz)
        sbc hl,de
        jr c,renlin4
renlinj ld c,e                  ;*** line xsize ok
        ld b,d              ;write back to BC
        inc ix
        ld a,"-"
        cp (ix-1)
        jr nz,renlin1
        ld (renlinw),ix         ;*** dash (wrap after)
        ld (renlinx),bc
        ld hl,(renclmcpn)
        ld (renlinwcp),hl
        ld a,(renclmcfr)
        ld (renlinwcf),a
        jr renlin1
renlin4 ld hl,(renlinw)         ;*** line too long
        ld a,l
        or h
        jr z,renlin5
        ex de,hl
        ld hl,(renlinwcp)
        ld (renclmcpn),hl
        ex de,hl
        ld a,(renlinwcf)
        ld (renclmcfr),a
        ld a,(hl)
        cp 32
        jr nz,renlino
        ex de,hl
        ld hl,renlins
        dec (hl)
        ex de,hl
renlino ld bc,(renlinx)
        or a
        jr renlin6
renlin5 push ix                 ;*** EOL, CF=1 per control
        pop hl              ;HL=first char after line
renlin6 push af
        ld e,l
        ld d,h
        jr c,renlin7
        ld a,(hl)
        cp 32
        jr nz,renlin7
        inc de              ;DE=start of next line
renlin7 push bc
        pop ix              ;IX=length of current line in pixel
        pop af
        pop bc              ;BC=start of current line
        push af
        or a
        sbc hl,bc           ;HL=length of current line in chars
        pop af
        call nc,renjus      ;justify, if needed
        ld a,(renliny)      ;A=line ysize
        ret

;### RENCTL -> Handles control codes
;### Input      A=control code, BC=current line length in pixel, IX=text
;### Output     BC,IX updated
;###            no sub-routine, will jump back somewhere into RENLIN
;### Destroyed  AF,DE,HL
renctl  inc ix
        cp 1
        jr c,renlin5        ;-- 0=end of text
        jr nz,renctl1
        ld a,(ix+0)         ;-- 1=pen/paper
        ld (renfrmcol),a
        jr renctl3
renctl1 cp 3
        jr z,renctla
        jr nc,renctl9
        ld l,(ix+0)         ;-- 2=font
        ld h,(ix+1)
        dec h
        jr nz,renctl5
        dec l               ;* font identified by ID
        ld (renfrmfnt),hl
        add hl,hl
        ld de,renfntadr
        add hl,de
        ld a,(hl)
        ld (ix+0),a
        inc hl
        ld a,(hl)
        ld (ix+1),a
renctl2 call renfnt
        inc ix
renctl3 inc ix
renctl4 jp renlin1
renctl5 inc h               ;* font identified by address
        ld de,renfntadr
        push bc
        ld b,3
renctl6 ld a,(de)
        inc de
        cp l
        jr nz,renctl7
        ld a,(de)
        cp h
        jr z,renctl8
renctl7 inc de
        djnz renctl6
renctl8 ld a,3
        sub b
        ld (renfrmfnt),a
        pop bc
        jr renctl2
renctl9 cp 5
        jr z,renctlb
        jr nc,renctlc
renctla ld hl,renfrmuli     ;-- 3/4=underline on/off
        and 1
        ld (hl),a
        jr renctl4
renctlb ld l,(ix+0)         ;-- 5=x-adjustment (hard variable space)
        ld h,0
        add hl,bc
        ex de,hl            ;DE=new line xlen
        ld hl,(renclmxsz)
        sbc hl,de
        jp nc,renlinj
        add hl,de
        ex de,hl
        jp renlinj
renctlc cp 8
        jr c,renctl4        ;-- 6/7=ignored
        ld d,(ix+0)         ;-- 8-11=extended formating code/skip bytes
        sub 7
        add a
        dec a
        ld e,a
        ld a,d
        ld d,0
        add ix,de
        cp 2
        jr z,renctld
        jp nc,renctli
        ld a,(ix-2)         ;-- 9,1=set format
        dec a
        ld (renfrmali),a
        ld a,(ix-1)
        dec a
        ld (renfrmysp),a
        jp renlin1
renctld ld a,(ix-3)         ;-- 10,2=insert graphic
        push iy
        bit 7,a
        jr nz,renctlg
        ld l,a              ;* left/right aligned graphic
        ld a,(rendoxs)
        cp (ix-1)
        jr z,renctlf
        ld (ix-1),a
        bit 6,l
        ld iy,gfxtablft
        jr z,renctle
        ld iy,gfxtabrgt
renctle res 6,l
        dec l
        ld a,(iy+0)
        cp gfxclmmax
        jr nc,renctlf
        inc (iy+0)
        ld e,a
        add a
        add e
        ld e,a
        ld d,0
        add iy,de
        ld a,(ix-4)
        ld (iy+1),a
        ld a,(ix-2)
        ld (iy+2),a
        ld (iy+3),l
renctlf pop iy
        jp renlin1
renctlg push bc             ;* inline graphic
        ld a,(ix-4)
        call gfxinf
        ld e,c
        ld d,b
        pop bc
        call reniln
        jr nc,renctlh
        pop iy
        jp renlin4          ;line too long
renctlh ld a,(ix-4-2)
        push bc
        call gfxinf
        pop bc
        ld (iy+2),10
        ld (iy+3),a
        ld (iy+4),l
        ld (iy+5),h
        jr renctlf
renctli cp 4
        jp c,renlin5        ;-- 8,3=line feed
        jr nz,renctlj
        call rensep         ;-- 9,4=horizontal rule (separator)
        scf
        jp renlin5
renctlj cp 6
        jr z,renctln
        jr nc,renctlz
        ld a,(ix-1)         ;-- 9,5=margin identation
        dec a
        ld e,a
        bit 1,(ix-2)
        jr nz,renctlk
        ld hl,renclmlmp
        call renctll
        ld (renclmlmd),hl
renctlm ld de,(renclmrmd)
        add hl,de
        ld (renclmrmd),hl
        jp renlin1
renctlk ld hl,renclmrmp
        call renctll
        jr renctlm
renctll sub (hl)
        ld (hl),e
        ld l,a
        ld a,0
        sbc a
        ld h,a
        ret
renctln ld l,(ix-2)         ;-- 9,6=tab stop
        ld h,(ix-1)
        dec h
        or a
        sbc hl,bc
        jr z,renctlo
        jr nc,renctlp
        add hl,bc           ;* new position in front of current one -> do line feed first
        inc h
        dec h
        jr z,renctlq
        ld l,255
renctlq ld (ix+1),l
        jp renlin5          ;CF is already set by the previouse add-command
renctlp dec l               ;* new position behind current one
        inc h
        dec h
        jr z,renctlo
        ld hl,254
renctlo inc l
        ld (ix+1),l
        inc ix
        inc ix
        add hl,bc
        ld c,l
        ld b,h
        jp renlin1
renctlz ;...                ;x,>=7 not defined
        jp renlin1

db "debug here"

;### RENSEP -> Adds a separator line below the current line
rensep  ld hl,renclmcfr
        ld a,(hl)
        dec a
        ret z
        ld (hl),a
        ld hl,(renclmcpn)
        ld de,16
        add hl,de
        ld (renclmcpn),hl
        ld (hl),d:inc hl    ;no link
        ld (hl),d:inc hl
        ld a,(ix-2)         ;type
        rrca:rrca:rrca:rrca
        ld e,a
        and #f0
        cp #30
        jr nc,rensep1
        ld a,e
        and 15
        ld e,a
        xor a
        jr rensep2
rensep1 ld a,e
        and 15
        or #c0
        ld e,a
        ld d,(ix-1)
        ld a,2
rensep2 ld (hl),a:inc hl
        ld (hl),-1:inc hl
        ld (hl),e:inc hl    ;colour
        ld (hl),d:inc hl
        ld de,(renclmxps)   ;xpos
        ld (hl),e:inc hl
        ld (hl),d:inc hl
        ld de,(renclmyps)   ;ypos
        ld a,c
        or b
        jr z,rensep3
        ld a,(renliny)
rensep3 add 4
        add e
        ld e,a
        ld a,0
        adc d
        ld d,a
        ld (hl),e:inc hl
        ld (hl),d:inc hl
        ld de,(renclmxsz)   ;xsize
        ld (hl),e:inc hl
        ld (hl),d:inc hl
        ld a,(ix-2)         ;ysize
        and 15
        ld (hl),a:inc hl
        ld (hl),0
        ld e,a
        ld a,c
        or b
        ld a,e
        ld hl,renliny
        jr z,rensep4
        add (hl)
rensep4 add 8
        ld (hl),a
        ret

;### RENILN -> Tests, if inline object still fits into current line and adds a data record
;### Input      BC=current line width, E=object width, D=object height, IX=text after object (points to 5,x control code)
;### Output     BC=updated, (IX+1),IX=updated,
;###            CF=0 ok (IY=link/pos/size prepared data record), (renclmcfr/renclmcpn) updated
;###            CF=1 line too long or no record available
;### Destroyed  AF,HL,IY
renilnnum   db 0

reniln  push de
        ld a,(ix-3)
        and 63
        add a
        add e
        ld (ix+1),a         ;update 5,x control code
        ld l,a
        ld h,0
        add hl,bc
        ex de,hl            ;DE=new line xlen
        ld a,c
        or b
        jr z,reniln2        ;skip width-test, if there are no previous elements in this line
        ld hl,(renclmxsz)
        sbc hl,de
        jr c,reniln1        ;line too long
reniln2 ld hl,renclmcfr
        ld a,(hl)
        dec a
        jr z,reniln1        ;no more records available
        ld (hl),a
        ld hl,renilnnum
        inc (hl)
        ld iy,(renclmcpn)
        ld a,(ix-3)
        and 63
        add c
        ld (iy+06+16),a
        ld a,0
        adc b
        ld (iy+07+16),a     ;xpos (relative)
        ld bc,16
        add iy,bc
        ld (renclmcpn),iy   ;IY=next free record
        ld (iy+11),b
        ld (iy+13),b
        ld c,e
        ld b,d              ;BC=new line xlen
        ld hl,(renclmyps)
        ld (iy+08),l
        ld (iy+09),h        ;ypos
        pop de
        ld (iy+10),e        ;xsize
        ld (iy+12),d        ;ysize
        ld a,(ix-2)
        ld (iy+0),a         ;link
        ld (iy+1),0
        ld a,d
        call renfnt1
        inc ix
        inc ix              ;skip 5,x control code
        ret
reniln1 ld de,-6            ;** abort -> move ix back to object
        add ix,de
        pop de
        ret

;### RENILX -> Adjust the x-positions of all inline objects
;### Input      HL=offset, IY+16=first record
;### Destroyed  de,iy
renilx  ld a,(renilnnum)
        or a
        ret z
        push de
        push iy
        ex de,hl
        ld bc,16
renilx1 ld l,(iy+6+16)
        ld h,(iy+7+16)
        add hl,de
        ld (iy+6+16),l
        ld (iy+7+16),h
        add iy,bc
        dec a
        jr nz,renilx1
        pop iy
        pop de
        ret

;### RENJUS -> Justify current textline, if required
;### Input      (renlins/t)=number and addresses of spaces, (renclmxsz)=maximum line width, IX=length in pixel
;### Output     -
;### Destroyed  AF
renjus  ld a,(renfrmali)
        cp 3
        ret nz
        ld a,(renlins)
        or a
        ret z
        push bc
        push de
        push hl
        ld hl,(renclmxsz)
        db #dd:ld e,l
        db #dd:ld d,h
        sbc hl,de
        ld c,l
        ld b,h
        ld e,a
        ld d,0
        push af
        call clcd16         ;HL=space width
        pop bc              ;B=number of spaces
        ld c,e              ;C=additional pixel
        ld a,l
        inc h:dec h
        jr nz,renjus1
        cp 20
        jr c,renjus2
renjus1 ld c,0
        ld a,20
renjus2 add 8+3
        ld hl,renlint
        inc c:dec c
        jr z,renjus3
        inc a
renjus3 cp 8+3
        jr nz,renjus4
        ld a,32
renjus4 ld e,(hl):inc hl
        ld d,(hl):inc hl
        ld (de),a
        dec c
        jr nz,renjus5
        dec a
        cp 8+3
        jr nz,renjus5
        ld a,32
renjus5 djnz renjus4
        pop hl
        pop de
        pop bc
        ret

;### RENFNT -> Initialize selected font
;### Destroyed  AF,DE,HL
renfnt  ld a,(renfrmfnt)
        ld h,a
        ld l,0
        srl h:rr l
        ld de,renfntwid-32
        add hl,de
        ld (renlin3+1),hl
        ld de,32+127
        add hl,de
        ld a,(hl)
renfnt1 ld hl,renliny
        cp (hl)
        ret c
        ld (hl),a
        ret

;### RENCLC -> Calculates the width and size of a column depending on the screen width
;### Input      (IX+0/1)=k1, (IX+2)=k2, (IX+3)=k3 [>0], HL=WinLen
;### Output     HL=k1[xxxxxxx1xxxxxxx1]+winlen*(k2-1)/k3, IX=IX+4
;### Destroyed  AF,BC,DE,IY
renclc  ld c,(ix+2)
        dec c
        ld a,c
        cp 1
        ld a,0
        jr z,renclc1
        ex de,hl
        ld h,a
        ld l,a
        jr c,renclc2
        ld b,a
        push ix
        call clcmul
        pop ix
renclc1 ld e,(ix+3)
        dec e
        jr z,renclc2
        inc e
        ld c,l
        ld b,h
        ld d,0
        push ix
        call clcdiv
        pop ix
renclc2 ld b,(ix+1)
        sra b
        sra b
        ld c,(ix+0)
        rr c
        add hl,bc
        ld bc,4
        add ix,bc
        ret


;==============================================================================
;### DOX-RENDERING-ENGINE (GRAPHICS) ##########################################
;==============================================================================

gfxanz  db 0
gfxtab  ds 255*5

gfxclmmax   equ 16
gfxtablft   db 0:ds gfxclmmax*3
gfxtabrgt   db 0:ds gfxclmmax*3

;### GFXINF -> Get information about a graphic
;### Input      A=graphic ID (starting with 1)
;### Output     A,HL=address, C=width, B=height
;### Destroyed  F
gfxinf  ld l,a
        ld h,0
        ld c,l
        ld b,h
        add hl,hl
        add hl,hl
        add hl,bc
        ld bc,gfxtab-5
        add hl,bc
        ld a,(hl)
        inc hl
        ld c,(hl)
        inc hl
        ld h,(hl)
        ld l,c
        push hl
        inc hl
        rst #20:dw jmp_bnkrwd
        pop hl
        ret

;### GFXFET -> Fetches the next graphic from the left/right stack
;### Input      HL=graphic stack
;### Output     CF=0 ok, A,HL=address, C=width, B=height, E=link ID, D=spacing
;### Destroyed  F,HL
gfxfet  ld a,(hl)
        sub 1
        ret c
        dec (hl)
        inc hl
        ld a,(hl)
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        push de
        ld e,l
        ld d,h
        inc hl
        dec de
        dec de
        ld bc,gfxclmmax*3-3
        ldir
        call gfxinf
        pop de
        or a
        ret

;### GFXFIN -> Finish the remaining graphics
;### Input      IY=control, B=number of free controls
;### Output     B,IY=updated
;### Destroyed  AF,C,DE,IX
gfxfin  push hl
        ld hl,(renclmyps)
        push hl
        ld ix,renclmglx
        ld hl,gfxtablft
        ld a,#af    ;xor a
        call gfxfin1
        ld hl,(renclmyps)
        ex (sp),hl
        ld (renclmyps),hl
        ld ix,renclmgrx
        ld hl,gfxtabrgt
        ld a,#37    ;scf
        call gfxfin1
        pop de
        ld hl,(renclmyps)
        or a
        sbc hl,de
        pop hl
        ret nc
        ld (renclmyps),de
        ret
gfxfin1 ld (gfxfin2),a
gfxfin3 ld e,(ix+1)             ;test, if graphic exist
        ld d,(ix+2)
        ld a,e
        and d
        inc a
        ret z
        ld (renclmyps),de       ;yes -> adjust column ysize and remove graphic
        push bc
        push hl
        call gfxend1
        pop hl
        push hl
        call gfxnew             ;watch out for new graphic
        pop hl
        pop bc
        push ix
        pop de
        inc de:inc de:inc de
        call gfxctl             ;add it as control, if possible
        ret nc
gfxfin2 nop
        jr nc,gfxfin3
        push hl
        ld hl,(renclmbxp)
        ld de,(renclmbxs)
        add hl,de
        ld e,(iy-16+10)
        ld d,(iy-16+11)
        sbc hl,de
        ld (iy-16+6),l
        ld (iy-16+7),h
        pop hl
        jr gfxfin3

;### GFXEND -> Test, if old graphic is existing or has been passed
;### Input      IX=graphic infos
;### Output     CF=0 old graphic is still in place, no changes, CF=1 old graphic has been passed or no old graphic existing, BC=x-difference
;### Destroyed  AF,DE,HL
gfxend  ld l,(ix+1)
        ld h,(ix+2)
        ld a,l
        and h
        ld bc,0
        inc a
        scf
        ret z               ;no old graphic existing, CF=1, BC=0
        ld de,(renclmyps)
        or a
        sbc hl,de
        ret nc              ;old graphic existing and still in place, CF=0
gfxend1 ld (ix+1),-1        ;old graphic finished, remove, adjust xsize, BC=old gfx xsize, CF=1
        ld (ix+2),-1
        ld c,(ix+0)
        ld b,0
        ld (ix+0),b
        ld hl,(renclmxsz)
        add hl,bc
        ld (renclmxsz),hl
        scf
        ret

;### GFXNEW -> Test, if new graphic is available and add it
;### Input      IX=graphic infos, HL=graphic stack
;### Output     BC=x-difference
;### Destroyed  AF,DE,HL
gfxnew  call gfxfet
        jr nc,gfxnew1
        ld bc,0
        ret
gfxnew1 ld (ix+3),1         ;prepare graphic control
        ld (ix+4+0),e
        ld (ix+4+1),d
        ld (ix+4+2),10
        ld (ix+4+3),a
        ld (ix+4+4),l
        ld (ix+4+5),h
        ld (ix+4+10),c
        ld (ix+4+11),0
        ld (ix+4+12),b
        ld (ix+4+13),0
        ld e,c
        ld a,d
        add a
        add b
        ld c,a
        ld a,0
        adc a
        ld b,a
        ld hl,(renclmyps)
        add hl,bc
        dec hl
        ld (ix+1),l
        ld (ix+2),h
        ld a,e
        add d
        ld c,a
        ld a,0
        adc a
        ld b,a
        ld (ix+0),c
        ld hl,(renclmxsz)
        sbc hl,bc
        ld (renclmxsz),hl
        ret

;### GFXCTL -> Adds a new graphic control, if necessary and possible
;### Input      DE=graphic data, IY=control, B=number of free controls+1
;### Output     CF=1 graphic was added, B,IY=updated
;### Destroyed  AF,DE
gfxctls db 0,0
gfxctl  ld a,(de)
        or a
        ret z
        dec b
        jr nz,gfxctl1
        inc b
        ret
gfxctl1 push bc
        push hl
        ex de,hl
        ld (hl),0
        inc hl
        push iy
        pop de
        ld bc,14
        ldir
        ld hl,(renclmyps)
        ld c,(iy+1)
        ld (iy+1),0
        add hl,bc
        ld (iy+8),l
        ld (iy+9),h
        ld a,c
        ld (gfxctls),a
        ld c,16
        add iy,bc
        pop hl
        pop bc
        scf
        ret


;==============================================================================
;### DOX-RENDERING-ENGINE (SUBS) ############################################
;==============================================================================

;### SYSCLL -> Betriebssystem-Funktion aufrufen
;### Eingabe    (SP)=Modul/Funktion, AF,BC,DE,HL,IX,IY=Register
;### Ausgabe    AF,BC,DE,HL,IX,IY=Register
sysclln db 0
syscll  ld (prgmsgb+04),bc      ;Register in Message-Buffer kopieren
        ld (prgmsgb+06),de
        ld (prgmsgb+08),hl
        ld (prgmsgb+10),ix
        ld (prgmsgb+12),iy
        push af
        pop hl
        ld (prgmsgb+02),hl
        pop hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        push hl
        ld (prgmsgb+00),de      ;Modul und Funktion in Message-Buffer kopieren
        ld a,e
        ld (sysclln),a
        ld iy,prgmsgb
        ld a,(prgprzn)          ;Desktop und System-Prozessnummer holen
        db #dd:ld l,a
        ld a,(sysprzn)
        db #dd:ld h,a
        rst #10                 ;Message senden
syscll1 rst #30
        ld iy,prgmsgb
        ld a,(prgprzn)
        db #dd:ld l,a
        ld a,(sysprzn)
        db #dd:ld h,a
        rst #18                 ;auf Antwort warten
        db #dd:dec l
        jr nz,syscll1
        ld a,(prgmsgb)
        sub 128
        ld e,a
        ld a,(sysclln)
        cp e
        jr nz,syscll1
        ld hl,(prgmsgb+02)      ;Register aus Message-Buffer holen
        push hl
        pop af
        ld bc,(prgmsgb+04)
        ld de,(prgmsgb+06)
        ld hl,(prgmsgb+08)
        ld ix,(prgmsgb+10)
        ld iy,(prgmsgb+12)
        ret

;### CLCDI8 -> Dividiert zwei Werte (8bit)
;### Eingabe    B=Wert1, C=Wert2
;### Ausgabe    B=Wert1/Wert2, A=Wert1 MOD Wert2
;### Veraendert F,E
clcdi8  xor a
        inc c
        dec c
        ret z
        ld e,8
clcdi81 rl b
        rla
        sub c
        jr nc,clcdi82
        add c
clcdi82 ccf
        dec e
        jr nz,clcdi81
        rl b
        ret

;### CLCD16 -> Dividiert zwei Werte (16bit)
;### Eingabe    BC=Wert1, DE=Wert2
;### Ausgabe    HL=Wert1/Wert2, DE=Wert1 MOD Wert2
;### Veraendert AF,BC,DE
clcd16  ld a,e
        or d
        ld hl,0
        ret z
        ld a,b
        ld b,16
clcd161 rl c
        rla
        rl l
        rl h
        sbc hl,de
        jr nc,clcd162
        add hl,de
clcd162 ccf
        djnz clcd161
        ex de,hl
        rl c
        rla
        ld h,a
        ld l,c
        ret

;### CLCDIV -> Dividiert zwei Werte (24bit)
;### Eingabe    A,BC=Wert1, DE=Wert2
;### Ausgabe    HL=Wert1/Wert2, DE=Wert1 MOD Wert2
;### Veraendert AF,BC,DE,IX,IYL
clcdiv  db #dd:ld l,e
        db #dd:ld h,d   ;IX=Wert2(Nenner)
        ld e,a          ;E,BC=Wert1(Zaehler)
        ld hl,0
        db #dd:ld a,l
        db #dd:or h
        ret z
        ld d,l          ;D,HL=RechenVar
        db #fd:ld l,24  ;IYL=Counter
clcdiv1 rl c
        rl b
        rl e
        rl l
        rl h
        rl d
        ld a,l
        db #dd:sub l
        ld l,a
        ld a,h
        db #dd:sbc h
        ld h,a
        ld a,d
        sbc 0
        ld d,a          ;D,HL=D,HL-IX
        jr nc,clcdiv2
        ld a,l
        db #dd:add l
        ld l,a
        ld a,h
        db #dd:adc h
        ld h,a
        ld a,d
        adc 0
        ld d,a
        scf
clcdiv2 ccf
        db #fd:dec l
        jr nz,clcdiv1
        ex de,hl        ;DE=Wert1 MOD Wert2
        rl c
        rl b
        ld l,c
        ld h,b          ;HL=Wert1 DIV Wert2
        ret

;### CLCMUL -> Multipliziert zwei Werte (24bit)
;### Eingabe    BC=Wert1, DE=Wert2
;### Ausgabe    A,HL=Wert1*Wert2 (24bit)
;### Veraendert F,BC,DE,IX
clcmul  ld ix,0
        ld hl,0
clcmul1 ld a,c
        or b
        jr z,clcmul3
        srl b
        rr c
        jr nc,clcmul2
        add ix,de
        ld a,h
        adc l
        ld h,a
clcmul2 sla e
        rl d
        rl l
        jr clcmul1
clcmul3 ld a,h
        db #dd:ld e,l
        db #dd:ld d,h
        ex de,hl
        ret

; Network scratch storage lives in the writable code area so it does not
; reduce the renderer's fixed data-area/TEXT capacity.
nettmppth ds 256
netprxhost ds 64
netprxport dw 5001
netorigin ds 128
nethnd db 0
netsockflg db 0
netfilhnd db 0
netfileflg db 0
nettmpflg db 0
nettimer dw 0
netsndptr dw 0
netsndlen dw 0
netremain ds 3
netwriteptr dw 0
netwritelen dw 0
netrcvbuf ds 1024
netheadflg db 0
netheadnum db 0
netlength ds 3
netdigits db 0
netdigit db 0
netline ds 256
nettmpext db ".DOX",0
netreqget db "GET ",0
netreqhost db " HTTP/1.0",13,10,"Host: ",0
netreqhdr db 13,10,"Connection: close",13,10
          db "User-Agent: SymZilla/0.3 (SymbOS)",13,10
          db "Accept: application/x-symbos-dox",13,10
          db "Accept-Encoding: identity",13,10
          db "X-GB-SGX: ",0
netcap2 db "0,2",0
netcap4 db "0,4",0
netcap16 db "5,16",0
netreqend db 13,10,13,10,0
nethttptxt db "HTTP/",0
netcltxt db "Content-Length:",0
netcttxt db "Content-Type:",0
nettettxt db "Transfer-Encoding:",0
netmimetype db "application/x-symbos-dox",0
netcfgerr db "Invalid GB-proxy address or temporary path.",0
netdmnerr db "Network Daemon is not running.",0
netdnserr db "GB-proxy host lookup failed.",0
netconerr db "Could not connect to GB-proxy.",0
netreqerr db "Could not send the proxy request.",0
netbodyerr db "Could not receive or save the proxy response.",0
netrsperr db "GB-proxy returned an invalid DOX response.",0

; The Network Daemon SDK uses these conventional application symbols.
DEFINE App_Process_ID prgprzn
DEFINE App_Bank_Number prgbnknum
DEFINE Message_Buffer prgmsgb

READ "SymbOS_Lib-SystemManager.asm"
READ "SymbOS_Lib-NetworkDaemon.asm"


;==============================================================================
;### DATA-AREA ################################################################
;==============================================================================

prgdatbeg

;### FONTS ####################################################################

;*** Font - ITALIC
fntita  db #08,#20
db #03,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00
db #03,#00,#40,#40,#80,#80,#00,#80,#00,#00,#00,#00,#00,#00,#00,#00
db #05,#00,#50,#50,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00
db #07,#00,#28,#7C,#28,#50,#F8,#50,#00,#00,#00,#00,#00,#00,#00,#00
db #05,#00,#20,#70,#60,#60,#E0,#40,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#60,#68,#10,#40,#B0,#30,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#20,#50,#60,#50,#A0,#50,#00,#00,#00,#00,#00,#00,#00,#00
db #03,#00,#40,#40,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00
db #04,#20,#40,#40,#40,#80,#80,#80,#40,#00,#00,#00,#00,#00,#00,#00
db #04,#40,#20,#20,#20,#40,#40,#40,#80,#00,#00,#00,#00,#00,#00,#00
db #07,#00,#00,#10,#7C,#70,#88,#00,#00,#00,#00,#00,#00,#00,#00,#00
db #07,#00,#00,#10,#10,#F8,#20,#20,#00,#00,#00,#00,#00,#00,#00,#00
db #04,#00,#00,#00,#00,#00,#C0,#40,#80,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#00,#00,#00,#F0,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00
db #03,#00,#00,#00,#00,#00,#00,#80,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#08,#08,#10,#20,#40,#40,#80,#80,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#30,#48,#48,#90,#90,#60,#00,#00,#00,#00,#00,#00,#00,#00
db #04,#00,#20,#60,#20,#40,#40,#E0,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#30,#48,#10,#60,#80,#F0,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#30,#48,#10,#10,#90,#60,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#40,#48,#88,#F0,#10,#10,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#78,#40,#70,#10,#90,#60,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#38,#40,#70,#90,#90,#60,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#78,#08,#10,#20,#40,#40,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#30,#48,#70,#90,#90,#60,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#30,#48,#48,#70,#10,#E0,#00,#00,#00,#00,#00,#00,#00,#00
db #03,#00,#00,#00,#40,#00,#00,#80,#00,#00,#00,#00,#00,#00,#00,#00
db #04,#00,#00,#00,#20,#00,#00,#40,#80,#00,#00,#00,#00,#00,#00,#00
db #05,#00,#00,#10,#60,#80,#40,#20,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#00,#00,#78,#00,#F0,#00,#00,#00,#00,#00,#00,#00,#00,#00
db #05,#00,#00,#40,#20,#20,#40,#80,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#30,#48,#10,#20,#00,#40,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#30,#48,#58,#B0,#80,#60,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#30,#48,#78,#90,#90,#90,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#70,#48,#70,#90,#90,#E0,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#30,#48,#40,#80,#90,#60,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#70,#48,#48,#90,#90,#E0,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#78,#40,#70,#80,#80,#F0,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#78,#40,#70,#80,#80,#80,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#38,#40,#58,#90,#90,#60,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#48,#48,#78,#90,#90,#90,#00,#00,#00,#00,#00,#00,#00,#00
db #03,#00,#40,#40,#40,#80,#80,#80,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#08,#08,#08,#10,#90,#60,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#48,#50,#60,#A0,#90,#90,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#40,#40,#40,#80,#80,#F0,#00,#00,#00,#00,#00,#00,#00,#00
db #07,#00,#44,#6C,#54,#88,#88,#88,#00,#00,#00,#00,#00,#00,#00,#00
db #07,#00,#44,#64,#54,#98,#88,#88,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#30,#48,#48,#90,#90,#60,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#70,#48,#58,#E0,#80,#80,#00,#00,#00,#00,#00,#00,#00,#00
db #07,#00,#30,#48,#48,#90,#B0,#68,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#70,#48,#70,#90,#90,#90,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#38,#40,#30,#10,#90,#60,#00,#00,#00,#00,#00,#00,#00,#00
db #07,#00,#7C,#10,#10,#20,#20,#20,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#48,#48,#48,#90,#90,#60,#00,#00,#00,#00,#00,#00,#00,#00
db #07,#00,#44,#44,#48,#50,#50,#20,#00,#00,#00,#00,#00,#00,#00,#00
db #07,#00,#44,#44,#44,#A8,#D8,#88,#00,#00,#00,#00,#00,#00,#00,#00
db #07,#00,#44,#28,#30,#50,#88,#88,#00,#00,#00,#00,#00,#00,#00,#00
db #07,#00,#44,#28,#10,#20,#20,#20,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#78,#08,#30,#40,#80,#F0,#00,#00,#00,#00,#00,#00,#00,#00
db #04,#00,#60,#40,#40,#80,#80,#C0,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#40,#40,#20,#20,#20,#20,#10,#10,#00,#00,#00,#00,#00,#00,#00
db #04,#00,#60,#20,#20,#40,#40,#C0,#00,#00,#00,#00,#00,#00,#00,#00
db #05,#00,#20,#50,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00
db #07,#00,#00,#00,#00,#00,#00,#F8,#00,#00,#00,#00,#00,#00,#00,#00
db #04,#00,#40,#20,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#00,#00,#38,#D0,#90,#70,#00,#00,#00,#00,#00,#00,#00,#00
db #05,#00,#40,#40,#70,#90,#90,#E0,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#00,#00,#38,#C0,#80,#70,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#08,#08,#38,#D0,#90,#70,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#00,#00,#30,#F0,#80,#60,#00,#00,#00,#00,#00,#00,#00,#00
db #04,#00,#20,#40,#60,#80,#80,#80,#00,#00,#00,#00,#00,#00,#00,#00
db #05,#00,#00,#00,#30,#D0,#70,#10,#E0,#00,#00,#00,#00,#00,#00,#00
db #05,#00,#40,#40,#70,#90,#90,#90,#00,#00,#00,#00,#00,#00,#00,#00
db #03,#00,#40,#00,#40,#80,#80,#80,#00,#00,#00,#00,#00,#00,#00,#00
db #04,#00,#20,#00,#20,#40,#40,#40,#80,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#40,#40,#48,#B0,#E0,#90,#00,#00,#00,#00,#00,#00,#00,#00
db #03,#00,#40,#40,#40,#80,#80,#40,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#00,#00,#68,#B8,#A8,#A8,#00,#00,#00,#00,#00,#00,#00,#00
db #05,#00,#00,#00,#70,#90,#90,#90,#00,#00,#00,#00,#00,#00,#00,#00
db #05,#00,#00,#00,#30,#D0,#90,#60,#00,#00,#00,#00,#00,#00,#00,#00
db #05,#00,#00,#00,#70,#90,#90,#E0,#80,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#00,#00,#38,#D0,#90,#70,#10,#00,#00,#00,#00,#00,#00,#00
db #05,#00,#00,#00,#70,#80,#80,#80,#00,#00,#00,#00,#00,#00,#00,#00
db #05,#00,#00,#00,#30,#C0,#60,#C0,#00,#00,#00,#00,#00,#00,#00,#00
db #04,#00,#40,#40,#60,#80,#80,#40,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#00,#00,#48,#90,#90,#60,#00,#00,#00,#00,#00,#00,#00,#00
db #07,#00,#00,#00,#44,#88,#50,#20,#00,#00,#00,#00,#00,#00,#00,#00
db #07,#00,#00,#00,#44,#A8,#A8,#50,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#00,#00,#48,#70,#60,#90,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#00,#00,#48,#90,#70,#10,#60,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#00,#00,#78,#20,#40,#F0,#00,#00,#00,#00,#00,#00,#00,#00
db #05,#10,#20,#20,#40,#20,#40,#40,#20,#00,#00,#00,#00,#00,#00,#00
db #03,#00,#40,#40,#40,#80,#80,#80,#00,#00,#00,#00,#00,#00,#00,#00
db #05,#40,#20,#20,#10,#20,#40,#40,#80,#00,#00,#00,#00,#00,#00,#00
db #07,#00,#00,#24,#58,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00
db #08,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00

;*** Font - BOLD
fntbld  db #08,#20
db #03,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00
db #03,#00,#C0,#C0,#C0,#C0,#00,#C0,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#D8,#D8,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00
db #08,#00,#6C,#FE,#6C,#6C,#FE,#6C,#00,#00,#00,#00,#00,#00,#00,#00
db #05,#00,#60,#F0,#E0,#70,#F0,#60,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#C0,#D8,#30,#60,#D8,#18,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#60,#F0,#C0,#78,#F0,#D8,#00,#00,#00,#00,#00,#00,#00,#00
db #03,#00,#C0,#C0,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00
db #04,#60,#C0,#C0,#C0,#C0,#C0,#C0,#60,#00,#00,#00,#00,#00,#00,#00
db #04,#C0,#60,#60,#60,#60,#60,#60,#C0,#00,#00,#00,#00,#00,#00,#00
db #07,#00,#00,#30,#FC,#78,#CC,#00,#00,#00,#00,#00,#00,#00,#00,#00
db #07,#00,#00,#30,#30,#FC,#30,#30,#00,#00,#00,#00,#00,#00,#00,#00
db #04,#00,#00,#00,#00,#00,#E0,#60,#C0,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#00,#00,#00,#F8,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00
db #03,#00,#00,#00,#00,#00,#00,#C0,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#18,#18,#30,#30,#60,#60,#C0,#C0,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#70,#D8,#D8,#D8,#D8,#70,#00,#00,#00,#00,#00,#00,#00,#00
db #05,#00,#60,#E0,#60,#60,#60,#F0,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#70,#D8,#30,#60,#C0,#F8,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#70,#D8,#30,#18,#D8,#70,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#C0,#D8,#D8,#F8,#18,#18,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#F8,#C0,#F0,#18,#D8,#70,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#78,#C0,#F0,#D8,#D8,#70,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#F8,#18,#30,#30,#60,#60,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#70,#D8,#70,#D8,#D8,#70,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#70,#D8,#D8,#78,#18,#F0,#00,#00,#00,#00,#00,#00,#00,#00
db #03,#00,#00,#00,#C0,#00,#00,#C0,#00,#00,#00,#00,#00,#00,#00,#00
db #04,#00,#00,#00,#60,#00,#00,#60,#C0,#00,#00,#00,#00,#00,#00,#00
db #05,#00,#00,#30,#60,#C0,#60,#30,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#00,#00,#F8,#00,#F8,#00,#00,#00,#00,#00,#00,#00,#00,#00
db #05,#00,#00,#C0,#60,#30,#60,#C0,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#70,#D8,#30,#60,#00,#60,#00,#00,#00,#00,#00,#00,#00,#00
db #07,#00,#78,#CC,#DC,#DC,#C0,#78,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#70,#D8,#F8,#D8,#D8,#D8,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#F0,#D8,#F0,#D8,#D8,#F0,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#70,#D8,#C0,#C0,#D8,#70,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#F0,#D8,#D8,#D8,#D8,#F0,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#F8,#C0,#F0,#C0,#C0,#F8,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#F8,#C0,#F0,#C0,#C0,#C0,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#78,#C0,#D8,#D8,#D8,#70,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#D8,#D8,#F8,#D8,#D8,#D8,#00,#00,#00,#00,#00,#00,#00,#00
db #03,#00,#C0,#C0,#C0,#C0,#C0,#C0,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#18,#18,#18,#18,#D8,#70,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#D8,#F0,#E0,#F0,#D8,#D8,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#C0,#C0,#C0,#C0,#C0,#F8,#00,#00,#00,#00,#00,#00,#00,#00
db #07,#00,#CC,#FC,#FC,#CC,#CC,#CC,#00,#00,#00,#00,#00,#00,#00,#00
db #07,#00,#CC,#EC,#FC,#DC,#CC,#CC,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#70,#D8,#D8,#D8,#D8,#70,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#F0,#D8,#D8,#F0,#C0,#C0,#00,#00,#00,#00,#00,#00,#00,#00
db #07,#00,#70,#D8,#D8,#D8,#F8,#6C,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#F0,#D8,#F0,#D8,#D8,#D8,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#78,#C0,#70,#18,#D8,#70,#00,#00,#00,#00,#00,#00,#00,#00
db #07,#00,#FC,#30,#30,#30,#30,#30,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#D8,#D8,#D8,#D8,#D8,#70,#00,#00,#00,#00,#00,#00,#00,#00
db #07,#00,#CC,#CC,#CC,#78,#78,#30,#00,#00,#00,#00,#00,#00,#00,#00
db #07,#00,#CC,#CC,#CC,#FC,#FC,#CC,#00,#00,#00,#00,#00,#00,#00,#00
db #07,#00,#CC,#78,#30,#78,#CC,#CC,#00,#00,#00,#00,#00,#00,#00,#00
db #07,#00,#CC,#78,#30,#30,#30,#30,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#F8,#18,#30,#60,#C0,#F8,#00,#00,#00,#00,#00,#00,#00,#00
db #04,#00,#E0,#C0,#C0,#C0,#C0,#E0,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#C0,#C0,#60,#60,#30,#30,#18,#18,#00,#00,#00,#00,#00,#00,#00
db #04,#00,#E0,#60,#60,#60,#60,#E0,#00,#00,#00,#00,#00,#00,#00,#00
db #05,#00,#70,#D8,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00
db #07,#00,#00,#00,#00,#00,#00,#FC,#00,#00,#00,#00,#00,#00,#00,#00
db #04,#00,#C0,#60,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#00,#00,#78,#D8,#D8,#78,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#C0,#C0,#F0,#D8,#D8,#F0,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#00,#00,#78,#C0,#C0,#78,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#18,#18,#78,#D8,#D8,#78,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#00,#00,#70,#F8,#C0,#70,#00,#00,#00,#00,#00,#00,#00,#00
db #04,#00,#60,#C0,#E0,#C0,#C0,#C0,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#00,#00,#70,#D8,#78,#18,#F0,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#C0,#C0,#F0,#D8,#D8,#D8,#00,#00,#00,#00,#00,#00,#00,#00
db #03,#00,#C0,#00,#C0,#C0,#C0,#C0,#00,#00,#00,#00,#00,#00,#00,#00
db #04,#00,#60,#00,#60,#60,#60,#60,#C0,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#C0,#C0,#D8,#F0,#F0,#D8,#00,#00,#00,#00,#00,#00,#00,#00
db #04,#00,#C0,#C0,#C0,#C0,#C0,#60,#00,#00,#00,#00,#00,#00,#00,#00
db #08,#00,#00,#00,#FC,#D6,#D6,#D6,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#00,#00,#F0,#D8,#D8,#D8,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#00,#00,#70,#D8,#D8,#70,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#00,#00,#F0,#D8,#D8,#F0,#C0,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#00,#00,#78,#D8,#D8,#78,#18,#00,#00,#00,#00,#00,#00,#00
db #05,#00,#00,#00,#F0,#C0,#C0,#C0,#00,#00,#00,#00,#00,#00,#00,#00
db #05,#00,#00,#00,#70,#E0,#70,#E0,#00,#00,#00,#00,#00,#00,#00,#00
db #04,#00,#C0,#C0,#E0,#C0,#C0,#60,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#00,#00,#D8,#D8,#D8,#70,#00,#00,#00,#00,#00,#00,#00,#00
db #07,#00,#00,#00,#CC,#CC,#78,#30,#00,#00,#00,#00,#00,#00,#00,#00
db #08,#00,#00,#00,#C6,#D6,#FE,#6C,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#00,#00,#D8,#70,#70,#D8,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#00,#00,#D8,#D8,#78,#18,#70,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#00,#00,#F8,#30,#60,#F8,#00,#00,#00,#00,#00,#00,#00,#00
db #05,#30,#60,#60,#C0,#60,#60,#60,#30,#00,#00,#00,#00,#00,#00,#00
db #03,#00,#C0,#C0,#C0,#C0,#C0,#C0,#00,#00,#00,#00,#00,#00,#00,#00
db #05,#C0,#60,#60,#30,#60,#60,#60,#C0,#00,#00,#00,#00,#00,#00,#00
db #07,#00,#00,#76,#DC,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00
db #08,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00

;*** Font - BIG
fntbig  db #0A,#20
db #03,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00
db #03,#C0,#C0,#C0,#C0,#C0,#C0,#00,#C0,#C0,#00,#00,#00,#00,#00,#00
db #07,#6C,#D8,#D8,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00
db #08,#6C,#6C,#FE,#6C,#6C,#6C,#FE,#6C,#6C,#00,#00,#00,#00,#00,#00
db #08,#10,#7C,#D6,#D0,#7C,#16,#D6,#7C,#10,#00,#00,#00,#00,#00,#00
db #08,#00,#40,#E6,#4C,#18,#30,#64,#CE,#04,#00,#00,#00,#00,#00,#00
db #08,#38,#6C,#6C,#38,#76,#DC,#CC,#CC,#76,#00,#00,#00,#00,#00,#00
db #04,#60,#60,#C0,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00
db #05,#30,#60,#C0,#C0,#C0,#C0,#C0,#60,#30,#00,#00,#00,#00,#00,#00
db #05,#C0,#60,#30,#30,#30,#30,#30,#60,#C0,#00,#00,#00,#00,#00,#00
db #08,#00,#00,#6C,#38,#FE,#38,#6C,#00,#00,#00,#00,#00,#00,#00,#00
db #07,#00,#00,#30,#30,#FC,#30,#30,#00,#00,#00,#00,#00,#00,#00,#00
db #04,#00,#00,#00,#00,#00,#00,#00,#60,#60,#C0,#00,#00,#00,#00,#00
db #06,#00,#00,#00,#00,#F8,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00
db #03,#00,#00,#00,#00,#00,#00,#00,#C0,#C0,#00,#00,#00,#00,#00,#00
db #07,#0C,#0C,#18,#18,#30,#60,#60,#C0,#C0,#00,#00,#00,#00,#00,#00
db #08,#38,#6C,#C6,#C6,#C6,#C6,#C6,#6C,#38,#00,#00,#00,#00,#00,#00
db #05,#30,#70,#F0,#30,#30,#30,#30,#30,#30,#00,#00,#00,#00,#00,#00
db #08,#7C,#C6,#C6,#0C,#38,#60,#C0,#C0,#FE,#00,#00,#00,#00,#00,#00
db #08,#7C,#C6,#06,#06,#1C,#06,#06,#C6,#7C,#00,#00,#00,#00,#00,#00
db #08,#0C,#1C,#3C,#6C,#CC,#FE,#0C,#0C,#0C,#00,#00,#00,#00,#00,#00
db #08,#FE,#C0,#C0,#F8,#0C,#06,#06,#CC,#78,#00,#00,#00,#00,#00,#00
db #08,#7C,#C6,#C6,#C0,#FC,#C6,#C6,#C6,#7C,#00,#00,#00,#00,#00,#00
db #08,#FE,#C6,#CC,#0C,#18,#18,#30,#30,#30,#00,#00,#00,#00,#00,#00
db #08,#7C,#C6,#C6,#C6,#7C,#C6,#C6,#C6,#7C,#00,#00,#00,#00,#00,#00
db #08,#7C,#C6,#C6,#C6,#7E,#06,#C6,#C6,#7C,#00,#00,#00,#00,#00,#00
db #03,#00,#00,#00,#C0,#C0,#00,#00,#C0,#C0,#00,#00,#00,#00,#00,#00
db #04,#00,#00,#00,#60,#60,#00,#00,#60,#60,#C0,#00,#00,#00,#00,#00
db #06,#00,#18,#30,#60,#C0,#60,#30,#18,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#00,#00,#F8,#00,#00,#F8,#00,#00,#00,#00,#00,#00,#00,#00
db #06,#00,#C0,#60,#30,#18,#30,#60,#C0,#00,#00,#00,#00,#00,#00,#00
db #08,#7C,#C6,#C6,#0C,#18,#30,#30,#00,#30,#00,#00,#00,#00,#00,#00
db #08,#00,#7C,#C6,#DE,#D6,#DC,#C0,#7C,#00,#00,#00,#00,#00,#00,#00
db #08,#10,#38,#6C,#C6,#C6,#FE,#C6,#C6,#C6,#00,#00,#00,#00,#00,#00
db #08,#FC,#C6,#C6,#C6,#FC,#C6,#C6,#C6,#FC,#00,#00,#00,#00,#00,#00
db #08,#7C,#C6,#C0,#C0,#C0,#C0,#C0,#C6,#7C,#00,#00,#00,#00,#00,#00
db #08,#F8,#CC,#C6,#C6,#C6,#C6,#C6,#CC,#F8,#00,#00,#00,#00,#00,#00
db #07,#FC,#C0,#C0,#C0,#F0,#C0,#C0,#C0,#FC,#00,#00,#00,#00,#00,#00
db #07,#FC,#C0,#C0,#C0,#F0,#C0,#C0,#C0,#C0,#00,#00,#00,#00,#00,#00
db #08,#7C,#C6,#C0,#C0,#CE,#C6,#C6,#C6,#7C,#00,#00,#00,#00,#00,#00
db #08,#C6,#C6,#C6,#C6,#FE,#C6,#C6,#C6,#C6,#00,#00,#00,#00,#00,#00
db #03,#C0,#C0,#C0,#C0,#C0,#C0,#C0,#C0,#C0,#00,#00,#00,#00,#00,#00
db #07,#0C,#0C,#0C,#0C,#0C,#0C,#CC,#CC,#78,#00,#00,#00,#00,#00,#00
db #08,#C6,#C6,#CC,#D8,#F0,#D8,#CC,#C6,#C6,#00,#00,#00,#00,#00,#00
db #07,#C0,#C0,#C0,#C0,#C0,#C0,#C0,#C0,#FC,#00,#00,#00,#00,#00,#00
db #08,#C6,#EE,#FE,#D6,#C6,#C6,#C6,#C6,#C6,#00,#00,#00,#00,#00,#00
db #08,#C6,#C6,#E6,#F6,#DE,#CE,#C6,#C6,#C6,#00,#00,#00,#00,#00,#00
db #08,#38,#6C,#C6,#C6,#C6,#C6,#C6,#6C,#38,#00,#00,#00,#00,#00,#00
db #08,#FC,#C6,#C6,#C6,#FC,#C0,#C0,#C0,#C0,#00,#00,#00,#00,#00,#00
db #08,#38,#6C,#C6,#C6,#C6,#D6,#CC,#DC,#76,#00,#00,#00,#00,#00,#00
db #08,#FC,#C6,#C6,#C6,#FC,#D8,#CC,#C6,#C6,#00,#00,#00,#00,#00,#00
db #08,#7C,#C6,#C0,#C0,#7C,#06,#06,#C6,#7C,#00,#00,#00,#00,#00,#00
db #07,#FC,#30,#30,#30,#30,#30,#30,#30,#30,#00,#00,#00,#00,#00,#00
db #08,#C6,#C6,#C6,#C6,#C6,#C6,#C6,#C6,#7C,#00,#00,#00,#00,#00,#00
db #08,#C6,#C6,#C6,#C6,#6C,#6C,#38,#38,#10,#00,#00,#00,#00,#00,#00
db #08,#C6,#C6,#C6,#C6,#C6,#D6,#FE,#EE,#C6,#00,#00,#00,#00,#00,#00
db #08,#C6,#C6,#C6,#6C,#38,#6C,#C6,#C6,#C6,#00,#00,#00,#00,#00,#00
db #07,#CC,#CC,#CC,#78,#30,#30,#30,#30,#30,#00,#00,#00,#00,#00,#00
db #07,#FC,#0C,#0C,#18,#30,#60,#C0,#C0,#FC,#00,#00,#00,#00,#00,#00
db #05,#F0,#C0,#C0,#C0,#C0,#C0,#C0,#C0,#F0,#00,#00,#00,#00,#00,#00
db #07,#C0,#C0,#60,#60,#30,#18,#18,#0C,#0C,#00,#00,#00,#00,#00,#00
db #05,#F0,#30,#30,#30,#30,#30,#30,#30,#F0,#00,#00,#00,#00,#00,#00
db #06,#20,#70,#D8,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00
db #07,#00,#00,#00,#00,#00,#00,#00,#00,#00,#FE,#00,#00,#00,#00,#00
db #05,#C0,#60,#30,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00
db #07,#00,#00,#00,#78,#0C,#7C,#CC,#CC,#7C,#00,#00,#00,#00,#00,#00
db #07,#C0,#C0,#C0,#F8,#CC,#CC,#CC,#CC,#F8,#00,#00,#00,#00,#00,#00
db #07,#00,#00,#00,#78,#CC,#C0,#C0,#CC,#78,#00,#00,#00,#00,#00,#00
db #07,#0C,#0C,#0C,#7C,#CC,#CC,#CC,#CC,#7C,#00,#00,#00,#00,#00,#00
db #07,#00,#00,#00,#78,#CC,#FC,#C0,#C0,#78,#00,#00,#00,#00,#00,#00
db #06,#38,#60,#60,#60,#F0,#60,#60,#60,#60,#00,#00,#00,#00,#00,#00
db #07,#00,#00,#00,#78,#CC,#CC,#CC,#7C,#0C,#F8,#00,#00,#00,#00,#00
db #07,#C0,#C0,#C0,#F8,#CC,#CC,#CC,#CC,#CC,#00,#00,#00,#00,#00,#00
db #03,#00,#C0,#00,#C0,#C0,#C0,#C0,#C0,#C0,#00,#00,#00,#00,#00,#00
db #05,#00,#30,#00,#30,#30,#30,#30,#30,#30,#E0,#00,#00,#00,#00,#00
db #07,#C0,#C0,#CC,#CC,#D8,#F0,#D8,#CC,#CC,#00,#00,#00,#00,#00,#00
db #04,#C0,#C0,#C0,#C0,#C0,#C0,#C0,#C0,#60,#00,#00,#00,#00,#00,#00
db #08,#00,#00,#00,#6C,#FE,#D6,#D6,#C6,#C6,#00,#00,#00,#00,#00,#00
db #07,#00,#00,#00,#F8,#CC,#CC,#CC,#CC,#CC,#00,#00,#00,#00,#00,#00
db #07,#00,#00,#00,#78,#CC,#CC,#CC,#CC,#78,#00,#00,#00,#00,#00,#00
db #07,#00,#00,#00,#F8,#CC,#CC,#CC,#F8,#C0,#C0,#00,#00,#00,#00,#00
db #07,#00,#00,#00,#7C,#CC,#CC,#CC,#7C,#0C,#0C,#00,#00,#00,#00,#00
db #06,#00,#00,#00,#D8,#F0,#C0,#C0,#C0,#C0,#00,#00,#00,#00,#00,#00
db #07,#00,#00,#00,#7C,#C0,#78,#0C,#0C,#F8,#00,#00,#00,#00,#00,#00
db #05,#60,#60,#60,#F0,#60,#60,#60,#60,#30,#00,#00,#00,#00,#00,#00
db #07,#00,#00,#00,#CC,#CC,#CC,#CC,#CC,#7C,#00,#00,#00,#00,#00,#00
db #07,#00,#00,#00,#CC,#CC,#CC,#CC,#78,#30,#00,#00,#00,#00,#00,#00
db #08,#00,#00,#00,#C6,#C6,#D6,#D6,#FE,#6C,#00,#00,#00,#00,#00,#00
db #08,#00,#00,#00,#C6,#6C,#38,#6C,#C6,#C6,#00,#00,#00,#00,#00,#00
db #07,#00,#00,#00,#CC,#CC,#7C,#0C,#0C,#F8,#00,#00,#00,#00,#00,#00
db #06,#00,#00,#00,#F8,#18,#30,#60,#C0,#F8,#00,#00,#00,#00,#00,#00
db #05,#30,#60,#60,#60,#C0,#60,#60,#60,#30,#00,#00,#00,#00,#00,#00
db #03,#C0,#C0,#C0,#C0,#00,#C0,#C0,#C0,#C0,#00,#00,#00,#00,#00,#00
db #05,#C0,#60,#60,#60,#30,#60,#60,#60,#C0,#00,#00,#00,#00,#00,#00
db #08,#00,#00,#20,#76,#DC,#08,#00,#00,#00,#00,#00,#00,#00,#00,#00
db #08,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00,#00

renviwtxt   db 0,-1         ;### last data-area byte!! ###


;==============================================================================
;### TRANSFER-AREA ############################################################
;==============================================================================

prgtrnbeg

prgicn16c db 12,24,24:dw $+7:dw $+4,12*24:db 5
db #44,#44,#44,#44,#44,#44,#44,#44,#44,#4F,#FF,#F4,#44,#44,#44,#44,#44,#4F,#FF,#F4,#F1,#33,#33,#33,#44,#44,#44,#44,#44,#F1,#13,#33,#31,#1F,#FF,#13,#44,#44,#44,#44,#4F,#31,#31,#11,#3F,#F1,#1F,#FF
db #44,#44,#44,#44,#4F,#33,#36,#61,#1F,#F1,#33,#1F,#44,#44,#44,#44,#4F,#33,#64,#63,#31,#FF,#13,#31,#44,#44,#44,#44,#13,#31,#66,#11,#F1,#1F,#13,#FF,#44,#44,#44,#13,#31,#13,#11,#FF,#13,#31,#F1,#FF
db #44,#4F,#13,#11,#FF,#F1,#11,#F1,#F3,#33,#1F,#FF,#4F,#13,#1F,#FF,#FF,#FF,#F1,#3F,#F1,#1F,#11,#FF,#43,#1F,#FF,#FF,#FF,#FF,#13,#1F,#FF,#FF,#FF,#1F,#F3,#3F,#FF,#FF,#FF,#F3,#33,#F1,#FF,#FF,#FF,#31
db #F3,#3F,#FF,#FF,#F1,#33,#33,#33,#FF,#FF,#FF,#3F,#F1,#1F,#FF,#FF,#33,#33,#33,#31,#FF,#FF,#F1,#31,#11,#FF,#F1,#33,#31,#33,#33,#31,#FF,#FF,#13,#31,#F3,#33,#33,#11,#33,#31,#13,#1F,#FF,#FF,#1F,#31
db #A3,#13,#13,#33,#11,#FF,#FF,#FF,#FF,#11,#F1,#1F,#A1,#33,#31,#FF,#F1,#33,#11,#FF,#13,#3F,#F1,#FF,#AA,#13,#33,#13,#33,#33,#33,#33,#33,#FF,#FF,#FF,#AA,#AF,#F3,#33,#31,#11,#13,#33,#3F,#FF,#FF,#FF
db #AA,#AA,#AF,#F1,#FF,#FA,#AF,#33,#33,#FF,#FF,#FF,#AA,#AA,#AA,#AA,#AA,#AA,#AA,#A3,#31,#1F,#FF,#FF,#AA,#AA,#AA,#AA,#AA,#AA,#AA,#AF,#3F,#11,#FF,#FF,#AA,#AA,#AA,#AA,#AA,#AA,#AA,#AA,#13,#3F,#FF,#FF

;### PRGPRZS -> Stack fur Programm-Prozess
        ds 128
prgstk  ds 6*2
        dw prgprz
prgprzn db 0
prgmsgb ds 14

gfxbrwbak  db 6,12,12:dw $+7:dw $+4:dw 6*12:db 5
db #22,#22,#11,#11,#22,#22,#22,#11,#77,#77,#11,#22,#21,#77,#77,#87,#77,#12,#21,#77,#78,#87,#77,#12,#17,#77,#88,#77,#77,#71,#17,#78,#88,#88,#87,#71
db #17,#78,#88,#88,#87,#71,#17,#77,#88,#77,#77,#71,#21,#77,#78,#87,#77,#12,#21,#77,#77,#87,#77,#12,#22,#11,#77,#77,#11,#22,#22,#22,#11,#11,#22,#22
gfxbrwfor  db 6,12,12:dw $+7:dw $+4:dw 6*12:db 5
db #22,#22,#11,#11,#22,#22,#22,#11,#77,#77,#11,#22,#21,#77,#78,#77,#77,#12,#21,#77,#78,#87,#77,#12,#17,#77,#77,#88,#77,#71,#17,#78,#88,#88,#87,#71
db #17,#78,#88,#88,#87,#71,#17,#77,#77,#88,#77,#71,#21,#77,#78,#87,#77,#12,#21,#77,#78,#77,#77,#12,#22,#11,#77,#77,#11,#22,#22,#22,#11,#11,#22,#22
gfxbrwstp  db 6,12,12:dw $+7:dw $+4:dw 6*12:db 5
db #21,#11,#11,#11,#22,#22,#21,#88,#88,#81,#12,#22,#21,#88,#88,#81,#D1,#22,#21,#88,#88,#81,#11,#12,#21,#88,#88,#88,#88,#12,#21,#8F,#F8,#FF,#88,#12
db #21,#88,#FF,#F8,#88,#12,#21,#88,#FF,#F8,#88,#12,#21,#8F,#F8,#FF,#88,#12,#21,#88,#88,#88,#88,#12,#21,#88,#88,#88,#88,#12,#21,#11,#11,#11,#11,#12
gfxbrwrel  db 6,12,12:dw $+7:dw $+4:dw 6*12:db 5
db #21,#11,#11,#11,#22,#22,#21,#88,#88,#81,#12,#22,#21,#88,#88,#81,#D1,#22,#21,#88,#88,#81,#11,#12,#21,#88,#88,#88,#88,#12,#21,#88,#89,#99,#88,#12
db #21,#88,#98,#99,#88,#12,#21,#88,#88,#88,#88,#12,#21,#88,#99,#89,#88,#12,#21,#88,#99,#98,#88,#12,#21,#88,#88,#88,#88,#12,#21,#11,#11,#11,#11,#12
gfxbrwhom  db 6,12,12:dw $+7:dw $+4:dw 6*12:db 5
db #22,#22,#21,#12,#22,#22,#22,#22,#11,#11,#33,#22,#22,#21,#1C,#C1,#13,#22,#22,#11,#CC,#CC,#11,#22,#21,#1C,#CC,#CC,#C1,#12,#11,#CC,#CC,#CC,#CC,#11
db #21,#CC,#11,#11,#CC,#12,#21,#CC,#13,#31,#CC,#12,#21,#CC,#13,#61,#CC,#12,#21,#CC,#13,#31,#CC,#12,#21,#CC,#13,#31,#CC,#12,#21,#11,#11,#11,#11,#12
gfxbrwfav  db 6,12,12:dw $+7:dw $+4:dw 6*12:db 5
db #22,#22,#21,#12,#22,#22,#22,#22,#21,#12,#22,#22,#22,#22,#1C,#C1,#22,#22,#22,#22,#1C,#C1,#22,#22,#11,#11,#1C,#C1,#11,#11,#1C,#CC,#CC,#CC,#CC,#C1
db #21,#1C,#CC,#CC,#C1,#12,#22,#21,#CC,#CC,#12,#22,#22,#21,#CC,#CC,#12,#22,#22,#1C,#C1,#1C,#C1,#22,#22,#1C,#12,#21,#C1,#22,#22,#11,#22,#22,#11,#22
gfxbrwlod  db 6,12,12:dw $+7:dw $+4:dw 6*12:db 5
db #22,#22,#22,#22,#22,#22,#22,#11,#11,#11,#11,#22,#21,#77,#77,#77,#77,#12,#21,#77,#78,#87,#77,#12,#21,#77,#77,#88,#77,#12,#21,#78,#88,#88,#87,#12
db #21,#78,#88,#88,#87,#12,#21,#77,#77,#88,#77,#12,#21,#77,#78,#87,#77,#12,#21,#77,#77,#77,#77,#12,#22,#11,#11,#11,#11,#22,#22,#22,#22,#22,#22,#22
gfxbrwopn  db 6,12,12:dw $+7:dw $+4:dw 6*12:db 5
db #22,#22,#11,#11,#22,#22,#22,#11,#77,#77,#11,#22,#21,#77,#77,#77,#77,#12,#21,#77,#78,#87,#77,#12,#17,#77,#88,#88,#77,#71,#17,#78,#88,#88,#87,#71
db #17,#77,#77,#77,#77,#71,#17,#78,#88,#88,#87,#71,#21,#77,#77,#77,#77,#12,#21,#77,#77,#77,#77,#12,#22,#11,#77,#77,#11,#22,#22,#22,#11,#11,#22,#22
gfxbrwac0  db 6,12,12:dw $+7:dw $+4:dw 6*12:db 5
db #22,#22,#00,#00,#22,#22,#22,#00,#00,#00,#00,#22,#20,#00,#00,#00,#00,#02,#20,#00,#02,#20,#00,#02,#00,#00,#22,#22,#22,#22,#00,#00,#00,#00,#00,#00
db #00,#00,#00,#00,#00,#00,#22,#22,#22,#22,#00,#00,#20,#00,#02,#20,#00,#02,#20,#00,#00,#00,#00,#02,#22,#00,#00,#00,#00,#22,#22,#22,#00,#00,#22,#22
gfxbrwac1  db 6,12,12:dw $+7:dw $+4:dw 6*12:db 5
db #22,#22,#FF,#11,#22,#22,#22,#FF,#FF,#11,#11,#22,#2F,#FF,#FF,#11,#11,#12,#2F,#FF,#F2,#21,#11,#12,#FF,#FF,#22,#22,#22,#22,#FF,#FF,#FF,#11,#11,#11
db #FF,#FF,#FF,#FF,#FF,#FF,#22,#22,#22,#22,#FF,#FF,#2F,#FF,#F2,#2F,#FF,#F2,#2F,#FF,#FF,#FF,#FF,#F2,#22,#FF,#FF,#FF,#FF,#22,#22,#22,#FF,#FF,#22,#22
gfxbrwac2  db 6,12,12:dw $+7:dw $+4:dw 6*12:db 5
db #22,#22,#FF,#FF,#22,#22,#22,#FF,#FF,#FF,#FF,#22,#2F,#FF,#FF,#FF,#FF,#F2,#2F,#FF,#F2,#2F,#FF,#F2,#FF,#FF,#22,#22,#22,#22,#FF,#FF,#FF,#FF,#FF,#FF
db #FF,#FF,#FF,#11,#11,#11,#22,#22,#22,#22,#11,#11,#2F,#FF,#F2,#21,#11,#12,#2F,#FF,#FF,#11,#11,#12,#22,#FF,#FF,#11,#11,#22,#22,#22,#FF,#11,#22,#22
gfxbrwac3  db 6,12,12:dw $+7:dw $+4:dw 6*12:db 5
db #22,#22,#FF,#FF,#22,#22,#22,#FF,#FF,#FF,#FF,#22,#2F,#FF,#FF,#FF,#FF,#F2,#2F,#FF,#F2,#2F,#FF,#F2,#FF,#FF,#22,#22,#22,#22,#FF,#FF,#FF,#FF,#FF,#FF
db #11,#11,#11,#FF,#FF,#FF,#22,#22,#22,#22,#FF,#FF,#21,#11,#12,#2F,#FF,#F2,#21,#11,#11,#FF,#FF,#F2,#22,#11,#11,#FF,#FF,#22,#22,#22,#11,#FF,#22,#22
gfxbrwac4  db 6,12,12:dw $+7:dw $+4:dw 6*12:db 5
db #22,#22,#11,#FF,#22,#22,#22,#11,#11,#FF,#FF,#22,#21,#11,#11,#FF,#FF,#F2,#21,#11,#12,#2F,#FF,#F2,#11,#11,#22,#22,#22,#22,#11,#11,#11,#FF,#FF,#FF
db #FF,#FF,#FF,#FF,#FF,#FF,#22,#22,#22,#22,#FF,#FF,#2F,#FF,#F2,#2F,#FF,#F2,#2F,#FF,#FF,#FF,#FF,#F2,#22,#FF,#FF,#FF,#FF,#22,#22,#22,#FF,#FF,#22,#22

;### CONFIGURATION ############################################################
cfgbeg
cfghom  db "http://www.symbos.de": ds 128-20

favanz  db 0
favmem  ds 16*96

cfgnav  db 2    ;flag, if display navigation bar
cfglnk  db 0    ;flag, if display quicklink bar
cfgsta  db 2    ;flag, if display status bar

; Appended for compatibility with existing appzilla.ini files.
cfgproxy db "gb-proxy:5001",0:ds 64-14

cfgend

;### MISC #####################################################################
prgwintit   db "SymZilla":ds 32+11-8

prgmsginf1  db "SymbOS SymZilla",0
prgmsginf2  db " Version 0.3 (Build 260816gbp)",0
prgmsginf3  db " Copyright <c> 2007 SymbiosiS",0

prgmsgerr1  db "SymZilla can't open this document,",0
prgmsgerr2a db "as there is no memory available.",0
prgmsgerr2b db "as the protocol is unknown.",0
prgmsgerr0  db 0

prgtxtok    db "Ok",0

prgstadon   db "Done",0
prgstalod   db "Loading...",0
prgstaren   db "Rendering...",0

lnkmem      ds 8*14

;### MENU #####################################################################
prgwinmentx1 db "File",0
prgwinmen1tx1 db "New Window",0
prgwinmen1tx2 db "Open Location...",0
prgwinmen1tx3 db "Open File...",0
prgwinmen1tx4 db "Close",0
prgwinmen1tx5 db "Save Page As...",0
prgwinmen1tx6 db "Exit",0

prgwinmentx2 db "Edit",0
prgwinmen2tx1 db "Find In This Page",0
prgwinmen2tx2 db "Options...",0

prgwinmentx3 db "View",0
prgwinmen3tx1 db "Navigation Toolbar",0
prgwinmen3tx2 db "Bookmarks Toolbar",0
prgwinmen3tx3 db "Status Bar",0

prgwinmentx4 db "Navigation",0
prgwinmen4tx1 db "Back",0
prgwinmen4tx2 db "Forward",0
prgwinmen4tx3 db "Home",0
prgwinmen4tx4 db "Reload",0
prgwinmen4tx5 db "Stop",0

prgwinmentx5 db "Bookmarks",0
prgwinmen5tx1 db "Bookmark This Page",0
prgwinmen5tx2 db "Organise Bookmarks",0

prgwinmentx6 db "?",0
prgwinmen6tx1 db "Index",0
prgwinmen6tx2 db "About SymZilla...",0

;### INFO AND FILE-SELECTION ##################################################

doxmsk  db "DOX",0
doxpth  ds 256
doxinf  ds 256          ;dox info header (also temporarily used for new links!)
doxemp  db "[empty]",0

;### INFO-FENSTER #############################################################

prgmsginf  dw prgmsginf1,4*1+2,prgmsginf2,4*1+2,prgmsginf3,4*1+2,prgicnbig

;### ERROR-FENSTER ############################################################

prgmsgerr  dw prgmsgerr1,4*1+2
prgmsgerra dw prgmsgerr0,4*1+2,prgmsgerr0,4*1+2

;### CONFIG WINDOW ############################################################

configwin   dw #1401,4+16,059,039,220,104,0,0,220,104,220,104,220,104,0,configtit,0,0,configgrp,0,0:ds 136+14
configtit   db "Options",0
configgrp   db 10,0:dw configdat,0,0,256*10+10,0,0,4
configdat
dw      00,         0,2,          0,0,1000,1000,0       ;00=Background
dw      00,255*256+ 3,configdsc0, 00, 01,220,46,0       ;01=Frame "Startup"
dw      00,255*256+ 1,configdsc1, 08, 13, 54, 8,0       ;02=Description "Home page"
dw      00,255*256+32,configinp1, 56, 11,156,12,0       ;03=Input "Home page"
dw cfghom1,255*256+16,configtxt2, 40, 27, 80,12,0       ;04="Use Current Page" -Button
dw cfghom2,255*256+16,configtxt3,124, 27, 80,12,0       ;05="Show Blank Page"-Button
dw      00,255*256+ 3,configdsc2, 00, 49,220,34,0       ;06=Frame "Network"
dw      00,255*256+ 1,configdsc3, 08, 61, 54, 8,0       ;07=Description "GB proxy"
dw      00,255*256+32,configinp2, 56, 59,156,12,0       ;08=Input "GB proxy"
dw cfgset1,255*256+16,prgtxtok,   86, 86, 48,12,0       ;09="Ok"    -Button

configdsc0  dw configtxt0,2+4
configdsc1  dw configtxt1,2+4
configdsc2  dw configtxt4,2+4
configdsc3  dw configtxt5,2+4

configinp1  dw cfghom,0,0,0,0,127,0
configinp2  dw cfgproxy,0,0,0,0,63,0

configtxt0  db "Startup",0
configtxt1  db "Home Page:",0
configtxt2  db "Use Current Page",0
configtxt3  db "Show Blank Page",0
configtxt4  db "Network",0
configtxt5  db "GB proxy:",0

;### BOOKMARKS ################################################################

prgwinlnk   dw #1501,0,80,5,160,166,0,0,160,166,160,166,160,166,prgicnsml,prgtitlnk,0,0,prggrplnk,0,0:ds 136+14
prggrplnk   db 13,0:dw prgdatlnk,0,0,256*13+13,0,0,2
prgdatlnk
dw 00,     255*256+0, 2,           0,0,1000,1000,0      ;00=background
dw favclk, 255*256+41,prgobjlnk1,   4, 4,152, 87,0      ;01=entry list
dw favmup, 255*256+16,prgtxtlnk1a,  4, 93,37, 12,0      ;02=Button "Up"
dw favmdw, 255*256+16,prgtxtlnk1b, 43, 93,37, 12,0      ;03=Button "Down"
dw favdel, 255*256+16,prgtxtlnk1c, 82, 93,36, 12,0      ;04=Button "Del"
dw favnew, 255*256+16,prgtxtlnk1d,120, 93,36, 12,0      ;05=Button "Add"
dw 00,     255*256+3, prgobjlnk2,  0,108,160, 44,0      ;06=edit frame
dw 00,     255*256+1, prgobjlnk2a,  8,120,38,  8,0      ;07=description name
dw 00,     255*256+1, prgobjlnk2c,  8,134,38,  8,0      ;08=description path
dw 00,     255*256+0, 2,           48,118,104,26,0      ;09=input field hide
prgdatlnk1
dw 00,     255*256+32,prgobjlnk2b, 48,118,104,12,0      ;10=input name
dw 00,     255*256+32,prgobjlnk2d, 48,132,104,12,0      ;11=input path
dw favman1,255*256+16,prgtxtok,    56,152, 48,12,0      ;12="Ok"    -Button

prgobjlnk2  dw prgtxtlnk2, 2+4

prgobjlnk2a dw prgtxtlnk2a,2+4
prgobjlnk2b dw favmem,0,0,0,0,25,0

prgobjlnk2c dw prgtxtlnk2c,2+4
prgobjlnk2d dw favmem+26,0,0,0,0,69,0

prgobjlnk1  dw 4,0,lnkentlst,0,256*0+1,lnkentcol,0,1
lnkentcol   dw 0,152,00,0
lnkentlst   dw 00,00*96+favmem,01,01*96+favmem,02,02*96+favmem,03,03*96+favmem,04,04*96+favmem,05,05*96+favmem,06,06*96+favmem,07,07*96+favmem
            dw 08,08*96+favmem,09,09*96+favmem,10,10*96+favmem,11,11*96+favmem,12,12*96+favmem,13,13*96+favmem,14,14*96+favmem,15,15*96+favmem

prgtitlnk   db "Bookmark manager",0
prgtxtlnk1a db "Up",0
prgtxtlnk1b db "Down",0
prgtxtlnk1c db "Del",0
prgtxtlnk1d db "Add",0
prgtxtlnk2  db "Edit",0
prgtxtlnk2a db "Name",0
prgtxtlnk2c db "Address",0

;### MAIN WINDOW ##############################################################

prgwindat dw #7702,3,05,05,300,140,0,0,300,140,180,60,10000,10000,prgicnsml,prgwintit
prgwindat0 dw prgstadon,prgwinmen,prgwingrp,0,0:ds 136+14

prgwinmen  dw 6, 1+4,prgwinmentx1,prgwinmen1,0, 1+4,prgwinmentx2,prgwinmen2,0, 1+4,prgwinmentx3,prgwinmen3,0, 1+4,prgwinmentx4,prgwinmen4,0, 1+4,prgwinmentx5,prgwinmen5,0, 1+4,prgwinmentx6,prgwinmen6,0
prgwinmen1 dw 8, 1,prgwinmen1tx1,brwnew,0, 0,prgwinmen1tx2,0,0, 1,prgwinmen1tx3,brwfil,0, 1,prgwinmen1tx4,brwclo,0, 1+8,0,0,0, 0,prgwinmen1tx5,0,0, 1+8,0,0,0, 1,prgwinmen1tx6,prgend,0
prgwinmen2 dw 3, 0,prgwinmen2tx1,0,0, 1+8,0,0,0, 1,prgwinmen2tx2,cfgset,0
prgwinmen3 dw 3, 1,prgwinmen3tx1,barnav,0, 1,prgwinmen3tx2,barlnk,0, 1,prgwinmen3tx3,barsta,0
prgwinmen4 dw 6, 1,prgwinmen4tx1,navbak,0, 1,prgwinmen4tx2,navfor,0, 1,prgwinmen4tx3,navhom,0, 1+8,0,0,0, 1,prgwinmen4tx4,navrel,0, 0,prgwinmen4tx5,navstp,0
prgwinmen5 dw 3, 1,prgwinmen5tx1,favadd,0, 1,prgwinmen5tx2,favman,0, 1+8,0,0,0
           dw    1,00*96+favmem,256+00,0, 1,01*96+favmem,256+01,0, 1,02*96+favmem,256+02,0, 1,03*96+favmem,256+03,0, 1,04*96+favmem,256+04,0, 1,05*96+favmem,256+05,0, 1,06*96+favmem,256+06,0, 1,07*96+favmem,256+07,0
           dw    1,08*96+favmem,256+08,0, 1,09*96+favmem,256+09,0, 1,10*96+favmem,256+10,0, 1,11*96+favmem,256+11,0, 1,12*96+favmem,256+12,0, 1,13*96+favmem,256+13,0, 1,14*96+favmem,256+14,0, 1,15*96+favmem,256+15,0
prgwinmen6 dw 3, 1,prgwinmen6tx1,hlpopn,0, 1+8,0,0,0, 1,prgwinmen6tx2,prginf,0

prgwingrp db 21,0:dw prgwinobj,prgwinclc,0,256*0+8,0,0,0
prgwinobj
dw     00,255*256+00,2         ,0,0,0,0,0   ;00=Background
prgwinobj2
dw navbak,255*256+10,gfxbrwbak ,0,0,0,0,0   ;01=Browse Back
dw navfor,255*256+10,gfxbrwfor ,0,0,0,0,0   ;02=Browse Forward
dw navstp,255*256+10,gfxbrwstp ,0,0,0,0,0   ;03=Browse Stop
dw navrel,255*256+10,gfxbrwrel ,0,0,0,0,0   ;04=Browse Reload
dw navhom,255*256+10,gfxbrwhom ,0,0,0,0,0   ;05=Browse Home
dw     00,255*256+32,prgobjinp1,0,0,0,0,0   ;06=Address line
dw brwopn,255*256+10,gfxbrwlod ,0,0,0,0,0   ;07=Browse Load
dw brwfil,255*256+10,gfxbrwopn ,0,0,0,0,0   ;08=Browse Open
dw favman,255*256+10,gfxbrwfav ,0,0,0,0,0   ;09=Browse Favourites
prgwinobj0
dw     00,255*256+10,gfxbrwac0 ,0,0,0,0,0   ;10=Browse Activity
prgwinobj3
dw 256+0,255*256+16,0*14+lnkmem,0,0,0,0,0   ;11=Quicklink 0
dw 256+1,255*256+16,1*14+lnkmem,0,0,0,0,0   ;12=Quicklink 1
dw 256+2,255*256+16,2*14+lnkmem,0,0,0,0,0   ;13=Quicklink 2
dw 256+3,255*256+16,3*14+lnkmem,0,0,0,0,0   ;14=Quicklink 3
dw 256+4,255*256+16,4*14+lnkmem,0,0,0,0,0   ;15=Quicklink 4
dw 256+5,255*256+16,5*14+lnkmem,0,0,0,0,0   ;16=Quicklink 5
dw 256+6,255*256+16,6*14+lnkmem,0,0,0,0,0   ;17=Quicklink 6
dw 256+7,255*256+16,7*14+lnkmem,0,0,0,0,0   ;18=Quicklink 7

dw     00,255*256+2 ,4*1+3     ,0,0,0,0,0   ;19=Viewer Border
prgwinobj1
dw     00,255*256+25,prgsupobj ,0,0,0,0,0   ;20=Viewer Content

objnumadr equ 6
objnumviw equ 20
objnumact equ 10
objnumlnk equ 11

prgwinclc
dw   0,      0,  0,  0,10000,     0,10000,     0    ;Background
dw   1,      0,  1,  0,  12,      0,  12,      0    ;Browse Back
dw  14,      0,  1,  0,  12,      0,  12,      0    ;Browse Forward
dw  27,      0,  1,  0,  12,      0,  12,      0    ;Browse Stop
dw  40,      0,  1,  0,  12,      0,  12,      0    ;Browse Reload
dw  53,      0,  1,  0,  12,      0,  12,      0    ;Browse Home
dw  69,      0,  1,  0,-126,256*1+1,  12,      0    ;Address line
dw -57,256*1+1,  1,  0,  12,      0,  12,      0    ;Browse Start
dw -42,256*1+1,  1,  0,  12,      0,  12,      0    ;Browse Favourites
dw -29,256*1+1,  1,  0,  12,      0,  12,      0    ;Browse Favourites
dw -13,256*1+1,  1,  0,  12,      0,  12,      0    ;Browse Activity
prgwinclc0
dw 0*65+1,   0, 14,  0,  64,      0,  12,      0    ;Quicklink 0
dw 1*65+1,   0, 14,  0,  64,      0,  12,      0    ;Quicklink 1
dw 2*65+1,   0, 14,  0,  64,      0,  12,      0    ;Quicklink 2
dw 3*65+1,   0, 14,  0,  64,      0,  12,      0    ;Quicklink 3
dw 4*65+1,   0, 14,  0,  64,      0,  12,      0    ;Quicklink 4
dw 5*65+1,   0, 14,  0,  64,      0,  12,      0    ;Quicklink 5
dw 6*65+1,   0, 14,  0,  64,      0,  12,      0    ;Quicklink 6
dw 7*65+1,   0, 14,  0,  64,      0,  12,      0    ;Quicklink 7
prgwinclc1
dw   1,      0, 14,  0,  -2,256*1+1, -15,256*1+1    ;Viewer Border
dw   2,      0, 15,  0,  -4,256*1+1, -17,256*1+1    ;Viewer Content

prgobjinp1  dw doxpth,0,0,0,0,255,0

;Reader-Subfenster
prgsupobj   dw prgsupgrp,500,500,0,0,2
prgsupgrp   db 1,0:dw prgsupdat,0,0,00*256+00,0,0,00
prgsupdat   dw 00,255*256+0,0,00,00,1000,10000,0            ;00 Background
renviwobj   db 0        ;### last transfer-area byte!! ###

prgtrnend

relocate_table
relocate_end
