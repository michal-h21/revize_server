# Příprava souborů

Vygenerovat seznam jednotek pro danou část fondu pomocí obecného formuláře pro vyhledávání.

Vygenerovat tsv soubor pomocí skriptu (je součástí skriptů přírustkového seznamu)

    ./revize_priprava xml_soubor_z_alephu > tabulka.tsv

Pokud obsahuje víc signatur, rozdělit je pomocí 

    texlua filtrovatsignatury.lua   < tabulka.tsv

# Nová revize

    make new

nebo pro studovnu

    make studovna

# instalace na notebooky

- [Nainstalovat Ubunbtu na Windows](https://itsfoss.com/install-bash-on-windows/)
- nainstalovat Git pomocí apt
- spustit:

    sudo make install

