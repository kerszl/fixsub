#!/bin/bash

#przygotowanie zestawu słów
#Przykladowa wersja
#https://sjp.pl/slownik/odmiany/sjp-odm-20201103.zip --output sjp-odm-20201103.zip
#----
PLIK_WYNIKOWY=odm_converted.txt
PLIK_TMP1=odm_tmp1.txt
PLIK_TMP2=odm_tmp2.txt
PLIK_TMP3=_odm_conv.txt
PLIK_TMP4=_odm.txt
PL_ODM=pl_odm.txt
PLIK_W_SJP=odm.txt
POLSKIE_ZNAKI=(ą ć ę ł ń ó ś ź ż)

sciagnij_slownik () {
    #Sciagamy najnowsza wersje slownika
    SJP_SITE='https://sjp.pl/slownik/odmiany/'
    SJP_WER=$(curl -sk https://sjp.pl/slownik/odmiany/ | grep  -o '[a-z0-9-]*\.zip' | uniq)
    
    
    echo Pobieram najnowsza wersje slownika z $SJP_SITE
    curl -ks $SJP_SITE$SJP_WER --output $SJP_WER
    
    echo Rozpakowuje $SJP_SITE$SJP_WER
    unzip -o $SJP_WER $PLIK_W_SJP
    
}

parsuj1 () {
    #etap przetwarzania (szukamy wyrazów z polskimi znakami, usuwamy je i zmniejszamy)
    echo przetwarzanie1 - szukamy wyrazów z polskimi znakami, usuwamy je i zmniejszamy
    grep -i 'ą\|ć\|ę\|ł\|ń\|ó\|ś\|ź\|ż' odm.txt | tr '[:upper:]' '[:lower:]' |\
    tr ',' '\n' | tr -d '\r' | grep 'ą\|ć\|ę\|ł\|ń\|ó\|ś\|ź\|ż' | tr ' ' '\n' | sort | uniq |\
    grep 'ą\|ć\|ę\|ł\|ń\|ó\|ś\|ź\|ż' | grep -v '-'> $PLIK_TMP1
}

parsuj2 () {
    #etap (szukamy wyrazow gdzie jest jeden polski znak)
    > $PLIK_TMP2
    echo przetwarzanie2 - szukamy wyrazow gdzie jest tylko jeden polski znak
    for i in ${POLSKIE_ZNAKI[@]}; do
        grep '^[a-z]*'$i'[a-z]*$' $PLIK_TMP1 >> $PLIK_TMP2
    done
}


podziel_pliki_na_mniejsze ()
{
    echo Dziele pliki na mniejsze
    #Podziel plik na mniejsze w celu szybszej analizy
    #Początkowe litery a-z
    for i in {a..z};do
        grep '^'$i $PLIK_TMP2 > "$i"$PLIK_TMP4
    done
    
    #polskie znaki
    > $PL_ODM
    for i in {ą,ć,ę,ł,ń,ó,ś,ź,ż};do
        grep '^'$i $PLIK_TMP2 >> $PL_ODM
    done
}

stworz_unikalne_slowniki ()
{
    #Stworz slownik z jedną polską literą i nie dublującą się na pozycji
    #np:
    # łona, żona (Polski znak na pozycji nr 1)
    # się, sił   (Polski znak na pozycji nr 3)
    echo Tworze unikalny slownik
    START_KONWERSJI=$(date +"%s")
    
    for znak in {a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,pl}; do
        
        PLIK="$znak"$PLIK_TMP4
        PLIK_KONW="$znak"$PLIK_TMP3
        ROZMIAR_PLIKU=$(stat --printf="%s" $PLIK)
        
        > $PLIK_KONW
        echo tworze $PLIK_KONW
        if (($ROZMIAR_PLIKU>0));then
            readarray -t TABLICA_SLOW < $PLIK
            for wyraz in ${TABLICA_SLOW[@]}; do
                #2 razy wolniej z tym
                #l1=$(echo $wyraz | grep -o '[ąćęłńóśźż]')
                #DWA_ZNAKI_UTF=${wyraz/$l1/[ąćęłńóśźż]}
                DWA_ZNAKI_UTF=${wyraz/[ąćęłńóśźż]/[ąćęłńóśźż]}
                ILOSC_WYSTAPIEN=$(grep -c '^'$DWA_ZNAKI_UTF'$' $PLIK)
                if (($ILOSC_WYSTAPIEN<2));then
                    echo $wyraz >> $PLIK_KONW
                fi
            done
        fi
    done
    
    KONIEC_KONWERSJI=$(date +"%s")
    CZAS_KONWERSJI_=$(( KONIEC_KONWERSJI - START_KONWERSJI ))      
    CZAS_KONWERSJI=$( printf '%02dg. %02dm. %02ds.' $(($CZAS_KONWERSJI_/3600)) $(($CZAS_KONWERSJI_%3600/60)) $(($CZAS_KONWERSJI_%60)) )
    echo Słownik tworzyłem: $CZAS_KONWERSJI
    
    
}

polacz_w_jeden_slownik ()
{
#Lacze wszystko w jedno
echo Polacz pliki w jeden

    > $PLIK_WYNIKOWY
    for znak in {a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,pl}; do
        cat "$znak"$PLIK_TMP3 >> $PLIK_WYNIKOWY
    done
    
}

poczysc_pliki ()
{
#Czyszcze
for znak in {a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,pl}; do
rm "$znak"$PLIK_TMP3
rm "$znak"$PLIK_TMP4
done

rm $PLIK_TMP1
rm $PLIK_TMP2
rm $PLIK_W_SJP

}


sciagnij_slownik
parsuj1
parsuj2
podziel_pliki_na_mniejsze
stworz_unikalne_slowniki
polacz_w_jeden_slownik
poczysc_pliki

#tutaj jest koniec skryptu



exit

#3.(nieaktualny) usun wyrazy majace conajmniej 7 znakow które się konczą na ę, ą
#egrep -v .{6}ę$\|.{6}ą$ odm2.txt > odm3.txt

#dalej to jakies smieci
#plik=z_odm.txt
#plik=s_odm.txt
#plik=odm2.txt

readarray -t TABLICA_SLOW < $plik

>a
for wyraz in ${TABLICA_SLOW[@]}; do
    
    #2 razy wolniej z tym
    #l1=$(echo $wyraz | grep -o '[ąćęłńóśźż]')
    #szukaj=${wyraz/$l1/[ąćęłńóśźż]}
    
    DWA_ZNAKI_UTF=${wyraz/[ąćęłńóśźż]/[ąćęłńóśźż]}
    ILOSC_WYSTAPIEN=$(grep -c '^'$DWA_ZNAKI_UTF'$' $plik)
    
    if (($ILOSC_WYSTAPIEN<2));then
        echo $wyraz >> $plik
    fi
    
done




licznik=1
licznikPrzekrec=false
licznik_zwieksz=1000
> a
for i in ${TABLICA_SLOW[@]}; do
    l1=$(echo $i | grep -o '[ąćęłńóśźż]')
    ((licznik_zwieksz=licznik_zwieksz+licznik))
    #echo $licznik_zwieksz
    szukaj=${i/$l1/[ąćęłńóśźż]}
    ilosc_wystapien=$(sed -n $licznik,$licznik_zwieksz"p" $plik | grep  -c '^'$szukaj'$' )
    
    if (($ilosc_wystapien<2));then
        echo $i >> a
        #sed -n $licznik,$licznik_zwieksz"p" $plik | grep '^'$szukaj'$'
    fi
    
    if [ $licznikPrzekrec = true ];then
        ((licznik++))
    else
        licznikPrzekrec=true
    fi
    
done

#---wersja z grep potok

#echo ${TABLICA_SLOW[@]} | grep -o aalborsk[ą-ź]


#[[ $s =~ [^0-9]+([0-9]+) ]]


for i in ${TABLICA_SLOW[@]}; do
    l1=$(echo $i | grep -o '[ąćęłńóśźż]')
    szukaj=${i/$l1/[ąćęłńóśźż]}
    k=0;
    for j in ${TABLICA_SLOW[@]}; do
        if [[ $j =~ $szukaj ]]; then
            #echo $j
            ((k++))
            #echo $k
        fi
    done
    if ((k<2)); then
        echo $i > a
    fi
    echo $i
done


> a
for i in ${TABLICA_SLOW[@]}; do
    l1=$(echo $i | grep -o '[ąćęłńóśźż]')
    szukaj=${i/$l1/[ąćęłńóśźż]}
    count=$(echo ${TABLICA_SLOW[@]} | grep -o $szukaj | wc -l)
    echo $count
    if (($count<2));then
        echo ${TABLICA_SLOW[@]} | grep -o $szukaj
    fi
done



grep ^[a-z]*ą[a-z]*$ odm1.txt > odm1_1.txt
grep ^[a-z]*ć[a-z]*$ odm1.txt > odm1_1.txt
grep ^[a-z]*ą[a-z]*$ odm1.txt > odm1_1.txt
grep ^[a-z]*ą[a-z]*$ odm1.txt > odm1_1.txt
grep ^[a-z]*ą[a-z]*$ odm1.txt > odm1_1.txt
grep ^[a-z]*ą[a-z]*$ odm1.txt > odm1_1.txt

#for i in ${TABLICA_SLOW[@]}; do
#    l1=$(echo $i | grep -o 'ą\|ć\|ę\|ł\|ń\|ó\|ś\|ź\|ż')
#    if (($? == 0)); then
#        for j in ${POLSKIE_ZNAKI[@]}; do
#            if [ $l1 != $j ];then
#                szukaj=${i/$l1/$j}
#                grep '^'$szukaj'$' odm2.txt
#            fi
#        done
#    fi
#done
#---wersja z grep plik
#sed -n 1,30"p" $plik | grep -m2 '^'aalborsk[ą-ż]'$'

