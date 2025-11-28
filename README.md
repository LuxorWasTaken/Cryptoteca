# Hackaton Avalanche
Progetto del team 6 per l'Hackathon di Avalanche

# Sommario
- [Introduzione](#Cryptoteca-Introduzione)
- [Requisiti](#Requisiti)
- [Uso](#uso)
- [Spiegazione Smart Contract](#SmartContract-Spiegazione)
- [Problematiche Riscontrate nello Sviluppo](#Problematiche)

## Cryptoteca-Introduzione

L'idea di cryptoteca è quella di un sistema decentralizzato per il caricamento e noleggio di libri digiitali tramite l'uso della tecncologia blockchain e ISPF con costi variabili per il noleggio.


## Requisiti

- Core Wallet
- IPFS (Solo per mettere a disposizione i libri)


## Uso

L'utente che vuole fare utilizzo di cryptoteca deve connettersi ad un eventuale sito su dominio pubblico e quindi connettere il proprio core wallet.
Dopo la connessione, diventerano visibili tutti i libri disponibili nel catalogo della blockchain. 

> Nota
> Sulla blockchain non vengono caricati i file effettivi del libro, ma solo i metadati, poichè caricare un intero libro richiederebbe costi troppo elevati.

Le possibili operazioni sono:

- Noleggio di un libro.
- Mettere a disposizione un libro.

### Noleggio di un libro

Il noleggio di un libro avviene nelle seguenti fasi: 

1) Scelta del libro da noleggiare dal catalogo globale.
2) Per il noleggio deve essere pagata una somma di avax alla persona che ha inserito il libro.
3) Nella sezione "I miei noleggi" si potrà leggere il libro scelto.

### Mettere a disposizione un libro

La messa a disposizione di un libro è leggermente più complessa perchè si ha la necessità di utilizzare un [IPFS](https://en.wikipedia.org/wiki/InterPlanetary_File_System) e avviene nel seguente modo: 

1) Cliccare sulla sezione "Carica Nuovo".
2) Inserimento delle informazioni (In particolare il CID, ossia il codice che permette di identificare un file presente in tutte le ISPF. Il CID lo si ottiene inserendo il file da mettere nella blockchain all'interno del proprio nodo IPFS). 
3) Cliccare "Conferma e paga il gas".

## SmartContract-Spiegazione

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
- ipfsHash: CID del libro fornito dal IPFS.
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
- La rimozione di un libro dalla blockchain.

### Funzioni

#### addBook
```
    function addBook(string memory _title, string memory _author, string memory _ipfsHash, uint256 _price) public {
        require(bytes(_title).length > 0, "Titolo obbligatorio");
        require(bytes(_ipfsHash).length > 0, "Hash IPFS obbligatorio");
        require(_price > 0, "Prezzo > 0");

        bookCount++;
        
        books[bookCount] = Book({
            id: bookCount,
            title: _title,
            author: _author,
            ipfsHash: _ipfsHash,
            rentalPrice: _price,
            uploader: payable(msg.sender),
            exists: true,
            isActive: true // Appena creato è attivo
        });

        emit BookAdded(bookCount, _title, msg.sender, _price);
    }
```
Prende in input:

- Titolo.
- Autore.
- uploader.
- hash IPFS.
- prezzo in avax per noleggio.

I require iniziali sono per controllare che tutti i campi vengano riempiti. La variabile di bookcount viene aggiornata perché abbiamo aggiunto un nuovo libro, quindi viene inserito il nuovo oggetto Book nel dizionario books. Infine viene chiamato l'evento di inserimento del libro.

#### removeBook

```
function removeBook(uint256 _bookId) public {
    // Uso 'storage' perché voglio modificare permanentemente la blockchain
    Book storage book = books[_bookId];

    require(book.exists, "Il libro non esiste");
    require(msg.sender == book.uploader, "Solo chi ha caricato il libro puo' rimuoverlo");
    require(book.isActive == true, "Il libro e' gia' stato rimosso");

    // Disattivo il libro
    book.isActive = false;

    emit BookRemoved(_bookId, msg.sender);
}
```
Prende in input:

- Un intero che è l'id del libro da rimuovere.

removeBook disattiva un libro presente nello smart contract. Si usa storage perché vogliamo accedere direttamente alla struttura Book memorizzata sulla blockchain e modificarne lo stato in modo permanente, non solo una copia temporanea in memoria. I require servono per controllare che il libro sia effettivamente memorizzato sulla blockchain, dopo i controlli si può disattivare il libro tramita la variabile isAcrive e quindi emettere l'evento di rimozione del libro.

#### rentBook

```
function rentBook(uint256 _bookId) public payable {
    // Recupero il libro dallo storage per leggere lo stato aggiornato
    Book memory book = books[_bookId];
        
    require(book.exists, "Il libro non esiste");
    require(book.isActive, "Questo libro e' stato rimosso dall'autore e non e' piu' noleggiabile"); // NUOVO CONTROLLO
    require(msg.value >= book.rentalPrice, "Importo insufficiente");
    require(msg.sender != book.uploader, "Non puoi noleggiare il tuo libro");

    Rental memory currentRental = rentals[msg.sender][_bookId];
    if (currentRental.isActive) {
        require(block.timestamp > currentRental.endTime, "Noleggio gia' attivo");
    }

    (bool sent, ) = book.uploader.call{value: msg.value}("");
    require(sent, "Errore nel pagamento");

    rentals[msg.sender][_bookId] = Rental({
        bookId: _bookId,
        startTime: block.timestamp,
        endTime: block.timestamp + RENTAL_DURATION,
        isActive: true
    });

    emit BookRented(_bookId, msg.sender, block.timestamp + RENTAL_DURATION);
}
 ```
Prende in input:

- Un intero che è l'id del libro da noleggiare.

rentBook permette a un utente di noleggiare un libro pagando il prezzo di noleggio. Qui si usa Book memory book perché ci serve solo leggere i dati del libro al momento del noleggio, senza modificare permanentemente lo stato sulla blockchain. Tutti i controlli (esistenza, attivazione, prezzo, proprietà) vengono effettuati prima di trasferire i fondi all’autore e registrare il noleggio nello storage.

#### hasAccess

```
    function hasAccess(address _user, uint256 _bookId) public view returns (bool, string memory) {
        Rental memory rental = rentals[_user][_bookId];
        Book memory book = books[_bookId];

        if (_user == book.uploader) {
            return (true, book.ipfsHash);
        }

        // Se un utente ha noleggiato il libro IERI e l'autore lo rimuove OGGI,
        // l'utente ha ancora diritto di leggerlo fino alla scadenza del suo noleggio.
        // La rimozione impedisce solo NUOVI noleggi.
        if (rental.isActive && block.timestamp <= rental.endTime) {
            return (true, book.ipfsHash);
        }

        return (false, "");
    }
```
Prende in input: 

- Indirizzo di un utente.
- Un intero che è identifica il libro.

Restituisce:

- True se l'utente con indirizzo _user ha accesso al libro identificato dal CID.
- False altrimenti.

> Nota
> Quando un utente noleggia un libro, ha accesso a questo fino alla fine del tempo di durata del noleggio. Anche se l'autore decide di rimuovere il libro dalla chain.

#### getBookDetails

```
    function getBookDetails(uint256 _id) public view returns (string memory, uint256, address, bool) {
        Book memory b = books[_id];
        return (b.title, b.rentalPrice, b.uploader, b.isActive);
    }
```
Prende in input: 

- L'id del libro di cui si vogliono avere più informazioni.

Ritorna:

- Titolo del libro.
- Prezzo del noleggio.
- Indirizzo dell'uploader.
- La disponibilità.

Permette di leggere le informazioni di un libro specifico: titolo, prezzo di noleggio, indirizzo dell’autore e stato di attivazione

## Problematiche

### Problematiche nella gestione di IPFS durante lo sviluppo dello smart contract

Durante lo sviluppo dello smart contract abbiamo incontrato diverse difficoltà legate all’utilizzo di IPFS per la memorizzazione dei file. Caricare un file su un singolo nodo IPFS, infatti, non garantiva né la decentralizzazione né la persistenza del contenuto: se quel nodo diventava irraggiungibile, l’hash salvato nello smart contract non era più utile.

Un’altra criticità era che, utilizzando un singolo nodo, ogni volta che il file veniva caricato su un nodo IPFS diverso o cambiava gateway, eravamo costretti a modificare il codice per aggiornare l’indirizzo del nodo stesso. Questo approccio era poco scalabile, fragile e contrario ai principi della decentralizzazione.

Per risolvere queste problematiche abbiamo adottato una soluzione basata su un nodo centrale che replica e contiene i contenuti provenienti da tutti gli altri nodi IPFS, garantendo così che i file fossero sempre disponibili e non dipendessero da un unico gateway. In questo modo non è più necessario cambiare l’indirizzo IPFS nel codice e si ottiene una gestione molto più affidabile e decentralizzata.










