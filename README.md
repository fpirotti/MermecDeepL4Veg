# Mer Mec Engineering - Mondo Rotaia

Vedi [Installazione](#installazione)

![](images/clipboard-3706240923.png)

## Installazione

Installa nell'ambiente R che le seguenti righe

```r

## Installa la funzione 'remotes' se non già presente; consente di installare il sistema

if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes")
}

## Installa la app -- Attenzione, ci metterà tra 2 minuti e 30 minuti 
remotes::install_github("fpirotti/MermecDeepL4Veg")

## Esegui la app
MermecDeepL4Veg::runMermecApp()



```
