using Gtk, CSV, RCall, GLMakie, AbstractPlotting, Colors, JSON, Random
# R instance requires ggplot2, and gmailr

# Read Gmail token and send to R environment
function read_secret(secret_location)
  secret_json = JSON.parse(read(secret_location, String))
  secret_val = secret_json["installed"]["client_secret"]
  key_val = secret_json["installed"]["client_id"]
  @rput secret_val key_val
end

R"""
if(!require(ggplot2)) {
    install.packages("ggplot2")
    require(ggplot2)
    }

if(!require(gmailr)) {
    install.packages("gmailr")
    require(gmailr)
    }

send_key_card <- function(giver1 = NULL, giver2 = NULL, sender = "safehouses@gmail.com", key = key_val, secret = secret_val) {

  if (is.null(giver1) || is.null(giver2)) {warning("Two clue givers must be designated!")} 
  
  # Determine whether team 1 (blue) or team 2 (red) goes first
  first <- sample(1:2, 1)
  
  # Create coordinates for key grid and colors for each space
  KEY_LAYOUT <<- expand.grid(1:5, LETTERS[1:5])
  KEY_LAYOUT$content <<- sample(c(
    rep(1, 8), 
    rep(2, 8), 
    rep(3, 7), 
    0, 
    first), 
  size = 25, 
  replace = FALSE)
  
  # Create key card to send out, with spaces colored according to value
  key_card <- ggplot(KEY_LAYOUT, aes(x = 0, y = 0, label = c("X", "B", "R", "Y")[content + 1], fill = as.factor(content), size = 12)) + 
      geom_tile(alpha = .5) + 
      geom_text(aes(colour = as.factor(content)), size = 12, alpha = .75) +
      facet_grid(Var2~Var1, switch = "y") + 
      scale_fill_manual(values = c("black", "blue", "red", "yellow")) + theme_bw() +
      scale_colour_manual(values = c("black", "blue", "red", "black")) + theme_bw() +
      theme(legend.position = "none", 
  	   axis.text = element_blank(), 
  		axis.ticks.length = unit(0, "in"), 
  		axis.title = element_blank(), 
  		strip.background = element_rect(
  		  colour = c(rgb(0, 0, 1, .5), rgb(1, 0, 0, .5))[first], 
  		  size = 2, 
  		  fill = "transparent"), 
  		panel.border = element_blank(), 
  		panel.spacing = unit(.05, "cm"), 
  		panel.grid = element_blank(), 
  		strip.text = element_text(size = 16), 
  		strip.text.y = element_text(angle = 180))
  		
  # Save card image to disk
  ggsave("key card.jpg", key_card, width = 5, height = 5, units = "in")
  
  # Timestamp to coordinate cards if multiple sent out in a short time
  timeStamp <- Sys.time()
  
  # Prepare e-mails and send card as attachment to specified clue givers
  gm_auth_configure(key = key_val, secret = secret_val)
  email <- gm_mime() %>%
      gm_to(giver1) %>%
      gm_from(sender) %>%
      gm_subject("Key Card") %>%
      gm_text_body(sprintf("Generated at %s", timeStamp)) %>%
      gm_attach_file("key card.jpg")
  gm_send_message(email)
  
  email <- gm_mime() %>%
      gm_to(giver2) %>%
      gm_from("cbjuarez8@gmail.com") %>%
      gm_subject("Key Card") %>%
      gm_text_body(sprintf("Generated at %s", timeStamp)) %>%
      gm_attach_file("key card.jpg")
  gm_send_message(email)
}
"""

# Timer

function timer(length::Int = 0)
  # Simple timer with text progress bar. Produces notification window when time expires.
  for i in 1:50
    sleep(length / 50)
	  print("\r" * "=" ^ i * " " ^ (50 - i) * "|" * string(Int(trunc(length - length * i / 50))) * " s remaining     ")
  end
  win = GtkWindow("Timer", 400, 200)
  b = GtkButton("Time's up!")
  push!(win,b)
  showall(win)
end

# Set up Makie plotting environment
GLMakie.activate!()
AbstractPlotting.inline!(false)
set_window_config!(vsync = false)
fig = Figure(resolution = (1200, 900))
# Axes and player subplots for Draw Again
ax = []
ax2 = []
player_grids = []
fig

# Set global turn counter for roll_and_write
turn = [1]

# roll_and_write

function play_roll_and_write(player_list::Array{String, 1})
  # Pre-fill rolls based on number of players
  roll_and_write_rolls = [repeat(player_list, 48), rand(1:6, 6, 48 * size(player_list)[1])]

  # Colors for dice when unlocked
  cellcolors = [:grey, RGBf0(0.94, 0.5, 0.5), RGBf0(1, 1, 0), RGBf0(0.25, 0.94, 0.25), RGBf0(0.5, 0.5, 0.94), :white, :white, :grey]
  
  global turn = turn
  turn = [1]
  
  global fig = fig
  fig = Figure(resolution = (1200, 900))
  supertitle = fig[0, :] = Label(fig, player_list[1], textsize = 30)

  # Each die is a button, plus forward and back buttons
  fig[2,:] = buttongrid = GridLayout(tellwidth = false)
  buttonlabels = string.(["<", roll_and_write_rolls[2][:, 1]..., ">"])
  buttons = buttongrid[1, 1:8] = [Button(fig, label = buttonlabels[i], height = 175, width = 200, textsize = 40.0f0, buttoncolor = cellcolors[i], buttoncolor_hover = cellcolors[i], strokecolor = :black) for i = 1:8]
  
  # Back button decrements turn counter, plays silly message to tease players
  on(buttons[1].clicks) do n
    global turn = turn
    if turn[1] >= 2
	    turn[1] -= 1
	    for i in 2:7
	      buttons[i].label = string.(roll_and_write_rolls[2][i - 1, turn[1]])
	    end
	    supertitle.text = roll_and_write_rolls[1][turn[1]]
	  end
  end
  
  # Forward button increments turn counter, plays chime to notify players
  on(buttons[8].clicks) do n
    global turn = turn
    if turn[1] <= size(roll_and_write_rolls[2])[2]
	    turn[1] += 1
	    for i in 2:7
	      buttons[i].label = string.(roll_and_write_rolls[2][i - 1, turn[1]])
	    end
	    supertitle.text = roll_and_write_rolls[1][turn[1]]
	  end
  end
  
  # Clicking the colored dice toggles between locked (black) and unlocked (default color)
  for i in 2:5
    on(buttons[i].clicks) do n
      buttons[i].buttoncolor = 
	    colordiff(buttons[i].buttoncolor[], RGBf0(0, 0, 0)) == 0 ? cellcolors[i] : RGBf0(0, 0, 0)
	  end
  end

  fig

end

# word_search

function word_search(time_limit = 0)
  dice = [  
  ["C", "O", "T", "U", "I", "M"],
  ["L", "R", "T", "T", "E", "Y"],
  ["R", "H", "N", "Z", "L", "N"],
  ["S", "I", "E", "T", "O", "S"],
  ["E", "R", "Y", "L", "V", "D"],
  ["L", "R", "D", "X", "I", "E"],
  ["T", "O", "T", "O", "A", "W"],
  ["V", "E", "T", "R", "H", "W"],
  ["C", "A", "P", "S", "H", "O"],
  ["K", "P", "S", "F", "A", "F"],
  ["W", "E", "E", "H", "N", "G"],
  ["Y", "I", "T", "D", "T", "S"],
  ["S", "E", "I", "N", "E", "U"],
  ["H", "M", "N", "Qu", "I", "U"],
  ["N", "A", "E", "A", "G", "E"],
  ["J", "O", "B", "B", "A", "O"]
  ]
  
  # Randomly permute dice and select a face from each die. Supplies coordinates for plotting in a grid
  values = [repeat(1:4, outer = 4) repeat(1:4, inner = 4) shuffle(map(x -> rand(x, 1)[1], dice))]
  
  #Set figure dimensions and hide axes
  f = Figure(resolution = (900, 900))
  ax = Axis(f[1, 1], aspect = AxisAspect(1))
  hidedecorations!(ax)
  
  # Place letters into grid
  for i in 1:16
    text!(values[i, 3], position = (values[i, 1] - 2.5, values[i, 2] - 2.5), align = (:center, :center), textsize = .75)
  end
  
  display(f)

  # Run timer if time limit greater than 0, otherwise play untimed game.
  if time_limit > 0
    timer(time_limit)
  end
end

# Tutti Frutti

# Create game counter to reduce number of repeated prompts
tutti_frutti_game = [0]

# Read prompts from file and randomize
prompts = shuffle(CSV.File("GameNight/assets/prompts.csv", header = false).Column1)

function play_tutti_frutti(time_limit = 0)
  # Select current set of prompts based on game number
  current_prompts = prompts[(12 * tutti_frutti_game[1] + 1):(12 * tutti_frutti_game[1] + 12)]
  # Select key letter for responses
  letter = "ABCDEFGHIJKLMNOPRSTW"[rand(1:20, 1)]
  
  f = Figure(resolution = (1200, 900))
  Axis(f[1, 1], aspect = DataAspect())

  # Plot prompts on screen
  for i in 12:-1:1
    text!(last("00" * string(13 - i), 2) * ". " * current_prompts[i], position = (1, i), align = (:left, :center), textsize = 1)
  end

  # Add key letter to screen  
  f[1, 1, TopLeft()] = Label(f, letter, textsize = 72, halign = :right)

  display(f)
  
  # Run timer if time limit greater than 0; otherwise play untimed game
  if time_limit > 0
    timer(time_limit)
  end
  
  # Increment game counter for next round.
  tutti_frutti_game[1] += 1
  
  # If game counter runs over number of prompts, reset prompts and start over
  if (tutti_frutti_game[1] * 12 + 12) > size(prompts)[1]
    tutti_frutti_game[1] = 0
  end
end

# safehouses

# Read in list of words and shuffle
word_list = shuffle(CSV.File("GameNight/assets/words.csv").word)

# Set game counter to track games and reduce repetition of words
safehouses_game = [0]

# Array contains the following values: x and y coordinates, hidden value of each cell, word to display, and an indicator whether each cell has been revealed to players
function create_word_matrix()
  coords = [repeat(1:5, inner = 5) repeat(1:5, outer = 5) [R"KEY_LAYOUT$content"...] word_list[(25 * safehouses_game[1] + 1):(25 * safehouses_game[1] + 25)] repeat([0], 25)]
end 

function play_safehouses(secret_path = "GameNight/assets/client_secret.json")
  read_secret(secret_path)
  println("E-mail address of first clue giver:")
  email_1 = readline()
  println("E-mail address of second clue giver:")
  email_2 = readline()
  @rput email_1 email_2
  R"send_key_card(giver1 = email_1, giver2 = email_2)"
  cards = create_word_matrix()
  
  # increment game counter
  global safehouses_game = safehouses_game
  safehouses_game[1] += 1

global fig = fig
fig = Figure(resolution = (1200, 900))

# Create matrix of buttons to represent cards
fig[:,:] = buttongrid = GridLayout(tellwidth = false)
buttonlabels = cards[:, 4]
buttons = buttongrid[1:5, 1:5] = [Button(fig, label = l, height = 175, width = 300, textsize = 40.0f0, buttoncolor_active = RGBf0(0.94, 0.94, 0.94), buttoncolor_hover = RGBf0(0.94, 0.94, 0.94)) for l in buttonlabels]

# Make sure all cards start out 'untouched'
cards[:, 5] .= 0

for i in 1:25
  on(buttons[i].clicks) do n
# Clicking each button turns the color to match the key card
    buttons[i].buttoncolor = [:black, :blue, :red, :yellow][Int(cards[Int(i), 3] + 1)] 
	  buttons[i].buttoncolor_active = [:black, :blue, :red, :yellow][Int(cards[Int(i), 3] + 1)] 
	  buttons[i].buttoncolor_hover = [:black, :blue, :red, :yellow][Int(cards[Int(i), 3] + 1)] 
	  buttons[i].labelcolor = [:white, :white, :black, :black][Int(cards[Int(i), 3] + 1)] 
# Marks card as revealed, counts as point for corresponding team
	  cards[Int(i), 5] = 1
	    if cards[Int(i), 3] == 0 # Assassin: Game Over
	      win = GtkWindow("safehouses", 400, 200)
        game_result = uppercase(buttonlabels[i]) * " was the Assassin! Game Over!"
        b = GtkButton(game_result)
        push!(win,b)
        showall(win)		  
        elseif minimum(cards[cards[:, 3] .== 1, 5]) == 1 # All blue team cards revealed
  	  	  win = GtkWindow("safehouses", 400, 200)
          game_result = "Blue team wins!"
	    	  b = GtkButton(game_result)
          push!(win,b)
  	  	  showall(win)
        elseif minimum(cards[cards[:, 3] .== 2, 5]) == 1 # All red cards revealed
	    	  win = GtkWindow("safehouses", 400, 200)
          game_result = "Red team wins!"
	    	  b = GtkButton(game_result)
          push!(win,b)
	  	    showall(win)
        end
      end
    end
  # Manually opening figure versus opening as function side effect seems to be more stable
  display(fig)
end

# safehouses duos

# Is current player 1 or 2?
current_player = false
# Track number of turns for time limit
duos_turn = 1

R"""
if(!require(ggplot2)) {
    install.packages("ggplot2")
    require(ggplot2)
    }

if(!require(gmailr)) {
    install.packages("gmailr")
    require(gmailr)
    }

send_duos_card <- function(giver1 = NULL, giver2 = NULL, sender = "safehouses@gmail.com", key = key_val, secret = secret_val) {

if (is.null(giver1) || is.null(giver2)) {warning("Two clue givers must be designated!")} 

KEY_LAYOUT <<- as.data.frame(expand.grid(1:5, LETTERS[1:5]))

# Use randomized vector so each player's card corresponds appropriately to the other's
randomizer <- sample(1:25)

# Create key cards for each player
# 0 => Assassin, 1 => Agent, 2 => Bystander
KEY_LAYOUT$player_1 <<- c(
  rep(1, 5), 
  rep(2, 5), 
  0, 
  2, 
  0, 
  rep(1, 4), 
  0, 
  rep(2, 7)
)[randomizer]

KEY_LAYOUT$player_2 <<- c(
  rep(2, 5),
  rep(1, 5),
  rep(0, 2),
  2,
  rep(1, 3),
  0,
  1,
  rep(2, 7)
)[randomizer]

card_1 <- ggplot(KEY_LAYOUT, aes(x = 0, y = 0, label = c("X", "G", "Y")[player_1 + 1], fill = as.factor(player_1), size = 12)) + 
  geom_tile(alpha = .5) + 
  geom_text(aes(colour = as.factor(player_1)), size = 12, alpha = .75) +
  facet_grid(Var2~Var1, switch = "y") + 
  scale_fill_manual(values = c("black", "darkgreen", "yellow")) + theme_bw() +
  scale_colour_manual(values = c("black", "darkgreen", "black")) + theme_bw() +
  theme(legend.position = "none", 
        axis.text = element_blank(), 
        axis.ticks.length = unit(0, "in"), 
        axis.title = element_blank(), 
        strip.background = element_blank(), 
        panel.border = element_blank(), 
        panel.spacing = unit(.05, "cm"), 
        panel.grid = element_blank(), 
        strip.text = element_text(size = 16), 
        strip.text.y = element_text(angle = 180))

card_2 <- ggplot(KEY_LAYOUT, aes(x = 0, y = 0, label = c("X", "G", "Y")[player_2 + 1], fill = as.factor(player_2), size = 12)) + 
  geom_tile(alpha = .5) + 
  geom_text(aes(colour = as.factor(player_2)), size = 12, alpha = .75) +
  facet_grid(Var2~Var1, switch = "y") + 
  scale_fill_manual(values = c("black", "darkgreen", "yellow")) + theme_bw() +
  scale_colour_manual(values = c("black", "darkgreen", "black")) + theme_bw() +
  theme(legend.position = "none", 
        axis.text = element_blank(), 
        axis.ticks.length = unit(0, "in"), 
        axis.title = element_blank(), 
        strip.background = element_blank(), 
        panel.border = element_blank(), 
        panel.spacing = unit(.05, "cm"), 
        panel.grid = element_blank(), 
        strip.text = element_text(size = 16), 
        strip.text.y = element_text(angle = 180))
		
ggsave("key card 1.jpg", card_1, width = 5, height = 5, units = "in")
ggsave("key card 2.jpg", card_2, width = 5, height = 5, units = "in")

timeStamp <- Sys.time()

gm_auth_configure(key = key, secret = secret)
email <- gm_mime() %>%
    gm_to(giver1) %>%
    gm_from(sender) %>%
    gm_subject("Key Card for Player 1") %>%
    gm_text_body(sprintf("Generated at %s", timeStamp)) %>%
    gm_attach_file("key card 1.jpg")
gm_send_message(email)

email <- gm_mime() %>%
    gm_to(giver2) %>%
    gm_from("cbjuarez8@gmail.com") %>%
    gm_subject("Key Card for Player 2") %>%
    gm_text_body(sprintf("Generated at %s", timeStamp)) %>%
    gm_attach_file("key card 2.jpg")
gm_send_message(email)
}
"""

# Each player's value is a separate column in the layout matrix
function create_duos_matrix()
  coords = [repeat(1:5, outer = 5) repeat(1:5, inner = 5) [R"KEY_LAYOUT$player_1"...] [R"KEY_LAYOUT$player_2"...] word_list[(25 * safehouses_game[1] + 1):(25 * safehouses_game[1] + 25)] repeat([:grey94], 25) repeat([:grey94], 25)]
end 

function play_safehouses_duos(secret_path = "GameNight/assets/client_secret.json", turn_limit = 9)
  read_secret(secret_path)
  println("E-mail address of first clue giver:")
  email_1 = readline()
  println("E-mail address of second clue giver:")
  email_2 = readline()
  @rput email_1 email_2
  R"send_duos_card(giver1 = email_1, giver2 = email_2)"
  cards = create_duos_matrix()
  
  global safehouses_game = safehouses_game
  safehouses_game[1] += 1
  
  global current_player = current_player
  current_player = false
  
  global fig = fig
  fig = Figure(resolution = (1200, 900))
  
  fig[:,:] = buttongrid = GridLayout(tellwidth = false)  
  buttonlabels = cards[:, 5]
  buttons = buttongrid[1:5, 1:5] = [Button(fig, label = l, height = 125, width = 300, textsize = 40.0f0, buttoncolor_active = :grey94, buttoncolor_hover = :grey94) for l in buttonlabels]
  
  for i in 1:25
    on(buttons[i].clicks) do n
    # Clicking a cell sets the color to the value for the current clue giver
  	    buttons[i].buttoncolor_active =     [:black, :green, :yellow][Int(cards[Int(i), 3 + current_player] + 1)]
        buttons[i].buttoncolor =            [:black, :green, :yellow][Int(cards[Int(i), 3 + current_player] + 1)]
  	    buttons[i].buttoncolor_hover =      [:black, :green, :yellow][Int(cards[Int(i), 3 + current_player] + 1)]
  	    buttons[i].labelcolor =             [:white, :black, :black ][Int(cards[Int(i), 3 + current_player] + 1)]
  	    cards[Int(i), 6 + current_player] = [:black, :green, :yellow][Int(cards[Int(i), 3 + current_player] + 1)]
  	    if cards[Int(i), 3 + current_player] == 0
  	      win = GtkWindow("safehouses", 400, 200)
          game_result = uppercase(buttonlabels[i]) * " was an Assassin! Game Over!"
          b = GtkButton(game_result)
          push!(win,b)
          showall(win)		  
        elseif sum(cards[:, 6:7] .== 1) == 16 # All green cards revealed
     		  win = GtkWindow("safehouses", 400, 200)
          game_result = "You win!"
  	  	  b = GtkButton(game_result)
          push!(win,b)
  		    showall(win)
        end
        # If touched card is green or an assassin, set both players as having touched the card
		    if cards[Int(i), 3 + current_player] <= 1.0
  	      cards[Int(i), 6 + ~current_player] = cards[Int(i), 6 + current_player]
		    end
      end
    end
  
  # Set up button to toggle active player
  fig[0,:] = player_button = Button(fig, label = "Player $(1 + current_player)'s turn", height = 125, textsize = 40.0f0, buttoncolor_active = :grey94, buttoncolor_hover = :grey94)
  
  on(player_button.clicks) do n
    # Clicking button toggles active player value between 0 (false) and 1 (true)
    global current_player = current_player
	  current_player = ~current_player
	
  # Each click also increments the turn counter
	  global duos_turn = duos_turn
	  duos_turn += 1
	  
    # If turn counter exceeds limit, game ends
	  if duos_turn > turn_limit
	    win = GtkWindow("safehouses", 400, 200)
      game_result = "Time's Up! Game Over!"
    	b = GtkButton(game_result)
      push!(win,b)
    	showall(win)
	  end
	  
	  player_button.label = "Player $(1 + current_player): Turn $(duos_turn) of $(turn_limit)"
	  
    # Set cards to show colors for next player
	  for i in 1:25
      buttons[i].buttoncolor        = cards[i, 6 + current_player]
	    buttons[i].buttoncolor_active = cards[i, 6 + current_player]
	    buttons[i].buttoncolor        = cards[i, 6 + current_player]
	    buttons[i].buttoncolor_hover  = cards[i, 6 + current_player]
	    buttons[i].labelcolor         = cards[i, 6 + current_player]
	  end
  end
  display(fig)  
end

# Draw Again

# Function to clear out a subplot
function Base.empty!(ax::Axis)
  while !isempty(ax.scene.plots)
    plot = first(ax.scene.plots)
    delete!(ax.scene, plot)
  end
end

# Shapes to display for each draw
shapedeck = 
      [
      (0) (0)
      (0) (0)
      (0) (0)
      (-.5, .5) (0, 0)
      (-.5, .5) (0, 0)
      (-.5, .5) (0, 0)
      (-.5, -.5, .5) (.5, -.5, -.5)
      (-.5, -.5, .5) (.5, -.5, -.5)
      (-1, 0, 1) (0, 0, 0)
      (-1, 0, 1) (0, 0, 0)
      (-1, 0, 0, 1) (-.5, -.5, .5, .5)
      (-1.5, -.5, .5, 1.5) (0, 0, 0, 0)
      (-1, 0, 1, 1) (-.5, -.5, -.5, .5)
      (-.5, -.5, -.5, .5) (1, 0, -1, 0)
      (-.5, -.5, .5, .5) (.5, -.5, .5, -.5)
      (-.5, -.5, -.5, .5, .5) (1, 0, -1, 1, -1)
      (-1, 0, 0, 0, 1) (0, 1, 0, -1, 0)
      (-1, 0, 0, 0, 1) (1, 1, 0, -1, 1)
      (-1, 0, 0, 1, 1) (-.5, .5, -.5, .5, -.5)
      (-1, -1, -1, 0, 1) (1, 0, -1, -1, -1)
      (-1.5, -.5, .5, .5, 1.5) (-.5, -.5, -.5, .5, .5)
      (-1, 0, 0, 0, 1) (-1, 1, 0, -1, 1)
      (-1.5, -.5, .5, 1.5, -.5) (.5, .5, .5, .5, -.5)
      (-1, -1, 0, 0, 1) (0, -1, 1, 0, 1)
      (-1, -1, -1, 0, 0, 1) (1, 0, -1, 1, 0, 1)
      (1, 0, -1, 1, 0, -1) (-.5, -.5, -.5, .5, .5, .5) 
      (-1, 0, 0, 0, 1, 1) (0, 1, 0, -1, 0, -1)
      (-1, 0, 0, 0, 0, 1) (.5, 1.5, .5, -.5, -1.5, .5)
      (-1, -1, 0, 0, 1, 1) (0, -1, 1, 0, 0, -1)
      (-.5, -.5, .5, .5, .5, .5) (.5, -.5, 1.5, .5, -.5, -1.5)
      (-2, -1, 0, 0, 1, 2) (-.5, -.5, .5, -.5, -.5, -.5)
      (-1.5, -1.5, -.5, .5, 1.5, 1.5) (.5, -.5, -.5, -.5, .5, -.5)
      (-1.5, -1.5, -.5, -.5, -.5, .5, 1.5) (1, -1, 1, 0, -1, 0, 0)
      (-1.5, -1.5, -.5, -.5, .5, .5, 1.5) (1.5, .5, .5, -.5, -.5, -1.5, -1.5)
      (-1, -1, -1, 0, 1, 1, 1) (1, 0, -1, 0, 1, 0, -1)
      (-1, -1, 0, 0, 0, 1, 1) (0, -1, 1, 0, -1, 0, -1)
      (-1, -1, -1, 0, 1, 1, 1) (1, 0, -1, -1, 1, 0, -1)
      (-1, -1, 0, 0, 0, 1, 1) (0, -1, 1, 0, -1, 1, 0)
      (-1.5, -.5, -.5, -.5, -.5, .5, 1.5) (-.5, 1.5, .5, -.5, -1.5, -.5, -.5)
      (-2, -1, 0, 1, 2, -1, 1) (.5, .5, .5, .5, .5, -.5, -.5)  
      ]
  # Sample shapes for reference appear in	upper middle column
	samplecards = copy(shapedeck)
  # Cards to draw from, shuffled
  shapecards  = copy(shapedeck)
	shapecards  = shapecards[shuffle([1:40...]), :]
	
  # Coordinates to display sample cards in their panel
	sample_x = [-14, -12, -14, -13.5, -13.5, -13.5, -13.5, -13.5, -13, -13, -9, -9.5, -9.5, -10.5, -9.5, -5.5, -6, -6, -9, -1, -.5, -3, -1.5, -5, 0, -1, 3, 0, 3, 3.5, 5, 3.5, 11.5, 9.5, 8, 7, 12, 11, 6.5, 11]
	sample_y = [9, 9, 7, 5, 3, 1, -1.5, -4.5, -7, -9, 8.5, -5, 5.5, 1, -2.5, 8, 1, -3, -8.5, -8, -.5, -4, 1.5, -8, 8, 4.5, -3, -5.5, -8, 7.5, .5, 3.5, 0, -3.5, 4, 8, 4, 8, -5.5, -8.5]
  
  # Shapes for each player's start of game  
    startingcards = 
      [
      (-1.5, -1.5, -.5, -.5, .5, .5, 1.5, 1.5) (1.5, -1.5, .5, -.5, .5, -.5, 1.5, -1.5)
      (-1, -1, -1, 0, 0, 1, 1, 1) (1.5, .5, -.5, -.5, -1.5, 1.5, .5, -.5)
      (2, 1, 0, -1, -2, 2, 0, -2) (-.5, -.5, -.5, -.5, -.5, .5, .5, .5)
      (-1, -1, 0, 0, 0, 0, 1, 1) (.5, -.5, 1.5, .5, -.5, -1.5, .5, -.5)
      (-1, -1, 0, 0, 0, 0, 1, 1) (1.5, -.5, 1.5, .5, -.5, -1.5, 1.5, -.5)
      (-2, -1, -1, 0, 0, 1, 1, 2) (1.5, 1.5, .5, .5, -.5, -.5, -1.5, -1.5)
      (-1.5, -1.5, -.5, -.5, -.5, -.5, .5, 1.5) (-.5, -1.5, 1.5, .5, -.5, -1.5, -.5, -.5)
      (2, 1, -1, -2, 1, 0, -1, 0) (-1, -1, -1, -1, 0, 0, 0, 1)
      (-1, -1, 0, 0, 0, 0, 1, 1) (1.5, -.5, 1.5, .5, -.5, -1.5, .5, -1.5)
      (-1, -1, 0, 0, 0, 0, 1, 1) (1.5, -1.5, 1.5, .5, -.5, -1.5, 1.5, -1.5)
      (-1, -1, -1, 0, 0, 1, 1, 1) (1, 0, -1, 1, -1, 1, 0, -1)
      (-1.5, -.5, .5, 1.5, 1.5, 1.5, 1.5, .5) (-1.5, -1.5, -1.5, -1.5, -.5, .5, 1.5, 1.5)
      ]
    
    # Vector of colors for each shape according to size
    colors = ["#FDE725FF" "#8FD744FF" "#35B779FF" "#21908CFF" "#31688EFF" "#443A83FF" "#440154FF"]
  
  # Player names, set to blank to start
  player_list = repeat([" "], 6)
  
  # Whether or not each player has drawn a second chance that turn, defaults to locked for first draw  
  locked = repeat([1], 6)
  
  # Assigned spaces in Gtk window for each player's name entry
  grid_spaces = [[[i, j] for j in [1 2 3], i in [1 3]]...]

function create_board()

  global fig = fig
  fig = Figure(resolution = (1200, 900))
  # Counter of remaining cards at top of figure window
  supertitle = fig[0, :] = Label(fig, "40 cards remain", textsize = 30)
  
  # Axes for player subplots on right and left columns
  global ax = ax
  ax = [Axis(fig[i, j]) for i in (2, 4, 6), j in (1:3, 7:9)]
  # Axes for subplots in center of figure
  global ax2 = ax2
  ax2 = [Axis(fig[i, 4:6]) for i in (1:2, 3:4, 5:6)]

  # Index of subplots for each player  
  global player_grids = player_grids
  player_grids = [(i, j) for i in (2, 4, 6), j in (1:3, 7:9)]
  
  # Buttons to draw second chances, default to blank label until names provided
  buttons = [Button(fig[i,j], label = " ") for i in (1, 3, 5), j in (2, 8)]
  for i in 1:6
    buttons[i].label = player_list[i] == "" ? " " : player_list[i]
  end

  # Plot sample cards
  for i in 1:40
    GLMakie.scatter!(fig[1:2, 4:6],
      .075 .* ([samplecards[i, 1]...] .+ sample_x[i]),
      .2 .* ([samplecards[i, 2]...] .+ sample_y[i]),
      marker = :rect,
      color = Colors.parse(Colorant, colors[length([samplecards[i, 2]...])]),
      strokecolor = :white,
      markersize = 12
    )
  end
  limits!(ax2[1], -2, 2, -2, 2)
  
  # Add button to clear board and draw new common cards
  redeal_button = Button(fig[7, 5], label = "Draw Again")
  on(redeal_button.clicks) do n
    global shapecards = shapecards
    global locked = locked
    for i in 1:6
      empty!(ax[i])
    end
    if (size(shapecards)[1] >= 2)
      for i in 2:3
        empty!(ax2[i])
  	  card_to_plot = shapecards[1, :]
        shapecards = shapecards[2:end, :]
  	  GLMakie.scatter!(
  	    fig[(3:4, 5:6)[i - 1], 4:6],
  	    .275 .* [card_to_plot[1]...], 
  	    .675 .* [card_to_plot[2]...],      
  	    marker = :rect,
          strokecolor = :white,
  	    color = Colors.parse(Colorant, colors[length([card_to_plot[1]...])]),
          markersize = 44
        )
      hidedecorations!(ax2[i])
      limits!(ax2[i], -2, 2, -2, 2)
      end
      ncards = size(shapecards)[1]
      supertitle.text = string(ncards) * " card" * (ncards == 1 ? "" : "s") * " remain" * (ncards == 1 ? "s" : "")
      # Resets locked indicators for next turn
      locked = repeat([0], 6)
    end
  end

  # Buttons to draw second chances for each player, and lock the player for remainder of turn
  for i in 1:6
    on(buttons[i].clicks) do n
    global locked = locked
    global shapecards = shapecards
  	if (locked[i] == 0) & (buttons[i].label != " ") & (size(shapecards)[1] >= 1) 
  	  empty!(ax[i])
  	  card_to_plot = shapecards[1, :]
        shapecards = shapecards[2:end, :]
  	  GLMakie.scatter!(
  	    fig[player_grids[i][1], player_grids[i][2]],
  	    .32 .* [card_to_plot[1]...], 
  	    .825 .* [card_to_plot[2]...],      
  	    marker = :rect,
          strokecolor = :white,
  	    color = Colors.parse(Colorant, colors[length([card_to_plot[1]...])]),
          markersize = 44
        )
        hidedecorations!(ax[i])
        limits!(ax[i], -2, 2, -2, 2)
        ncards = size(shapecards)[1]
        supertitle.text = string(ncards) * " card" * (ncards == 1 ? "" : "s") * " remain" * (ncards == 1 ? "s" : "")
  	  locked[i] = 1
      end
    end
  end
  
  for i in 1:6
    hidedecorations!(ax[i])
    limits!(ax[i], -2, 2, -2, 2)
  end
  
  for i in 1:3
    hidedecorations!(ax2[i])
    limits!(ax[i], -2, 2, -2, 2)
  end
  
  fig
end

  # Create Gtk window to enter player names
  win = GtkWindow("Draw Again")
  destroy(win)
  e1, e2, e3, e4, e5, e6 = GtkEntry(), GtkEntry(), GtkEntry(), GtkEntry(), GtkEntry(), GtkEntry()
  entry_widgets = [e1, e2, e3, e4, e5, e6]

  # Collects player names using Gtk window, then prompts player to display the game board
  function play_draw_again()
    global win = win
	  global shapecards = shapecards
	  global locked = locked
	  locked = repeat([1], 6)
	  shapecards = copy(shapedeck)
	  shapecards = shapecards[shuffle([1:40...]), :]

    # Arrange text entry widgets in two columns of three
    g = GtkGrid()
    spaces = [[i, j] for j in [1 2 3], i in [1 3]]
    for i in 1:6
      global g[grid_spaces[i]...] = entry_widgets[i]
    end
    
    # Create button to kick off game and add to bottom row of Gtk window
    start_button = GtkButton("Start Game")
    g[2, 2:3] = start_button
    id = signal_connect(widget->(set_players();create_board();display(fig);draw_starting_cards();destroy(win)), start_button, "clicked")
    
    # Assemble window and display it
    set_gtk_property!(g, :column_homogeneous, true)
    set_gtk_property!(g, :column_spacing, 15)
    push!(win, g)
    showall(win)
  end
  
  # Take player names from Gtk window and save for later
  function set_players()
    global player_list = player_list
    player_list = [get_gtk_property(i, :text, String) for i in [e1 e2 e3 e4 e5 e6]]
  end

function draw_starting_cards()

  global ax2 = ax2
  global ax = ax
  global startingcards = startingcards
  startingcards = startingcards[shuffle([1:12...]), :]

  # Prepare board and draw starting cards for each named player
  for i in 2:3
    empty!(ax2[i])
  end
  for i in 1:6
    empty!(ax[i])
    if player_list[i] != ""
      GLMakie.scatter!(fig[player_grids[i][1], player_grids[i][2]],
       .325 .* [startingcards[i, 1]...],
       .825 .* [startingcards[i, 2]...],
       marker = :rect,
       strokecolor = :white,
       markersize = 44
      )
      hidedecorations!(ax[i])
      limits!(ax[i], -2, 2, -2, 2)
    end
  end
end
