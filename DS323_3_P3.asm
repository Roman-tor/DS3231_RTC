; odczyt/zapis RTC DS3231  PODLACZONY POD P3 !!! /SDA PC.0, SCL-PC.4 w zlaczu uzytkownika
 ; na CA nowy by phill , DS w P3          SDA - pin  18  SCL - pin 22   ZU50
 ; odczyt z DS 3231 tylko po uruchomieniu programu, potem wyswietlanie czasu i daty /na LCD/ z RAM CA80                 
PRINT:       EQU 01D4H ; wyswietla tekst wg (HL), + PWysw np. CD D4 01 44
PARAM:       EQU 01F4H ; pobiera 4. znaki do HL + PWysw
;CO:          EQU 01E0h
COM:         EQU 01ABh ; wysw. znaku z rej. C, podaæ jeszcze PWYS
;TI:          EQU 7     ; Pobranie znaku z jednoczesnym jego wyswietleniem w/g PWYS. [ tzw.ECHO ]
EXPR:        EQU 0213h ; pob. liczb/4./ na stos
;EXPRW:       EQU 19B4h ; j.w. ale tylko cyfry dziesietne
CSTS:        EQU 0FFC3h; czy klaw. wcisniety, WYJ - kod w rej. A
;CZASK:       EQU 1225h ; wysw. czasu /MIN i GODZ/ bez zera poczatkowego /godz./
CZASR:       EQU 1221h  ; wysw. czasu (SEK,MIN, GODZ/  bez zera pocz./z CA88/
WYSKOM:      EQU 1217h ; procedura wysw. dnia tyg. z CA88
SETSEK:      EQU 0FFECh ;  setne sek <0-99>
SEK:         EQU 0FFEDh; w CA80
MIN:         EQU 0FFEEh; j.w.
GODZ:        EQU 0FFEFh; j.w.
TABD:        EQU 123Fh ; tabl. dni, symbole literowe, np. PN, WT
dnityg:      EQU 0FFF0h; dzien tyg. ca80
DNIM:        EQU 0FFF1h; dzien miesiaca ca80
MIES:        EQU 0FFF2h
LATA:        EQU 0FFF3h; lata/rok ca80
CYF0:        EQU 0FFF7h ;wysw. cyfry na pozycji 0 wyswietlacza CA80
CYF1:        EQU 0FFF8h ;wysw. cyfry na pozycji 1
CYF2:        EQU 0FFF9h
CYF3:        EQU 0FFFAh
CYF4:        EQU 0FFFBh
CYF5:        EQU 0FFFCh
CYF6:        EQU 0FFFDh
CYF7:        EQU 0FFFEh
KO3:         EQU 0A23h ; adres komunikatu "ERROR"
;LADR:        EQU 20h ;wyswietlenie HL w postaci 4. liczb
TABM:        EQU 32Dh ; tabela ograniczen miesiecy CA80
;TABC:        EQU 328h ; tablica ograniczen czasowych CA80
STOS:        EQU 0FF66h ; pocz. stosu systemowego CA80
 ; procedury I2C z mojej wersji CA80  - DS3231 podlaczony pod: SDA PC.0 SCL PC.4
WE_WE:      EQU 8Bh  ; SDA WEJ/H, SCL-WEJ/H
WY_WE:      EQU 8Ah  ; SDA WYJ/L  SCL-WEJ/H -podczas <spr_ACK>
WE_WY:      EQU 83h  ; SDA WEJ/J  SCL-WYJ L
WY_WY:      EQU 80h  ; SDA i SCL na L
port_C:     EQU 0E2h ; tu podlaczony DS - patrz wyzej
CTRL:       EQU 0E3h
OUT_SDA:    EQU port_C
IN_SDA:     EQU port_C
SCL_bit:    equ 4h  ; SCL port PC.4 - moja wersja - SCL na PC4 - dla P1, P2 i P3, dla DS3231 na PC.5, SDA na PC.2
SDA_bit:    equ 0h  ; SDA port PA0 lub PB0 lub PC.0, w zaleznosci j.w.czy P1 P2 lub P3


;P_P3:        EQU 1E2Eh ; obsluga portu P3 - PC.0 - SDA. PC.4 - SCL
rozdziel:    EQU 1C15h ; dzieli rej. A na dwie liczby/znaki i umieszcza w HL
BLAD:        EQU 1C6Ah  ; wyswietl ERROR na ca80 i LCD przez dwie sekundy

wyb_port:    EQU 0FD99h ; przechowalnia wybranego portu /E3 lub E7/
L1:          EQU 80h  ; pocz. 1. linii LCD
L2:          EQU 0C0h ; pocz. 2. linii
L3:          EQU 94h  ; pocz. 3 linii
L4:          EQU 0D4h ; pocz. 4. linii
  ; procedury obslugi DS-3231
buf_T:       EQU 0FD11h ; tu przechow. odczytana temperatura
temp_ca80:   EQU 0FD35h ; tu przeliczona temp. po odczycie z DS-a
SEK_P:       EQU 0FD22h ;sekundy do potrzeb kontroli uplywu czasu do wysw. na LCD
MIN_P:       EQU SEK_P+1 ; minuty do potrzeb kontroli uplywu czasu do wysw. na LCD
GODZ_P:      EQU SEK_P+2
STULECIE:    EQU 0FD20h ; do wyswietlania calego rok na LCD np. 2021
LATA_P:      EQU STULECIE+1
DZIEN_ROKU:  EQU 0FE15h ; ktory dzien roku
tydz_roku:   EQU 0FE19h; ktory tydzien roku
USER_PORT0:  EQU 0E3h ; slowo kontr. portu u¿ytkownika
DS_PORT:     EQU USER_PORT0
POZ_SEK:     EQU 9Bh ; pozycja na LCD jednostek sekund, przesuw na lewo!!
POZ_DNI:     EQU 0D4h ; pozycja wysw. dni na LCD
POZ_T:       EQU POZ_SEK+3 ; pozycja wysw. temp. na LCD
DATA_M:      EQU 0FE10h ; pamiec pobranej daty: dzien, m-c, rok, stulecie, dzien tyg
   
   ; ..3_A3 - wersja bez LCD
   ORG 0E000h
DS_ODCZ:       EQU 0D1h ; "adres" odczytu z DS3231 - D1
DS_ZAP:        EQU 0D0h ;"adres" zapisu do DS3231
adr_odcz_ds:   EQU 0FD1Fh ; adres przechowywania bajtu /D1h/ na odczyt DS3231

czas_dane:
  ld a, 0C3h ; rozkaz C3 JP
  ld (0FF20h), a ; od FF20 C3 xx (powrót po bledzie ACK)
  ld hl, brak_DS ; tu powrót po bledzie ACK
  ld (0FF21h), hl
 czas_dane1: 
  ld a, DS_ODCZ ; "adres" DS, tu 0D1h, zapis to 0D0h
  ld (adr_odcz_ds), a
  ld a, 20h  ; aktualny wiek
  ld (STULECIE), a

 odczyt_czasu:
  ld sp, STOS
 odcz1:
  ld ix, SEK ; na potrzeby wpisu danych  z odczytu DS3231
  call START_I2C ; start magistrali I2C
  call czyt_DS3231 ; odczyt czasu, daty, temperatury...
  ld a, (LATA)
  ld (LATA_P), a ; do porownania, czy minelo stulecie
  call set_dni_tyg ; przelicz dni tygodnia na potrzeby CA88, liczy do "tylu"
 odcz2:
  ld h, 0AAh ; to wartosc na start programu, potem sa wart. rzeczywiste
  ld L, 0AAh ; unikac AA AA, gdyz podczas "SZUKANIA .." Aa AA jest znacznikiem pocz/konca programu
  ld (MIN_P), hl ; do porównania min i godz, jesli nastapila zmiana
  ld a, (SEK)
  ld (SEK_P), a
  call wysw_temp_DS3231
  call obl_dn_roku ; oblicz dzien i tydzien roku, wyswietl
 wysw_czas:  ; na CA80 i na LCD
  ld c, 40h  ; znak kreski
  call COM  ; wyswietl kreske
  defb 12h
  call COM
  defb 15h
 wysw_czas1:
  call CSTS; sprawdz klawisze
  jr c,  xt1
  ld hl, SEK ; wysw. czas
  call czasr ;  wysw. czasu bez zera pocz./z CA88/
  jr wysw_czas
 xt1:
  cp 4 ; klawisze 0 - 3
  jr nc, xt2
  ld hl, DNIM; dni miesiaca, wysw. date
  call czasr ; wysw. date
  jr wysw_czas

 xt2:
  cp 0Bh ; klawisze 4 - A - wysw. dzien tygodnia / CA80/
  jr nc, xt3 ; jesli klawisz >= od C
 wysw_dz_tyg:
  ld hl, TABD_1; tablica dni tygodnia /dla CA80 na DS3231/, po dwie litery, np. ND, SO
  ld a, (dnityg) ; dzien tygodnia  w RAM CA80
  dec a
  ld e, a
  ld d, 0
  add hl, de
  add hl, de
  call WYSKOM ; wysw. dwie litery na poz. 0 i 1 CA80, skrot dnia tygodnia
  jr wysw_czas

xt3: ; wcisnieto klawisz wiekszy niz B
  cp 0Ch
  jr z, set_DS3231_C ; jesli klawisz C, ustaw zegar
  cp 0Dh ;
  jr z, set_DS3231_D ;  jesli klawisz D - ustaw date
  cp 0Eh ; jesli E - wysw. temperature
  call z, WYSW_TEMP_DS3231
  cp 0Fh  ; jesli F - wysw. dzien i tydzien roku na CA80
  call z, dzien_CA
  jr wysw_czas

set_DS3231_C: ;  wcisnieto C, ustaw czas
   rst 10h  ; D7 40 czysc wyswietlacz
   defb 40h
   ld hl, tekst_pobT ; na CA80 "CZAS"
   call print ;
   defb 44h ; PWYS
  ld c, 3 ; 3. parametry: godz, min, sek
  call EXPR ; pobranie parametrów i odlozenie na stos
  defb 20h; PWYSW
   ; tu mozna dodac XOR A, LD (S_SEK), A ; start setnych sek tez od 0 
  ld hl, SEK ; adres sekund w CA80
  ld e, 3 ; do zapisu 3. parametry

 set_DS_3: ;wyswietl komunikat i ustaw czas  DS3231
  pop bc ; zdejmowanie ze stosu:  godz, min, sek
  ld (hl), c ; wpis do RAM ca80,
  inc hl
  dec e
  jr nz, set_DS_3
  ld a, DS_PORT ; port uzytkownika - przylacze DS3231
  ld (wyb_port), a ; przechow. adresu portu, potrzebne do procedury START_I2C
  call START_I2C
  ld a, DS_ZAP ; D0
  call zap_bajt
  ld a, 0 ; wpis od rejestru 0. w DS3231 - sekundy
  call zap_bajt
  ld hl, SEK ; poczatek zapisanego czasu w RAM CA80
  ld b, 3 ; 3. parametry
 set_DS_31:
  ld a, (hl)
  inc hl
  call zap_bajt; wpis do DS3231
  djnz set_DS_31
  call stop
  jp ODCZYT_CZASU

set_DS3231_D: ; wcisnieto D, ustaw date
  rst 10h  ; D7 40 czysc wyswietlacz
  defb 40h
  ld hl, tekst_pobD ; na CA80 "DATA"
  call print ;
  defb 44h ; PWYS
  ld c, 4 ; 4. parametry: rok, m-c, dz. m-ca, dzien tyg.
  call EXPR ; pobranie parametrów i odlozenie na stos
  defb 20h; PWYSW
  ld hl, dnityg ;
  ld e, 4 ; ile parametrów zapisac w CA80

 set_DS_4: ;wyswietl komunikat, ustaw date  DS3231
  pop bc  ;zdejmij ze stosu: dzien tyg, rok, m-c, dzien m-ca
  ld (hl), c ; i wpisuj od dnityg w RAM ca80
  inc hl
  dec e
  jr nz, set_DS_4
  ld a, DS_PORT ; port uzytkownika dodatkowy- przylacze DS3231
  ld (wyb_port), a ; przechow. adresu portu, potrzebne do procedury START_I2C
  call START_I2C
  ld a, DS_ZAP ; D0
  call zap_bajt
  ld a, 3 ; wpis od rejestru 3. DS3231 - roku
  call zap_bajt
  ld hl, dnityg ; poczatek zapisanej daty w RAM CA80
  ld b, 4 ; 4. parametry
  jr  set_DS_31

     ;  ORG 0D0C0h
czyt_DS3231:
  ld a, DS_ZAP ;"adres" ukladu DS3231 do zapisu /D0/
  call ZAP_BAJT; wpis bajtu i kontrola ACK
  ld a, 0 ; ustaw wskaznik rejestru na 0. - 1-szy rejestr DS3231 - sekundy
  call ZAP_BAJT
  call START_I2C ; restart
  ld a, DS_ODCZ ; D1
  call ZAP_BAJT; wpis bajtu i kontrola ACK
  ; odczyt 7. bajtów      1    2    3     4       5      6    7         8
  ld b,7 ; 12. bajtów to: sek, min, godz, dz.tyg, dzien, m-c, rok, ALARM1-sek, AL1- min,
          ;9h-> AL1-godz, Ah->AL1-dz.tyg/MSB i dz.m-ca/LSB, Bh->AL2-min, Ch->AL2-godz,
          ;Dh->AL2-dz.tyg/MSB i dz.m-ca/LSB, Eh->Control, Fh-Control/Status, 10h->
          ; AgingOFFSET, bajt 11h/MSB/ i 12h/LSB/ to temperatura
 czyt_1:
  call czytaj_bajt
  call send_ACK ; master -> ca80 potwierdza odebrany bajt
  djnz czyt_1
  call czytaj_bajt
  call stop
  call spr_cz_d ; sprawdz czas i date
  ret

        ; w DS3231 konwersja temperatury odbywa sie co 64 sek./nota katalogowa/
        ; jesli chcemy wywolac konwersje, ustaw bit 5. w Control Register /0Eh/
        ; nie zmianiamy pozostalych bitów!!
wysw_temp_DS3231: ; wysw. temp. na LCD jesli uplynal INTERWAL_TEMP,
  ld hl, CYF3
  set 7, (hl); znak, ze konwersja, dobicie kropki, tylko dla "optyki"
  call op_100ms
  defb 7
 konw: ; wymuszenie konwersji temperatury
  call START_I2C
  ld a, DS_ODCZ ;"adres" ukladu DS3231 do odczytu
  call ZAP_BAJT; wpis bajtu i kontrola ACK
  ld a, 0Eh ; Control Register
  call czytaj_bajt ; w rej. A aktualny stan rejestru kontrolnego
  ld b, a ; zapamietanie stanu rejestru
  bit 5, A ; sprawdz 5. bit rej.  /CB 6F
  jr nz, konw
    ;
  call START_I2C
  ld a, DS_ZAP ;"adres" ukladu DS3231 do zapisu
  call zap_bajt
  ld a, 0Eh
  call zap_bajt
  ld e, b ; odtworzenie oryginalnej wartosci rej. kontrolnego DS-a /E/
  set 5, E ; ustaw 5. bit - wymuszenie konwersji
  call zap_bajt
  call op_100ms ; czas na konwersje temp., ok. 120 ms
  defb 2 ; dla pewnosci wartosc wieksza
  ;ld e, b ; odtworzenie wartosci rej. kontrolnego /E/ DS-a
  ;res 5, E ; na przyszlosc!
  call START_I2C
  ld a, DS_ZAP ; ustaw DS na zapis - bedzie odczyt od rej. 11h /temperat/
  call zap_bajt
  ld a, 11h ; ustaw wskaznik rejestru na 11h - DS3231
  call ZAP_BAJT
  call START_I2C ; restart
  ld a, DS_ODCZ ; D1
  call ZAP_BAJT; wpis bajtu i kontrola ACK
           ; odczyt 2. bajtów 11h i 12 h /temperatura/
  ld ix, BUF_T
  call czytaj_bajt  ; mlodszy bajt temp
  ld h, a
  call send_ACK ; master -> ca80 potwierdza odebrany bajt
  call czytaj_bajt ; starszy bajt temp.
  ld ix, buf_t ; powrót do poprzedniej wartosci w RAM przy wpisie temperat.
  call stop

 wys_temp_1:
  ld a, (BUF_T); wskazuje stopnie calk. temp /FD11h/
  call zam_16_10_1bajt ; zamien bajt hex  na liczbe dziesietna
  ld a, L ; w L do 99 st. C, w H setki st. C, jesli wyszlo z obliczen
  push hl ; zapamietanie pelnych stopni

 obl_t2: ; wylicz dziesiate st. C
   ld a, (BUF_T+1) ; dziesiate st. Celsjusza
   rlca
   rlca
   ld hl, tab_dz ; tabela musi lezec w obrebie strony
   add a, l
   ld l, a
   ld a, (hl)
   pop hl; odtworzenie pelnych stopni
   ld h, l
   ld l, a ; H - pelne stopnie /0 do 99/, L - dziesiate i setne
   ld (temp_ca80), hl ; zapamietanie, dla CA80
     ;wysw_t_CA80: ; wysw. temp. na CA80, wcisnieto klawisz E
   rst 10h ; D7 26
   defb 26h ; czysc CYF7 i CYF8
   ld hl, (temp_ca80) ; odtworzenie temp.
   ld a, H ; 0-99 st. C
   ld b, L
   rst 18h ; DF wysw. rej. A
   defb 24h
   ld hl, CYF4 ; cyfra na poz. 4 wysw. CA80
   set 7, (hl) ; dobicie kropki
   ld a, b ; dziesiate st. C
   rst 18h ; DF
   defb 22h
    ; wysw. "*C" na CA80
   ld c, 63h ; znak stopnia
   call com
   defb 11h
   ld c, 39h  ; znak "C" Celsjusza
   call com
   defb 10h
   call op_100ms
   defb 10h ; parametr opoznienia
   ret

zam_16_10_1bajt: ; zamiana liczby 1. bajtowej na dziesietna
   push AF              ; WYJ: liczba zamieniona w HL
  ld hl, 0             ; H - setki, L -0-99
   and 0F0h ; zeruj mlodsze bity
   rrca
   rrca
   rrca
   rrca
   ld d, a ; zapamietanie
   pop af
   and 0Fh
   cp 0Ah
   jr c, obl_t1
   ld b, 0FAh ; zamiana liczby >= 0A na dziesietna
   sub b
 obl_t1:
   ld L, a ; zapamietaj
   ld a, d ; ile razy dodac 16 st. Celsjusza
   cp 0 ;
   jr z, obl_t2 ;temp. < od 16 st. C
   ld b, d
 obl_t4:
   ld a, 16h ; ile razy dodac 16 st.
 obl_temp:
   add a, L
   daa
   ld L, a ; zapamietania
   jr nc, t_5
   inc H ; setki
 t_5:
   djnz obl_t4
   ret


BRAK_DS:   ; gdy brak DS3231
  jp wysw_czas

obl_dn_roku: ; oblicz i pokaz na LCD i CA80 aktualny dzien roku
   ;obliczanie dnia roku, do aktualnego dnia dodaj dni z poprzednich m-cy z tabeli <t_d_m>
  ld hl, 0
  ld (dzien_roku), hl ; zerowanie bufora przechowujacego dzien roku
  call spr_mies ;m-c <1-12>, powrot-miesiac zmniejszony o 1
  cp 0 ; czy byl styczen?
  jr z, obl_2 ; wyswietl dzien roku dla stycznia
  cp 10h ; pazdziernik?
  jr c, obl_2
  jr z, pazdz
  cp 11h
  jr z, listo
   ; grudzien
  ld a, 0Ch
  jr obl_2
 listo:
  ld a, 0Bh
  jr obl_2
 pazdz:
  ld a, 0Ah
 obl_2:
  ld e, a ; miesiac
  ld d, 0
  ld hl, t_d_m ; tabela il. dni - 2. bajtowa, narastajaco dziesietnie
  add hl, de
  add hl, de ; adres tabeli dni, ktore trzeba dodac do dnia biezacego
  ld e, (hl); jednosci i dziesiatki dni
  inc hl
  ld d, (hl) ;setki dni
  ld h, d ; zapamietanie
  ld a, (dnim)
  adc a, e ; dodaj aktualny dzien do il. dni z tabelki
  daa ; poprawka dziesietna
  ld l, a ; zapamietanie, teraz H-setki dni, L=dziesiatki i jednosci dni roku
  jr nc, obl_1
  inc h ; liczba dni >= 100 /dziesietnie/
 obl_1:; sprawdz czy data > 28.02 i czy rok przestepny
  ld (dzien_roku), hl ; zapamietanie
  call spr_r_p ; sprawdz, czy rok przestepny, jesli tak to zwieksz dzien_roku o 1.
  call obl_tydz_roku ; oblicz tydzien roku
  ret ; powrot z podprogramu

spr_mies: ;sprawdz, czy m-c prawidlowy <1-12>
  ld a, (mies) ; miesiac
  cp 13h
  jp nc, blad_daty ; bledny miesiac >12
  or a
  dec a; jesli bedzie pazdzier /10/ musimy zrobic DAA !!!
  daa                    ; inaczej bedzie blad, wynik = 0F
  cp 0FFh
  jp z, blad_daty
  ret

spr_r_p: ;rej. A-rok sprawdz, czy rok przestepny
            ; dodawaj 4, az >= 100, jesli  = 0, przestepny
  ld a, (LATA)
  ld b, 4 ; rok przestepny co 4. lata
 spr_r1:  ;
  add a, b    ; WYJ: jesli C i Z, rok przestepny
  daa
  jr nc, spr_r1
  ret nz
     ; rok przestepny
  ld a, (mies)
  cp 1
  ret z
  cp 2
  jr z, spr_r3 ; jaki dzien
  jr spr_r4
 spr_r3:
  ld a, (dnim); dzien miesiaca
  cp 30h
  ret c ; dzien <= 28
 spr_r4:
   ; rok przestepny -> zwieksz dzien o 1
  ld hl, (dzien_roku)
  ld a, l
  inc a
  daa
  ld l, a
  jr nc, spr_r2
  inc h
 spr_r2:
  ld (dzien_roku), hl ; aktualny dzien roku
  ret

dzien_CA: ; wysw. na CA80 dzien i tydzien roku
   rst 10h
   defb 23h ; czysc 2 cyfry
   ld a, (tydz_roku)
   rst 18h; DF wysw. rej A
   defb 20h ; PWYSW
   cp 0Ah
   jr nc, dzien_CA1
   rst 10h
   defb 11h 
 dzien_CA1:
   ld hl, (dzien_roku)
   ld a, h
   cp 0
   jr z, wysw_d_r2
 wysw_d_r3: ;wysw. dzien roku 3. cyfrowy
    rst 20h ; E7 wysw. rej. HL
    defb 43h
    jr op_dr

wysw_d_r2: ; wysw. dzien roku 2. cyfrowy
   rst 20h ; E7 wysw. rej. HL
   defb 34h
   ld a, L
   cp 0Ah
   jr nc, op_dr
        ; dzien 1. cyfrowy, skasuj CYF5
   rst 10h
   defb 15h
        ; teraz skasowane beda 2. pierwsze znak i- bo wysw. tekstu "dr."
 op_dr: ;opoznienie podczas wyswietlania dnia i tygodnia roku
   ld hl, dn_r ; "dr." dzien roku na CA80
   call print   ; na koncu bo wyzej jest kasowana 4. cyfra
   defb 26h
   call op_100ms ; opoznienie ok. 1 sek.
   defb 10h
   ret

blad_daty: ; jesli data wpisana blednie
   call BLAD ; wyswietl na CA80 i LCD "Error"
   ld hl, err_d ; ERR"
   call print
   defb 80h
   call op_100ms
   defb 10h ; parametr opoznienia
   jp SET_DS3231_D ; nowa data

t_d_m: ; tablica dni miesiecy narastajaco, dwubajtowe
      defb 0,0, 31h,0, 59h,0, 90h,0, 20h,1, 51h,1
      ;     1     2      3      4      5      6
      defb 81h,1, 12h,2, 43h,2, 73h,2, 04h,3, 34h,3,;
      ;      7      8      9      10     11    12
             ; jesli np 18.IV to 18 dodajemy do 90 /marzec/
      ; teksty na CA80
dn_r: defb 5Eh, 0D0h, 0FFh ; "dr." dzien roku na CA80
err_d: defb 79H,50H,50H, 5Eh, 77h,31h,66h, 0FFH ; Errdaty
tekst_pobT: defb 39h, 5Bh, 77h, 6Dh, 0FFh   ;"CZAS" set Time
tekst_pobD: defb 5Eh, 77h, 31h, 77h, 0FFh   ;"DATA"  set Date
no_ack:     defb 54h,77h, 39h, 78h, 0FFh ; "no ACK" dla ca80

TABD_1:  ; tablica dni tyg. dla CA80, na potrzeby DS3231
           defm 54h, 79h ; ND
           defm 6Dh, 5Ch ; SO
           defm 73h, 31h ; PT
           defm 39h, 1Ch ; CZ
           defm 6Dh, 50h ; SR
           defm 1Ch, 31h ; WT
           defm 73h, 54h ; PN
           ; do CA 80
tab_dz: ; tablica dziesietnych stopni Celsjusza
          defb 0
          defb 25h
          defb 50h
          defb 75h
          defb 75h

obl_tydz_roku: ; oblicza, ktory tydzien roku wg daty w CA80
   call kal_roku ; jaki dzien tygodnia to 1.01 zadanego roku
   ld (DATA_M+4), a ; zapamietanie w buforze daty /4. bajt
   ld c, a ; PN-1, WT-2 ... SB 6, ND-7
   cp 5 ; do czwartku wlacznie to 1. tydzien, PT, Sb lub Nd to ostatni tydz. starego roku
   jr c, otr1 ;; jesli Carry, to 1. styczen/PN, WT, SR lub CZ/ - to 1. tydzien roku
   ld b, 0
   jr otr2
 otr1:
   ld b, 1 ;
   ld a, (DATA_M+4) ; jaki dzien tygodnia
   cp 1
   jr nz, otr2
   dec b
 otr2:
   ld de, 0 ; start od zera
 obl_tr0:
   or a ; potrzebne przy odejmowaniu HL i DE
   ld hl, (DZIEN_ROKU) ; aktualny dzien i m-c /zadany/
   sbc hl, de
   jr z, obl_tr ; obliczono tydzien roku
      ; szukaj zgodnosci dalej, zwieksz tydzien o 1
   ld a, c ; dzien tgodnia
   cp 1  ; czy poniedzialek?
   jr nz, obl_tr2
        ; poniedzialek, zwieksz tydz_roku
   ld a, b ; tydzien
   inc a
   daa
   ld b, a
 obl_tr2:
   ld a, e ; zwiekszanie DE o jeden
   add a, 1
   daa
   ld e, a
   ld a, d
   adc a, 0
   daa
   ld d, a ; zwiekszono DE 0 jeden
      ; zwieksz dzien tyg., jesli PN to i <TYDZ_ROKU> o jeden
   inc c ; dzien tygodnia
   ld a, c
   cp 8
   jr c, obl_tr1 ; jeszcze nie PN
   ld c, 1 ; poniedzialek
 obl_tr1:
   jr obl_tr0
 obl_tr: ; tydzien znaleziony
   ld a, b
   ld (tydz_roku),a
   push af
   call d_tyg_ca ; wpisz dzien tygodnia do CA80 /FFF0h/
   pop af
   cp 0  ;
   call z, kor_tr ; zrob korekcje <TYDZ_ROKU>
   ret   ; POWROT z podprogramu <obl_tydz_roku>

kal_roku: ; z C800 MIK 11 Emulator, str. 157
   ;#d[ROK][.][MIESIAC][.][DZIEN MIES][=] w oryginale
 UD:  ld hl, 0101h ; 01. stycznia
     ld (DATA_M), hl
     ld a, (LATA) ; przechowywany rok CA80 /FFF3
     ld (DATA_M+2), a
     ld a, 20h ; aktualny XXI wiek
     ld (DATA_M+3), a
 UD1: CALL     SROK     ;Szukanie roku
     LD     DE,(DATA_M) ;E-dzien, D-miesiac
     CALL     SDZIEN     ;Szukanie dnia
     JR     Z,U4A     ;Dzien znaleziono, C - dzien tygodnia w dniu 1 stycznia
   ;Error - data falszywa                       danego roku
     LD     HL,KO3     ;Error
     CALL     PRINT
     DEFB     50H
   ;Opoznienie 0.7 sek
     call op_100ms ;
     defb 7;
     JR     UD
 ;Wyswietlenie znalezionego dnia tygodnia
 ;WE: C - dzien tygodnia (1-Pn,2-Wt,3-Sr....)
 U4A:   ld a, c ; dzien tygodnia
   ld (DATA_M+4), a
   ret

  ;SROK - szukanie roku
  ;0000.01.01 - PIATEK ;dzien odniesienia,  ;0000 - rok przestepny
  ;# w rzeczywistosci powinno byc 0001.01.01 SOBOTA, nie bylo roku 0000, uwaga SK#
  ;365 dni - rok normalny, 366 dni - rok przestepny co 4 lata
  ;52 (tygodnie) * 7 = 364 dni
  ;WE: DATA+2 - etykieta wskazujaca zadany rok;
  ;    HL = zadany rok
  ;WY: C - dzien tygodnia w dniu 1 stycznia
  ;    B = 4 - rok przestepny
SROK:     LD     BC,405H     ;B=4 C=5 - piatek
     LD     DE,0000H ;Rok odniesienia (moja uwaga - powinno byc 0001 bo nie bylo roku 0000 n.e.) 
     OR     A     ;CY=0
     SBC     HL,DE
     RET     Z     ;Zad.rok=0000
  ;ROK ZADANY > 0000
     INC     C     ;0000 - przestepny
 P0001:     LD     A,E
     ADD     A,1
     DAA
     LD     E,A
     LD     A,D
     ADC     A,0     ;Dodanie CY
     DAA
     LD     D,A
     LD     HL,(DATA_M+2) ;Rok zadany
     INC     C     ;Rok normalny
     LD     A,C
     CP     8
     JR     C,P2A
     LD     C,1     ;Poniedzialek
 P2A:     DEC     B     ;Czy rok przestepny ?
     JR     NZ,P2C     ;Nie
     LD     B,4     ;Rok przestepny
     OR     A     ;CY=0
     SBC     HL,DE
     RET     Z     ;Rok przestepny
     INC     C
     LD     A,C     ;Dzien tygodnia
     CP     8
     JR     C,P2B
     LD     C,1     ;Poniedzialek
 P2B:     JR     P0001     ;Nastepny rok
 P2C:     OR     A     ;CY=0
     SBC     HL,DE
     JR     NZ,P0001 ;Nastepny rok
  ;Rok znaleziony
     RET
  ;SDZIEN - szukanie dnia tygodnia w roku
  ;WE: B=4 - rok przestepny
  ;    C   - dzien tygodnia w dniu 1 stycznia
  ;    E   - dzien zadany
  ;    D   - miesiac zadany
  ;WY: C   - znaleziony dzien tygodnia
  ;    Z=0 - Error (rej.C - nieokreslony)
  ;ZMIENIA: HL,C,AF
SDZIEN:     LD     A,B
     CP     4     ;Czy rok przestepny ?
     JR     NZ,NPRZE
  ;Rok przestepny
     LD     A,D     ;Miesiac zadany
     CP     3
     CALL     NC,INCC ;Miesiac 3-12
     CP     2     ;Czy luty ?
     JR     NZ,NPRZE ;Nie luty
     LD     A,E     ;Zadany dzien
     CP     29H      ;Czy 29 luty
     JR     NZ,NPRZE
 ;Zadany dzien 29 luty
     LD     B,3     ;Dodanie 3 dni
 LICZD:     CALL     INCC
     DJNZ     LICZD
     RET          ;Z=1 dobrze
 NPRZE:     LD     HL,TABM
     LD     B,1     ;Licznik miesiecy
 NASA:     LD     A,1     ;Licznik dni
 DNAST:     CP     E
     JR     NZ,DNA
  ;Dzien zgodny
     PUSH     AF     ;Ochrona dnia
     LD     A,B     ;Miesiac biezacy
     CP     D     ;D-miesiac zadany
     JR     NZ,NZG
     POP     AF
     RET          ;Z=1 dobrze
 NZG:     POP     AF     ;Dzien biezacy
 DNA:     OR     A     ;CY=0
     INC     A
     DAA
     CALL     INCC
     CP     (HL)     ;Ost. dzien mies ?
     JR     C,DNAST ;Nastepny dzien
     LD     A,B
     INC     A
     DAA
     LD     B,A      ;Biezacy miesiac
     INC     HL     ;Nastepny miesiac
     LD     A,39H     ;Str.21 w MIK08, TABM od 32D-339 /38 to koniec TABM
     CP     (HL)     ;mies 13 !!
     JR     NZ,NASA
     OR     A
     RET          ;Z=0 Error
  ;INCC - zwiekszenie dni tygodnie w rej. C
 INCC:     PUSH     AF
     INC     C
     LD     A,C
     CP     8
     JR     C,INC1
     LD     C,1     ;poniedzialek
 INC1:     POP     AF
     RET

kor_tr: ; korekta tygodnia roku
        ; jesli 1.01 zaczyna sie w PT i <TYDZ_ROKU> = 0, to 1. tydzien
        ;danego roku = 53., jesli SB lub ND to 52. tydzien
    ld a, (DATA_M+4) ; dzien tyg. 1. stycznia zadanego roku
    cp 5 ; piatek
    jr z, set53
    ld a, 52h
 kor_tr1:
    ld (TYDZ_ROKU), a
    ret
         set53:
    ld a, 53h
    jr kor_tr1

set_dni_tyg:; "przelicz" dni tygodnia na potrzeby CA80
  ld hl, dnityg   ;liczenie do "tylu!"
  ld a, (hl)
  cpl
  inc a
  and 7
  ld (hl), a
  ret
           ; obliczenie dnia tygodnia dla akt. daty i wpis do CA80
d_tyg_ca: ; wpis obliczonego dnia tygodnia /aktualna data/ do CA80
    ld a, c ; dzien tygodnia
    dec a
    cp 0
    jr nz, d_tyg_ca2
 d_tyg_ca1: ; jesli 0 to wpisz 7 /niedziela/
    ld a, 7
 d_tyg_ca2:
    ld b, a
    ld a, 8
    sub b
    ld (dnityg), a ; wpis dnia tygodnia do CA80
    ret

; CENTURY: ; zmiana stulecia
;   ld a, (LATA) ; aktualne lata po 0:00:00 /polnoc/
;   cp 0
 ;  ret nz
;   ld L, A
;   ld a, (LATA_P)
;   cp L
;   ret z ; brak zmiany
;   ld hl, STULECIE
;   inc (HL)
;   ld a, (LATA)
;   ld (LATA_P), a
;   ret

    ; odczyt rejestru 5. DS3231 i sprawdz. bitu 7. jesli 1 to nastapila
    ; zmiana roku z 99 na 00 /o polnocy/-  nota katalogowa str. 11
   ;ld a, DS_ZAP ;"adres" ukladu DS3231 do zapisu /D0/
   ;call ZAP_BAJT; wpis bajtu i kontrola ACK
   ;ld a, 5 ; ustaw wskaznik rejestru na 5. -  rejestr DS3231 - Month/Century
   ;call ZAP_BAJT
   ;call START_I2C ; restart
   ;ld a, DS_ODCZ ; D1
   ;call ZAP_BAJT; wpis bajtu i kontrola ACK
   ;call czytaj_bajt
   ;call send_ACK ; master -> ca80 potwierdza odebrany bajt
   ;call stop
     ;w rej. E odczytany bajt
  ;bit 7, E
  ;ret nz
    ; bit 7. = 1, zmiana roku z 99 na 00, nastepuje o polnocy
  ;ld hl, stulecie
  ;inc (hl)
  ;jp czas_dane1

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

op_2ms:
  EX (sp), hl
  ld e, (hl)
  inc hl
  ex (sp), hl
 op_1:
  halt
  dec e
  jr nz, op_1
  ret

spr_cz_d:
   ;spr_date:  ; sprawdzenie, czy dzien jest zgodny z ograniczeniem dni
   ld hl, dnim
   ld b, 3
 spr_date1:
   or A
   ld a, (HL)
   inc a
   dec a
   daa
   ld  (HL), a
   inc hl
   djnz spr_date1
   ld hl, mies
   ld a, (HL) ; miesiac
   cp 0Ah
   jr c, spr_dzien1  ;gdy mies =< 9
   sub 6             ;gdy mies > 9
spr_dzien1:
   ld b, a ; zapamietanie miesiaca
   cp 13h
   jp nc, blad_daty ; bledny miesiac >12       B7           or A
   dec a
   daa
   cp 0FFh
   jp z, blad_daty
   ld HL, DNIM
   ld a, (HL) ; dzien miesiaca
   ld de, TABM ; tabela ograniczen dni w miesiacu
   dec b ; miesiac
   ld a, b
   add a, e
   ld e, a
   ld a, (de) ; ograniczenie
   dec a
   ld hl, dnim ; w CA80
   ld d, (hl)
   cp d ; porownanie z ograniczeniem w rej. A
   jp c, blad_daty
   ret

ini_LCD:
  start_I2C:          ; i2c START 
  ld a, WE_WE  ; SDA i SCL na H
  out (CTRL), a
  ld a, WY_WE ; SDA na L ale SCL jeszcze H
  out (CTRL), a
  ld a, WY_WY
  out (CTRL), a
  ret

STOP:           ; ??? i2c STOP 
  push af
  ld a, WY_WY
  out (CTRL), a ; SDA i SCL na L
  ;call sclset
  ld a, WY_WE ;SDA jeszcze L, SCL na H
  out (CTRL), a
  ld a, WE_WE
  out (CTRL), a
  call op_2ms
  defb 3 ; nota katalogowa, min 10 ms, "doswiadczalnie stwierdzono"
  pop  af    ; 6 ms wystarczy
  ret

zap_bajt:  ; zapisz bajt umieszczony w rej. A
    push bc
    push af ; ochrona danej do zapisu
    ld c, a
    ld a, WE_WY
    out (CTRL), a
    ld   b,8 ; ile bitow
    pop af
 za_b1:
    sla c        ;B[7] => CY
     ; ustaw SDA na 0 lub 1, w zaleznoœci od CY
    in A,(IN_SDA); odczyt portu, gdzie linia SDA - zmiana TYLKO bitu 0
    res SDA_bit, a  ; ???
    jr nc, wys_0
    set SDA_bit, a; wyslij "1"
 wys_0: ; wyslij "0"
    push af
    ld a, WY_WY
    out (CTRL), a
    pop af
    out (OUT_SDA), A
    call sclclk   ; CLK na H, potem na L
    djnz za_b1
    call spr_ACK
    pop bc
    ret

spr_ACK: ; czy SLAVE wystawil ACK - stan L 
  push bc
  ld A, WE_WY   ; SDA - WEJ, SCL - WYJ
  out (CTRL), A
  ld b, 250  ; ilosc prob sprawdzenia czy ACK
 get1:       ; jesli przekroczy tê iloœæ, to blad
  dec b
  jp z, blad_ACK
  in A,(IN_SDA)
  bit sda_bit, A ; testuj bit PC0
  jr nz, get1
  call sclset
  nop
  nop
  call sclclr
  pop bc
  ret

send_ack: 
  ld a, WY_WY  ; SDA + SCL output
  out (CTRL),A
  call sclset      ; zegar SCL
  call sclclr
  ret

czytaj_bajt:     ; odczyt bajtu
  push bc
  ld A, WE_WY  ; SDA - in, SCL - out
  out (CTRL),A
  ld b, 8
CZ_B1:
  call sclset
  in A,(IN_SDA)    ; odczyt portu, gdzie linia SDA
  rrca
  rl c           ; przesuñ CY do C
  call sclclr
  djnz CZ_B1
  ld a, c        ; odczytany bajt
  pop bc
  ld (IX+0), A ; wpis do CA80 (IX) lub bufora przy wyœwietlaniu bajtów
  inc ix
  ret
sclset: ; SCL na H, bez zmiany SDA /SCL to PC.4         
  in   a, (port_C)
  set  SCL_bit, a
  out  (port_C), a
  ret

sclclr:  ; SCL na L, bez zmiany SDA            
  in   a, (port_C)
  res  SCL_bit, a
  out  (port_C), a
  ret

sclclk:         ;     "Clock"  SCL na  H, potem  -> L
  call sclset
  call sclclr
  ret

blad_ack: ; wyœw. komunikatów, gdy brak potwierdz. ACK z urz¹dzenia
  push de ; ochrona E
  ld hl, no_ack ;  "no_ACK"
  call PRINT ; wyœw. "no ACK" na ca80
  defb 44h ; PWYSW
  call op_100ms
  defb 7
  ret
