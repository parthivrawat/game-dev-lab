extends SceneTree

## Tests for Catch the Firefly (main.gd).
## Run from a terminal inside this folder:
##     godot --headless --script test_main.gd      (or run_tests.bat)
##
## How it works: the game lives in _initialize() — Godot only calls that
## for the script it launches as the main loop. Instantiating main.gd
## here builds a game object WITHOUT starting a session, so each test
## places the player and firefly directly and calls the logic functions
## one at a time. settings.cfg is never written by these tests.

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


# --- Config and spawning ----------------------------------------------------------

func test_validate_config_clamps_the_rules() -> void:
	var g = _new_game()
	g.track_length = 2
	g.max_turns = 0
	g.min_spawn_distance = 99
	g._validate_config()
	expect_eq(g.track_length, 3, "track needs room to chase on")
	expect_eq(g.max_turns, 1, "at least one turn")
	expect_eq(g.min_spawn_distance, 2, "spawn distance clamped to the track")


func test_spawns_respect_min_distance_and_wall_heading() -> void:
	for s in range(1, 40):
		seed(s)
		var g = _new_game()
		g.track_length = 20
		g.min_spawn_distance = 4
		g._start_round()
		expect_eq(g.player_pos, 10, "player starts mid-track")
		expect(absi(g.target_pos - g.player_pos) >= g.min_spawn_distance,
			"seed %d: firefly spawns %d+ cells away" % [s, g.min_spawn_distance])
		if g.target_pos == 0:
			expect_eq(g.target_dir, 1, "left wall can only drift right")
		elif g.target_pos == g.track_length - 1:
			expect_eq(g.target_dir, -1, "right wall can only drift left")
		expect_eq(g.state, Game.State.PLAYING)


func test_spawn_relaxes_distance_rule_when_no_cell_qualifies() -> void:
	for s in range(1, 20):
		seed(s)
		var g = _new_game()
		g.track_length = 3          # player at 1, min distance 2 leaves no cells
		g.min_spawn_distance = 2
		g._start_round()
		expect(g.target_pos == 0 or g.target_pos == 2,
			"fallback spawns on any free cell")
		expect(g.target_pos != g.player_pos, "never on top of the player")


# --- The tick ---------------------------------------------------------------------

func test_wall_bump_still_costs_a_turn() -> void:
	var g = _new_game()
	g.track_length = 20
	g.player_pos = 0
	g.target_pos = 15
	g._take_turn(-1)
	expect_eq(g.player_pos, 0, "the wall holds")
	expect_eq(g.turns_used, 1, "bumping costs a turn")
	expect(g.last_message.contains("wall"), "the bump is reported")


func test_moving_toward_firefly_drifts_it() -> void:
	var g = _new_game()
	g.track_length = 20
	g.player_pos = 10
	g.target_pos = 15
	g.target_dir = 1
	g._take_turn(1)
	expect_eq(g.player_pos, 11, "the move applies")
	expect_eq(g.target_pos, 16, "unthreatened, it drifts its heading")
	expect_eq(g.turns_used, 1)


func test_firefly_bounces_off_the_wall() -> void:
	var g = _new_game()
	g.track_length = 20
	g.player_pos = 0
	g.target_pos = 19
	g.target_dir = 1
	g._take_turn(0)
	expect_eq(g.target_pos, 19, "it spends a tick sitting on the wall")
	expect_eq(g.target_dir, -1, "and heads back the other way")
	expect(g.last_message.contains("bounces"), "the bounce is narrated")


func test_adjacent_firefly_darts_away() -> void:
	var g = _new_game()
	g.track_length = 20
	g.player_pos = 10
	g.target_pos = 12
	g.target_dir = -1
	g._take_turn(1)
	expect_eq(g.player_pos, 11)
	expect_eq(g.target_pos, 13, "adjacent means it flees one cell")
	expect_eq(g.target_dir, 1, "its heading now points away from you")
	expect(g.last_message.contains("darts"), "the dodge is narrated")


func test_pinned_firefly_can_be_caught() -> void:
	var g = _new_game()
	g.track_length = 20
	g.player_pos = 17
	g.target_pos = 19
	g.target_dir = -1
	g._take_turn(1)
	expect_eq(g.target_pos, 19, "pinned against the wall, it holds")
	expect(g.last_message.contains("pinned"), "the pin is announced")
	g._take_turn(1)
	expect_eq(g.state, Game.State.ROUND_OVER, "landing on its cell wins")
	expect_eq(g.catches, 1)
	expect_eq(g.best_turns, 2, "the catch time is recorded")
	expect(g.last_message.contains("caught"), "the catch is narrated")


func test_landing_on_the_firefly_wins_directly() -> void:
	var g = _new_game()
	g.track_length = 20
	g.player_pos = 18
	g.target_pos = 19
	g._take_turn(1)
	expect_eq(g.state, Game.State.ROUND_OVER)
	expect_eq(g.rounds_played, 1)
	expect_eq(g.last_tone, "good")


func test_best_turns_keeps_the_minimum() -> void:
	var g = _new_game()
	g.best_turns = 5
	g.turns_used = 7
	g._win_round("test")
	expect_eq(g.best_turns, 5, "a slower catch keeps the record")
	g.turns_used = 3
	g._win_round("test")
	expect_eq(g.best_turns, 3, "a faster catch replaces it")


func test_running_out_of_turns_loses() -> void:
	var g = _new_game()
	g.track_length = 20
	g.max_turns = 2
	g.turns_used = 1
	g.player_pos = 0
	g.target_pos = 15
	g._take_turn(0)
	expect_eq(g.state, Game.State.ROUND_OVER)
	expect_eq(g.escapes, 1, "the escape is counted")
	expect_eq(g.last_tone, "bad")
	expect(g.last_message.contains("slips away"), "the loss is narrated")


func test_distance_feedback_turns_hint_when_close() -> void:
	var g = _new_game()
	g.track_length = 20
	g.player_pos = 10
	g.target_pos = 14
	g.target_dir = -1
	g._take_turn(0)   # firefly drifts to 13 — three cells away
	expect_eq(g.last_tone, "hint", "close range switches the tone")
	expect(g.last_message.contains("3 cells"), "distance is reported")


# --- Commands ---------------------------------------------------------------------

func test_help_and_bad_input_are_free() -> void:
	var g = _new_game()
	g.track_length = 20
	g.player_pos = 10
	g.target_pos = 15
	g.state = Game.State.PLAYING
	g._update("help")
	expect_eq(g.turns_used, 0, "help costs no turn")
	g._update("xyzzy")
	expect_eq(g.turns_used, 0, "unknown commands cost no turn")
	expect_eq(g.last_tone, "warn")


func test_quit_reveals_the_firefly() -> void:
	var g = _new_game()
	g.target_pos = 15
	g.state = Game.State.PLAYING
	g._update("q")
	expect(not g.game_running, "quit ends the session")
	expect(g.last_message.contains("15"), "it tells you where it was")


func test_round_over_replay_flow() -> void:
	var g = _new_game()
	g.state = Game.State.ROUND_OVER
	g._update_round_over("n")
	expect(not g.game_running, "n ends the session")
	var g2 = _new_game()
	seed(5)
	g2.state = Game.State.ROUND_OVER
	g2._update_round_over("y")
	expect_eq(g2.state, Game.State.PLAYING, "y chases again")
	expect_eq(g2.turns_used, 0, "the turn count resets")
	g2.state = Game.State.ROUND_OVER
	g2._update_round_over("maybe")
	expect_eq(g2.last_tone, "warn")
