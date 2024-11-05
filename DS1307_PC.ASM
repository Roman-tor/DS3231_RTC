; odczyt/zapis RTC DS 1307 
TOS       equ 0FF66h ; stos uzytkownika
;M0        equ 10EEh ; zegar na CA88         ; Show clock CA 80 system procedure
M01:      equ 1221h ; j.w., bez "kresek" i jest powrot z tej procedury
wys_czas: equ 2D30h ; ca80 by phill
PRINT     equ 01D4h ; wysw. komunikatu na CA
EXPR      equ 0213h ; pobieranie liczb na stos, rej. C - ilo
CSTS      equ 0FFC3h ; pobranie znaku z klawiatury
port_A    equ 0E0h   ; (port A)
port_B    equ port_A+1 ; (port B)
port_C    equ port_A+2 ; (port C)
CTRL:     equ port_A+3 ; rejestr kontrolny /0E3h lub np. E7
S_SEK:    EQU 0FFECh ; setne sekundy w CA80
SEK:      EQU 0FFEDh
MIN:      EQU SEK+1
GODZ:     EQU SEK+2
DNI_TYG:  EQU 0FFF0h
DNIM:     EQU 0FFF1h
MIES:     EQU DNIM+1
LATA:     EQU DNIM+2
CYF0:     EQU 0FFF7h
CYF1:     EQU CYF0+1
CYF2:     EQU CYF0+2
CYF3:     EQU CYF0+3
CYF4:     EQU CYF0+4
CYF5:     EQU CYF0+5
CYF6:     EQU CYF0+6
CYF7:     EQU CYF0+7
; WE_WE:        equ 89h ; dla PC /PA-98h; PB-8Ah
; WE_WY:        equ 81h ; dla PC /PA-90h; PB-82h
; WY_WE:        equ 88h ; dla PC, PA i PB
; WY_WY:        equ 80h ; dla PC, PA i PB
; CTRL dla 8255   bit!        7  6  5  4     3     2  1    0   
;                       1  0  0  PA  PC.7-4  0  PB  PC.0-3   // WEJ - 1 WYJ 0
; ver. ..P1a - zmiana START i STOP, sterownie pojedynczymi bitami
;      ..P1b - SDA na PC.0, SCL na PC.5, (IY) wskazuje wybrany port podlaczenia DS1307/3231
;      ..P1c - SDA na PC.2, SCL na PC.5, j.w.  
;      ..P1c2 - obliczenia CL_L i CL_H   
; PC.0-ZU50 pin 18, ZU64-pin 14a
; PC.1          19           15a
; PC.2          20           16a
; PC.3          21           17a
;
; PC.4          22           13a
; PC.5          23           12a
; PC.6          24           11a
; PC.7          25           10a
; GND           50           23a, 23b
; +5V           48           32a, 32b 
; SDA powinno byc na bitach PC0-3, SCL na PC4-7    
wyb_P:   equ port_C ; tu port C /8255 - wybrany port
  ;=====
SDA_bit: equ 0 ; SDA port PC.x - program automatycznie dopasuje odczytany bit!!
SCL_bit: equ 4 ; SCL port PC.y - automatycznie steruje CLK!
DS_WR:   equ 0D0h ; zapis do DS1307/3231, A0 do EEprom I2C AT24Cx
DS_RD:   equ DS_WR+1 ; odczyt z DS
SDA_L:   equ SDA_bit+SDA_bit ; 0FEA0h  ; 4h/PC.2 - do sterowania pojedynczymi bitami !!
SDA_H:   equ SDA_L+1         ; sda_L+1 ; 5h
CL_L:    equ SCL_bit+SCL_bit ; sda_L+2 ; 0Ah ;PC.5
CL_H:    equ CL_L+1          ; sda_L+3 ; 0Bh
port_DS: equ 0FEA0h ; sda_L+4 ; PA/E0 lub PB/E1 lub PC/E2 
     ; dla DS1307/3231, SDA-PC.0-pin 14a, SCL-PC.4-pin 13a, piny - patrz wyzej ZU64
   ORG 0C000h; pocz. programu
  ld HL, SDA_SCL
  call print
  defb 80h
  call op_100ms
  defb 8
RTC_DS1307:  ; jesli mamy inne piny  zmiana w EB08h/sda_bit i EB12h/scl_bit  - TYLKO na porcie PC ukladu 8255
  LD SP,TOS
 ; ld IY, dni_tyg
  rst 10h ; D7
  defb 80h 
  call start_I2C
  ld A, DS_WR ; adres wyboru DS1307 /3231
  call zap_bajt ; zapis bajtu i kontrola ACK
  ld A, 0 ; odczyt od rejestru 0 -SEK
  call zap_bajt
  ld IX, 0FFEDh ; od sekund w CA80
  call start_I2C ; ponowny start magistrali I2C
  ld A, DS_RD ; D1
  call zap_bajt
   ; odczyt 7. bajtów:SEK, MIN, GODZ, DTYG, DZIEN, M-C, ROK
  ld b, 7    ; i zapis do CA80 od FFED - SEK
 ds_odcz:
  push bc
  call czyt_bajt ; odczyt bajtu i potwierdzenie ACK
  pop bc 
  djnz ds_odcz 
  call stop
    ; zamiana dnia_tyg na "odpowiedni" dla CA80, bo CA liczy do "tylu"
  ld HL, dni_tyg
  ld e, (HL)
  ld a, 8
  sub e
  ld (HL), a
  ;
ds_o1:
  ld hl, 0FFEDh ; sek
  call M01 ; wysw. czas na CA80
  call CSTS
  cp 0Ch ; klaw. C - ustaw czas
  jp z, SET_DS1307_C
  cp 0Dh  ; ustaw date
  jp z, SET_DS1307_D
  cp 17h ; klawisz F1/Z - gorny lewy 
  jp z, set_aktual
  cp 14h ; klaw. F4/W - dolny lewy
  jp z, show_aktual ; pokaz czas i date aktualizacji
  jr ds_o1
    
ZAP_BAJT: ; wpis bajtu do DS1307, w A dana do zapisu
       ;PC.5/SCL, PC.2/SDA, jesli PA, PC jako WEJSCIE
       ; WYJ: jesli B = 0 -  brak urzadzenia/brak ACK 
  ld E, A  ; w A bajt do zapisu
 zap1:
  LD D, 08H  ;ilosc bitów
 ZAP:
  LD A, E  ; odtworzenie danej do wpisu
  RLCA     ; przesuñ na lewo /na znacznik C/
  LD E, A  ; zapamiêtanie
  JR C, ZAPJEDYNKE  ; wyslij "1"
     ;wyslanie "0"
  LD A, 80H   ; PA PB i PC jako WYJ/ RES SDA i RES SCL
  OUT (CTRL), A  ; ustawia dane "0" na SDA
 ZEGAR:
  CALL CLK
  DEC D  ; czy 8. bit?
  JR NZ, ZAP
 ACK:
  LD A, 89H  ; PC.5 i PC.2 -> WEJ, poczatek 9. cyklu SCL "1"
  OUT (CTRL), A
  NOP
  push bc
  ld b, 0FEh ; ilosc prób sprawdz. ACK
 ACK_0:
  dec b
  jp z, no_A ; brak ACK
  IN A, (port_C) ; (C) ; odczyt portu PC
  BIT sda_bit, A ; testuj bit 0 (SDA=0 potwierdzenie, SDA=1 brak
  JR NZ, ACK_0 ; czekaj a¿ ACK
  pop bc
  LD A, 90H  ; PA - WEJ, PB I PC WYJ
  OUT (CTRL), A  ;PA.0 WEJ, PC.4 WYJ, koniec 9. cyklu SCL /SDA "1", SCL "0"
  RET

ZAPJEDYNKE:
  LD A, 81H  ;  PC.0-3 WEJ/SDA/, PC.5 WYJ/SCL/
  OUT (CTRL), A ; ustawia dane "1" na SDA
  JR ZEGAR

CLK:  ; port PC.5 - sterowanie bitami
  LD A, cl_h ; 0BH
  OUT (CTRL), A ; SET SCL
  DEC A  ; RES SCL
 CL1:
  OUT (CTRL), A
  RET

SCLH:  ; SCL /port PC.5/ na H
  LD A, CL_H ;0BH
  JR CL1

SCLL:
  LD A, CL_L ;0Ah  ; ustaw SCL /port PC.5/ na L
  JR CL1

start_I2C:
  ld A, 80h  ; jako wyjsciowe
  out (CTRL), A
  ld A, SDA_H
  out (CTRL), A
  ld A, CL_H
  out (CTRL), A
  ld A, SDA_L
  out (CTRL), A
  ld A, CL_L
  out (CTRL), A
  ret 

stop:
  ld A, 80h  ; jako wyjsciowe
  out (CTRL), A
  ld A, SDA_L
  out (CTRL), A
  ld A, CL_H
  out (CTRL), A
  ld A, SDA_H
  out (CTRL), A
  halt
  ret 

CZYT_BAJT: ; odczyt bajtu i zapis do RAM wg (IX)
 CZYT1:
  LD A, 81H ; PC.0-3 WEJ - SDA "1" ,PC.5 WYJ - SCL "0 "
  OUT (CTRL), A
  ld d, 8; D - il. bitów = 8, E - jako bufor do odbieranych bitów = 0
 CZYT:    ; moze byc tylko ld d, 8  bo rej E "idzie" od zera
  CALL SCLH ; ustaw SCL na H 
  IN A, (port_C);(C) ; odczyt portu PC
  push AF
  CALL SCLL ; ustaw SCL na L
  ld a, sda_bit ; na ktorym bicie port SDA
  inc a
  ld b, a ; ile przesuniec na prawo 
  pop AF ; odtworz odczytany bajt 
 cz1:
  rrca ; przesuñ na CY
  djnz cz1 ; bo BIT PC.2 /trzeci!
  rl e  ; przesun CY na bit 0 rej. E  
  DEC D
  JR NZ, CZYT  ; czy ostatni bit?
  LD (IX+0H), E  ; zapisanie w pamieci
  INC IX  ; ustaw RAM na zapis nastepnego bajtu
  ;
M_ACK: ; Master /CA80/ wystawia ACK /"0"/ na SDA
  LD A, 80H ; PA, PB, PC - WYJ, stan L
  OUT (CTRL), A ; ustaw SDA na L /czytaj nastepne bajty
  CALL CLK
  RET

no_A: ; gdy blad ACK
  ld hl, no_ACK
  call print
  defb 80h
  rst 8 ; CF - czekaj na klawisz
  jp RTC_DS1307

  defb 0DDh, 0E2h ; marker nazwy
  defm " RTC DS1307 PC 0_4", 255
tekst_pobT: defb 39h, 5Bh, 77h, 6Dh, 0FFh   ;"CZAS" set Time
tekst_pobD: defb 5Eh, 77h, 31h, 77h, 0FFh   ;"DATA"  set Date
no_ACK:     defb 54h, 0DCh,77h, 39h, 0F8h, 50h, 31h, 58h, 255  ; "no.ACK.rTC" dla ca80
SDA_SCL:    defb 5Eh, 0F7h, 3Fh, 0, 39h, 0B8h, 8, 66h, 255 ; dA0 CL_4 - DATA 0 CLK 4

 set_DS1307_C: ;  wcisnieto C, ustaw czas
  rst 10h  ; D7 40 czysc wyswietlacz
  defb 40h
  ld hl, tekst_pobT ; na CA80 "CZAS"
  call print ;
  defb 44h ; PWYS
  ld c, 3 ; 3. parametry: godz, min, sek
  call EXPR ; pobranie parametrów i odlozenie na stos
  defb 20h; PWYSW
    ;
 set_DS_3: ;wyswietl komunikat i ustaw czas  DS1307/DS3231
    ; wpis do DS1307
  call start_I2C
  ld a, DS_WR ; D0
  call zap_bajt
  ld a, 0 ; wpis od rejestru 0. w DS1307/DS3231 - sekundy
  call zap_bajt
  ld b, 3 ; 3. parametry
  ld IY, SEK
 set_DS_31:
  pop DE
  ld a, E
  ld (IY), A ; wpis do CA80
  inc IY
  call zap_bajt; wpis do DS1307/DS3231
  djnz set_DS_31
  call stop
  jp ds_o1

set_DS1307_D: ; wcisnieto D, ustaw date
  rst 10h  ; D7 40 czysc wyswietlacz
  defb 40h
  ld hl, tekst_pobD ; na CA80 "DATA"
  call print ;
  defb 44h ; PWYS
  ld c, 4 ; 4. parametry: rok, m-c, dz. m-ca, dzien tyg.
  call EXPR ; pobranie czterech parametrów i odlozenie na stos
  defb 20h; PWYSW
   ;
 set_DS_4: ;wyswietl komunikat, ustaw date  DS1307/DS3231
    ; teraz wpis do DS1307/DS3231
  call start_I2C
  ld a, DS_WR ; D0
  call zap_bajt
  ld a, 3 ; wpis od rejestru nr 3. DS1307/DS3231 - "day of week"
  call zap_bajt 
  ld b, 4
  ld IY, DNI_TYG
  jr set_DS_31 
;=========
 ; FFED-SEK, FFEE-MIN, FFEF-GODZ, FFF0-Dtyg, FFF1-DNIM, FFF2-MIES, FFF3-LATA
set_aktual: ; wcisnieto F1/Z /gorny lewy/ - wpisz do DS1307/DS3231 date i czas aktualizacji /z CA80/
  call start_I2C
  ld a, DS_WR ; D0
  call zap_bajt
  ld a, 8 ; wpis od rejestru 8. DS1307 - pamiec RAM w DS-a  /8 - 3F/ 56 bajtow
  call zap_bajt                         ; DS3231 inne rejestry!!
  ld hl, DNIM ; poczatek zapisanej daty w RAM CA80 -dzien. m-c, lata/rok
  ld b, 3
 set_akt1:
  ld a, (hl)
  inc hl
  call zap_bajt; wpis do DS1307/DS3231
  djnz set_akt1
  ld a, (godz)
  call zap_bajt
  ld a, (min)
  call zap_bajt
  call stop
  rst 10h ; D7 czysc wysw. CA
  defb 80h
  call op_100ms
  defb 5 ; czas na stabilizacje DS1307 po STOP
  jp wys_czas-9 ; ujeto call INI_LCD ; skok do wysw. czasu z CA88

show_aktual: ; wcisnieto F4 - pokaz czas i date aktualizacji zegara DS1307
 sh: equ 0FEF0h ; tu zapisz odczytane bajty
  call start_I2C
  ld A, DS_WR ; adres wyboru DS1307/DS3231
  call zap_bajt ; zapis bajtu i kontrola ACK
  ld A, 8 ; odczyt od rejestru 8 - poczatek RAM w DS1307
  call zap_bajt
  ld IX, sh ; poczatek odczytanej daty i czasu aktualizacji /zapis w CA80
  call start_I2C ; ponowny start magistrali I2C
  ld A, DS_RD
  call zap_bajt
   ; odczyt 5. bajtów: dzien, m-c, rok i godz, min
  ld b, 5 
 sh_odcz:
  push bc
  call czyt_bajt ; dzien, m-c, rok, godz, min i zapisz w CA, od <sh> 
  pop bc  ;   call M_ACK ; potwierdz odebrany bajt
  djnz sh_odcz
  call stop
  ld HL, sh
  ld a, (HL)
  rst 18h ; DF wysw. A
  defb 26h
  inc HL
  ld a, (HL)
  rst 18h
  defb 23h
  inc HL
  ld a, (HL)
  rst 18h
  defb 20h
  call op_100ms
  defb 10 ; opoz. ok. 1 sek
  inc HL
  rst 10h ; D7 czysc wysw. CA
  defb 80h
  ld a, (HL) ; godz
  rst 18h
  defb 24h
  inc HL
  ld a, (HL) ; min
  rst 18h
  defb 21h
  rst 8 ; CF czekaj na wcisn. klaw.
  jp RTC_DS1307
 ;  opóznienie
op_100ms:; opózn. x 0,1s+ podaj param. /cd xx yy zz/
  EX (sp), hl    ; zz - wielkosc opóznienia
  ld a, (hl)
  inc hl
  ex (sp), hl
  push bc
  push HL
  ld b, a  
 op1:
  ld HL, 3C18h
 op2:
  dec HL
  ld a, L
  or H
  jr nz, op2 
  djnz op1    
  pop hl
  pop bc
  ret
