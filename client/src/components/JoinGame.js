import React, { useState, useEffect } from "react";
import { Button, Typography, CircularProgress, TextField } from "@mui/material";
import useEth from "../contexts/EthContext/useEth";
import toast from "react-hot-toast";
import Board from "./Board";
import { generateMerkleTree, generateCard, getMatrix } from "../services/TableService";

const JoinGame = ({ setView }) => {
  const mockTable = [
      [67, 24, 45, 82, 13],
      [91, 56, 78, 33, 42],
      [10, 99, "🆓", 29, 54],
      [73, 17, 88, 36, 25],
      [47, 59, 3, 80, 66]
  ]
  const { state: { contract, accounts } } = useEth();
  const [gameId, setGameId] = useState("");
  const [ethBet, setEthBet] = useState(0);
  const [maxJoiners, setMaxJoiners] = useState(0);
  const [totalJoiners, setTotalJoiners] = useState(0);
  const [infoFetched, setInfoFetched] = useState(false);
  const [loading, setLoading] = useState(false);
  const [waitingForPlayers, setWaitingForPlayers] = useState(false);
  const [error, setError] = useState("");
  const [gameStarted, setGameStarted] = useState(false);
  const [card, setCard] = useState();
  const [cardMatrix, setCardMatrix] = useState();
  const [gameEnded, setGameEnded] = useState(false);
  const [removed, setRemoved] = useState(false);
  const re = /^[0-9\b]+$/;

  const joinGame = () => {
    setLoading(true);
    let _card = generateCard();
    setCard(_card);
    setCardMatrix(getMatrix(_card));
    let merkleTree = generateMerkleTree(_card);
    contract.methods.joinGame(parseInt(gameId), `0x${merkleTree[merkleTree.length - 1][0]}`).send({ from: accounts[0], gas: 20000000 })
      .then((logArray) => {
        console.log(parseInt(logArray.events.GameJoined.returnValues._gameId));
        setLoading(false);
        setWaitingForPlayers(true);
      })
      .catch((error) => {
        console.error("Error joining game:", error);
        setLoading(false);
        toast.error("Non posso entrare nel gioco selezionato!")
        setGameId("")
    });
  };
  const denunciaCreator = () => {
    contract.methods.denunciaCreator(parseInt(gameId)).send({ from: accounts[0], gas: 20000000 })
      .then((logArray) => {
        console.log(parseInt(logArray.events.EventDenunciaCreator.returnValues._gameId));
        toast.success("Il creatore e' stato denunciato!");
        const timeOut =  setTimeout(() => {
            contract.methods.RiDenunciaCreator(parseInt(gameId)).send({ from: accounts[0], gas: 20000000 })
                .then((logArray) => {
                    console.log(parseInt(logArray.events.ConfermaDenuncia.returnValues._gameId));

                }).catch((error) => {
                    console.error("Error joining game:", error);
                    setLoading(false);
                    toast.error("Non posso ottenere la conferma della denuncia!")
                    setGameId("")
            });
        }, 10000);
        //clearTimeout(timeOut);
      })
      .catch((error) => {
        console.error("Error joining game:", error);
        setLoading(false);
        toast.error("Non posso denunciare!")
        setGameId("")
    });
  };


  const getInfoGame = () => {
    setLoading(true);
    contract.methods.getInfoGame(parseInt(gameId)).send({ from: accounts[0], gas: 20000000 })
      .then((logArray) => {
        console.log(parseInt(logArray.events.GetInfo.returnValues._gameId));
        setEthBet(parseInt(logArray.events.GetInfo.returnValues._ethAmount));
        setMaxJoiners(parseInt(logArray.events.GetInfo.returnValues._maxjoiners));
        setTotalJoiners(parseInt(logArray.events.GetInfo.returnValues._totalJoiners));
        setInfoFetched(true);
        setLoading(false);
      })
      .catch((error) => {
        console.error("Error fetching game info:", error);
        setLoading(false);
        toast.error("Non trovo il gioco selezionato!")
        setGameId("")
    });
  };

  useEffect(() => {
    try {
      contract._events.GameStarted().on('data', event => {
          // console.log('Event received:', event);
          // console.log(event.returnValues);
          setGameStarted(true)
      }).on('error', console.error);
    } catch {}
    try {
        contract._events.CreatorRemoved().on('data', event => {
            if(parseInt(event.RemoveCreator.returnValues._result)){//se e' true allora il creatore e' stato rimosso dal game quindi termino il gioco
                setGameEnded(true);
                //TODO: aggiungi schermata per dire che il giocatore ha vinto dei soldi. il totale e' ethBet/totaleJoiners
                setView("");//torno alla schermata iniziale
                }
        }).on('error', console.error);
      } catch {}

  }, [contract]);

  return (
    <div className="flex justify-center items-center h-screen">
      {!gameStarted ? waitingForPlayers ? (
        <div className="grid grid-rows-2 gap-4">
          <h1 className="text-center text-2xl text-white">Aspetto che altri giocatori si connettano!</h1>
          <CircularProgress className="m-auto" />
        </div>
      ) : (
        <div className="grid grid-cols-1 gap-4">
          {!infoFetched ? (
            <div className="grid grid-cols-1 gap-4">

              <input
                value={gameId}
                placeholder="Game ID"
                className="text-field"
                onChange={(e) => {
                //   setError("");
                if (e.target.value === "" || re.test(e.target.value))
                  setGameId(e.target.value);
                }}
                id="outlined-basic"
                label="Game ID"
                // variant="outlined"
                // error={!!error}
                // helperText={error}
              />
              <Button
                variant="contained"
                className="dark:bg-blue-500 dark:hover:bg-blue-600 bg-blue-400
                                   hover:bg-blue-500 text-white items-center shadow-xl
                                    transition duration-300 dark:disabled:bg-gray-500 disabled:bg-gray-300"
                onClick={getInfoGame}
                disabled={loading || gameId.trim() === "" || gameId === "0"}
              >
                {loading ? 'Loading...' : 'Fetch Game Info'}
              </Button>
              <Button
              variant="outlined"
              className="dark:border-blue-500 dark:hover:border-blue-600
                            dark:text-blue-500 dark:hover:text-blue-600
                            border-blue-400 hover:border-blue-500
                            text-blue-400 hover:text-blue-500
                            items-center shadow-xl
                            transition duration-300"
              onClick={() => setView("")}>Back</Button>
            </div>
          ) : (
            <div>
              <Typography className="text-black dark:text-white" variant="h6">Game ID: {gameId}</Typography>
              <Typography className="text-black dark:text-white" variant="h6">ETH Bet: {ethBet}</Typography>
              <Typography className="text-black dark:text-white" variant="h6">Max Joiners: {maxJoiners}</Typography>
              <Typography className="text-black dark:text-white" variant="h6">Total Joiners: {totalJoiners}</Typography>
              <div className="grid grid-cols-2 gap-4">
                <Button
                  variant="contained"
                  onClick={joinGame}
                  className="dark:bg-blue-500 dark:hover:bg-blue-600 bg-blue-400 hover:bg-blue-500 text-white items-center shadow-xl transition duration-300 dark:disabled:bg-gray-500 disabled:bg-gray-300"
                  disabled={gameId.trim() === "" || loading || gameId === "0"}
                >
                  {loading ? 'Joining...' : 'Join Game'}
                </Button>
                <Button
                  className="dark:border-blue-500 dark:hover:border-blue-600 dark:text-blue-500 dark:hover:text-blue-600 border-blue-400 hover:border-blue-500 text-blue-400 hover:text-blue-500 items-center shadow-xl transition duration-300"
                  variant="outlined"
                  onClick={() => setInfoFetched(false)}
                >
                  Torna indietro
                </Button>
              </div>
            </div>
          )}
        </div>
      ) : (
        <div className="flex items-start gap-4"> {/* Applica flexbox e aggiungi gap tra gli elementi */}
        <Board size={5} table={cardMatrix}/>
        <Button
          variant="contained"
          onClick={denunciaCreator}
          className="dark:bg-blue-500 dark:hover:bg-blue-600 bg-blue-400 hover:bg-blue-500 text-white items-center shadow-xl transition duration-300 dark:disabled:bg-gray-500 disabled:bg-gray-300"
          disabled={gameId.trim() === "" || loading || gameId === "0"}
        >
          Denuncia Creator
        </Button>
      </div>
    )}
    </div>
  );
};

export default JoinGame;
