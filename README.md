# Hackaton Avalanche
Progetto del team 6 per l'Hackathon di Avalanche

## Cryptoteca

L'idea di cryptoteca è quella di un sistema decentralizzato per il caricamento e noleggio di libri digiitali tramite l'uso della tecncologia blockchain e ISPF con costi variabili per il noleggio.


## Requisiti

- Core Wallet
- ISPF (Solo per mettere a disposizione i libri)


## Funzionamento

L'utente che vuole fare utilizzo di cryptoteca deve connettersi ad un eventuale sito su dominio pubblico e quindi connettere il proprio core wallet.
Dopo la connessione, diventerano visibili tutti i libri disponibili nel catalogo della blockchain. 

> Nota
> Sulla blockchain non vengono caricati i file effettivi del libro, ma solo i metadati, poichè caricare un intero libro richiederebbe costi troppo elevati.

Le possibili operazioni sono:

- Noleggio di un libro.
- Mettere a disposizione un libro.

## Noleggio di un libro

Il noleggio di un libro avviene nelle seguenti fasi: 

1) Scelta del libro da noleggiare dal catalogo globale.
2) Per il noleggio deve essere pagata una somma di avax alla persona che ha inserito il libro.
3) Nella sezione "I miei noleggi" si potrà leggere il libro scelto.

## Mettere a disposizione un libro

La messa a disposizione di un libro è leggermente più complessa perchè si ha la necessità di utilizzare un [ISPF](https://en.wikipedia.org/wiki/ISPF) e avviene nel seguente modo: 

1) Cliccare sulla sezione "Carica Nuovo".
2) Inserimento delle informazioni (In particolare il CID, ossia il codice che permette di identificare un file presente in tutte le ISPF).
3) Cliccare "Conferma e paga il gas".

## Funzionamento dello Smart Contract

Lo smart contract è scrito in solidity e lo si può modificare dal file 





