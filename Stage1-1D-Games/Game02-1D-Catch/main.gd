extends SceneTree

## Catch the Firefly — Stage 1, Game 2.
## A firefly drifts back and forth along a 1D track, bouncing off the
## walls. It darts away whenever you step next to it — the only way to
## catch it is to pin it against a wall, then land on its cell before
## the turn budget runs out.
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
var track_length := 20
var max_turns := 40
var min_spawn_distance := 4
var use_color := true
var clear_screen := true

# --- Game state ---
var state := State.PLAYING
var player_pos := 0
var target_pos := 0
var target_dir := 1            # -1 = drifting left, +1 = drifting right
var turns_used := 0
var catches := 0
var escapes := 0
var rounds_played := 0
var best_turns := 0            # fewest turns in a catch; 0 = no catches yet
var game_running := true
var last_message := ""
var last_tone := "info"        # info | hint | warn | bad | good
var _input_lines: Array = []   # queued lines when stdin delivers a chunk


func _init() -> void:
	# Without a real stdin, reads return "" instantly and we'd spin forever.
	if OS.get_stdin_type() == OS.STD_HANDLE_INVALID:
		print("This game reads moves from stdin — run it from a terminal:")
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
	track_length = int(config.get_value("game", "track_length", track_length))
	max_turns = int(config.get_value("game", "max_turns", max_turns))
	min_spawn_distance = int(config.get_value("game", "min_spawn_distance", min_spawn_distance))
	use_color = bool(config.get_value("ui", "use_color", use_color))
	clear_screen = bool(config.get_value("ui", "clear_screen", clear_screen))
	_validate_config()


func _save_default_config(config: ConfigFile) -> void:
	config.set_value("game", "track_length", track_length)
	config.set_value("game", "max_turns", max_turns)
	config.set_value("game", "min_spawn_distance", min_spawn_distance)
	config.set_value("ui", "use_color", use_color)
	config.set_value("ui", "clear_screen", clear_screen)
	if config.save(CONFIG_PATH) == OK:
		print("Created settings.cfg with defaults — edit it to change the game.")


func _validate_config() -> void:
	track_length = maxi(track_length, 3)
	max_turns = maxi(max_turns, 1)
	min_spawn_distance = clampi(min_spawn_distance, 2, track_length - 1)


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
		printraw("\nMove (l/r/w): ")
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
		# split them so queued input isn't swallowed in one move.
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
		"left", "l":
			_take_turn(-1)
		"right", "r":
			_take_turn(1)
		"wait", "w", "":
			_take_turn(0)
		"help", "h", "?":
			_print_help()
		"quit", "q":
			game_running = false
			_say("You give up the chase — the firefly was at cell %d." % target_pos)
		_:
			_say("Unknown move — use l/r/w, or 'quit'.", "warn")


func _update_round_over(input: String) -> void:
	match input:
		"y", "yes":
			_start_round()
		"n", "no", "quit", "q":
			game_running = false
		_:
			_say("Please answer 'y' or 'n'.", "warn")


func _take_turn(direction: int) -> void:
	# Every action — including waiting and bumping a wall — is one tick of
	# the game world: the firefly always gets to react. That's the rule
	# that turns "chase it" into "corner it".
	turns_used += 1
	var old_dist := absi(target_pos - player_pos)

	var note := "You hold still."
	if direction != 0:
		var target_cell := player_pos + direction
		if target_cell < 0 or target_cell >= track_length:
			note = "A wall stops you."
		else:
			player_pos = target_cell
			note = "You move %s." % ("left" if direction < 0 else "right")

	if player_pos == target_pos:
		# The one and only catch: land on its cell — possible only when it
		# was pinned against a wall and couldn't dodge last tick.
		_win_round("You land on the trapped firefly — caught!")
		return

	if absi(target_pos - player_pos) == 1:
		# Adjacent: it darts one cell away — unless a wall is there.
		# Even when pinned we update its heading, so the map shows it
		# straining against the wall.
		target_dir = signi(target_pos - player_pos)
		var dodge_cell := target_pos + target_dir
		if dodge_cell < 0 or dodge_cell >= track_length:
			note += " It's pinned against the wall — nowhere to run!"
		else:
			target_pos = dodge_cell
			note += " It darts away!"
	else:
		# Free: drift one cell in its current direction, bouncing off the
		# walls — it spends a tick sitting on the wall when it hits.
		target_pos += target_dir
		if target_pos < 0 or target_pos >= track_length:
			target_pos = clampi(target_pos, 0, track_length - 1)
			target_dir = -target_dir
			note += " The firefly bounces off the wall!"

	if turns_used >= max_turns:
		_lose_round()
		return
	_turn_report(note, old_dist)


func _turn_report(note: String, old_dist: int) -> void:
	var dist := absi(target_pos - player_pos)
	var trend := "holding range."
	if dist < old_dist:
		trend = "closing in!"
	elif dist > old_dist:
		trend = "it pulls away."
	_say("%s %d cell%s apart — %s" % [
		note, dist, "" if dist == 1 else "s", trend],
		"hint" if dist <= 3 else "info")


func _win_round(how: String) -> void:
	state = State.ROUND_OVER
	catches += 1
	rounds_played += 1
	if best_turns == 0 or turns_used < best_turns:
		best_turns = turns_used
	_say("%s (%d turn%s)" % [
		how, turns_used, "" if turns_used == 1 else "s"], "good")


func _lose_round() -> void:
	state = State.ROUND_OVER
	escapes += 1
	rounds_played += 1
	_say("Out of time — the firefly slips away into the dark.", "bad")


func _start_round() -> void:
	player_pos = track_length / 2
	# Spawn on any cell far enough away; if the config left no valid cell,
	# relax the rule rather than fail — never trust an editable file.
	var spawn_cells: Array = []
	for i in track_length:
		if absi(i - player_pos) >= min_spawn_distance:
			spawn_cells.append(i)
	if spawn_cells.is_empty():
		for i in track_length:
			if i != player_pos:
				spawn_cells.append(i)
	target_pos = spawn_cells[randi_range(0, spawn_cells.size() - 1)]
	# A firefly on a wall can only drift inward.
	if target_pos == 0:
		target_dir = 1
	elif target_pos == track_length - 1:
		target_dir = -1
	else:
		target_dir = 1 if randi() % 2 == 0 else -1
	turns_used = 0
	state = State.PLAYING
	_say("A firefly appears %d cells to your %s — corner it!" % [
		absi(target_pos - player_pos),
		"left" if target_pos < player_pos else "right"])


# --- RENDER ----------------------------------------------------------------

func _render() -> void:
	if clear_screen:
		_clear_screen()
	elif last_message != "":
		print("")
	_print_hud()
	if last_message != "":
		print(_tone(last_message, last_tone))
	if state == State.ROUND_OVER and game_running:
		var best := ""
		if catches > 0:
			best = " | Best: %d turn%s" % [best_turns, "" if best_turns == 1 else "s"]
		print(_c("Score: %d/%d fireflies caught%s" % [
			catches, rounds_played, best], "1;36"))


func _print_hud() -> void:
	var cells := PackedStringArray()
	for i in track_length:
		if i == player_pos:
			cells.append(_c("P", "1;32"))
		elif i == target_pos:
			# The firefly's symbol is also its velocity: < left, > right.
			cells.append(_c(">" if target_dir > 0 else "<", "1;33"))
		else:
			cells.append(_c(".", "90"))
	var turns_left := maxi(max_turns - turns_used, 0)
	var meter := "[" + "#".repeat(turns_left) + "-".repeat(turns_used) + "]"
	print(_c("=== CATCH THE FIREFLY ===", "1;36"))
	print("[%s]" % " ".join(cells))
	print("Distance: %d   Turns left: %s %d/%d" % [
		absi(target_pos - player_pos), _c(meter, "33"), turns_left, max_turns])
	print(_c("P=you  </>=firefly+drift   l/r=move  w=wait", "90"))
	print(_c("-".repeat(44), "90"))


# --- Output helpers --------------------------------------------------------

func _say(text: String, tone := "info") -> void:
	# All status messages funnel through here so render() can color by tone.
	last_message = text
	last_tone = tone


func _tone(text: String, tone: String) -> String:
	match tone:
		"good": return _c(text, "1;32")   # bold green  — catches
		"bad":  return _c(text, "1;31")   # bold red    — escapes
		"warn": return _c(text, "33")     # yellow      — invalid input
		"hint": return _c(text, "36")     # cyan        — close to catching
		_:      return text               # info        — plain


func _c(text: String, code: String) -> String:
	if not use_color:
		return text
	return ESC + "[" + code + "m" + text + ESC + "[0m"


func _clear_screen() -> void:
	printraw(ESC + "[2J" + ESC + "[H")


# --- Bookkeeping -----------------------------------------------------------

func _print_intro() -> void:
	print("=== CATCH THE FIREFLY ===")
	print("A firefly drifts along a %d-cell track and darts away whenever" % track_length)
	print("you step next to it. Pin it against a wall, land on its cell —")
	print("you have %d turns." % max_turns)


func _print_outro() -> void:
	print("")
	if rounds_played > 0 and catches > 0:
		print(_c("=== Final: %d/%d caught | Best: %d turns ===" % [
			catches, rounds_played, best_turns], "1;36"))
	elif rounds_played > 0:
		print(_c("=== Final: %d/%d caught ===" % [catches, rounds_played], "1;36"))
	else:
		print("=== No completed rounds. See you next time! ===")


func _print_help() -> void:
	# Route through _say() so the text survives the next _render()'s
	# screen clear — direct print() output would be wiped instantly.
	_say("Moves: l/left, r/right, w/wait (or just Enter), quit/q\n"
		+ "It dodges when you get adjacent — pin it at a wall, then step on it.")
