// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Cryptoteca {

    struct Book {
        uint256 id;
        string title;
        string author;
        string ipfsHash;
        uint256 rentalPrice;
        address payable uploader;
        bool exists;    // Serve per sapere se l'ID è stato mai creato
        bool isActive;  // Serve per sapere se è attualmente noleggiabile
    }

    struct Rental {
        uint256 bookId;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
    }

    uint256 public bookCount = 0;
    
    uint256 constant RENTAL_DURATION = 7 days;

    mapping(uint256 => Book) public books;
    mapping(address => mapping(uint256 => Rental)) public rentals;

    // Eventi
    event BookAdded(uint256 bookId, string title, address uploader, uint256 price);
    event BookRented(uint256 bookId, address renter, uint256 endTime);
    event BookRemoved(uint256 bookId, address uploader); // NUOVO EVENTO

    // --- FUNZIONI ---

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

    /**
     * @dev NUOVA FUNZIONE: Permette solo all'uploader di disattivare il libro.
     * Non cancella i dati storici, ma impedisce nuovi noleggi.
     */
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
    
    // Funzione helper per vedere se un libro è attivo
    function getBookDetails(uint256 _id) public view returns (string memory, uint256, address, bool) {
        Book memory b = books[_id];
        return (b.title, b.rentalPrice, b.uploader, b.isActive);
    }
}