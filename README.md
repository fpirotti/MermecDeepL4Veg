# Mer Mec Engineering - Mondo Rotaia

Vedi [Installazione](#installazione)

![](images/clipboard-3706240923.png)

## Installazione

[**Se installate in ambiente MS WINDOWS**]{.underline} prima installate 
[Rtools](https://cran.r-project.org/bin/windows/Rtools/rtools45/rtools.html)!

Installa nell'ambiente R usando le seguenti righe. 

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
