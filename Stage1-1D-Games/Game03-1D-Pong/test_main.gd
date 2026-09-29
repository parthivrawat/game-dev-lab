extends SceneTree

## Tests for 1D Pong (main.gd).
## Run from a terminal inside this folder:
##     godot --headless --script test_main.gd      (or run_tests.bat)
##
## How it works: the game lives in _initialize() — Godot only calls that
## for the script it launches as the main loop. Instantiating main.gd
## here builds a game object WITHOUT starting a session, so each test
## places ball and paddles directly and calls the logic functions one
## at a time. Tests set jitter = 0 where exact speeds are asserted, and
## never write settings.cfg (only _load_config/_save_scores touch it).

const Game := preload("res://main.gd")

var _checks := 0
var _failures := 0
var _games: Array = []   # live game objects, freed after each test


func _initialize() -> void:
	var names: Array = []
	for m in get_script().get_script_method_list():
		if String(m.name).begins_with("test_"):
			names.append(m.name)
	names.sort()
	for name in names:
		var failures_before := _failures
		call(name)
		for g in _games:
			g.free()
		_games.clear()
		print("%s%s" % ["PASS  " if _failures == failures_before else "FAIL  ", name])
	print("\n%d tests, %d checks, %d failure%s" % [
		names.size(), _checks, _failures, "" if _failures == 1 else "s"])
	quit(1 if _failures > 0 else 0)


# --- Micro test framework -----------------------------------------------------

func _new_game():
	var g = Game.new()
	g.use_color = false
	g.clear_screen = false
	g.jitter = 0.0      # exact speed assertions need no randomness
	g.ai_error = 0.0
	_games.append(g)
	return g


func expect(condition: bool, msg := "") -> void:
	_checks += 1
	if not condition:
		_failures += 1
		print("    FAILED: ", msg)


func expect_eq(actual: Variant, expected: Variant, msg := "") -> void:
	_checks += 1
	if actual != expected:
		_failures += 1
		print("    FAILED: %s — expected <%s>, got <%s>" % [msg, expected, actual])


func expect_near(actual: float, expected: float, eps: float, msg := "") -> void:
	_checks += 1
	if absf(actual - expected) > eps:
		_failures += 1
		print("    FAILED: %s — expected ~<%s>, got <%s>" % [msg, expected, actual])


# --- Config -------------------------------------------------------------------

func test_validate_config_repairs_and_derives() -> void:
	var g = _new_game()
	g.track_length = 4
	g.points_to_win = 0
	g.series_length = 4
	g.start_speed = 0.1
	g.max_speed = 0.2
	g.paddle_radius = 9
	g.players = 7
	g._validate_config()
	expect_eq(g.track_length, 8, "track needs room for two halves")
	expect_eq(g.mid, 4, "mid is derived from the clamped length")
	expect_eq(g.points_to_win, 1)
	expect_eq(g.series_length, 5, "best-of-N must be odd")
	expect_eq(g.matches_needed, 3, "majority of 5")
	expect_eq(g.paddle_radius, 4)
	expect_eq(g.players, 2)
	expect_near(g.start_speed, 0.5, 0.001, "speed floors at 0.5")
	expect_near(g.max_speed, g.start_speed, 0.001,
		"max speed never drops below start speed")


func test_coverage_shrinks_as_rally_grows() -> void:
	var g = _new_game()
	g.paddle_radius = 2
	g.shrink_every = 2
	g.rally_len = 0
	expect_eq(g._coverage(), 2)
	g.rally_len = 2
	expect_eq(g._coverage(), 1, "one cell lost per shrink_every returns")
	g.rally_len = 4
	expect_eq(g._coverage(), 0)
	g.rally_len = 50
	expect_eq(g._coverage(), 0, "coverage floors at zero")


# --- The landing rule --------------------------------------------------------------

func test_hit_cell_requires_a_landing() -> void:
	var g = _new_game()
	g.paddle_radius = 1
	g.swept_collision = false
	g.ball_vel = -2.0
	g.ball_pos = 5.9            # lands on cell 5, having crossed cells 8..5
	expect_eq(g._hit_cell(8.5, 4), 5, "landing inside coverage returns")
	expect_eq(g._hit_cell(8.5, 6), 5, "cell 5 is covered by paddle 6 too")
	expect_eq(g._hit_cell(8.5, 7), -1,
		"paddle 7 was crossed mid-flight but the landing is outside — tunneling is the design")


func test_swept_collision_catches_crossings() -> void:
	var g = _new_game()
	g.paddle_radius = 1
	g.swept_collision = true
	g.ball_vel = -2.0
	g.ball_pos = 5.9            # came from 8.5 — crossed cells 8..5
	expect_eq(g._hit_cell(8.5, 7), 8,
		"the shot that tunneled before is caught at the first covered cell")
	g.ball_vel = 2.0
	g.ball_pos = 4.5            # came from 1.5 — crossed cells 1..4
	expect_eq(g._hit_cell(1.5, 5), 4,
		"moving right, the lowest covered cell intercepts first")


func test_ball_past_a_wall_scores() -> void:
	var g = _new_game()
	g.track_length = 20
	g.mid = 10
	g.player_pos = 2
	g.ai_pos = 17
	g.ball_live = true
	g.ball_vel = -1.5
	g.ball_pos = 0.4
	g._take_turn(0, 0)
	expect_eq(g.ai_score, 1, "past your wall is the CPU's point")
	expect(not g.ball_live, "play stops between points")
	expect_eq(g.serve_dir, -1, "the conceding side receives next")
	var g2 = _new_game()
	g2.track_length = 20
	g2.mid = 10
	g2.ball_live = true
	g2.ball_vel = 1.5
	g2.ball_pos = 19.6
	g2._take_turn(0, 0)
	expect_eq(g2.player_score, 1, "past their wall is your point")
	expect_eq(g2.serve_dir, 1)


func test_paddles_stay_in_their_halves() -> void:
	var g = _new_game()
	g.track_length = 20
	g.mid = 10
	g.players = 2
	g.player_pos = 0
	g.ai_pos = 19
	g.ball_live = true
	g.ball_vel = -1.0
	g.ball_pos = 9.5
	g._take_turn(-1, 1)
	expect_eq(g.player_pos, 0, "P1 cannot leave the track")
	expect_eq(g.ai_pos, 19, "P2 cannot leave the track")
	g._take_turn(1, -1)
	expect_eq(g.player_pos, 1)
	expect_eq(g.ai_pos, 18)
	g.player_pos = 9
	g.ai_pos = 10
	g._take_turn(1, -1)
	expect_eq(g.player_pos, 9, "P1 is capped at mid - 1")
	expect_eq(g.ai_pos, 10, "P2 is floored at mid")


# --- Returns ------------------------------------------------------------------------

func test_return_flips_direction_and_adds_speed() -> void:
	var g = _new_game()
	g.paddle_radius = 1
	g.rally_len = 0
	g.ball_vel = -1.5
	g.player_pos = 4
	g._return_ball(1, 4, 4, 0)
	expect_eq(g.rally_len, 1)
	expect_near(g.ball_vel, 1.75, 0.001, "|vel| + speed_up, now heading right")
	expect_eq(g.ai_frozen, g.ai_delay, "the CPU needs a beat to read your shot")


func test_return_edge_adds_drive_speed() -> void:
	var g = _new_game()
	g.paddle_radius = 1
	g.rally_len = 0
	g.ball_vel = -1.5
	g.player_pos = 4
	g._return_ball(1, 5, 4, 0)   # met on the mid-court edge of your reach
	expect_near(g.ball_vel, 1.9, 0.001,
		"edge of reach = drive: base 1.75 + 1 * edge_bonus")
	var g2 = _new_game()
	g2.paddle_radius = 1
	g2.ball_vel = -1.5
	g2.player_pos = 4
	g2._return_ball(1, 3, 4, 0)   # scooped off the wall line — a weak dig
	expect_near(g2.ball_vel, 1.6, 0.001, "negative edge loses speed")


func test_smash_rewards_stepping_into_the_shot() -> void:
	var g = _new_game()
	g.paddle_radius = 1
	g.rally_len = 0
	g.ball_vel = -1.5
	g.player_pos = 4
	g._return_ball(1, 4, 4, 1)   # moved toward the incoming ball
	expect_near(g.ball_vel, 2.15, 0.001, "smash adds smash_bonus")
	var g2 = _new_game()
	g2.paddle_radius = 1
	g2.ball_vel = -1.5
	g2.player_pos = 4
	g2._return_ball(1, 4, 4, -1)  # backed away instead
	expect_near(g2.ball_vel, 1.75, 0.001, "retreating is not a smash")


func test_return_speed_respects_the_caps() -> void:
	var g = _new_game()
	g.paddle_radius = 4
	g.rally_len = 0
	g.max_speed = 3.0
	g.ball_vel = -2.99
	g.player_pos = 4
	g._return_ball(1, 8, 4, 1)   # max edge + smash on a near-max ball
	expect_near(g.ball_vel, minf(3.0 + 4 * g.edge_bonus + g.smash_bonus,
		g.max_speed * 1.25), 0.001,
		"edge and smash stack past max_speed but under the hard ceiling")
	expect(g.ball_vel <= g.max_speed * 1.25 + 0.001, "hard ceiling holds")


func test_cpu_return_headed_left() -> void:
	var g = _new_game()
	g.paddle_radius = 1
	g.rally_len = 0
	g.ball_vel = 1.5
	g.ai_pos = 17
	g._return_ball(-1, 17, 17, 0)
	expect_near(g.ball_vel, -1.75, 0.001, "their return comes back at you")


# --- Points, matches, series -----------------------------------------------------------

func test_point_to_scores_and_ends_match() -> void:
	var g = _new_game()
	g.points_to_win = 2
	g.matches_needed = 2
	g.player_score = 1
	g.ai_score = 0
	g._point_to("player")
	expect_eq(g.player_score, 2)
	expect_eq(g.state, Game.State.MATCH_OVER, "reaching the target ends it")
	expect_eq(g.set_you, 1)
	expect_eq(g.matches_won, 1)


func test_series_ends_on_majority() -> void:
	var g = _new_game()
	g.matches_needed = 2
	g.set_you = 1
	g.set_cpu = 0
	g.player_score = 5
	g.ai_score = 2
	g._end_match()
	expect_eq(g.state, Game.State.SERIES_OVER, "majority of matches wins the series")
	expect_eq(g.series_won, 1)
	expect_eq(g.set_you, 2)


func test_start_match_resets_the_court() -> void:
	var g = _new_game()
	g.track_length = 20
	g.mid = 10
	g.series_length = 3
	seed(3)
	g.player_score = 4
	g.ai_score = 5
	g.ball_live = true
	g._start_match()
	expect_eq(g.player_score, 0)
	expect_eq(g.ai_score, 0)
	expect_eq(g.player_pos, 5, "a quarter of the track in")
	expect_eq(g.ai_pos, 14)
	expect(not g.ball_live, "waiting to serve")
	expect_eq(g.state, Game.State.PLAYING)
	expect(g.serve_dir == 1 or g.serve_dir == -1, "a side is drawn to serve")


func test_serve_places_the_ball_mid_court() -> void:
	var g = _new_game()
	g.track_length = 20
	g.serve_dir = -1
	g.ai_delay = 2
	g._serve(1.0, "Test")
	expect_near(g.ball_pos, 9.5, 0.001, "serves start dead center")
	expect_near(g.ball_vel, -1.0, 0.001, "serve flies at the chosen speed")
	expect(g.ball_live)
	expect_eq(g.rally_len, 0)
	expect_eq(g.ai_frozen, 0, "no read delay on a serve aimed at you")
	var g2 = _new_game()
	g2.track_length = 20
	g2.serve_dir = 1
	g2.ai_delay = 2
	g2._serve(2.2, "Test")
	expect_eq(g2.ai_frozen, 2, "a serve at the CPU buys it thinking time")


# --- Commands --------------------------------------------------------------------------

func test_serve_inputs_pick_a_speed() -> void:
	var g = _new_game()
	g.serve_dir = 1
	g.ball_live = false
	g._update_playing("1")
	expect_near(g.ball_vel, g.serve_lob, 0.001, "lob serve is the slow one")
	g.ball_live = false
	g._update_playing("3")
	expect_near(g.ball_vel, g.serve_flat, 0.001, "hard serve is the fast one")
	g.ball_live = false
	g._update_playing("")
	expect_near(g.ball_vel, g.start_speed, 0.001, "Enter serves standard")
	g.ball_live = false
	g._update_playing("xyzzy")
	expect(not g.ball_live, "invalid input does not serve")
	expect_eq(g.last_tone, "warn")


func test_between_points_positioning_is_free() -> void:
	var g = _new_game()
	g.track_length = 20
	g.mid = 10
	g.players = 1
	g.player_pos = 5
	g.ball_live = false
	g._update_playing("left")
	expect_eq(g.player_pos, 4, "you can set up before serving")
	g.player_pos = 0
	g._update_playing("left")
	expect_eq(g.player_pos, 0, "still bounded by your wall")


func test_parse_moves_table() -> void:
	var g = _new_game()
	var cases := {
		"": [0, 0], "w": [0, 0], "a": [-1, 0], "d": [1, 0],
		",": [0, -1], ".": [0, 1], "a,": [-1, -1], "d.": [1, 1],
		"w,": [0, -1], "ad": [-1, 0], "x": [], "abc": [], "ax": []}
	for input in cases:
		expect_eq(g._parse_moves(input), cases[input],
			"input '%s'" % input)


func test_live_inputs_tick_the_world() -> void:
	var g = _new_game()
	g.track_length = 20
	g.mid = 10
	g.players = 1
	g.player_pos = 5
	g.ball_live = true
	g.ball_vel = 1.0
	g.ball_pos = 9.5
	g._update_playing("l")
	expect_eq(g.player_pos, 4, "the move applies")
	expect_near(g.ball_pos, 10.5, 0.001, "the ball flies one tick")
	g._update_playing("bogus")
	expect_near(g.ball_pos, 10.5, 0.001, "a typo does not tick the world")
	expect_eq(g.last_tone, "warn")


func test_quit_reports_the_score() -> void:
	var g = _new_game()
	g.player_score = 2
	g.ai_score = 3
	g.state = Game.State.PLAYING
	g._update("q")
	expect(not g.game_running)
	expect(g.last_message.contains("2-3"), "the walk-off shows the score")


func test_match_and_series_replies() -> void:
	var g = _new_game()
	g.state = Game.State.MATCH_OVER
	g._update("n")
	expect(not g.game_running)
	var g2 = _new_game()
	seed(2)
	g2.state = Game.State.MATCH_OVER
	g2._update("y")
	expect_eq(g2.state, Game.State.PLAYING, "next match begins")
	var g3 = _new_game()
	seed(2)
	g3.state = Game.State.SERIES_OVER
	g3._update("y")
	expect_eq(g3.state, Game.State.PLAYING, "new series begins")
	expect_eq(g3.set_you, 0)
	expect_eq(g3.set_cpu, 0)


# --- CPU -------------------------------------------------------------------------------

func test_ai_drifts_home_when_ball_heads_away() -> void:
	var g = _new_game()
	g.track_length = 20
	g.mid = 10
	g.ai_pos = 17
	g.ball_vel = -1.0         # heading at you — its half is quiet
	g._update_ai()
	expect_eq(g.ai_pos, 16, "it slides back toward the middle of its half")
	g.ai_pos = 14              # home for a 20-cell track
	g._update_ai()
	expect_eq(g.ai_pos, 14, "at home it holds")


func test_ai_freeze_buys_reading_time() -> void:
	var g = _new_game()
	g.ai_pos = 17
	g.ball_vel = 1.0
	g.ai_frozen = 2
	g._update_ai()
	expect_eq(g.ai_pos, 17, "frozen means no move")
	expect_eq(g.ai_frozen, 1, "the freeze ticks down")


func test_ai_moves_toward_a_readable_landing() -> void:
	var g = _new_game()
	g.track_length = 20
	g.mid = 10
	g.paddle_radius = 1
	g.ai_pos = 18
	g.ai_frozen = 0
	g.ball_pos = 15.0
	g.ball_vel = 1.5          # next landings: 16, 18, 19...
	g._update_ai()
	expect_eq(g.ai_pos, 17, "it steps toward the first reachable landing")


func test_ai_pick_target_falls_back_to_desperation() -> void:
	var g = _new_game()
	g.track_length = 20
	g.mid = 10
	g.ai_pos = 15
	g.paddle_radius = 1
	g.ball_pos = 18.0
	g.ball_vel = 2.0          # 18 -> 20 is already past the wall
	expect_eq(g._ai_pick_target(), 19,
		"no reachable landing means diving for the last cell")


func test_ai_misread_stays_in_its_half() -> void:
	for s in range(1, 30):
		seed(s)
		var g = _new_game()
		g.track_length = 20
		g.mid = 10
		g.ai_error = 1.0       # every shot is misread
		var misread: int = g._ai_roll_misread()
		expect(absi(misread) >= 2 and absi(misread) <= 4,
			"seed %d: misread is 2-4 cells off" % s)
		g.ai_pos = 19
		g.ai_misread = -4
		g.ball_vel = 1.0
		g.ball_pos = 18.0
		g._update_ai()
		expect(g.ai_pos >= g.mid, "a misread never leaves its half")


# --- Presentation helpers ------------------------------------------------------------------

func test_foe_labels_follow_player_count() -> void:
	var g = _new_game()
	g.players = 1
	expect_eq(g._foe(), "the CPU")
	expect_eq(g._foe_cap(), "The CPU")
	expect_eq(g._foe_possessive(), "the CPU's")
	g.players = 2
	expect_eq(g._foe(), "P2")
	expect_eq(g._foe_cap(), "P2")
	expect_eq(g._foe_possessive(), "P2's")


func test_ball_heat_tiers() -> void:
	var g = _new_game()
	g.ball_vel = 1.5
	expect_eq(g._ball_heat(), "1;33", "readable speed is yellow")
	g.ball_vel = -2.5
	expect_eq(g._ball_heat(), "95", "hot is magenta — sign matters not")
	g.ball_vel = 3.5
	expect_eq(g._ball_heat(), "1;31", "dead-center territory is red")
