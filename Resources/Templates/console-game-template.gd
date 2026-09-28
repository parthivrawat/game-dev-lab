extends SceneTree

## Console Game Template — a turn-based game skeleton for Stage 0-1.
## Copy this file as main.gd into a new game folder, then replace the
## CONFIG / STATE / UPDATE / RENDER sections with your game's rules.
##
## Run from a terminal inside the game folder:
##     godot --headless --script main.gd      (or use the run.bat template)
##
## IMPORTANT: use the *_console.exe build on Windows — the regular exe
## detaches from the console and cannot read stdin.

const CONFIG_PATH := "res://settings.cfg"
const ESC := "\u001b"   # ANSI escape character

enum State { PLAYING, GAME_OVER }

# --- Configuration (defaults; overridden by settings.cfg) ---
var starting_value := 0
var max_turns := 20
var use_color := true
var clear_screen := true

# --- Game state ---
var state := State.PLAYING
var score := 0
var turns := 0
var game_running := true
var last_message := ""
var last_tone := "info"   # info | hint | warn | bad | good
var _input_lines: Array = []   # queued lines for piped stdin


func _init() -> void:
	# Without a real stdin, reads return "" instantly and we'd spin forever.
	if OS.get_stdin_type() == OS.STD_HANDLE_INVALID:
		print("This game reads input from stdin — run it from a terminal:")
		print("    godot --headless --script main.gd   (or run.bat)")
		quit()
		return
	_load_config()
	_detect_terminal()
	randomize()
	_start_game()
	_render()
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
	starting_value = int(config.get_value("game", "starting_value", starting_value))
	max_turns = int(config.get_value("game", "max_turns", max_turns))
	use_color = bool(config.get_value("ui", "use_color", use_color))
	clear_screen = bool(config.get_value("ui", "clear_screen", clear_screen))
	_validate_config()


func _save_default_config(config: ConfigFile) -> void:
	config.set_value("game", "starting_value", starting_value)
	config.set_value("game", "max_turns", max_turns)
	config.set_value("ui", "use_color", use_color)
	config.set_value("ui", "clear_screen", clear_screen)
	if config.save(CONFIG_PATH) == OK:
		print("Created settings.cfg with defaults — edit it to change the game.")


func _validate_config() -> void:
	# Clamp absurd settings here, and derive any values that must stay
	# consistent (e.g. a midpoint derived from a clamped length).
	starting_value = maxi(starting_value, 0)
	max_turns = maxi(max_turns, 1)


func _detect_terminal() -> void:
	# ANSI color and screen-clearing only make sense on a real console.
	var piped := OS.get_stdout_type() != OS.STD_HANDLE_CONSOLE
	var no_color := OS.get_environment("NO_COLOR") != ""
	var forced := OS.get_environment("FORCE_COLOR") != ""
	if (piped or no_color) and not forced:
		use_color = false
		clear_screen = false


# --- INPUT -----------------------------------------------------------------

func _read_input() -> String:
	if state == State.GAME_OVER:
		printraw("\nPlay again? (y/n): ")
	else:
		printraw("\n> ")
	if _input_lines.is_empty():
		var chunk := OS.read_string_from_stdin()
		if chunk == "":
			# EOF on piped stdin -> quit instead of looping forever.
			if OS.get_stdin_type() != OS.STD_HANDLE_CONSOLE:
				return "quit"
			return ""
		# A piped read may deliver several lines — queue them so extra
		# input isn't swallowed in one turn.
		_input_lines = chunk.trim_suffix("\n").trim_suffix("\r").split("\n")
	var line: String = _input_lines.pop_front()
	return line.strip_edges().to_lower()


# --- UPDATE (game logic) ---------------------------------------------------

func _update(input: String) -> void:
	match state:
		State.PLAYING:
			_update_playing(input)
		State.GAME_OVER:
			match input:
				"y", "yes": _start_game()
				"n", "no", "quit", "q": game_running = false
				_: _say("Please answer 'y' or 'n'.", "warn")


func _update_playing(input: String) -> void:
	match input:
		"quit", "q":
			game_running = false
			_say("You leave the game. Final score: %d." % score)
		"help", "h", "?":
			_print_help()
		# --- replace with your game's commands ---
		"score":
			_say("Score: %d, turn %d/%d." % [score, turns, max_turns])
		_:
			turns += 1
			score += 1
			_say("You did a thing. +1 point!")
			if turns >= max_turns:
				_end_game()


func _start_game() -> void:
	state = State.PLAYING
	score = starting_value
	turns = 0
	_say("Game start! Type 'help' for commands.", "good")


func _end_game() -> void:
	state = State.GAME_OVER
	_say("Game over! Final score: %d." % score, "good")


# --- RENDER ----------------------------------------------------------------

func _render() -> void:
	if clear_screen:
		_clear_screen()
	_print_board()
	if last_message != "":
		print(_tone(last_message, last_tone))
		last_message = ""


func _print_board() -> void:
	# Draw the current game state. Keep it small and readable.
	print("=== MY GAME ===  Score: %d  Turn: %d/%d" % [score, turns, max_turns])


# --- Presentation helpers --------------------------------------------------

func _say(msg: String, tone := "info") -> void:
	last_message = msg
	last_tone = tone


func _tone(msg: String, tone: String) -> String:
	if not use_color:
		return msg
	var code := "37"   # default: white
	match tone:
		"good": code = "32"   # green
		"hint": code = "36"   # cyan
		"warn": code = "33"   # yellow
		"bad":  code = "31"   # red
	return "%s[%sm%s%s[0m" % [ESC, code, msg, ESC]


func _clear_screen() -> void:
	printraw(ESC + "[2J" + ESC + "[H")


func _print_help() -> void:
	print("\nCommands:")
	print("  score      — show score and turns")
	print("  help       — this list")
	print("  quit       — leave the game")


func _print_outro() -> void:
	if clear_screen:
		_clear_screen()
		if last_message != "":
			print(_tone(last_message, last_tone))
	print("\nThanks for playing!")
