
from ctypes import *
import json
import re
import string
import time
import types
import zipfile


Plik_slownik = "odm_converted.txt"
Plik_slownik_zip = "sjp/odm_converted.zip"


PLIK_IN = 'zle-utf8-bom.srt'
PLIK_OUT = PLIK_IN.rstrip(".srt")+"_corr"+".srt"
PLIK_OUT_BEZ_OGONKOW = PLIK_IN.rstrip(".srt")+"_corr_bez_ogonkow"+".srt"


#with open('sjp/odm_converted.txt') as f:
#    slownik = f.read().splitlines()

zipfile=zipfile.ZipFile(Plik_slownik_zip)
with zipfile.open(Plik_slownik) as f:    
    slownik = f.read().splitlines()

#python 3.9 has default zip.open with "text mode", but
#earlier versions have "binary mode", so check it
if (isinstance(slownik[0],bytes)):
    slownik_= []
    for i in slownik:    
        slownik_.append(i.decode('utf-8'))
    slownik=slownik_

slownik = " ".join(slownik)

#with open("slowa.json", "r") as file:
#    polskieSlowaDiaktryczne = json.load(file)

with open(PLIK_IN, 'rb') as file:
    tesktDoEdycji = file.read()


ziemba=tesktDoEdycji
#--rozdziel slowa z pliku----
#--Zamien litery na male
ziemba=ziemba.lower()
#--usun cyfry
bStringDigit=string.digits.encode()
for i in bStringDigit:    
    ziemba=ziemba.replace(i.to_bytes(1,'little'),b' ')
#--usun interpunkcje
bStringPunctation=string.punctuation.encode()

for i in bStringPunctation:    
    ziemba=ziemba.replace(i.to_bytes(1,'little'),b' ')



#---zamien nowa linie na spacje
ziemba=ziemba.replace(b'\n',b' ')
ziemba=ziemba.replace(b'\r',b' ')


#---Usun zdublowane slowa
listaSlow = set(ziemba.split())
#listaSlow = b' '.join(listaSlow)

#---zostaw tylko slowa z jednym polskim znakiem
listaSlow_ =[]
for i in listaSlow:
    slowo=re.search(b'^[a-z]*[\x80-\xFF]{2}[a-z]*$',i)
    if slowo:
        listaSlow_.append (slowo[0])


listaSlow= listaSlow_
listaSlow.sort()


#start_time = time.time()


# ą,ć,ę,ł,ń,ó,ś,ź,ż
polskieZnaki = {'A z ogonkiem':[0,b'a',b'\xc4\x85',b'\x00\x00'],
'Ce z kreska':[0,b'c',b'\xc4\x87',b'\x00\x00'],
'E z ogonkiem':[0,b'e',b'\xc4\x99',b'\x00\x00'],
'El z kreska':[0,b'l',b'\xc5\x82',b'\x00\x00'],
'En z kreska':[0,b'n',b'\xc5\x84',b'\x00\x00'],
'O z kreska':[0,b'o',b'\xc3\xb3',b'\x00\x00'],
'Es z kreska':[0,b's',b'\xc5\x9b',b'\x00\x00'],
'Zet z kreska':[0,b'z',b'\xc5\xba',b'\x00\x00'],
'Zet z kropka':[0,b'z',b'\xc5\xbc',b'\x00\x00'],
}


for slowoRex in listaSlow:    
    slowoRexDot=re.sub(b'[\x80-\xFF]{2}',b'.',slowoRex).decode()
    slowoRexDot=" "+slowoRexDot+" "
    polskiNieznanyZnak=re.search(b'[\x80-\xFF]{2}',slowoRex)
    polskiNieznanyZnakB=polskiNieznanyZnak[0]
    
    slowo=re.search(slowoRexDot,slownik)
    
    if slowo:        
        slowo=slowo[0].strip()        
        polskiUTF8Znak=re.search('[ąćęłńóśźż]',slowo)
        polskiUTF8ZnakB=polskiUTF8Znak[0].encode('utf-8')
        #print (time.time()-start_time)
        for i in polskieZnaki:
            for j in polskieZnaki[i][2:3]:
                if j==polskiUTF8ZnakB:
                    print ('Znaleziono literę: {} w slowie {:<15}utf-8 {} rozpoznany {}'.format(polskiUTF8Znak[0],slowo,polskiUTF8ZnakB,polskiNieznanyZnakB))
                    polskieZnaki[i][3]=polskiNieznanyZnakB
                    polskieZnaki[i][0]=polskieZnaki[i][0]+1


odkodowanoWszystko=True

for i in polskieZnaki:
    print('"{:<12}" - {:<4}wystąpień {}'.format(i,polskieZnaki[i][0:1][0],polskieZnaki[i][3:4][0]))
    #jezeli nie znaleziono znaku
    if polskieZnaki[i][0:1][0]==0:
        odkodowanoWszystko=False
if odkodowanoWszystko==True:
    print ("Odkodowano wszystkie litery")
else:
    print ("Nie odkodowano wszystkich liter")


def zapiszPoprawneKodowanie ():
    global tesktDoEdycji
    global PLIK_OUT
    global polskieZnaki

    tesktDoEdycjiPopr=tesktDoEdycji
    for i in polskieZnaki:
        for j,k in zip (polskieZnaki[i][3:4],polskieZnaki[i][2:3]):                        
            tesktDoEdycjiPopr=tesktDoEdycjiPopr.replace(j,k)
    #zapisz poprawne kodowanie
    print ("Zapisuje poprawiony plik utf-8 do:",PLIK_OUT)
    with open(PLIK_OUT, 'wb') as file:
        file.write(tesktDoEdycjiPopr)

#z dekoratorem i funkcja sie pobawic
#zapisz litery bez ogonkow

def zapiszLiteryBezOgonkow ():
    global tesktDoEdycji
    global PLIK_OUT_BEZ_OGONKOW
    global polskieZnaki
    tesktDoEdycjiPopr=tesktDoEdycji

    for i in polskieZnaki:
        for j,k in zip (polskieZnaki[i][3:4],polskieZnaki[i][1:2]):                                        
            tesktDoEdycjiPopr=tesktDoEdycjiPopr.replace(j,k)
    #skaduj znacznik utf-8-BOM
    utf8bom_sig=b'\xef\xbb\xbf'
    tesktDoEdycjiPopr=tesktDoEdycjiPopr.replace(utf8bom_sig,b'')
    
    print ("Zapisuje poprawiony plik bez ogonkow do:",PLIK_OUT_BEZ_OGONKOW)
    with open(PLIK_OUT_BEZ_OGONKOW, 'wb') as file:
        file.write(tesktDoEdycjiPopr)

zapiszPoprawneKodowanie ()
zapiszLiteryBezOgonkow ()


#opcje
#uszkodz plik
#litery bez ogonkow
exit ()
proba = proba.replace(b'\xc2\xb9', b'\xc4\x85').\
    replace(b'\xc3\xa6', b'\xc4\x87').\
    replace(b'\xc3\xaa', b'\xc4\x99').\
    replace(b'\xc2\xb3', b'\xc5\x82').\
    replace(b'\xc3\xb1', b'\xc5\x84').\
    replace(b'\xc3\xb3', b'\xc3\xb3').\
    replace(b'\xc5\x93', b'\xc5\x9b').\
    replace(b'\xc5\xb8', b'\xc5\xba').\
    replace(b'\xc2\xbf', b'\xc5\xbc')
# Ę,Ł,Ń,Ó,Ś
proba = proba.replace(b'\xc3\x8a', b'\xc4\x98').\
    replace(b'\xC2\xA3', b'\xc5\x81').\
    replace(b'\xc3\x91', b'\xc5\x83').\
    replace(b'\xc3\x93', b'\xc3\x93').\
    replace(b'\xC5\x92', b'\xc5\x9a')



#print ("ść".encode("utf-8"))
#print (int('23',7))
#print (proba1)

exit()
# proba1=b"Doctor nie żyje. Zamknij się."
proba1 = b"Doctor nie zyje. Zamknij sie. \x23 a \x45"
index = proba1.find(b'Doc')
proba2 = proba1.replace(b'e', b'ooo').strip(b'nio')
# proba3=proba2.



print(proba3)
exit()
print(proba1.fromhex('3a 3b 3c'))
print(b"d o g".hex(""))

exit()
proba2 = proba1[index:-2:2]
print(proba2)

exit()

print(wyrazy)
#wyraz2 = wyraz.decode()
exit()
print(wyraz)
print(wyraz2)
exit()
for i in wyraz:
    print(i)
print(wyraz)
#print (rzadkie_slowa)
exit()
for i, j in rzadkie_slowa.items():
    print(i, j)
# nic waz
exit()
# -*- coding: ISO-8859-2 23-*-
# Ą260
A = '\u0104'
C = '\u0106'
E = '\u0118'


# A_WIN='0xca'.encode('ascii')
ą_WIN = 0xca
ć_WIN = 0xC6


byt = bytes([ą_WIN, ć_WIN])
byt2 = bytes([ą_WIN])

print(int(ą_WIN))

#print (byt[1])

# A5 	#C6 	#CA 	#A3 	#D1 	#D3 	#8C 	#8F 	#AF 	#B9 	#E6 	#EA 	#B3 	#F1 	#F3 	#9C 	#9F 	#BF
Tekst = "ząaki"
tekst = bytes(Tekst, 'UTF-8')
tekst = tekst+byt2
# if tekst[1]==ord('z'):
if tekst[1] == int(ą_WIN):
    print("jest ą")
print(tekst[1])
#print (tekst)
exit()
# Tekst=znaki+bytes(chr(A_WIN))+chr(C_WIN)
# Tekst=Tekst+int.to_bytes(1,A_WIN,byteorder='little')
print(tekst)
# Tekst=znaki+bytes(A_WIN)


# A=261
#print (ord(u"ą"))
# Au'\u0103'
#print (A)
#print (Tekst)

#exit ()
#print (unichr(A))
with open("plik", 'wb') as plik:
    # plik.write(Tekst.encode("utf-8"))
    plik.write(tekst)
    # plik.write(bytes((E_WIN,))) # python 3
