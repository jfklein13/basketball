# Basketball

This project is both a simple basketball simulator and a building block for adding both your own simulations, statistics and user interfaces. It is both meant as a toy for enjoying the back-and-forth of a basketball game and a starting point for developing your own basketball simulation ideas. You can even use this project to track a live basketball game, by plugging in a controller where you enter the results of each possession.

# Playing the Game

To get started, I recommend you use the [literate programming notebook](https://www.wolframcloud.com/env/jfklein/Published/BasketballSim.nb). To view the notebook without logging in, use its [object view](https://www.wolframcloud.com/obj/jfklein/Published/BasketballSim.nb).

This notebook is set to AutoCopy, so you'll get a strip across the top to create your own copy of the source so you can edit it. You will need a Wolfram Cloud account.

To play a game, download either the notebook (linked above) or the source file (which is the same code as in the notebook, but wrapped into a package), and open Mathematica (desktop or cloud). If you are using the source file, load the program:

```
Get["/path/to/download/basketball/Basketball.m"]
```

If you are using the notebook, evaluate each input cell (except the `p = g[gamestate]` which is meant to just be illustrative).

Then evaluate `runGame[]` to get the user interface:

![](https://raw.githubusercontent.com/jfklein13/basketball/master/screenshot.png)

* Click the "Next Possession" button to run the next possession.
* Click "+10 Possessions" to skip a bit.
* Click "New Game" to start over.

At any time you can examine the `gs` variable to see the current game state. To get the history of plays, use `gs["PossessionHistory"]` which is an association keyed by period (1, 2, `Overtime[1]`, etc.) giving a list of the possession results in that period. You can add statistics or make your own extended views using this information.
