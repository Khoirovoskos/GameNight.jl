# GameNight.jl

A small library of games to play over video-conference calls, motivated by the COVID-19 pandemic.

Contains the following games:

Game           | Command                                                     | Description
:------------: | :-------------------------------------------------------:   | :---------:
Safehouses     | `play_safehouses()`                                         | A team-based guessing game compatible with materials for Codenames
Safehouses Duos| `play_safehouses_duos()`                                    | A two-player cooperative version of Safehouses
Roll and Write | `play_roll_and_write(["player 1", "player 2", "player 3"])` | A roll-and-write dice game compatible with materials for Qwixx
Draw Again     | `play_draw_again()`                                         | A draw-and-write tile placement game compatible with materials for Second Chance
Word Search    | `word_search(time_limit = 180)`                             | A timed word search grid similar to Boggle
Tutti Frutti   | `play_tutti_frutti(time_limit = 180)`                       | A classic parlor game similar to the one published as Scattergories

## Installation Notes

These games are implemented in [the Julia language](https://julialang.org/). After installing and opening the Julia compiler, type the following into the command line: 
```
    using Pkg
    Pkg.add https://github.com/Khoirovoskos/GameNight.jl
    using GameNight
```

### Installation Details for Safehouses

Safehouses and Safehouses Duos rely on the [`gmailr` R package](https://cran.r-project.org/web/packages/gmailr/) and [RCall.jl](https://juliainterop.github.io/RCall.jl/stable/). Refer to those packages' respective documentation for installation details. The game host will need to replace the client_secret.json file in the assets folder with a Google API key, which can be obtained through developers.google.com.

## Usage Details for Games
*forthcoming*
### Roll and Write
Start game with `play_roll_and_write(player_name)`, where `player_names` is a vector of names formatted like `["Alice", "Bob", "Charlie"]`.
Once loaded, the host can advance through rolls or back up using the far-right and far-left buttons, respectively. Each die can be toggled as active or locked by clicking on it.

![Roll and Write board](/images/Roll and Write 1.jpg)
![Roll and Write board with one die locked](/images/Roll and Write 2.jpg)

### Draw Again
Start game with `play_draw_again()`. A pop-up window will appear with six text entry boxes. Enter up to six player names and then click the Start Game button. The game board will appear with starting cards for each player. 

![Specify player names in the pop-up window](/images/Draw Again 1.jpg)

After that, clicking the Draw Again button on the board will clear the board and draw two cards in the center column. Clicking on each player's name will draw another card for that player.

![Draw Again board](/images/Draw Again 2.jpg)

### Word Search

### Tutti Frutti

### Safehouses

### Safehouses Duos
