extends SceneTree

## 1D Pong — Stage 1, Game 3.
## Game 2's drifting firefly grew up: the ball now has real velocity —
## a float position and a speed in cells per tick — and once speed
## passes 1.0 it SKIPS cells. You and the CPU defend opposite walls: a
## shot is returned only if the ball LANDS on a cell the paddle covers
## (paddle_pos ± paddle_radius). Landings get sparser as the rally
## speeds up — read them early or the ball slips through. Meet it on
## the mid-court edge of your reach for a faster "drive" return, step
## INTO the shot for a smash, and pick lob/flat/hard serves.
## Series are best-of-N; players = 2 puts a second human on ,/. keys.
##
## Run from a terminal inside this folder:
##     godot --headless --script main.gd      (or double-click run.bat)
##
## Game rules live in settings.cfg — created with defaults on first run.
## Career record and best rally persist under [scores]. Note: saving
## rewrites the file — hand-written comments in it are not preserved.

const CONFIG_PATH := "res://settings.cfg"
const ESC := "\u001b"   # ANSI escape character

enum State { PLAYING, MATCH_OVER, SERIES_OVER }

# --- Configuration (settings.cfg; these are the defaults) ---
var track_length := 20
var points_to_win := 5        # points to win a match
var series_length := 3        # matches per series — best-of-N (odd forced)
var start_speed := 1.5        # cells per tick on a standard serve
var serve_lob := 0.9          # slow serve — safe, gives you time to read
var serve_flat := 2.2         # fast serve — pressures the receiver
var speed_up := 0.25          # added to ball speed on every return
var edge_bonus := 0.15        # extra speed per cell of "edge" on the return
var smash_bonus := 0.4        # extra speed for moving TOWARD the incoming ball
var jitter := 0.06            # random ± speed perturbation per return
var max_speed := 3.0
var swept_collision := false  # true = ball can't skip over coverage (see README)
var paddle_radius := 1        # paddle covers pos ± this many cells...
var shrink_every := 6         # ...minus 1 per this many returns (min 0)
var players := 1              # 1 = vs CPU, 2 = two humans on one keyboard
var ai_delay := 2             # ticks the CPU freezes when a shot heads its way
var ai_error := 0.10          # chance per incoming shot the CPU commits to a wrong read
var aim_assist := true        # mark the ball's next landing cell on the map
var use_color := true
var clear_screen := true

# --- Game state ---
var state := State.PLAYING
var ball_live := false        # false = between points, waiting to serve
var ball_pos := 0.0           # float! cells are just where it gets drawn
var ball_vel := 0.0           # cells per tick; sign = direction
var player_pos := 2
var ai_pos := 17
var ai_frozen := 0            # reaction ticks the CPU has left
var ai_misread := 0           # persistent cell offset while it reads a shot wrong
var ai_move_dir := 0          # which way the CPU moved this tick (for smashes)
var serve_dir := 1            # which side the next serve flies toward
var player_score := 0
var ai_score := 0
var set_you := 0              # matches won this series
var set_cpu := 0
var matches_needed := 2       # matches_to_win (set in _validate_config)
var rally_len := 0            # returns so far this point
var mid := 10                 # the halves split here (set in _validate_config)
var game_running := true
var last_message := ""
var last_tone := "info"       # info | hint | warn | bad | good
var _input_lines: Array = []  # queued lines when stdin delivers a chunk

# --- Session stats ---
var matches_won := 0
var matches_lost := 0
var series_won := 0
var series_lost := 0
var longest_rally := 0

# --- Career record (settings.cfg [scores]) ---
var career_won := 0
var career_lost := 0
var best_rally := 0


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
	_start_series()
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
	points_to_win = int(config.get_value("game", "points_to_win", points_to_win))
	series_length = int(config.get_value("game", "series_length", series_length))
	start_speed = float(config.get_value("game", "start_speed", start_speed))
	serve_lob = float(config.get_value("game", "serve_lob", serve_lob))
	serve_flat = float(config.get_value("game", "serve_flat", serve_flat))
	speed_up = float(config.get_value("game", "speed_up", speed_up))
	edge_bonus = float(config.get_value("game", "edge_bonus", edge_bonus))
	smash_bonus = float(config.get_value("game", "smash_bonus", smash_bonus))
	jitter = float(config.get_value("game", "jitter", jitter))
	max_speed = float(config.get_value("game", "max_speed", max_speed))
	swept_collision = bool(config.get_value("game", "swept_collision", swept_collision))
	paddle_radius = int(config.get_value("game", "paddle_radius", paddle_radius))
	shrink_every = int(config.get_value("game", "shrink_every", shrink_every))
	players = int(config.get_value("game", "players", players))
	ai_delay = int(config.get_value("ai", "reaction_delay", ai_delay))
	ai_error = float(config.get_value("ai", "error_rate", ai_error))
	aim_assist = bool(config.get_value("ui", "aim_assist", aim_assist))
	use_color = bool(config.get_value("ui", "use_color", use_color))
	clear_screen = bool(config.get_value("ui", "clear_screen", clear_screen))
	_load_scores(config)
	_validate_config()


func _save_default_config(config: ConfigFile) -> void:
	config.set_value("game", "track_length", track_length)
	config.set_value("game", "points_to_win", points_to_win)
	config.set_value("game", "series_length", series_length)
	config.set_value("game", "start_speed", start_speed)
	config.set_value("game", "serve_lob", serve_lob)
	config.set_value("game", "serve_flat", serve_flat)
	config.set_value("game", "speed_up", speed_up)
	config.set_value("game", "edge_bonus", edge_bonus)
	config.set_value("game", "smash_bonus", smash_bonus)
	config.set_value("game", "jitter", jitter)
	config.set_value("game", "max_speed", max_speed)
	config.set_value("game", "swept_collision", swept_collision)
	config.set_value("game", "paddle_radius", paddle_radius)
	config.set_value("game", "shrink_every", shrink_every)
	config.set_value("game", "players", players)
	config.set_value("ai", "reaction_delay", ai_delay)
	config.set_value("ai", "error_rate", ai_error)
	config.set_value("ui", "aim_assist", aim_assist)
	config.set_value("ui", "use_color", use_color)
	config.set_value("ui", "clear_screen", clear_screen)
	if config.save(CONFIG_PATH) == OK:
		print("Created settings.cfg with defaults — edit it to change the game.")


func _validate_config() -> void:
	track_length = maxi(track_length, 8)
	points_to_win = maxi(points_to_win, 1)
	series_length = maxi(series_length, 1)
	if series_length % 2 == 0:
		series_length += 1   # best-of-N needs an odd N
	matches_needed = series_length / 2 + 1
	start_speed = clampf(start_speed, 0.5, 5.0)
	serve_lob = clampf(serve_lob, 0.3, 5.0)
	serve_flat = clampf(serve_flat, 0.5, 6.0)
	speed_up = maxf(speed_up, 0.0)
	edge_bonus = maxf(edge_bonus, 0.0)
	smash_bonus = maxf(smash_bonus, 0.0)
	jitter = clampf(jitter, 0.0, 0.5)
	max_speed = clampf(max_speed, start_speed, 6.0)
	paddle_radius = clampi(paddle_radius, 0, 4)
	shrink_every = maxi(shrink_every, 1)
	players = clampi(players, 1, 2)
	ai_delay = maxi(ai_delay, 0)
	ai_error = clampf(ai_error, 0.0, 1.0)
	mid = track_length / 2


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
	career_won = int(config.get_value("scores", "matches_won", 0))
	career_lost = int(config.get_value("scores", "matches_lost", 0))
	best_rally = int(config.get_value("scores", "best_rally", 0))


func _save_scores() -> void:
	# Only worth writing if something was actually played this session.
	if matches_won + matches_lost == 0 and longest_rally == 0:
		return
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)   # reload so unrelated edits aren't lost
	config.set_value("scores", "matches_won", career_won + matches_won)
	config.set_value("scores", "matches_lost", career_lost + matches_lost)
	config.set_value("scores", "best_rally", maxi(best_rally, longest_rally))
	config.save(CONFIG_PATH)


# --- INPUT -----------------------------------------------------------------

func _read_input() -> String:
	if state == State.SERIES_OVER:
		printraw("\nNew series? (y/n): ")
	elif state == State.MATCH_OVER:
		printraw("\nNext match? (y/n): ")
	elif not ball_live:
		var keys := "a/d + ,/." if players == 2 else "l/r"
		printraw("\nServe: 1=lob 2/Enter=flat 3=hard  (%s positions): " % keys)
	else:
		printraw("\nMove (%s): " % ("l/r/w" if players == 1 else "P1 a/d, P2 ,/."))
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
		State.MATCH_OVER:
			match input:
				"y", "yes": _start_match()
				"n", "no", "quit", "q": game_running = false
				_: _say("Please answer 'y' or 'n'.", "warn")
		State.SERIES_OVER:
			match input:
				"y", "yes": _start_series()
				"n", "no", "quit", "q": game_running = false
				_: _say("Please answer 'y' or 'n'.", "warn")


func _update_playing(input: String) -> void:
	match input:
		"quit", "q":
			game_running = false
			_say("You walk off the court at %d-%d." % [player_score, ai_score])
			return
		"help", "h", "?":
			_print_help()
			return
		_:
			pass
	if not ball_live:
		# Between points the world doesn't tick — positioning is free,
		# and the server picks a speed: lob (safe) or flat (risky).
		match input:
			"", "s", "serve", "2":
				_serve(start_speed, "Serve!")
			"1", "lob":
				_serve(serve_lob, "Lob serve — slow and readable.")
			"3", "flat":
				_serve(serve_flat, "Flat serve — hard to read!")
			_:
				var d := _parse_moves(input)
				if d.is_empty() and players == 1:
					match input:
						"left": d = [-1, 0]
						"right": d = [1, 0]
				if d.is_empty():
					_say("Serve with 1/2/3, or set position first.", "warn")
				else:
					player_pos = clampi(player_pos + d[0], 0, mid - 1)
					if players == 2:
						ai_pos = clampi(ai_pos + d[1], mid, track_length - 1)
					_say("Position: P1 cell %d, %s cell %d." % [
						player_pos, _foe(), ai_pos])
		return
	if players == 2:
		var d := _parse_moves(input)
		if d.is_empty():
			_say("P1 moves with a/d (l/r ok), P2 with ,/. — 'w' waits.", "warn")
		else:
			_take_turn(d[0], d[1])
		return
	match input:
		"left", "l", "a":
			_take_turn(-1, 0)
		"right", "r", "d":
			_take_turn(1, 0)
		"wait", "w", "":
			_take_turn(0, 0)
		_:
			_say("Unknown move — use l/r/w, or 'quit'.", "warn")


func _parse_moves(input: String) -> Array:
	# Two-player lines: char 1 drives P1, char 2 drives P2 — "a," moves
	# P1 left and P2 left. One char alone means P2 waits. Returns []
	# for unrecognized input. Single-player uses the word commands.
	if input.length() > 2:
		return []
	# A lone P2 key means "P2 moves, P1 waits".
	if input == ",": return [0, -1]
	if input == ".": return [0, 1]
	var chars := " " + input   # pad so substr() is always safe
	var d1 := 0
	var d2 := 0
	match chars.substr(1, 1):
		"a", "l": d1 = -1
		"d", "r": d1 = 1
		"w", " ", ",", ".", "": d1 = 0
		_: return []
	match chars.substr(2, 1):
		",", "l": d2 = -1
		".", "r": d2 = 1
		"w", " ", "a", "d", "": d2 = 0
		_: return []
	return [d1, d2]


func _foe() -> String:
	return "P2" if players == 2 else "the CPU"


func _foe_cap() -> String:
	# Sentence-initial form. Not .capitalize() — it would mangle "P2" to "P 2".
	return "P2" if players == 2 else "The CPU"


func _foe_possessive() -> String:
	return "P2's" if players == 2 else "the CPU's"


func _take_turn(dir1: int, dir2: int) -> void:
	# Every action — including waiting — is one tick of the world: both
	# paddles move one cell, then the ball flies. Same rule as the
	# firefly: the world doesn't pause for you.
	if dir1 != 0:
		player_pos = clampi(player_pos + dir1, 0, mid - 1)
	if players == 2:
		if dir2 != 0:
			ai_pos = clampi(ai_pos + dir2, mid, track_length - 1)
	else:
		_update_ai()
	var prev_pos := ball_pos
	ball_pos += ball_vel
	var cell := floori(ball_pos)
	# A ball past the goal line is gone — check before returns so a
	# paddle can't "cover" cells that are already out.
	if cell < 0:
		_point_to("ai")
		return
	if cell >= track_length:
		_point_to("player")
		return
	# Only a ball that LANDS on a covered cell comes back — with speed
	# > 1 it can sail clean over the paddle's reach between landings.
	# (swept_collision changes this — see _hit_cell.)
	if ball_vel < 0.0:
		var hit := _hit_cell(prev_pos, player_pos)
		if hit >= 0:
			if swept_collision:
				ball_pos = float(hit)   # bounce at the contact cell
			_return_ball(1, hit, player_pos, dir1)
			return
	else:
		var hit := _hit_cell(prev_pos, ai_pos)
		if hit >= 0:
			if swept_collision:
				ball_pos = float(hit)
			_return_ball(-1, hit, ai_pos,
				dir2 if players == 2 else ai_move_dir)
			return
	_flight_report(cell)


func _hit_cell(prev_pos: float, paddle: int) -> int:
	# Returns the cell the ball is intercepted on, or -1. Default rule:
	# only the landing cell counts. With swept_collision on, ANY covered
	# cell the ball crossed this tick intercepts it — the paddle becomes
	# a wall, which plays much worse (see README). Implemented so you
	# can feel the difference.
	var cell := floori(ball_pos)
	var cov := _coverage()
	if not swept_collision:
		return cell if absi(cell - paddle) <= cov else -1
	var lo := mini(cell, floori(prev_pos))
	var hi := maxi(cell, floori(prev_pos))
	if ball_vel < 0.0:
		# moving left: first contact is the highest covered cell crossed
		for c in range(hi, lo - 1, -1):
			if absi(c - paddle) <= cov:
				return c
	else:
		for c in range(lo, hi + 1):
			if absi(c - paddle) <= cov:
				return c
	return -1


func _flight_report(cell: int) -> void:
	var next := floori(ball_pos + ball_vel)
	if ball_vel < 0.0:
		if next < 0:
			_say("Ball lands at cell %d — your wall is NEXT!" % cell, "warn")
		elif absi(next - player_pos) <= _coverage():
			_say("Ball lands at cell %d — next: cell %d, covered." % [cell, next], "hint")
		else:
			_say("Ball lands at cell %d — next: cell %d — move!" % [cell, next], "warn")
	else:
		if next >= track_length:
			_say("Ball lands at cell %d — one tick from %s wall!" % [
				cell, _foe_possessive()], "hint")
		else:
			_say("Ball sails on at cell %d — %s lines it up." % [cell, _foe()])


func _return_ball(direction: int, cell: int, paddle: int, move_dir: int) -> void:
	# direction = which way the ball now flies: +1 toward the right side.
	var coverage_before := _coverage()
	rally_len += 1
	var shrunk := _coverage() < coverage_before
	# Edge hits are the 1D version of paddle angle: meeting the ball on
	# the mid-court edge of your reach ("edge" > 0) is a drive — extra
	# speed. Scooping it off your wall line ("edge" < 0) is a weak dig.
	var edge := cell - paddle if direction > 0 else paddle - cell
	# Smash: you moved TOWARD the incoming ball on its landing tick —
	# move_dir == direction means you stepped into the shot. Aggression
	# pays: extra speed, same hard ceiling.
	var smashed := move_dir == direction and move_dir != 0
	# The edge bonus applies past the cap — a drive can exceed max_speed
	# (up to the hard ceiling), so positioning always changes the shot,
	# even once the ball is at top speed.
	var speed := minf(absf(ball_vel) + speed_up, max_speed)
	speed += edge * edge_bonus + (smash_bonus if smashed else 0.0)
	# Jitter: no two real paddle contacts are identical. Even a parked
	# return perturbs the landing lattice by a hair — this is what makes
	# dead-center orbits impossible and guarantees every point ends.
	speed = clampf(speed + randf_range(-jitter, jitter),
		0.5, max_speed * 1.25)
	ball_vel = direction * speed
	var contact := "back it goes!"
	if edge > 0:
		contact = "driven back!"
	elif edge < 0:
		contact = "dug out."
	if smashed:
		contact = "SMASHED!"
	if shrunk:
		contact += " Coverage now ±%d!" % _coverage()
	if direction > 0:
		# The CPU needs a beat to read your return — and may read it wrong.
		ai_frozen = ai_delay
		ai_misread = _ai_roll_misread()
		_say("%s meet it at cell %d — %s Speed: %.1f cells/tick." % [
			"P1" if players == 2 else "You", cell, contact, speed],
			"hint" if edge > 0 or smashed else "info")
	else:
		var verb := "gets a paddle on it"
		if smashed:
			verb = "smashes it back"
		elif edge > 0:
			verb = "drives it back"
		var extra := ""
		if shrunk:
			extra = " Coverage now ±%d!" % _coverage()
		_say("%s %s at cell %d. Speed: %.1f cells/tick.%s" % [
			_foe_cap(), verb, cell, speed, extra],
			"warn" if edge > 0 or smashed else "info")


func _point_to(who: String) -> void:
	ball_live = false
	longest_rally = maxi(longest_rally, rally_len)
	if who == "player":
		player_score += 1
		serve_dir = 1    # they conceded — they receive the next serve
	else:
		ai_score += 1
		serve_dir = -1
	if player_score >= points_to_win or ai_score >= points_to_win:
		_end_match()
		return
	if who == "player":
		_say("You score! %d-%d — press Enter to serve." % [
			player_score, ai_score], "good")
	else:
		_say("The ball slips past you — %s scores! %d-%d." % [
			_foe(), player_score, ai_score], "bad")


func _end_match() -> void:
	# A match win feeds the series score; the series ends when one side
	# reaches matches_needed (best-of-N).
	if player_score > ai_score:
		set_you += 1
		matches_won += 1
	else:
		set_cpu += 1
		matches_lost += 1
	var tag := "Match point — %s %d-%d!" % [
		"YOU take it" if player_score > ai_score else "%s takes it" % _foe(),
		player_score, ai_score]
	if set_you >= matches_needed or set_cpu >= matches_needed:
		_end_series(tag)
		return
	state = State.MATCH_OVER
	_say("%s Series: %d-%d." % [tag, set_you, set_cpu],
		"good" if player_score > ai_score else "bad")


func _end_series(tag: String) -> void:
	state = State.SERIES_OVER
	if set_you > set_cpu:
		series_won += 1
		_say("%s SERIES YOURS, %d-%d!" % [tag, set_you, set_cpu], "good")
	else:
		series_lost += 1
		_say("%s %s takes the series %d-%d." % [
			tag, _foe_cap(), set_you, set_cpu], "bad")


func _serve(speed: float, label: String) -> void:
	ball_pos = (track_length - 1) / 2.0
	ball_vel = serve_dir * speed
	rally_len = 0
	ball_live = true
	if serve_dir > 0:
		ai_frozen = ai_delay
		ai_misread = _ai_roll_misread()
	_say("%s The ball flies %s at %.1f cells/tick." % [
		label, "to you" if serve_dir < 0 else "to %s" % _foe(), speed])


func _start_match() -> void:
	player_score = 0
	ai_score = 0
	player_pos = mid / 2                     # a quarter of the track in
	ai_pos = track_length - 1 - mid / 2
	serve_dir = 1 if randi() % 2 == 0 else -1
	ball_live = false
	rally_len = 0
	ai_frozen = 0
	ai_misread = 0
	ai_move_dir = 0
	state = State.PLAYING
	var set_info := ""
	if series_length > 1:
		set_info = " (series %d-%d)" % [set_you, set_cpu]
	_say("Match %d — first to %d.%s Serve: 1=lob 2=flat 3=hard." % [
		set_you + set_cpu + 1, points_to_win, set_info])


func _start_series() -> void:
	set_you = 0
	set_cpu = 0
	_start_match()


func _coverage() -> int:
	# The faster the rally, the harder the ball is to control: effective
	# coverage shrinks by one cell every shrink_every returns, to a
	# floor of zero — dead-center hits only. This is the rule that
	# guarantees no point lasts forever: past a certain rally length the
	# sparse high-speed landings must eventually slip through.
	return maxi(paddle_radius - rally_len / shrink_every, 0)


# --- CPU opponent ----------------------------------------------------------

func _update_ai() -> void:
	ai_move_dir = 0
	if ball_vel <= 0.0:
		# Ball heading away — drift back toward the middle of its half.
		var home := mid + (track_length - 1 - mid) / 2
		if ai_pos != home:
			ai_pos += signi(home - ai_pos)
		return
	if ai_frozen > 0:
		ai_frozen -= 1   # hasn't read your shot yet
		return
	var target := clampi(_ai_pick_target() + ai_misread,
		mid, track_length - 1)
	if absi(target - ai_pos) > _coverage():
		# Clamp: a misread target must never drag the CPU out of its half.
		ai_move_dir = signi(target - ai_pos)
		ai_pos = clampi(ai_pos + ai_move_dir, mid, track_length - 1)


func _ai_roll_misread() -> int:
	# Rolled once per incoming shot: with probability ai_error the CPU
	# commits to a landing cell 2-4 cells off the real one for the whole
	# approach — a persistent misread it can't recover from.
	if randf() < ai_error:
		return randi_range(2, 4) * (1 if randi() % 2 == 0 else -1)
	return 0


func _ai_pick_target() -> int:
	# Simulate the ball's future landing cells; pick the first one the
	# CPU can cover in time. If none are reachable, sprint for the last
	# landing before the wall — a desperation dive.
	var pos := ball_pos
	var last := track_length - 1
	var t := 0
	while true:
		t += 1
		pos += ball_vel
		var c := floori(pos)
		if c >= track_length:
			break
		last = maxi(c, mid)
		if absi(c - ai_pos) <= _coverage() + t:
			return c
	return last


# --- RENDER ----------------------------------------------------------------

func _render() -> void:
	if clear_screen:
		_clear_screen()
	elif last_message != "":
		print("")
	_print_hud()
	if last_message != "":
		print(_tone(last_message, last_tone))
	if state == State.MATCH_OVER and game_running:
		print(_c("Series %d-%d | Session: %dW-%dL | Best rally: %d" % [
			set_you, set_cpu, matches_won, matches_lost,
			maxi(best_rally, longest_rally)], "1;36"))
	if state == State.SERIES_OVER and game_running:
		print(_c("Session: %dW-%dL matches, %dW-%dL series | Career: %dW-%dL | Best rally: %d" % [
			matches_won, matches_lost, series_won, series_lost,
			career_won + matches_won, career_lost + matches_lost,
			maxi(best_rally, longest_rally)], "1;36"))


func _print_hud() -> void:
	var cells := PackedStringArray()
	var ball_cell := floori(ball_pos) if ball_live else -1
	var next_cell := -1
	if ball_live and aim_assist:
		next_cell = floori(ball_pos + ball_vel)
	for i in track_length:
		var s := "."
		var code := "90"
		if i == player_pos:
			s = "P"
			code = "1;32"
		elif i == ai_pos:
			s = "2" if players == 2 else "C"
			code = "1;35" if players == 2 else "1;31"
		elif i == ball_cell:
			s = "o"
			code = _ball_heat()
		elif i == next_cell:
			s = "*"
			code = "36"
		elif absi(i - player_pos) <= _coverage() \
				or absi(i - ai_pos) <= _coverage():
			s = "-"
		cells.append(_c(s, code))
	print(_c("=== 1D PONG ===", "1;36"))
	print("[%s]" % " ".join(cells))
	var score_line := "%s %d — %d %s   first to %d" % [
		"P1" if players == 2 else "You", player_score,
		ai_score, "P2" if players == 2 else "CPU", points_to_win]
	if series_length > 1:
		score_line += "   series %d-%d (bo%d)" % [set_you, set_cpu, series_length]
	print(score_line)
	if ball_live:
		print("Ball: cell %d   speed %.1f/tick   heading: %s   rally %d   cover ±%d" % [
			floori(ball_pos), absf(ball_vel),
			"LEFT <<" if ball_vel < 0.0 else ">> RIGHT",
			rally_len, _coverage()])
	else:
		print("Serve is headed: %s" % (
			"LEFT <<" if serve_dir < 0 else ">> RIGHT"))
	if players == 2:
		print(_c("P1=green -=covered 2=P2 o=ball(heat) *=next  P1:a/d P2:,/.", "90"))
	else:
		print(_c("P=you -=covered C=cpu o=ball(heat) *=next landing  l/r/w", "90"))
	print(_c("-".repeat(52), "90"))


func _ball_heat() -> String:
	# Ball color is its speed tier — the difficulty curve made visible.
	var speed := absf(ball_vel)
	if speed < 2.0:
		return "1;33"   # yellow — readable
	if speed < 3.0:
		return "95"     # magenta — getting hot
	return "1;31"       # red — dead-center territory soon


# --- Output helpers --------------------------------------------------------

func _say(text: String, tone := "info") -> void:
	# All status messages funnel through here so render() can color by tone.
	last_message = text
	last_tone = tone


func _tone(text: String, tone: String) -> String:
	match tone:
		"good": return _c(text, "1;32")   # bold green  — your points
		"bad":  return _c(text, "1;31")   # bold red    — CPU points
		"warn": return _c(text, "33")     # yellow      — danger, bad input
		"hint": return _c(text, "36")     # cyan        — returns, coverage
		_:      return text               # info        — plain


func _c(text: String, code: String) -> String:
	if not use_color:
		return text
	return ESC + "[" + code + "m" + text + ESC + "[0m"


func _clear_screen() -> void:
	printraw(ESC + "[2J" + ESC + "[H")


# --- Bookkeeping -----------------------------------------------------------

func _print_intro() -> void:
	print("=== 1D PONG ===")
	print("Defend your wall on a %d-cell track. The ball returns only if" % track_length)
	print("it LANDS on a cell your paddle covers (-) — and every return")
	print("makes it faster. First to %d wins a match%s." % [
		points_to_win,
		"; best of %d wins the series" % series_length
			if series_length > 1 else ""])
	if players == 2:
		print("Two-player mode — P1: a/d, P2: ,/. on the same line.")


func _print_outro() -> void:
	print("")
	if matches_won + matches_lost > 0:
		print(_c("=== Session: %dW-%dL matches, %dW-%dL series | Career: %dW-%dL | Longest rally: %d ===" % [
			matches_won, matches_lost, series_won, series_lost,
			career_won + matches_won, career_lost + matches_lost,
			maxi(best_rally, longest_rally)], "1;36"))
	else:
		print("=== No finished matches. See you next time! ===")


func _print_help() -> void:
	# Route through _say() so the text survives the next _render()'s
	# screen clear — direct print() output would be wiped instantly.
	var moves := "Moves: l/r (or a/d), w/wait (or just Enter), quit/q"
	if players == 2:
		moves = "P1: a/d  P2: ,/.  — both on one line, e.g. 'a,' — w waits"
	_say(moves + "\n"
		+ "Serve: 1=lob 2=flat 3=hard. A ball returns only when it\n"
		+ "LANDS on a covered (-) cell — * shows the next landing.\n"
		+ "Edge of your reach = faster return. Step INTO it = SMASH.")
