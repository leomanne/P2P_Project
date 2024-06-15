// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2; // Needed to use bytes32[][] as function parameter
contract Bingo {
/**************************************************************************** */
/**           Struct containing all the info for a game                      **/
/**************************************************************************** */

    struct info {
        address creator;
        address[] joiners;
        uint maxJoiners;
        uint totalJoiners;
        uint ethBalance;
        uint betAmount;
        bytes32 creatorMerkleRoot;
        mapping(address => bytes32) joinerMerkleRoots; // Updated to a mapping
        uint8[] numbersExtracted;
        uint accusationTime;
        address accuser;
    }
    enum WinningReasons {
        BINGO,
        CREATOR_STALLED
    }
    // enum Cols {
    //     FIRST_COL,
    //     SECOND_COL,
    //     THIRD_COL,
    //     FOURTH_COL,
    //     FIFTH_COL
    // }
/************************************************ */
/**            Global variables                  **/
/************************************************ */
    int256 public gameId = 0; // Game ID counter
    mapping(int256 => info) public gameList; // Mapping of game ID to game info
    int256[] public elencoGiochiDisponibili;    // List of available game IDs
    // mapping(uint8 => Cols) private COLS;
    // uint8[] private _FIRST_COL   = [0, 5, 10, 14, 19];
    // uint8[] private _SECOND_COL  = [1, 6, 11, 15, 20];
    // uint8[] private _THIRD_COL   = [2, 7, 16, 21];
    // uint8[] private _FOURTH_COL  = [3, 8, 12, 17, 22];
    // uint8[] private _FIFTH_COL   = [4, 9, 13, 18, 23];








/***************************************** */
/**            Events                     **/
/***************************************** */

    event GameCreated(int256 indexed _gameId, uint256 _maxJoiners,uint256 _totalJoiners); //  Event to log game creation
    event Log(string message);
    //TODO: implementa piu persone
    event GameJoined(
        int256 indexed _gameId,
        address _creator,
        address _joiner,
        uint256 _maxjoiners,
        uint256 _totalJoiners,
        uint256 _ethAmount
    );
    event Checked(int256 indexed _gameId,bool _value);
    event GetInfo(
        int256 indexed _gameId,
        uint256 _maxjoiners,
        uint256 _totalJoiners,
        uint256 _ethAmount,
        bool _found
    );
    event Checkvalue(
        int256 indexed _gameId,
        address _address,
        uint256 _row,
        uint256 _col
    );
    event GameStarted(int256 indexed _gameId);

    event NumberExtracted(int256 _gameId, uint8 number,bool _endGame);

    event GameCancelled(uint256 indexed _gameId);
    //event to communicate the end of a game to all the joiners and the creator, loser is used if reason is that he cheated
    event NotBingo(int256 indexed _gameId, address player);

    event ConfirmRemovedAccuse(int256 _gameId,bool _value);
    event GameEnded(
        int256 indexed _gameId,
        address _winner,
        WinningReasons _reason
    );

    event ReceiveAccuse(
        int256 indexed _gameId,
        address _accuser
    );

    event AmountEthResponse(
        address _sender,
        uint256 _amount,
        uint256 indexed _gameId,
        uint256 _response
    );

    constructor() {
        /** Code used for the verification of the table
        for (uint i = 0; i < 5; i++) {
            COLS[_FIRST_COL[i]]  = Cols.FIRST_COL;
            COLS[_SECOND_COL[i]] = Cols.SECOND_COL;
            COLS[_THIRD_COL[i]]  = Cols.THIRD_COL;
            COLS[_FIFTH_COL[i]]  = Cols.FIFTH_COL;
            if (i < 4) {
                COLS[_FOURTH_COL[i]] = Cols.FOURTH_COL;

            }
        }
        */
    }

    /*********************************************** */
    /**               GETTERS                       **/
    /*********************************************** */
    function getIDGame() private returns(int256) {
        return ++gameId;
    }

    function getInfo(int256 _gameId) private view returns (info storage) {
        // Restituisce la struttura dati "info" associata al gameId specificato
        return gameList[_gameId];
    }

    function getInfoGame(int256 _gameId) public {
        // Verifica se ci sono giochi disponibili
        if(_gameId == 0){
            int256 gameID = getRandomGame();
            if (gameID <= 0){
                emit GetInfo(_gameId, 0, 0, 0, false);
                return;
            }else{
                emit GetInfo(gameID, gameList[gameID].maxJoiners, gameList[gameID].totalJoiners, gameList[gameID].betAmount, true);
                return;
            }
        }else{
            uint256 gameID = findIndex(_gameId);
            if(gameID > elencoGiochiDisponibili.length){
                emit GetInfo(_gameId, 0, 0, 0, false);
                return;
                // revert("Reverted because game is not available!");
            }
            emit GetInfo(_gameId, gameList[_gameId].maxJoiners, gameList[_gameId].totalJoiners, gameList[_gameId].betAmount, true);
        }
    }


    function getRandomNumber(uint256 _max) private view returns (uint256) {
       require(_max > 0, "Max must be greater than 0");
        // Generate the random number
        uint randomHash = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender)));
        // Ensure the result is within the desired range
        return (randomHash % _max);
    }

    function getRandomGame() private view returns (int256 idGiocoCasuale) {
        // Verifica se ci sono giochi disponibili
        if (elencoGiochiDisponibili.length == 0) {
            return -1;
        }
        uint256 indiceCasuale = getRandomNumber(elencoGiochiDisponibili.length);
        idGiocoCasuale = elencoGiochiDisponibili[indiceCasuale];// Ottiene l'ID del gioco corrispondente all'indice casuale
        //removeFromGiochiDisponibili(idGiocoCasuale);// Rimuove il gioco dalla lista degli ID disponibili se il massimo num di giocatori e' stato superato
        return idGiocoCasuale;
    }

    function getJoinerMerkleRoots(int256 _gameId) public view returns (bytes32[] memory) {
        uint256 joinerCount = gameList[_gameId].joiners.length;
        bytes32[] memory merkleRoots = new bytes32[](joinerCount);
        for (uint256 i = 0; i < joinerCount; i++) {
            address joiner = gameList[_gameId].joiners[i];
            merkleRoots[i] = gameList[_gameId].joinerMerkleRoots[joiner];
        }
        return merkleRoots;
    }

/************************************************ */
/**            Utility Functions                 **/
/************************************************ */
    function verifyMerkleProof(
        bytes32 _root,
        string memory _leaf,
        bytes32[] memory _proof,
        uint256 _index
    ) internal pure returns (bool) {
        bytes32 _hash = keccak256(abi.encodePacked(_leaf));
        // Starting from 2 to avoid resizing the array
        for (uint256 i = 2; i < _proof.length; i++) {
            if (_index % 2 == 0) {
                _hash = keccak256(abi.encodePacked(_hash, _proof[i]));
            } else {
                _hash = keccak256(abi.encodePacked(_proof[i], _hash));
            }
            _index /= 2;
        }
        return _hash == _root;
    }

    function remove(int256 _gameId) public  returns (bool) {
        uint256 index = findIndex(_gameId);
        // Verifica se l'elemento è stato trovato e se il numero totale di partecipanti raggiunge il limite
        if (index < elencoGiochiDisponibili.length) {
                // Sostituisce l'elemento da rimuovere con l'ultimo elemento
                elencoGiochiDisponibili[index] = elencoGiochiDisponibili[elencoGiochiDisponibili.length - 1];
                // Rimuove l'ultimo elemento
                elencoGiochiDisponibili.pop();
                return true;

        }
        return false;
    }

    // Trova l'indice dell'elemento specificato nell'array elencoGiochiDisponibili
    function findIndex(int256 _gameId) private view returns (uint256) {
        for (uint256 i = 0; i < elencoGiochiDisponibili.length; i++) {
            if (elencoGiochiDisponibili[i] == _gameId) {
                return i;
            }
        }
        // Se l'elemento non è stato trovato, restituisci una posizione maggiore della lunghezza dell'array
        return elencoGiochiDisponibili.length+1;
    }

    function distributePrizetoAll(int256 _gameId) public {
        info storage game = gameList[_gameId];
        uint256 betAmountPerPlayer = game.ethBalance /game.joiners.length;
        for (uint256 i = 0; i < game.joiners.length; i++) {
            address player = game.joiners[i];
            if (player != msg.sender) {
                payable(player).transfer(betAmountPerPlayer);
            }
        }
        if (game.creator != msg.sender) {
            payable(game.creator).transfer(betAmountPerPlayer);
        }
    }
    //returns true if the element is in the array
    function contains(address[] memory array, address element) internal pure returns (bool) {
        uint256 length = array.length;
        for (uint256 i = 0; i < length; i++) {
            if (array[i] == element) {
                return true;
            }
        }
        return false;
    }

    //remove an address from an array
    function remove(address[] memory array, address element) internal pure returns (address[] memory) {
        uint256 length = array.length;
        for (uint256 i = 0; i < length; i++) {
            if (array[i] == element) {
                array[i] = array[length - 1];
                assembly {
                    mstore(array, sub(length, 1))
                }
                return array;
            }
        }
        return array;
    }
    function removeFromGiochiDisponibili(int256 _gameId) public  returns (bool) {
        uint256 index = findIndex(_gameId);
        // Verifica se l'elemento è stato trovato e se il numero totale di partecipanti raggiunge il limite
        if (index < elencoGiochiDisponibili.length) {
                // Sostituisce l'elemento da rimuovere con l'ultimo elemento
                elencoGiochiDisponibili[index] = elencoGiochiDisponibili[elencoGiochiDisponibili.length - 1];
                // Rimuove l'ultimo elemento
                elencoGiochiDisponibili.pop();
                return true;

        }
        return false;
    }

    /** This code has been implemented to perform a table check. It should be implemented in a proper backend not to burn a huge amount of gas
    function uint8ToBytes32(uint8 _value) public pure returns (bytes32 result) {
        assembly {
            mstore(result, shl(248, _value)) // Shift left by 248 to pad with zeros
        }
    }

    function computeCardHash(uint8[24] memory card) internal pure returns (bytes32) {
        bytes memory cardBytes = new bytes(24 * 32);
        uint8 pos = 0;
        for (uint256 i = 0; i < 24; i++) {
            bytes32 elementBytes = uint8ToBytes32(card[i]); // uint to bytes
            for (uint256 k = 0; k < 32; k++) {
                cardBytes[pos] = elementBytes[k];
                pos++;
            }
        }
        return keccak256(cardBytes);
    }

    function isCardValid(int256 _gameId, uint8[24] memory card) internal view returns (bool, bytes32) {
        bool[75] memory numberSeen;
        bytes32 _cardHash = 0;
        _cardHash = computeCardHash(card);
        for (uint i = 0; i < gameList[_gameId].joiners.length; i++) {
            if (
                gameList[_gameId].joinersCardHashes[gameList[_gameId].joiners[i]] != 0 &&
                gameList[_gameId].joinersCardHashes[gameList[_gameId].joiners[i]] != _cardHash) {
                for (uint8 j = 0; j < 24; j++) {
                    if (COLS[j] == Cols.FIRST_COL && (card[j] < 1 || card[j] > 15)) {
                        return (false, bytes32(0));
                    } else if (COLS[j] == Cols.SECOND_COL && (card[j] < 16 || card[j] > 30)) {
                        return (false, bytes32(0));
                    } else if (COLS[j] == Cols.THIRD_COL && (card[j] < 31 || card[j] > 45)) {
                        return (false, bytes32(0));
                    } else if (COLS[j] == Cols.FOURTH_COL && (card[j] < 61 || card[j] > 75)) {
                        return (false, bytes32(0));
                    } else if (COLS[j] == Cols.FIFTH_COL && (card[j] < 46 || card[j] > 60)) {
                        return (false, bytes32(0));
                    }
                    if (numberSeen[card[j]-1]) {
                        return (false, bytes32(0));
                    }
                    numberSeen[card[j]-1] = true;
                }
            } else if (gameList[_gameId].joinersCardHashes[gameList[_gameId].joiners[i]] == _cardHash) {
                return (false, bytes32(0));
            }
        }
        return (true, _cardHash);
    }

    */
    /**************************************************************** */
    /**       Functions to handle main logic of game                 **/
    /**************************************************************** */

    function createGame(uint _maxJoiners, uint _betAmount, bytes32 _cardMerkleRoot) public payable {

        require(_maxJoiners > 0, "Max joiners must be greater than 0");
        require(_betAmount > 0, "Bet amount must be greater than 0");

        int256 gameID = getIDGame();
        info storage newGame = gameList[gameID];
        newGame.creator = msg.sender;
        newGame.joiners = new address[](0);
        newGame.maxJoiners = _maxJoiners;
        newGame.totalJoiners = 0;
        newGame.ethBalance = 0;
        newGame.betAmount = _betAmount;
        newGame.creatorMerkleRoot = _cardMerkleRoot;
        newGame.accusationTime = 0;
        newGame.accuser = address(0);

        // Initialize the creator's merkle root mapping
        newGame.joinerMerkleRoots[msg.sender] = 0;

        elencoGiochiDisponibili.push(gameID);

        newGame.ethBalance +=  _betAmount;

        emit GameCreated(gameID,newGame.maxJoiners,newGame.totalJoiners);
    }


    function joinGame(int256 _gameId, bytes32 _cardMerkleRoot) public {
        require(_gameId >= 0, "Game ID must be greater than 0!");
        require(elencoGiochiDisponibili.length > 0, "No available games!");
        int256 chosenGameId;
        if (_gameId == 0) {
            do {
                chosenGameId = getRandomGame();
            } while (gameList[chosenGameId].creator == msg.sender);

        } else {
            chosenGameId = _gameId;
        }
        //check if the game is available and if the player is not the creator
        require(chosenGameId > 0, "Chosen id negative!");
        require(gameList[chosenGameId].totalJoiners < gameList[chosenGameId].maxJoiners, "Game already taken!");
        require(gameList[chosenGameId].creator != msg.sender, "You can't join a game created by yourself!");
        require(gameList[chosenGameId].creatorMerkleRoot != _cardMerkleRoot, "Invalid merkle root!");
        for (uint i = 0; i < gameList[chosenGameId].joiners.length; i++) {
            require(
                gameList[chosenGameId]
                    .joinerMerkleRoots[gameList[chosenGameId]
                    .joiners[i]] != _cardMerkleRoot, "Invalid merkle root!");
        }
        //add the player to the game
        gameList[chosenGameId].joiners.push(msg.sender);
        gameList[chosenGameId].totalJoiners++;
        gameList[chosenGameId].ethBalance += gameList[chosenGameId].betAmount;
        gameList[chosenGameId].joinerMerkleRoots[msg.sender] = _cardMerkleRoot;

        emit GameJoined(
            chosenGameId,
            gameList[chosenGameId].creator,
            msg.sender,
            gameList[chosenGameId].maxJoiners,
            gameList[chosenGameId].totalJoiners,
            gameList[chosenGameId].ethBalance
        );
        if(gameList[chosenGameId].totalJoiners == gameList[chosenGameId].maxJoiners){
            removeFromGiochiDisponibili(chosenGameId);
            emit GameStarted(chosenGameId);
        }
    }

    function isExtracted(uint8[] memory numbersList, uint8 newNumber) internal pure returns(bool) {
        for (uint i = 0; i < numbersList.length; i++) {
            if (numbersList[i] == newNumber) return true;
        }
        return false;
    }

    function getNewNumber(int256 seed) internal view returns(uint8) {
        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, seed)));
        uint256 randomNumber = (randomHash % 75) + 1;
        return uint8(randomNumber);
    }

    function extractNumber(int256 _gameId,bool accused) public {
        require(gameList[_gameId].numbersExtracted.length <= 75, "All numbers have been extracted!");
        uint8 newNumber = getNewNumber(_gameId);
        int8 i = 1;
        while (isExtracted(gameList[_gameId].numbersExtracted, newNumber)) {
            newNumber = getNewNumber(_gameId+i);
            i++;
        }
        gameList[_gameId].numbersExtracted.push(newNumber);
        if(accused){
            gameList[_gameId].accusationTime = 0;
            gameList[_gameId].accuser = address(0);
        }
        if(gameList[_gameId].numbersExtracted.length < 75){
            emit NumberExtracted(_gameId, newNumber,false);
        }else{
            emit GameEnded(_gameId, gameList[_gameId].creator,WinningReasons.BINGO);        }
    }

    function accuse (int256 _gameId) public {
        require(_gameId > 0, "Game id is negative!");
        require(gameList[_gameId].creator!=msg.sender, "Creator cannot accuse!");
        require(contains(gameList[_gameId].joiners, msg.sender), "Player not in that game!");
        require(gameList[_gameId].accusationTime == 0, "Accusation already made!");
        gameList[_gameId].accusationTime = block.timestamp;
        gameList[_gameId].accuser = msg.sender;
        emit ReceiveAccuse(_gameId, msg.sender);
    }
    function checkaccuse(int256 _gameId) public {
    require(_gameId > 0, "Game id is negative!");
    require(gameList[_gameId].creator == msg.sender, "Only the Creator may accuse!");
    require(gameList[_gameId].accusationTime != 0, "Accusation not made");

    // Check if at least 5 seconds have passed since the accusation
    if (block.timestamp >= gameList[_gameId].accusationTime + 5) {
        // If more than 5 seconds have passed, handle end game logic

        // TODO: Pay all remaining players
        // Implement the logic to pay remaining players here

        emit GameEnded(_gameId, gameList[_gameId].creator, WinningReasons.CREATOR_STALLED);
    } else {
        emit Checked(_gameId, true);
    }
}



    // function amountEthDecision(int256 _gameId, bool _response) public payable {
    //     require(_gameId > 0, "Game id is negative!");
    //     address sender = msg.sender;
    //     require(gameList[_gameId].creator == sender || contains(gameList[_gameId].joiners, sender),
    //             "Player not in that game!"
    //     );

    //     if (!_response) {
    //         require(gameList[_gameId].creator != sender, "Creator cannot refuse their own game!");
    //         remove(gameList[_gameId].joiners,sender);
    //         elencoGiochiDisponibili.push(_gameId);
    //             //emith the amount eth refused
    //         emit AmountEthResponse(sender, gameList[_gameId].betAmount, _gameId, 0);
    //         } else {
    //             require(msg.value == gameList[_gameId].ethBalance, "ETH amount is wrong!");
    //             gameList[_gameId].betAmount += msg.value;
    //             //emit the amount eth accepted
    //             emit AmountEthResponse(sender, gameList[_gameId].ethBalance, _gameId, 1);
    //         }
    // }
    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function stringToUint(string memory s) public pure returns (uint256) {
        bytes memory b = bytes(s);
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            // Ensure the character is a digit
            require(b[i] >= 0x30 && b[i] <= 0x39, "Invalid character");
            result = result * 10 + (uint256(uint8(b[i])) - 48);
        }
        return result;
    }
    function submitCard(int256 _gameId, bytes32[][] memory _merkleProofs) public {
        require(_gameId > 0, "Game id is negative!");
        require(
            gameList[_gameId].creator == msg.sender || contains(gameList[_gameId].joiners, msg.sender),
            "Player not in that game!"
        );
        // require(
        //     (game.creator == msg.sender && game.creatorMerkleRoot == 0) ||
        //     (contains(gameList[_gameId].joiners, msg.sender) && game.joinerMerkleRoots[msg.sender] == 0),
        //     "Card already submitted!"
        // );
        bytes32 root = gameList[_gameId].creator == msg.sender
                       ? gameList[_gameId].creatorMerkleRoot
                       : gameList[_gameId].joinerMerkleRoots[msg.sender];

        for (uint8 i = 0; i < _merkleProofs.length; i++) {
            if (!verifyMerkleProof(root, bytes32ToString(_merkleProofs[i][0]), _merkleProofs[i], stringToUint(bytes32ToString(_merkleProofs[i][1])))){
                emit NotBingo(_gameId, msg.sender);
                return;
            }
        }
        emit GameEnded(_gameId, msg.sender, WinningReasons.BINGO);
    }

}
