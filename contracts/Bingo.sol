// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.19;
contract Bingo {
    struct info {
    address creator;
    address[] joiners;
    uint maxJoiners;
    uint totalJoiners;
    uint ethBalance;
    uint betAmount;
    bytes32 creatorMerkleRoot;
    bytes32 joinerMerkleRoots; //TODO: implementa piu persone
    uint accusationTime;
    address accuser;
    }
    uint256 public gameId = 0; // Game ID counter
    mapping(uint256 => info) public gameList; // Mapping of game ID to game info
    uint256[] public availableGames;    // List of available game IDs

    error OutputError(string myError); // event: error output
    event GameCreated(uint256 indexed _gameId); //  Event to log game creation
    
    
    //TODO: implementa piu persone
    event GameJoined(
        uint256 indexed _gameId,
        address _creator,
        address _joiner, 
        uint256 _maxjoiners,
        uint256 _totalJoiners,
        uint256 _ethAmount
    );
    event GameStarted(
        uint256 indexed _gameId,
            
    );
    //TODO: AGGIUNGI DIVERSI LOSERS
    event GameEnded(
        uint256 indexed _gameId,
        address _winner,
        address _loser,
        uint256 _reason
        );

    event ResolveAccuse(
        uint256 indexed _gameId,
        address _accuser
    );

    event AmountEthResponse(
        address _sender,
        uint256 _amount,
        uint256 indexed _gameId,
        uint256 _response
    );

    event GameEnded(uint256 indexed _gameId, address _winner);
    event GameCancelled(uint256 indexed _gameId);


    constructor() {
        // Add constructor code
    }
    
    function createGame(uint _maxJoiners, uint _betAmount)  public payable {
        require(_maxJoiners > 0, "Max joiners must be greater than 0");
        require(_betAmount > 0, "Bet amount must be greater than 0");

    
        uint256 gameID = getIDGame();
        info memory newGame;
        newGame.creator = msg.sender;
        newGame.joiners = new address[](0);
        newGame.maxJoiners = _maxJoiners;
        newGame.totalJoiners = 0;
        newGame.ethBalance = 0;
        newGame.betAmount = _betAmount;
        newGame.creatorMerkleRoot = 0;
        newGame.joinerMerkleRoots = 0; //TODO: aggiorna per piu utenti
        newGame.accusationTime = 0;
        newGame.accuser = address(0);
       
        gameList[gameID] = newGame;
           
        availableGames.push(gameID);
        gameList[gameID].ethBalance += msg.value;
        emit GameCreated(gameID);
    }
    

    function getIDGame() private returns(uint256 ) {
        return ++gameId;
    }
    function join(uint256 _gameId) external{
        
    }

    // Add other functions as needed
}