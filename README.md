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

Lo smart contract è scrito in solidity e lo si può modificare dal file: "cryptoteca.sol". Di seguito la spiegazione: 

### Creazione del struttura del libro

```
    struct Book {
        uint256 id;
        string title;
        string author;
        string ipfsHash;
        uint256 rentalPrice;
        address payable uploader;
        bool exists;    
        bool isActive;  
    }
```

- id: Codice identificativo del libro.
- title: Titolo del libro.
- author: Autore del libro.
- ipfsHash: CID del libro fornito dal ISPF.
- Uploader: Indirizzo dell'utente che ha fatto l'upload del libro.
- exists: Variabile per vedere se un libro esiste.
- isActive: Variabile per vedere se il libro è ancora noleggiabile (Ossia non è scaduto il tempo di noleggio).

### Creazione della struttura per il noleggio 

```
    struct Rental {
        uint256 bookId;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
    }
```

- bookId: Codice identificativo del libro che è stato noleggiato.
- startTime: Tempo di inizio del periodo di noleggio.
- endTime: Tempo di fine del periodo di noleggio.
- isActive: Variabile che definisce se il noleggio è ancora attivo.

### Variabili del contratto
```
    uint256 public bookCount = 0;
    uint256 constant RENTAL_DURATION = 7 days;
    mapping(uint256 => Book) public books;
    mapping(address => mapping(uint256 => Rental)) public rentals;
```

- bookcount: Numero totale di libri presenti sulla blockchain.
- RENTAL_DURATION: Tempo di durate del periodo di noleggio.
- books: Corrispondenza tra interi e libri.
- rentals: Associa a ciascun indirizzo un insieme numerato di oggetti Rental, dove l’indirizzo identifica il proprietario e il numero identifica ciascun Rental di quell’individuo.

### Eventi
```
event BookAdded(uint256 bookId, string title, address uploader, uint256 price);
event BookRented(uint256 bookId, address renter, uint256 endTime);
event BookRemoved(uint256 bookId, address uploader);
```

Gli eventi esprimono rispettivamente: 

- L'inserimento di un libro sulla blockchain.
- Il noleggio di un libro sulla blockchain.
- La rimozione di un libro dalla bo







