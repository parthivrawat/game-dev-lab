extends SceneTree

## 1D Pong — Stage 1, Game 3.
## Game 2's drifting firefly grew up: the ball now has real velocity —
## a float position and a speed in cells per tick — and once speed
## passes 1.0 it SKIPS cells. You and the CPU defend opposite walls: a
## shot is returned only if the ball LANDS on a cell the paddle covers
## (paddle_pos ± paddle_radius). Landings get sparser as the rally
## speeds up — read them early or the ball slips through. Meet it on
## the mid-court edge of your reach for a faster "drive" return.
##
## Run from a terminal inside this folder:
##     godot --headless --script main.gd      (or double-click run.bat)
##
## Game rules live in settings.cfg — created with defaults on first run.
## Career record and best rally persist under [scores]. Note: saving
## rewrites the file — hand-written comments in it are not preserved.

const CONFIG_PATH := "res://settings.cfg"
const ESC := "\u001b"   # ANSI escape character

enum State { PLAYING, MATCH_OVER }

# --- Configuration (settings.cfg; these are the defaults) ---
var track_length := 20
var points_to_win := 5
var start_speed := 1.5        # cells per tick on serve
var speed_up := 0.25          # added to ball speed on every return
var edge_bonus := 0.15        # extra speed per cell of "edge" on the return
var max_speed := 3.0
var paddle_radius := 1        # paddle covers pos ± this many cells...
var shrink_every := 6         # ...minus 1 per this many returns (min 0)
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
var serve_dir := 1            # which side the next serve flies toward
var player_score := 0
var ai_score := 0
var rally_len := 0            # returns so far this point
var mid := 10                 # the halves split here (set in _validate_config)
var game_running := true
var last_message := ""
var last_tone := "info"       # info | hint | warn | bad | good
var _input_lines: Array = []  # queued lines when stdin delivers a chunk

# --- Session stats ---
var matches_won := 0
var matches_lost := 0
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
	_start_match()
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
	start_speed = float(config.get_value("game", "start_speed", start_speed))
	speed_up = float(config.get_value("game", "speed_up", speed_up))
	edge_bonus = float(config.get_value("game", "edge_bonus", edge_bonus))
	max_speed = float(config.get_value("game", "max_speed", max_speed))
	paddle_radius = int(config.get_value("game", "paddle_radius", paddle_radius))
	shrink_every = int(config.get_value("game", "shrink_every", shrink_every))
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
	config.set_value("game", "start_speed", start_speed)
	config.set_value("game", "speed_up", speed_up)
	config.set_value("game", "edge_bonus", edge_bonus)
	config.set_value("game", "max_speed", max_speed)
	config.set_value("game", "paddle_radius", paddle_radius)
	config.set_value("game", "shrink_every", shrink_every)
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
	start_speed = clampf(start_speed, 0.5, 5.0)
	speed_up = maxf(speed_up, 0.0)
	edge_bonus = maxf(edge_bonus, 0.0)
	max_speed = clampf(max_speed, start_speed, 6.0)
	paddle_radius = clampi(paddle_radius, 0, 4)
	shrink_every = maxi(shrink_every, 1)
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
	if state == State.MATCH_OVER:
		printraw("\nRematch? (y/n): ")
	elif not ball_live:
		printraw("\nPress Enter to serve (l/r sets position): ")
	else:
		printraw("\nMove (l/r/w): ")
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
			_update_match_over(input)


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
		# Between points the world doesn't tick — l/r is free positioning.
		match input:
			"", "s", "serve":
				_serve()
			"left", "l":
				player_pos = clampi(player_pos - 1, 0, mid - 1)
				_say("You take position at cell %d." % player_pos)
			"right", "r":
				player_pos = clampi(player_pos + 1, 0, mid - 1)
				_say("You take position at cell %d." % player_pos)
			_:
				_say("Press Enter to serve (l/r sets your position).", "warn")
		return
	match input:
		"left", "l":
			_take_turn(-1)
		"right", "r":
			_take_turn(1)
		"wait", "w", "":
			_take_turn(0)
		_:
			_say("Unknown move — use l/r/w, or 'quit'.", "warn")


func _update_match_over(input: String) -> void:
	match input:
		"y", "yes":
			_start_match()
		"n", "no", "quit", "q":
			game_running = false
		_:
			_say("Please answer 'y' or 'n'.", "warn")


func _take_turn(direction: int) -> void:
	# Every action — including waiting — is one tick of the world: your
	# paddle moves one cell, the CPU moves one cell, then the ball
	# flies. Same rule as the firefly: the world doesn't pause for you.
	if direction != 0:
		player_pos = clampi(player_pos + direction, 0, mid - 1)
	_update_ai()
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
	if ball_vel < 0.0 and absi(cell - player_pos) <= _coverage():
		_return_ball(1, cell, player_pos)
		return
	if ball_vel > 0.0 and absi(cell - ai_pos) <= _coverage():
		_return_ball(-1, cell, ai_pos)
		return
	_flight_report(cell)


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
			_say("Ball lands at cell %d — one tick from the CPU's wall!" % cell, "hint")
		else:
			_say("Ball sails on at cell %d — the CPU lines it up." % cell)


func _return_ball(direction: int, cell: int, paddle: int) -> void:
	# direction = which way the ball now flies: +1 toward the CPU.
	var coverage_before := _coverage()
	rally_len += 1
	var shrunk := _coverage() < coverage_before
	# Edge hits are the 1D version of paddle angle: meeting the ball on
	# the mid-court edge of your reach ("edge" > 0) is a drive — extra
	# speed. Scooping it off your wall line ("edge" < 0) is a weak dig.
	# Without this, a fast ball settles into a fixed orbit neither side
	# can break — this is what keeps rallies alive.
	var edge := cell - paddle if direction > 0 else paddle - cell
	# The edge bonus applies past the cap — a drive can exceed max_speed
	# (up to the hard ceiling), so positioning always changes the shot,
	# even once the ball is at top speed.
	var speed := minf(absf(ball_vel) + speed_up, max_speed)
	speed = minf(speed + edge * edge_bonus, max_speed * 1.25)
	ball_vel = direction * speed
	var contact := "back it goes!"
	if edge > 0:
		contact = "driven back!"
	elif edge < 0:
		contact = "dug out."
	if shrunk:
		contact += " Coverage now ±%d!" % _coverage()
	if direction > 0:
		# The CPU needs a beat to read your return — and may read it wrong.
		ai_frozen = ai_delay
		ai_misread = _ai_roll_misread()
		_say("You meet it at cell %d — %s Speed: %.1f cells/tick." % [
			cell, contact, speed], "hint" if edge > 0 else "info")
	else:
		var extra := ""
		if shrunk:
			extra = " Coverage now ±%d!" % _coverage()
		_say("The CPU %s at cell %d. Speed: %.1f cells/tick.%s" % [
			"drives it back" if edge > 0 else "gets a paddle on it",
			cell, speed, extra],
			"warn" if edge > 0 else "info")


func _point_to(who: String) -> void:
	ball_live = false
	longest_rally = maxi(longest_rally, rally_len)
	if who == "player":
		player_score += 1
		serve_dir = 1    # the CPU conceded — it receives the next serve
	else:
		ai_score += 1
		serve_dir = -1   # you conceded — you receive
	if player_score >= points_to_win or ai_score >= points_to_win:
		_end_match()
		return
	if who == "player":
		_say("You score! %d-%d — press Enter to serve." % [
			player_score, ai_score], "good")
	else:
		_say("The ball slips past you — CPU scores! %d-%d." % [
			player_score, ai_score], "bad")


func _end_match() -> void:
	state = State.MATCH_OVER
	if player_score > ai_score:
		matches_won += 1
		_say("Match point — YOU take it %d-%d!" % [player_score, ai_score], "good")
	else:
		matches_lost += 1
		_say("Match point — the CPU takes it %d-%d." % [
			player_score, ai_score], "bad")


func _serve() -> void:
	ball_pos = (track_length - 1) / 2.0
	ball_vel = serve_dir * start_speed
	rally_len = 0
	ball_live = true
	if serve_dir > 0:
		ai_frozen = ai_delay
		ai_misread = _ai_roll_misread()
	_say("Serve! The ball flies %s at %.1f cells/tick." % [
		"to you" if serve_dir < 0 else "to the CPU", start_speed])


func _start_match() -> void:
	player_score = 0
	ai_score = 0
	player_pos = mid / 2                     # a quarter of the track in
	ai_pos = track_length - 1 - mid / 2
	serve_dir = 1 if randi() % 2 == 0 else -1
	ball_live = false
	rally_len = 0
	ai_frozen = 0
	state = State.PLAYING
	_say("New match — first to %d. Press Enter to serve." % points_to_win)


func _coverage() -> int:
	# The faster the rally, the harder the ball is to control: effective
	# coverage shrinks by one cell every shrink_every returns, to a
	# floor of zero — dead-center hits only. This is the rule that
	# guarantees no point lasts forever: past a certain rally length the
	# sparse high-speed landings must eventually slip through.
	return maxi(paddle_radius - rally_len / shrink_every, 0)


# --- CPU opponent ----------------------------------------------------------

func _update_ai() -> void:
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
		ai_pos = clampi(ai_pos + signi(target - ai_pos), mid, track_length - 1)


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
		print(_c("Session: %dW-%dL | Career: %dW-%dL | Best rally: %d" % [
			matches_won, matches_lost,
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
			s = "C"
			code = "1;31"
		elif i == ball_cell:
			s = "o"
			code = "1;33"
		elif i == next_cell:
			s = "*"
			code = "36"
		elif absi(i - player_pos) <= _coverage() \
				or absi(i - ai_pos) <= _coverage():
			s = "-"
		cells.append(_c(s, code))
	print(_c("=== 1D PONG ===", "1;36"))
	print("[%s]" % " ".join(cells))
	print("You %d — %d CPU   first to %d" % [
		player_score, ai_score, points_to_win])
	if ball_live:
		print("Ball: cell %d   speed %.1f/tick   heading: %s   rally %d" % [
			floori(ball_pos), absf(ball_vel),
			"YOU <<" if ball_vel < 0.0 else ">> CPU", rally_len])
	else:
		print("Serve is headed: %s" % (
			"YOU <<" if serve_dir < 0 else ">> CPU"))
	print(_c("P=you -=covered C=cpu o=ball *=next landing  l/r/w", "90"))
	print(_c("-".repeat(52), "90"))


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
	print("makes it faster. First to %d wins the match." % points_to_win)


func _print_outro() -> void:
	print("")
	if matches_won + matches_lost > 0:
		print(_c("=== Session: %dW-%dL | Career: %dW-%dL | Longest rally: %d ===" % [
			matches_won, matches_lost,
			career_won + matches_won, career_lost + matches_lost,
			maxi(best_rally, longest_rally)], "1;36"))
	else:
		print("=== No finished matches. See you next time! ===")


func _print_help() -> void:
	# Route through _say() so the text survives the next _render()'s
	# screen clear — direct print() output would be wiped instantly.
	_say("Moves: l/left, r/right, w/wait (or just Enter), quit/q\n"
		+ "A ball returns only when it LANDS on a covered (-) cell.\n"
		+ "Watch the * — that's where it lands next. Speed >1 skips cells!")
