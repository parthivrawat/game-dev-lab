extends SceneTree

## Number Guessing — Stage 1, Game 1 (improved edition).
## Two modes, both configurable:
##   normal  — the computer picks a number; you hunt it with hints
##   reverse — YOU pick a number; the computer binary-searches it
##
## Run from a terminal inside this folder:
##     godot --headless --script main.gd      (or double-click run.bat)
##
## Game rules live in settings.cfg — created with defaults on first run.
## Command-line overrides apply for one run only:
##     godot --headless --script main.gd -- --attempts 3
## Options: --min N --max N --attempts N --mode normal|reverse
##          --difficulty easy|normal|hard|custom --no-hints
##
## Best scores persist in settings.cfg under [scores]. Note: saving
## rewrites the file — hand-written comments in it are not preserved.

const CONFIG_PATH := "res://settings.cfg"
const ESC := "\u001b"   # ANSI escape character

enum State { PLAYING, ROUND_OVER }

# --- Configuration (settings.cfg; these are the defaults) ---
var min_number := 1
var max_number := 100
var max_attempts := 7
var proximity_hints := true
var difficulty := "custom"      # custom = use the [game] values directly
var mode := "normal"            # normal | reverse
var use_color := true
var clear_screen := true

# Difficulty presets — the [difficulty] section can override each key.
var presets := {
	"easy":   {"min": 1, "max": 50,  "attempts": 7},
	"normal": {"min": 1, "max": 100, "attempts": 7},
	"hard":   {"min": 1, "max": 500, "attempts": 10},
}

# --- Game state ---
var state := State.PLAYING
var secret := 0
var attempts_used := 0
var rounds_won := 0
var rounds_played := 0
var best_scores := {}           # difficulty -> fewest attempts (persisted)
var game_running := true
var last_message := ""
var last_tone := "info"         # info | hint | warn | bad | good
var _input_lines: Array = []    # queued lines when stdin delivers a chunk

# --- Reverse-mode state (the computer's binary-search window) ---
var comp_lo := 0
var comp_hi := 0
var comp_guess := 0


func _init() -> void:
	# Without a real stdin, reads return "" instantly and we'd spin forever.
	if OS.get_stdin_type() == OS.STD_HANDLE_INVALID:
		print("This game reads guesses from stdin — run it from a terminal:")
		print("    godot --headless --script main.gd   (or run.bat)")
		quit()
		return
	_load_config()
	_parse_cli_overrides()
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
	_save_scores()
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
	mode = str(config.get_value("game", "mode", mode)).to_lower()
	difficulty = str(config.get_value("game", "difficulty", difficulty)).to_lower()
	use_color = bool(config.get_value("ui", "use_color", use_color))
	clear_screen = bool(config.get_value("ui", "clear_screen", clear_screen))
	for p in presets:
		presets[p]["min"] = int(config.get_value("difficulty", p + "_min", presets[p]["min"]))
		presets[p]["max"] = int(config.get_value("difficulty", p + "_max", presets[p]["max"]))
		presets[p]["attempts"] = int(config.get_value("difficulty", p + "_attempts", presets[p]["attempts"]))
	_load_scores(config)
	_apply_difficulty()
	_validate_config()


func _save_default_config(config: ConfigFile) -> void:
	config.set_value("game", "min_number", min_number)
	config.set_value("game", "max_number", max_number)
	config.set_value("game", "max_attempts", max_attempts)
	config.set_value("game", "proximity_hints", proximity_hints)
	config.set_value("game", "mode", mode)
	config.set_value("game", "difficulty", difficulty)
	for p in presets:
		config.set_value("difficulty", p + "_min", presets[p]["min"])
		config.set_value("difficulty", p + "_max", presets[p]["max"])
		config.set_value("difficulty", p + "_attempts", presets[p]["attempts"])
	config.set_value("ui", "use_color", use_color)
	config.set_value("ui", "clear_screen", clear_screen)
	if config.save(CONFIG_PATH) == OK:
		print("Created settings.cfg with defaults — edit it to change the game.")


func _apply_difficulty() -> void:
	# "custom" leaves the [game] values in charge; a named preset replaces
	# them. CLI numeric overrides can still tweak the result afterwards.
	if difficulty == "custom" or not presets.has(difficulty):
		return
	var p: Dictionary = presets[difficulty]
	min_number = p["min"]
	max_number = p["max"]
	max_attempts = p["attempts"]


func _validate_config() -> void:
	if min_number > max_number:
		var tmp := min_number
		min_number = max_number
		max_number = tmp
	max_attempts = maxi(max_attempts, 1)
	if mode not in ["normal", "reverse"]:
		mode = "normal"
	if difficulty != "custom" and not presets.has(difficulty):
		difficulty = "custom"


func _parse_cli_overrides() -> void:
	# get_cmdline_user_args() = everything after "--" on the command line.
	var args := OS.get_cmdline_user_args()
	# Pass 1: --difficulty first so a named preset lands before any numeric
	# overrides — "--difficulty hard --attempts 5" = hard rules + 5 tries.
	for i in args.size() - 1:
		if args[i] == "--difficulty":
			difficulty = args[i + 1].to_lower()
	_apply_difficulty()
	# Pass 2: plain --key value pairs; pass-1 lets these beat the preset.
	for i in args.size() - 1:
		match args[i]:
			"--min":      min_number = int(args[i + 1])
			"--max":      max_number = int(args[i + 1])
			"--attempts": max_attempts = int(args[i + 1])
			"--mode":     mode = args[i + 1].to_lower()
	if "--no-hints" in args:
		proximity_hints = false
	_validate_config()


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


# --- Persistent best scores (settings.cfg [scores]) --------------------------

func _load_scores(config: ConfigFile) -> void:
	for d in ["easy", "normal", "hard", "custom"]:
		best_scores[d] = int(config.get_value("scores", "best_" + d, 0))


func _save_scores() -> void:
	# Only worth writing if something was actually won this session.
	var dirty := false
	for d in best_scores:
		if best_scores[d] > 0:
			dirty = true
	if not dirty:
		return
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)   # reload so unrelated edits aren't lost
	for d in best_scores:
		if best_scores[d] > 0:
			config.set_value("scores", "best_" + d, best_scores[d])
	config.save(CONFIG_PATH)


# --- INPUT -----------------------------------------------------------------

func _read_input() -> String:
	if state == State.PLAYING:
		if mode == "reverse":
			printraw("\n(h)igher (l)ower (c)orrect: ")
		else:
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
		# split them so queued input isn't swallowed in one guess. Drop
		# one trailing line ending first, or its empty tail becomes a
		# phantom input.
		_input_lines = chunk.trim_suffix("\n").trim_suffix("\r").split("\n")
	var line: String = _input_lines.pop_front()
	return line.strip_edges().to_lower()


# --- UPDATE (game logic) ---------------------------------------------------

func _update(input: String) -> void:
	match state:
		State.PLAYING:
			if mode == "reverse":
				_update_reverse(input)
			else:
				_update_guessing(input)
		State.ROUND_OVER:
			_update_round_over(input)


func _update_guessing(input: String) -> void:
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
		if distance <= 2:
			hint += " (blazing!)"
		elif distance <= 5:
			hint += " (hot)"
		elif distance <= 15:
			hint += " (warm)"
		elif distance <= 40:
			hint += " (cool)"
		else:
			hint += " (freezing)"
	_say(hint, "hint")


func _update_reverse(input: String) -> void:
	# The player answers about THEIR secret — h/l narrows the window.
	match input:
		"quit", "q":
			game_running = false
			_say("Fine — keep your number.")
			return
		"h", "higher":
			comp_lo = comp_guess + 1
		"l", "lower":
			comp_hi = comp_guess - 1
		"c", "correct":
			_reverse_win()
			return
		_:
			_say("Answer h/l/c — is your number higher, lower, or my guess?", "warn")
			return
	if comp_lo > comp_hi:
		state = State.ROUND_OVER
		rounds_played += 1
		_say("No number fits your answers — one of us fibbed!", "bad")
	elif attempts_used >= max_attempts:
		state = State.ROUND_OVER
		rounds_played += 1
		_say("Out of attempts — you beat the machine!", "bad")
	else:
		_reverse_guess()


func _reverse_guess() -> void:
	# Binary search, played by the computer: always guess the middle of
	# the remaining window. Watch it run — this is the algorithm.
	comp_guess = (comp_lo + comp_hi) / 2
	attempts_used += 1
	_say("I guess %d." % comp_guess)


func _reverse_win() -> void:
	state = State.ROUND_OVER
	rounds_won += 1
	rounds_played += 1
	_say("Got it in %d attempt%s — that's binary search for you." % [
		attempts_used, "" if attempts_used == 1 else "s"], "good")


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
	var best: int = best_scores.get(difficulty, 0)
	if best == 0 or attempts_used < best:
		best_scores[difficulty] = attempts_used
	_say("Correct! You got it in %d attempt%s." % [
		attempts_used, "" if attempts_used == 1 else "s"], "good")


func _start_round() -> void:
	attempts_used = 0
	state = State.PLAYING
	if mode == "reverse":
		comp_lo = min_number
		comp_hi = max_number
		_reverse_guess()
	else:
		secret = randi_range(min_number, max_number)
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
		var score: int = best_scores.get(difficulty, 0)
		if score > 0:
			best = " | Best(%s): %d" % [difficulty, score]
		print(_c("Score: %d/%d rounds won%s" % [rounds_won, rounds_played, best], "1;36"))


func _print_hud() -> void:
	var remaining := maxi(max_attempts - attempts_used, 0)
	var meter := "[" + "#".repeat(remaining) + "-".repeat(attempts_used) + "]"
	print(_c("=== NUMBER GUESSING ===", "1;36"))
	print("Range: %d-%d   Attempts: %s %d/%d   %s (%s)" % [
		min_number, max_number, _c(meter, "33"), remaining, max_attempts,
		mode, difficulty])
	if mode == "reverse" and state == State.PLAYING:
		print(_c("My search window: %d-%d" % [comp_lo, comp_hi], "36"))
	var optimal := _optimal_attempts()
	if max_attempts >= optimal:
		print(_c("Halve the range each guess — %d tries always wins." % optimal, "90"))
	else:
		print(_c("Warning: perfect play needs %d attempts!" % optimal, "1;33"))
	print(_c("-".repeat(48), "90"))


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
	if mode == "reverse":
		print("Think of a number between %d and %d — I'll hunt it." % [
			min_number, max_number])
		print("Answer (h)igher, (l)ower, (c)orrect — I get %d tries." % max_attempts)
	else:
		print("I'll think of a number between %d and %d." % [min_number, max_number])
		print("You get %d attempts — I'll say 'higher' or 'lower'." % max_attempts)
	print("Difficulty: %s." % difficulty)
	var optimal := _optimal_attempts()
	if max_attempts >= optimal:
		print("Tip: %d tries is always enough if you halve the range each guess!"
			% optimal)
	else:
		print("Warning: even perfect play needs %d attempts — good luck!" % optimal)


func _print_outro() -> void:
	print("")
	if rounds_played > 0:
		var line := "=== Final: %d/%d rounds won" % [rounds_won, rounds_played]
		var bests: Array = []
		for d in ["easy", "normal", "hard", "custom"]:
			if best_scores.get(d, 0) > 0:
				bests.append("%s: %d" % [d, best_scores[d]])
		if not bests.is_empty():
			line += " | Bests — " + ", ".join(bests)
		print(_c(line + " ===", "1;36"))
	else:
		print("=== No completed rounds. See you next time! ===")
