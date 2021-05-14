# GameNight.jl

A small library of games to play over video-conference calls, motivated by the COVID-19 pandemic.

Contains the following games:

Game           | Command                                                     | Description
:------------: | :-------------------------------------------------------:   | :---------:
Safehouses     | `play_safehouses()`                                         | A team-based guessing game compatible with materials for Codenames
Safehouses Duos| `play_safehouses_duos()`                                    | A two-player cooperative version of Safehouses
Roll and Write | `play_roll_and_write(["player 1", "player 2", "player 3"])` | A roll-and-write dice game compatible with materials for Qwixx
Draw Again     | `play_draw_again()`                                         | A draw-and-write tile placement game compatible with materials for Second Chance
Word Search    | `word_search(180)`                                          | A timed word search grid similar to Boggle
Tutti Frutti   | `play_tutti_frutti(180)`                                    | A classic parlor game similar to the one published as Scattergories

## Installation Notes

These games are implemented in [the Julia language](https://julialang.org/). After installing the Julia compiler, download this project as a ZIP folder and extract the GameNight.jl-main folder into Julia's bin folder. Do not re-name the folder.

Safehouses and Safehouses Duos rely on the [`gmailr` R package](https://cran.r-project.org/web/packages/gmailr/) and [RCall.jl](https://juliainterop.github.io/RCall.jl/stable/). Refer to those packages' respective documentation for installation details. The game host will need to replace the client_secret.json file in the assets folder with a Google API key, which can be obtained through developers.google.com.

The most reliable way to use RCall is to [download R](https://cran.r-project.org) and install it. Find and copy the path to the folder containing the R executable (e.g., C:/Program Files/R/R-4.0.5/bin/x64 on 64-bit Windows systems). Note that any backslashes (\\) need to be changed to forward slashes (/).

Run the R executable (Rgui) and run the following block of code:

```
if(!require(ggplot2)) {
    install.packages("ggplot2")
    require(ggplot2)
    }

if(!require(gmailr)) {
    install.packages("gmailr")
    require(gmailr)
    }
```

After the packages load, close Rgui.

Next, open the Julia console and type the following:

```
] activate GameNight.jl-main
include("GameNight.jl-main/src/GameNight.jl")
```

This last block of code will need to be run every time you open Julia to load the games.

## Usage Details for Games

### Safehouses
Start game with `play_safehouses()`. The host will be prompted to enter two e-mail addresses, one for each team's clue giver. Clue givers will receive their key cards via e-mail. Colors and symbols on the key cards indicate which cells on the board belong to each team. Red and Blue are the respective teams, Yellow are neutral, and Black is the assassin. Finding the assassin is an automatic game over. 

![Safehouses board](/images/key%20card.jpg)

A board will appear for all players to see, but the colors from the key card are hidden.

![Safehouses board](/images/Safehouses1.JPG)

Clue givers provide hints, and teams make their guesses. The host confirms guesses by clicking on a cell to reveal its color.

![Revealed Safehouses board](/images/Safehouses2.JPG)

*Note:* On some machines, Safehouses will randomly close during gameplay. If this happens, type `fig` in the Julia console to bring up the game again where you left off.

### Safehouses Duos
Start game with `play_safehouses_duos()`. Details are much the same as regular Safehouses, except there is an optional turn counter argument (defaults to 9 turns). Each player gets a different key card, and green are the two players' targets. The e-mail subject line indicates whether the receiving player is Player 1 or Player2.

The host clicks the button at the top of the board to toggle the active clue-giver. Player 1 gives clues (and Player 2 guesses) when the button reads "Player 1."

![Safehouses Duos board](/images/Safehouses%20Duos.JPG)

### Roll and Write
Start game with `play_roll_and_write(player_name)`, where `player_names` is a vector of names formatted like `["Alice", "Bob", "Charlie"]`.
Once loaded, the host can advance through rolls or back up using the far-right and far-left buttons, respectively. Each die can be toggled as active or locked by clicking on it.

![Roll and Write board](/images/Roll%20and%20Write%201.JPG)
![Roll and Write board with one die locked](/images/Roll%20and%20Write%202.JPG)

### Draw Again
Start game with `play_draw_again()`. A pop-up window will appear with six text entry boxes. Enter up to six player names and then click the Start Game button. The game board will appear with starting cards for each player. 

![Specify player names in the pop-up window](/images/Draw%20Again%201.JPG)

After that, clicking the Draw Again button on the board will clear the board and draw two cards in the center column. Clicking on each player's name will draw another card for that player.

![Draw Again board](/images/Draw%20Again%202.JPG)

*Note:* On some machines, Draw Again will randomly close during gameplay. If this happens, type `fig` in the Julia console to bring up the game again where you left off.

### Word Search
Start game with `word_search(time_limit)` where time_limit is a number of seconds to play. A window will appear with a grid of letters. After the time limit elapses, a pop-up window will notify players.

![Word Search grid](/images/Word%20Search.JPG)

### Tutti Frutti
Start game with `play_tutti_frutti(time_limit)` where time_limit is a number of seconds to play. A window will appear with a list of 12 prompts and a letter in the upper left corner. After the time limit elapses, a pop-up window will notify players.

![Tutti Frutti board](/images/Tutti%20Frutti.JPG)
