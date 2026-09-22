extends SceneTree

## Number Guessing — Stage 1, Game 1.
## The computer picks a number in a configurable range; you have a
## configurable number of attempts to find it.
##
## Run from a terminal inside this folder:
##     godot --headless --script main.gd
##
## Game settings live in settings.cfg — edit it to change the rules.
## If the file is missing, the game creates it with defaults on first run.

const CONFIG_PATH := "res://settings.cfg"

enum State { PLAYING, ROUND_OVER }

# --- Configuration (loaded from settings.cfg; these are the defaults) ---
var min_number := 1
var max_number := 100
var max_attempts := 7
var proximity_hints := true

# --- Game state ---
var state := State.PLAYING
var secret := 0
var attempts_used := 0
var rounds_won := 0
var rounds_played := 0
var best_attempts := 0          # fewest attempts in a win; 0 = no wins yet
var game_running := true
var last_message := ""


func _init() -> void:
	# Without a real stdin, reads return "" instantly and we'd spin forever.
	if OS.get_stdin_type() == OS.STD_HANDLE_INVALID:
		print("This game reads guesses from stdin — run it from a terminal:")
		print("    godot --headless --script main.gd")
		quit()
		return
	_load_config()
	randomize()
	_print_intro()
	_start_round()
	while game_running:
		var input := _read_input()          # 1. INPUT
		_update(input)                      # 2. UPDATE
		_render()                           # 3. RENDER
	_print_outro()
	quit()


# --- Configuration ---------------------------------------------------------

func _load_config() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		_save_default_config(config)
		return
	min_number = int(config.get_value("game", "min_number", min_number))
	max_number = int(config.get_value("game", "max_number", max_number))
	max_attempts = int(config.get_value("game", "max_attempts", max_attempts))
	proximity_hints = bool(config.get_value("game", "proximity_hints", proximity_hints))
	_validate_config()


func _save_default_config(config: ConfigFile) -> void:
	config.set_value("game", "min_number", min_number)
	config.set_value("game", "max_number", max_number)
	config.set_value("game", "max_attempts", max_attempts)
	config.set_value("game", "proximity_hints", proximity_hints)
	if config.save(CONFIG_PATH) == OK:
		print("Created settings.cfg with defaults — edit it to change the game.")


func _validate_config() -> void:
	if min_number > max_number:
		var tmp := min_number
		min_number = max_number
		max_number = tmp
	max_attempts = maxi(max_attempts, 1)


func _optimal_attempts() -> int:
	# Binary search always wins within ceil(log2(range size)) guesses.
	var span := max_number - min_number + 1
	return int(ceil(log(span) / log(2.0)))


# --- INPUT -----------------------------------------------------------------

func _read_input() -> String:
	if state == State.PLAYING:
		printraw("\nGuess %d-%d (%d left): " % [
			min_number, max_number, max_attempts - attempts_used])
	else:
		printraw("\nPlay again? (y/n): ")
	var line := OS.read_string_from_stdin().strip_edges().to_lower()
	# EOF on piped/redirected stdin -> quit instead of looping forever.
	if line == "" and OS.get_stdin_type() != OS.STD_HANDLE_CONSOLE:
		return "quit"
	return line


# --- UPDATE (game logic) ---------------------------------------------------

func _update(input: String) -> void:
	match state:
		State.PLAYING:
			_update_playing(input)
		State.ROUND_OVER:
			_update_round_over(input)


func _update_playing(input: String) -> void:
	match input:
		"quit", "q":
			game_running = false
			last_message = "Giving up? The number was %d." % secret
			return
		_:
			pass
	if not input.is_valid_int():
		last_message = "Not a number — enter %d to %d, or 'quit'." % [min_number, max_number]
		return
	var guess := input.to_int()
	if guess < min_number or guess > max_number:
		last_message = "Out of range — the number is between %d and %d." % [min_number, max_number]
		return
	attempts_used += 1
	if guess == secret:
		_win_round()
		return
	var remaining := max_attempts - attempts_used
	if remaining <= 0:
		state = State.ROUND_OVER
		rounds_played += 1
		last_message = "Out of attempts! The number was %d." % secret
		return
	var hint := "Higher!" if guess < secret else "Lower!"
	if proximity_hints:
		var distance := absi(guess - secret)
		if distance <= 5:
			hint += " (very close!)"
		elif distance <= 15:
			hint += " (close)"
	last_message = hint


func _update_round_over(input: String) -> void:
	match input:
		"y", "yes":
			_start_round()
		"n", "no", "quit", "q":
			game_running = false
		_:
			last_message = "Please answer 'y' or 'n'."


func _win_round() -> void:
	state = State.ROUND_OVER
	rounds_won += 1
	rounds_played += 1
	if best_attempts == 0 or attempts_used < best_attempts:
		best_attempts = attempts_used
	last_message = "Correct! You got it in %d attempt%s." % [
		attempts_used, "" if attempts_used == 1 else "s"]


func _start_round() -> void:
	secret = randi_range(min_number, max_number)
	attempts_used = 0
	state = State.PLAYING
	last_message = "New round — I've picked a number."


# --- RENDER ----------------------------------------------------------------

func _render() -> void:
	if last_message != "":
		print("\n" + last_message)
	if state == State.ROUND_OVER and game_running:
		var best := ""
		if rounds_won > 0:
			best = " | Best: %d attempts" % best_attempts
		print("Score: %d/%d rounds won%s" % [rounds_won, rounds_played, best])


# --- Bookkeeping -----------------------------------------------------------

func _print_intro() -> void:
	print("=== NUMBER GUESSING ===")
	print("I'll think of a number between %d and %d." % [min_number, max_number])
	print("You get %d attempts — I'll say 'higher' or 'lower'." % max_attempts)
	var optimal := _optimal_attempts()
	if max_attempts >= optimal:
		print("Tip: %d tries is always enough if you halve the range each guess!"
			% optimal)
	else:
		print("Warning: even perfect play needs %d attempts — good luck!" % optimal)


func _print_outro() -> void:
	print("")
	if rounds_played > 0 and rounds_won > 0:
		print("=== Final: %d/%d rounds won | Best: %d attempts ===" % [
			rounds_won, rounds_played, best_attempts])
	elif rounds_played > 0:
		print("=== Final: %d/%d rounds won ===" % [rounds_won, rounds_played])
	else:
		print("=== No completed rounds. See you next time! ===")
