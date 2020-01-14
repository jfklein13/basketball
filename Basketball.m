(* Wolfram Language Package *)

BeginPackage["Basketball`"]

initialGameState::usage = "initialGameState is an initial game state using the defaults for a U.S. men's college basketball game.";

Overtime::usage = "Overtime[n] represents the nth overtime period.";

Final::usage = "Final represents that a game is over.";

gameIsOverQ::usage = "gameIsOverQ[state] returns True if the given game state represents a game that is completed.";

updateGameState::usage = "updateGameState[state, p] returns the next game state starting from a given state and applying the result of a given possession.";

generatePossession::usage = "generatePossession[state] gives the result of a single possession using a simple random model.";

runPossession::usage = "runPossession[state] applies generatePossession to the given state and returns the next game state.";

(* TODO add a function to run a complete game without a user interface *)

runGame::usage = "runGame[]";

Begin["`Private`"] (* Begin Private Context *) 

initialGameState = <|
	"Score" -> <|"Home" -> 0, "Away" -> 0|>,
	"Period" -> 1,
	"PeriodClock" -> {20, 0},
	"Possession" -> "Away",
	"PossessionArrow" -> "Home",
	"PeriodsInGame" -> 2,
	"MinutesInPeriod" -> 20,
	"MinutesInOvertime" -> 5,
	"PossessionHistory" -> <||>
|>;

gameIsOverQ[gs_] :=
	periodClockSeconds[gs] <= 0.0 && 
	(gs["Period"] === gs["PeriodsInGame"] || 
		MatchQ[gs["Period"], Final | _Overtime]) && 
	UnsameQ @@ Values[gs["Score"]]

periodClockSeconds[gs_?AssociationQ] := 
	periodClockSeconds[gs["PeriodClock"]]

periodClockSeconds[{min_, sec_}] := min*60 + sec

updateGameState[gs_, 
	p : KeyValuePattern[{"Team" -> team_, "Elapsed" -> telapsed_}]] :=
	With[{newClockAndPeriod = advanceGameClockAndPeriod[gs, telapsed]},
		Join[gs,
			newClockAndPeriod,
			<|
				"Possession" -> 
					Replace[team, {"Home" -> "Away", "Away" -> "Home"}],
				"Score" -> updateScore[gs, p["Result"]],
				"PossessionHistory" ->
				With[{history = gs["PossessionHistory"]},
					Append[history, 
						gs["Period"] -> 
							Append[Lookup[history, gs["Period"], {}], p]
					]
				]
			|>
		]
	]

advanceGameClockAndPeriod[gs_,tseconds_?QuantityQ] :=
    With[ {newclock = advanceGameClock[gs,tseconds]},
        If[ periodClockSeconds[newclock]>0,
        (* there's still time on the clock *)
            Append[KeyTake[gs,"Period"],"PeriodClock"->newclock],
            (* clock has expired, advance the period *)
            advancePeriod[Append[gs,"PeriodClock"->newclock]]
        ]
    ]

advanceGameClock[gs_,tseconds_?QuantityQ] :=
    toMinutesSeconds[
    	Max[periodClockSeconds[gs] - QuantityMagnitude[tseconds],0]
    ]

toMinutesSeconds[tseconds_] :=
    With[{t = Round[tseconds,0.1]},
        {Floor[t/60.],Mod[t,60.]}
    ]

advancePeriod[gs_] :=
	If[gameIsOverQ[gs],
		<|"Period" -> Final, "PeriodClock" -> {0, 0}|>,
		With[{period = advancePeriod[gs["Period"], gs["PeriodsInGame"]]},
			<|
				"Period" -> period, 
				"PeriodClock" -> 
					{
						If[IntegerQ[period], 
							gs["MinutesInPeriod"], 
							gs["MinutesInOvertime"]
						], 
						0
					}
			|>
		]
	]

advancePeriod[n_Integer, ppg_] := If[n < ppg, n + 1, Overtime[1]]

advancePeriod[Overtime[n_], _] := Overtime[n + 1]

advancePeriod[Final, _] := Final

updateScore[gs_, Score[type_, ___]] :=
	With[{team = gs["Possession"], score = gs["Score"]},
		Append[score, 
			team -> 
				(score[team] + Replace[type, {"3PtJumpShot" -> 3, _ -> 2}])
		]
	]

updateScore[gs_, _] := gs["Score"]

generatePossession[gs_] :=
	<|
		"Team" -> gs["Possession"],
		"Start" -> gs["PeriodClock"],
		"Elapsed" -> Quantity[RandomReal[{0, 35}], "Seconds"], 
		"Result" -> 
			RandomChoice[
		    	With[{fgpct = 0.4}, 
		    		{fgpct, 1.0 - fgpct}
		    	] -> {Score["Jumper", 1], MissedShot["Jumper", 2]}
		    ]
	|>

runPossession[gamestate_] :=
	updateGameState[gamestate, generatePossession[gamestate]]

(********************************************************************)
(* User interface to run a game *)

runGame[] := 
(
	gs = initialGameState;
	Dynamic[
		Grid[
			{
				{
					Dataset[<|
						"Away" -> gs["Score", "Away"], 
						"Home" -> gs["Score", "Home"], 
						"Clock" -> viewClockAndPeriod[gs], 
						"Last Play:" -> 
							Replace[gs["PossessionHistory", gs["Period"]], {
								{___, p_} :> 
									viewPlay[KeyTake[p, {"Team", "Result"}]], 
								_ :> ""
							}]
					|>], 
					SpanFromLeft
				},
				{
					Row[{
						Button["Next Possession", gs = runPossession[gs]], 
						Button["+10 Possessions", Do[gs = runPossession[gs], {10}]]
					}], 
					Button["New Game", gs = initialGameState]
				}
			}, Alignment -> Left
		]
	]
)

viewClockAndPeriod[gs_] := viewClock[gs] <> " " <> viewPeriod[gs]

viewClock[gs_?AssociationQ] :=
	With[{clock = gs["PeriodClock"]},
		StringJoin[format2Digit@First[clock], ":", format2Digit@Ceiling[Last[clock]]]
	]

format2Digit[n_] := IntegerString[n, 10, 2]

viewPeriod[gs_?AssociationQ] := viewPeriod[gs["Period"]]

viewPeriod[p_Integer] := 
	StringJoin[ToString[p], Replace[p, ordinals], " ", 
		Switch[gs["PeriodsInGame"], 2, "Half", 4, " Quarter", _, "Period"]
	]

ordinals = {1 -> "st", 2 -> "nd", 3 -> "rd", _ -> "th"};

viewPeriod[Overtime[1]] := "OT"

viewPeriod[Overtime[n_]] := "OT" <> ToString[n]

viewPeriod[Final] := "Final"

viewPlay[result : KeyValuePattern["Result" -> MissedShot[type_, n_]]] := 
	Row[{result["Team"], ": #", n, " missed ", ToLowerCase[type]}]

viewPlay[result : KeyValuePattern["Result" -> Score[type_, n_]]] := 
	Row[{result["Team"], ": #", n, " made ", ToLowerCase[type]}]

viewPlay[other_] := other

End[] (* End Private Context *)

EndPackage[]
