# Mer Mec Engineering - Mondo Rotaia

Vedi [Installazione](#installazione)

![](images/clipboard-3706240923.png)

## Installazione

### Software da installare 

 - Installare [R]([https://cran.r-project.org/bin/windows/Rtools/rtools45/rtools.html](https://cran.rstudio.com/)
ed [Rstudio](https://posit.co/download/rstudio-desktop/) per prima cosa.
 - [**Se installate in ambiente MS WINDOWS**]{.underline}  installate 
poi [Rtools](https://cran.r-project.org/bin/windows/Rtools/rtools45/rtools.html)!

### Esecuzione

Lanciare RStudio ed eseguire i seguenti comandi: 

```r

## Installa la funzione 'remotes' se non già presente; consente di installare il sistema

if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes")
}

## Installa la app ...
# prima modificare il timeout di default di 60 secondi
options(timeout = max(600, getOption("timeout")))
remotes::install_github("fpirotti/MermecDeepL4Veg")

## Carica la app 
## Attenzione, la prima volta viene eseguita una verifica di 
## compatibilità, può richiedere qualche minuto

## Lancia l'interfaccia da RStudio mediante i seguenti due comandi
library(MermecDeepL4Veg)
runMermecApp()


```

Vanno poi caricati i modelli se non sono già presenti. Il software esegue varie elaborazioni e può essere usato anche senza modelli caricati, fino allo step 3.

