extends SceneTree

## Number Guessing — Stage 1, Game 1.
## The computer picks a number in a configurable range; you have a
## configurable number of attempts to find it.
##
## Run from a terminal inside this folder:
##     godot --headless --script main.gd      (or double-click run.bat)
##
## Game settings live in settings.cfg — edit it to change the rules.
## If the file is missing, the game creates it with defaults on first run.

const CONFIG_PATH := "res://settings.cfg"
const ESC := "\u001b"   # ANSI escape character

enum State { PLAYING, ROUND_OVER }

# --- Configuration (settings.cfg; these are the defaults) ---
var min_number := 1
var max_number := 100
var max_attempts := 7
var proximity_hints := true
var use_color := true
var clear_screen := true

# --- Game state ---
var state := State.PLAYING
var secret := 0
var attempts_used := 0
var rounds_won := 0
var rounds_played := 0
var best_attempts := 0          # fewest attempts in a win; 0 = no wins yet
var game_running := true
var last_message := ""
var last_tone := "info"         # info | hint | warn | bad | good
var _input_lines: Array = []    # queued lines when stdin delivers a chunk


func _init() -> void:
	# Without a real stdin, reads return "" instantly and we'd spin forever.
	if OS.get_stdin_type() == OS.STD_HANDLE_INVALID:
		print("This game reads guesses from stdin — run it from a terminal:")
		print("    godot --headless --script main.gd   (or run.bat)")
		quit()
		return
	_load_config()
	_detect_terminal()
	randomize()
	if not clear_screen:
		_print_intro()
	_start_round()
	_render()
	while game_running:
		var input := _read_input()          # 1. INPUT
		_update(input)                      # 2. UPDATE
		_render()                           # 3. RENDER
	if clear_screen:
		_clear_screen()
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
	use_color = bool(config.get_value("ui", "use_color", use_color))
	clear_screen = bool(config.get_value("ui", "clear_screen", clear_screen))
	_validate_config()


func _save_default_config(config: ConfigFile) -> void:
	config.set_value("game", "min_number", min_number)
	config.set_value("game", "max_number", max_number)
	config.set_value("game", "max_attempts", max_attempts)
	config.set_value("game", "proximity_hints", proximity_hints)
	config.set_value("ui", "use_color", use_color)
	config.set_value("ui", "clear_screen", clear_screen)
	if config.save(CONFIG_PATH) == OK:
		print("Created settings.cfg with defaults — edit it to change the game.")


func _validate_config() -> void:
	if min_number > max_number:
		var tmp := min_number
		min_number = max_number
		max_number = tmp
	max_attempts = maxi(max_attempts, 1)


func _optimal_attempts() -> int:
	# Worst-case binary search depth is ceil(log2(span + 1)) — a 1-value
	# range still needs 1 guess, and exact powers of two need one extra
	# split (span 2 needs 2 guesses, span 4 needs 3).
	var span := max_number - min_number + 1
	return int(ceil(log(span + 1) / log(2.0)))


func _detect_terminal() -> void:
	# ANSI codes and screen clearing only make sense on a real console —
	# disable them when output is piped/redirected, honor the NO_COLOR
	# convention, and allow FORCE_COLOR to override for testing.
	var piped := OS.get_stdout_type() != OS.STD_HANDLE_CONSOLE
	var no_color := OS.get_environment("NO_COLOR") != ""
	var forced := OS.get_environment("FORCE_COLOR") != ""
	if (piped or no_color) and not forced:
		use_color = false
		clear_screen = false


# --- INPUT -----------------------------------------------------------------

func _read_input() -> String:
	if state == State.PLAYING:
		printraw("\nGuess %d-%d (%d left): " % [
			min_number, max_number, max_attempts - attempts_used])
	else:
		printraw("\nPlay again? (y/n): ")
	if _input_lines.is_empty():
		var chunk := OS.read_string_from_stdin()
		if chunk == "":
			# EOF on piped/redirected stdin -> quit instead of looping
			# forever. On a console, "" is just the Enter key.
			if OS.get_stdin_type() != OS.STD_HANDLE_CONSOLE:
				return "quit"
			return ""
		# A single read may contain several lines when stdin is piped —
		# split them so queued input isn't swallowed in one guess.
		_input_lines = chunk.split("\n")
	var line: String = _input_lines.pop_front()
	return line.strip_edges().to_lower()


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
			_say("Giving up? The number was %d." % secret)
			return
		_:
			pass
	if not input.is_valid_int():
		_say("Not a number — enter %d to %d, or 'quit'." % [min_number, max_number], "warn")
		return
	var guess := input.to_int()
	if guess < min_number or guess > max_number:
		_say("Out of range — the number is between %d and %d." % [min_number, max_number], "warn")
		return
	attempts_used += 1
	if guess == secret:
		_win_round()
		return
	var remaining := max_attempts - attempts_used
	if remaining <= 0:
		state = State.ROUND_OVER
		rounds_played += 1
		_say("Out of attempts! The number was %d." % secret, "bad")
		return
	var hint := "Higher!" if guess < secret else "Lower!"
	if proximity_hints:
		var distance := absi(guess - secret)
		if distance <= 5:
			hint += " (very close!)"
		elif distance <= 15:
			hint += " (close)"
	_say(hint, "hint")


func _update_round_over(input: String) -> void:
	match input:
		"y", "yes":
			_start_round()
		"n", "no", "quit", "q":
			game_running = false
		_:
			_say("Please answer 'y' or 'n'.", "warn")


func _win_round() -> void:
	state = State.ROUND_OVER
	rounds_won += 1
	rounds_played += 1
	if best_attempts == 0 or attempts_used < best_attempts:
		best_attempts = attempts_used
	_say("Correct! You got it in %d attempt%s." % [
		attempts_used, "" if attempts_used == 1 else "s"], "good")


func _start_round() -> void:
	secret = randi_range(min_number, max_number)
	attempts_used = 0
	state = State.PLAYING
	_say("New round — I've picked a number.")


# --- RENDER ----------------------------------------------------------------

func _render() -> void:
	if clear_screen:
		_clear_screen()
		_print_hud()
	elif last_message != "":
		print("")
	if last_message != "":
		print(_tone(last_message, last_tone))
	if state == State.ROUND_OVER and game_running:
		var best := ""
		if rounds_won > 0:
			best = " | Best: %d attempts" % best_attempts
		print(_c("Score: %d/%d rounds won%s" % [rounds_won, rounds_played, best], "1;36"))


func _print_hud() -> void:
	var remaining := maxi(max_attempts - attempts_used, 0)
	var meter := "[" + "#".repeat(remaining) + "-".repeat(attempts_used) + "]"
	print(_c("=== NUMBER GUESSING ===", "1;36"))
	print("Range: %d-%d   Attempts: %s %d/%d" % [
		min_number, max_number, _c(meter, "33"), remaining, max_attempts])
	var optimal := _optimal_attempts()
	if max_attempts >= optimal:
		print(_c("Halve the range each guess — %d tries always wins." % optimal, "90"))
	else:
		print(_c("Warning: perfect play needs %d attempts!" % optimal, "1;33"))
	print(_c("-".repeat(40), "90"))


# --- Output helpers --------------------------------------------------------

func _say(text: String, tone := "info") -> void:
	# All status messages funnel through here so render() can color by tone.
	last_message = text
	last_tone = tone


func _tone(text: String, tone: String) -> String:
	match tone:
		"good": return _c(text, "1;32")   # bold green  — wins, pickups
		"bad":  return _c(text, "1;31")   # bold red    — defeat, damage
		"warn": return _c(text, "33")     # yellow      — invalid input
		"hint": return _c(text, "36")     # cyan        — higher/lower
		_:      return text               # info        — plain


func _c(text: String, code: String) -> String:
	if not use_color:
		return text
	return ESC + "[" + code + "m" + text + ESC + "[0m"


func _clear_screen() -> void:
	printraw(ESC + "[2J" + ESC + "[H")


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
		print(_c("=== Final: %d/%d rounds won | Best: %d attempts ===" % [
			rounds_won, rounds_played, best_attempts], "1;36"))
	elif rounds_played > 0:
		print(_c("=== Final: %d/%d rounds won ===" % [rounds_won, rounds_played], "1;36"))
	else:
		print("=== No completed rounds. See you next time! ===")
