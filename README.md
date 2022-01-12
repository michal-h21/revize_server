# Příprava souborů

Vygenerovat seznam jednotek pro danou část fondu pomocí obecného formuláře pro vyhledávání.

Vygenerovat tsv soubor pomocí skriptu (je součástí skriptů přírustkového seznamu)

    ./revize_priprava xml_soubor_z_alephu > tabulka.tsv

Z Almy zatím dokážu dostat XLSX soubor se seznamem jednotek, kterej ale
neobsahuje status zpracování. Předělám ho na tsv pomocí 

    texlua xlsx_to_tsv.lua soubor.xlsx > tabulka.tsv


Pokud tsv soubor obsahuje víc signatur, rozdělit je pomocí 

    texlua filtrovatsignatury.lua   < tabulka.tsv

# Nová revize

    make new

nebo pro studovnu

    make studovna

# Vygenerování kontrolního souboru

Spustit sript `revizechyby.lua` na adresář obsahující konfigurační soubor, data revize a načtené kódy:

    lua revizechyby.lua 2sc > revize_2sc.tsv

Získat pořadí načtených kódů

    lua nacteneporadi.lua 2sc > poradi_2sc.tsv

# instalace na notebooky

- [Nainstalovat Ubunbtu na Windows](https://itsfoss.com/install-bash-on-windows/)
- nainstalovat Git pomocí apt
- spustit:

    sudo make install

