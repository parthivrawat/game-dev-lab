extends SceneTree

## Dustline — Stage 1, Game 4.
## This time the track scrolls itself: rocks (#) roll in low and birds
## (v) swoop in high from the right edge while your legs do the running
## on their own — every input is one tick of road. A rock only hurts if
## your feet are DOWN when it crosses your column; a bird only hurts if
## you're in the AIR. So the game is one decision repeated forever:
## when to leave the ground — against a spawner whose gaps shrink and a
## scroll speed that climbs with every meter. The difficulty curve,
## given a name.
##
## Run from a terminal inside this folder:
##     godot --headless --script main.gd      (or double-click run.bat)
##
## Game rules live in settings.cfg — created with defaults on first run.
## Best distance and career stats persist under [scores]. Note: saving
## rewrites the file — hand-written comments in it are not preserved.

const CONFIG_PATH := "res://settings.cfg"
const ESC := "\u001b"   # ANSI escape character

enum State { PLAYING, RUN_OVER }

# --- Configuration (settings.cfg; these are the defaults) ---
var track_length := 24
var player_cell := 4        # your column — fixed; the road moves, not you
var jump_ticks := 3         # ticks one jump keeps you airborne
var start_speed := 1.0      # scroll speed in cells/tick at distance 0
var speed_growth := 0.02    # added to scroll speed per meter run
var max_speed := 2.5
var start_gap := 9.0        # cells between obstacle spawns at distance 0
var min_gap := 5.0          # the curve's floor (fairness may raise it)
var gap_shrink := 0.03      # cells the spawn gap loses per meter run
var flyer_chance := 0.25    # chance each spawn is a bird instead of a rock
var spawn_delay := 4        # ticks of clear track before the first spawn
var use_color := true
var clear_screen := true

# --- Game state ---
var state := State.PLAYING
var distance := 0.0         # meters run this attempt — also the score
var speed := 1.0            # current scroll speed, derived from distance
var air_left := 0           # ticks of jump coverage remaining (>0 = airborne)
var spawn_cd := 0           # ticks until the spawner fires again
var obstacles: Array = []   # {"x", "flyer", "met", "passed"}, oldest first
var cleared := 0            # obstacles left behind this run
var jumps := 0
var game_running := true
var last_message := ""
var last_tone := "info"     # info | hint | warn | bad | good
var _input_lines: Array = []  # queued lines when stdin delivers a chunk

# --- Session stats ---
var runs := 0
var session_best := 0
var session_meters := 0
var total_cleared := 0

# --- Career record (settings.cfg [scores]) ---
var best_distance := 0
var career_runs := 0
var career_meters := 0


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
	_start_run()
	_render()
	while game_running:
		var input := _read_input()          # 1. INPUT
		_update(input)                      # 2. UPDATE
		_render()                           # 3. RENDER
	if clear_screen:
		_clear_screen()
		if last_message != "":
			# Re-show the final status line the clear just wiped.
			print(_tone(last_message, last_tone))
	_save_scores()
	_print_outro()
	quit()


# --- Configuration ---------------------------------------------------------

func _load_config() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		_save_default_config(config)
		return
	track_length = int(config.get_value("game", "track_length", track_length))
	player_cell = int(config.get_value("game", "player_cell", player_cell))
	jump_ticks = int(config.get_value("game", "jump_ticks", jump_ticks))
	start_speed = float(config.get_value("game", "start_speed", start_speed))
	speed_growth = float(config.get_value("game", "speed_growth", speed_growth))
	max_speed = float(config.get_value("game", "max_speed", max_speed))
	start_gap = float(config.get_value("game", "start_gap", start_gap))
	min_gap = float(config.get_value("game", "min_gap", min_gap))
	gap_shrink = float(config.get_value("game", "gap_shrink", gap_shrink))
	flyer_chance = float(config.get_value("game", "flyer_chance", flyer_chance))
	spawn_delay = int(config.get_value("game", "spawn_delay", spawn_delay))
	use_color = bool(config.get_value("ui", "use_color", use_color))
	clear_screen = bool(config.get_value("ui", "clear_screen", clear_screen))
	_load_scores(config)
	_validate_config()


func _save_default_config(config: ConfigFile) -> void:
	config.set_value("game", "track_length", track_length)
	config.set_value("game", "player_cell", player_cell)
	config.set_value("game", "jump_ticks", jump_ticks)
	config.set_value("game", "start_speed", start_speed)
	config.set_value("game", "speed_growth", speed_growth)
	config.set_value("game", "max_speed", max_speed)
	config.set_value("game", "start_gap", start_gap)
	config.set_value("game", "min_gap", min_gap)
	config.set_value("game", "gap_shrink", gap_shrink)
	config.set_value("game", "flyer_chance", flyer_chance)
	config.set_value("game", "spawn_delay", spawn_delay)
	config.set_value("ui", "use_color", use_color)
	config.set_value("ui", "clear_screen", clear_screen)
	if config.save(CONFIG_PATH) == OK:
		print("Created settings.cfg with defaults — edit it to change the game.")


func _validate_config() -> void:
	track_length = maxi(track_length, 12)
	player_cell = clampi(player_cell, 1, track_length / 2)
	jump_ticks = clampi(jump_ticks, 1, 10)
	start_speed = clampf(start_speed, 0.5, 4.0)
	speed_growth = maxf(speed_growth, 0.0)
	max_speed = clampf(max_speed, start_speed, 8.0)
	start_gap = maxf(start_gap, 2.0)
	min_gap = clampf(min_gap, 2.0, start_gap)
	gap_shrink = maxf(gap_shrink, 0.0)
	flyer_chance = clampf(flyer_chance, 0.0, 1.0)
	spawn_delay = maxi(spawn_delay, 1)


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


# --- Persistent record (settings.cfg [scores]) -------------------------------

func _load_scores(config: ConfigFile) -> void:
	best_distance = int(config.get_value("scores", "best_distance", 0))
	career_runs = int(config.get_value("scores", "runs", 0))
	career_meters = int(config.get_value("scores", "meters", 0))


func _save_scores() -> void:
	# Only worth writing if something was actually run this session.
	if runs == 0:
		return
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)   # reload so unrelated edits aren't lost
	config.set_value("scores", "best_distance", maxi(best_distance, session_best))
	config.set_value("scores", "runs", career_runs + runs)
	config.set_value("scores", "meters", career_meters + session_meters)
	config.save(CONFIG_PATH)


# --- INPUT -----------------------------------------------------------------

func _read_input() -> String:
	if state == State.RUN_OVER:
		printraw("\nRun again? (y/n): ")
	else:
		printraw("\nMove (j/w): ")
	if _input_lines.is_empty():
		var chunk := OS.read_string_from_stdin()
		if chunk == "":
			# EOF on piped/redirected stdin -> quit instead of looping
			# forever. On a console, "" is just the Enter key.
			if OS.get_stdin_type() != OS.STD_HANDLE_CONSOLE:
				return "quit"
			return ""
		# A single read may contain several lines when stdin is piped —
		# split them so queued input isn't swallowed in one move. Drop one
		# trailing line ending first, or its empty tail becomes a phantom
		# "wait" turn.
		_input_lines = chunk.trim_suffix("\n").trim_suffix("\r").split("\n")
	var line: String = _input_lines.pop_front()
	return line.strip_edges().to_lower()


# --- UPDATE (game logic) ---------------------------------------------------

func _update(input: String) -> void:
	match state:
		State.PLAYING:
			_update_playing(input)
		State.RUN_OVER:
			_update_run_over(input)


func _update_playing(input: String) -> void:
	match input:
		"jump", "j":
			_take_turn(true)
		"wait", "w", "run", "r", "":
			_take_turn(false)
		"help", "h", "?":
			_print_help()
		"quit", "q":
			if distance > 0.0:
				_log_run()   # meters you earned still count
			game_running = false
			_say("You step off the trail at %d m." % int(distance))
		_:
			_say("Unknown move — j to jump, Enter to run, 'quit' to stop.", "warn")


func _update_run_over(input: String) -> void:
	match input:
		"y", "yes":
			_start_run()
		"n", "no", "quit", "q":
			game_running = false
		_:
			_say("Please answer 'y' or 'n'.", "warn")


func _take_turn(want_jump: bool) -> void:
	# Every input is one tick of road: your feet, the world's scroll,
	# the spawner, the adjudication — in that order, every time.
	var parts := PackedStringArray()
	_tick_tone = "info"
	if want_jump:
		if air_left > 0:
			parts.append("Already airborne — no double-jump!")
			_escalate("warn")
		else:
			air_left = jump_ticks
			jumps += 1
			parts.append("You leap!")
	# The world scrolls. Speed and spawn gap are pure functions of
	# distance, so the difficulty is a curve you can watch — not dice.
	distance += speed
	speed = _current_speed()
	spawn_cd -= 1
	if spawn_cd <= 0:
		parts.append(_spawn_obstacle())
	var crash := _advance_obstacles(parts)
	if air_left > 0:
		air_left -= 1
		if air_left == 0:
			parts.append("You touch down.")
	if crash != "":
		_end_run(crash)
		return
	var threat := _threat_status()
	if threat != "":
		parts.append(threat)
	_say(" ".join(parts), _tick_tone)


var _tick_tone := "info"

func _escalate(tone: String) -> void:
	# One status line per tick, so events compete for its color:
	# worst tone wins.
	var rank := {"info": 0, "good": 1, "hint": 2, "warn": 3, "bad": 4}
	if rank[tone] > rank[_tick_tone]:
		_tick_tone = tone


func _spawn_obstacle() -> String:
	var flyer := randf() < flyer_chance
	obstacles.append({
		"x": float(track_length - 1),
		"flyer": flyer,
		"met": false,      # has it been adjudicated on your column yet
		"passed": false,   # has it fallen behind you (cleared, counted)
	})
	# Convert the cell gap into ticks at the current speed. Since every
	# obstacle scrolls at the same speed, spawn spacing stays ~gap cells.
	spawn_cd = maxi(1, int(ceil(_current_gap() / speed)))
	if flyer:
		return "A bird swoops in on the horizon!"
	return "A rock rolls in on the horizon!"


func _advance_obstacles(parts: PackedStringArray) -> String:
	# Returns a crash message on death, "" while the run continues.
	for ob in obstacles:
		var was := floori(ob["x"])
		ob["x"] -= speed
		var now := floori(ob["x"])
		var airborne := air_left > 0
		# Reached your column? The check is SWEPT — "did it occupy your
		# cell at any point this tick" — so speed can never skip the one
		# cell that matters. Game 3's tunneling fix, shipped.
		if now == player_cell or (was > player_cell and now < player_cell):
			if ob["flyer"] == airborne:
				return ("A bird clips you out of the air!" if ob["flyer"]
					else "The rock takes your legs out!")
			if not ob["met"]:
				ob["met"] = true
				parts.append("The bird whips past overhead!" if ob["flyer"]
					else "You sail clean over the rock!")
				_escalate("good")
		if was >= player_cell and now < player_cell and not ob["passed"]:
			ob["passed"] = true
			cleared += 1
			total_cleared += 1
	# Drop obstacles that scrolled off the left edge of the world.
	while not obstacles.is_empty() and floori(obstacles[0]["x"]) < 0:
		obstacles.pop_front()
	return ""


func _threat_status() -> String:
	# Feedback for next tick: name the nearest incoming obstacle and how
	# many ticks until it's on your column — the runner's equivalent of
	# Game 3's "next landing" read.
	var near_x := -1.0
	var near_flyer := false
	for ob in obstacles:
		if floori(ob["x"]) > player_cell and (near_x < 0.0 or ob["x"] < near_x):
			near_x = ob["x"]
			near_flyer = ob["flyer"]
	if near_x < 0.0:
		return ""
	var ticks := int(floor((near_x - player_cell - 1.0) / speed)) + 1
	if near_flyer:
		if ticks <= air_left:
			_escalate("warn")
			return "Bird arrives in ~%d — and you're stuck in the air!" % ticks
		if ticks <= jump_ticks + 1:
			_escalate("warn")
			return "Bird arrives in ~%d — stay DOWN." % ticks
		return "Bird closes in — on you in ~%d." % ticks
	if ticks <= jump_ticks:
		_escalate("warn")
		return "Rock arrives in ~%d — jump window is OPEN." % ticks
	return "Rock closes in — on you in ~%d." % ticks


func _current_speed() -> float:
	# Difficulty knob 1: the road itself gets faster with distance.
	return minf(max_speed, start_speed + distance * speed_growth)


func _current_gap() -> float:
	# Difficulty knob 2: obstacle spacing shrinks with distance — but the
	# fairness floor jump_ticks * speed keeps every pattern survivable.
	# Two crossings closer than one jump's airtime would be an impossible
	# read, not a hard one; the curve is never allowed to cheat.
	return maxf(maxf(min_gap, start_gap - distance * gap_shrink),
		jump_ticks * speed)


func _end_run(crash: String) -> void:
	_log_run()
	state = State.RUN_OVER
	_say("%s Run over at %d m — %d obstacle%s cleared." % [
		crash, int(distance), cleared, "" if cleared == 1 else "s"], "bad")


func _log_run() -> void:
	runs += 1
	session_best = maxi(session_best, int(distance))
	session_meters += int(distance)


func _start_run() -> void:
	distance = 0.0
	speed = start_speed
	air_left = 0
	spawn_cd = spawn_delay
	obstacles.clear()
	cleared = 0
	jumps = 0
	state = State.PLAYING
	_say("You hit the trail — rocks are low, birds are high. Run!")


# --- RENDER ----------------------------------------------------------------

func _render() -> void:
	if clear_screen:
		_clear_screen()
	elif last_message != "":
		print("")
	_print_hud()
	if last_message != "":
		print(_tone(last_message, last_tone))
	if state == State.RUN_OVER and game_running:
		print(_c("Session best: %d m | Career best: %d m | Runs: %d" % [
			session_best, maxi(best_distance, session_best),
			career_runs + runs], "1;36"))


func _print_hud() -> void:
	var air_map := {}
	var ground_map := {}
	for ob in obstacles:
		var c := floori(ob["x"])
		if c < 0 or c >= track_length:
			continue
		if ob["flyer"]:
			air_map[c] = "v"
		else:
			ground_map[c] = "#"
	var air := PackedStringArray()
	var ground := PackedStringArray()
	for i in track_length:
		var a: String = air_map.get(i, ".")
		var g: String = ground_map.get(i, ".")
		var a_code := "1;35" if a == "v" else "90"
		var g_code := "1;31" if g == "#" else "90"
		if i == player_cell:
			# Your column shows on the row you're on; a faint | marks it
			# on the other so you can read the crossing at a glance.
			if air_left > 0:
				a = "^"
				a_code = "1;32"
				g = "|"
				g_code = "90"
			else:
				g = "P"
				g_code = "1;32"
				a = "|"
				a_code = "90"
		air.append(_c(a, a_code))
		ground.append(_c(g, g_code))
	print(_c("=== DUSTLINE — 1D ENDLESS RUNNER ===", "1;36"))
	print("air    [%s]" % " ".join(air))
	print("ground [%s]" % " ".join(ground))
	print("Distance %d m   speed %.1f cells/tick   spawn gap %.1f cells   cleared %d" % [
		int(distance), speed, _current_gap(), cleared])
	if air_left > 0:
		print("Feet: AIR — covers the next %d tick%s" % [
			air_left, "" if air_left == 1 else "s"])
	else:
		print("Feet: ground")
	print(_c("P=you ^=airborne |=your column  #=rock: jump!  v=bird: stay low  j/w", "90"))
	print(_c("-".repeat(64), "90"))


# --- Output helpers --------------------------------------------------------

func _say(text: String, tone := "info") -> void:
	# All status messages funnel through here so render() can color by tone.
	last_message = text
	last_tone = tone


func _tone(text: String, tone: String) -> String:
	match tone:
		"good": return _c(text, "1;32")   # bold green — clean dodges
		"bad":  return _c(text, "1;31")   # bold red   — crashes
		"warn": return _c(text, "33")     # yellow     — danger, bad input
		"hint": return _c(text, "36")     # cyan       — proximity reads
		_:      return text               # info       — plain


func _c(text: String, code: String) -> String:
	if not use_color:
		return text
	return ESC + "[" + code + "m" + text + ESC + "[0m"


func _clear_screen() -> void:
	printraw(ESC + "[2J" + ESC + "[H")


# --- Bookkeeping -----------------------------------------------------------

func _print_intro() -> void:
	print("=== DUSTLINE — 1D ENDLESS RUNNER ===")
	print("The road scrolls past on its own — every input is one tick.")
	print("Rocks (#) hit grounded feet: be AIRBORNE when one reaches you.")
	print("Birds (v) hit a body in the air: stay DOWN when one crosses.")
	print("A jump lasts %d ticks and there is no double-jump. Survive." % jump_ticks)


func _print_outro() -> void:
	print("")
	if runs > 0:
		print(_c("=== Session: best %d m in %d run%s | Career: %d m best, %d m total ===" % [
			session_best, runs, "" if runs == 1 else "s",
			maxi(best_distance, session_best),
			career_meters + session_meters], "1;36"))
	else:
		print("=== No finished runs. See you on the trail! ===")


func _print_help() -> void:
	# Route through _say() so the text survives the next _render()'s
	# screen clear — direct print() output would be wiped instantly.
	_say("Moves: j/jump, w/wait (or just Enter), quit/q\n"
		+ "Rock (#): be airborne on the tick it crosses your column.\n"
		+ "Bird (v): be grounded — jumping into it is the only way to die to it.\n"
		+ "A jump covers %d ticks and can't be re-pressed mid-air." % jump_ticks)
