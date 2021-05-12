# GameNight.jl

A small library of games to play over video-conference calls, motivated by the COVID-19 pandemic.

Contains the following games:

Game           | Command                                                   | Description
:------------: | :-------------------------------------------------------: | :---------:
Roll and Write | play_roll_and_write(["player 1", "player 2", "player 3"]) | A roll-and-write dice game compatible with materials for Qwixx.
Draw Again     | play_draw_again()                                         | A draw-and-write tile placement game compatible with materials for Second Chance
Word Search    | word_search(time_limit = 180)                             | A timed word search grid similar to Boggle
Tutti Frutti   | play_tutti_frutti(time_limit = 180)                       | A classic parlor game similar to the one published as Scattergories
Safehouses     | play_safehouses()                                         | A team-based guessing game compatible with materials for Codenames
Safehouses Duos| play_safehouses_duos()                                    | A two-player cooperative version of Safehouses
