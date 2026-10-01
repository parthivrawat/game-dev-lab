extends SceneTree

## Tests for Dustline — 1D Endless Runner (main.gd).
## Run from a terminal inside this folder:
##     godot --headless --script test_main.gd      (or run_tests.bat)
##
## How it works: the game lives in _initialize() — Godot only calls that
## for the script it launches as the main loop. Instantiating main.gd
## here builds a game object WITHOUT starting a session, so each test
## places obstacles and the runner directly and calls the logic
## functions one at a time. settings.cfg is never written by these
## tests (only _load_config/_save_scores touch it).

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


func _rock(x: float) -> Dictionary:
	return {"x": x, "kind": "rock", "met": false, "passed": false}


func _bird(x: float) -> Dictionary:
	return {"x": x, "kind": "bird", "met": false, "passed": false}


func _wall(x: float) -> Dictionary:
	return {"x": x, "kind": "wall", "met": false, "passed": false}


# --- Config and the difficulty curve -----------------------------------------------

func test_validate_config_clamps_the_rules() -> void:
	var g = _new_game()
	g.track_length = 5
	g.player_cell = 99
	g.jump_ticks = 0
	g.hop_ticks = 99
	g.grace_ticks = -2
	g.start_speed = 0.1
	g.max_speed = 0.1
	g.flyer_chance = 7.0
	g.wall_chance = -1.0
	g.run_seed = -5
	g._validate_config()
	expect_eq(g.track_length, 12, "a minimum of road")
	expect(g.player_cell >= 1 and g.player_cell <= g.track_length / 2,
		"runner column inside its half")
	expect_eq(g.jump_ticks, 1)
	expect_eq(g.hop_ticks, 1, "hop can never outlast a full jump")
	expect_eq(g.grace_ticks, 0, "no negative grace")
	expect_near(g.start_speed, 0.5, 0.001)
	expect_near(g.max_speed, g.start_speed, 0.001,
		"max speed never drops below start speed")
	expect_near(g.flyer_chance, 1.0, 0.001, "chance clamps to [0, 1]")
	expect_near(g.wall_chance, 0.0, 0.001, "chance clamps to [0, 1]")
	expect_eq(g.run_seed, 0, "no negative seeds")


func test_speed_grows_with_distance_to_a_cap() -> void:
	var g = _new_game()
	g.distance = 0.0
	expect_near(g._current_speed(), 1.0, 0.001, "day one pace")
	g.distance = 50.0
	expect_near(g._current_speed(), 2.0, 0.001, "growth adds to the pace")
	g.distance = 10000.0
	expect_near(g._current_speed(), g.max_speed, 0.001, "the curve tops out")


func test_spawn_gap_shrinks_but_stays_survivable() -> void:
	var g = _new_game()
	g.speed = 1.0
	g.distance = 0.0
	expect_near(g._spawn_gap("rock"), g.start_gap, 0.001, "the opening gap")
	expect_near(g._curve_gap(), g.start_gap, 0.001,
		"the raw curve matches the floored gap at distance 0")
	g.distance = 100.0
	expect_near(g._spawn_gap("rock"), 6.0, 0.001, "shrinks with distance")
	g.speed = 2.5
	g.distance = 10000.0
	expect_near(g._spawn_gap("rock"), g.jump_ticks * g.speed, 0.001,
		"the fairness floor is one jump of airtime — never an impossible read")


func test_wall_gap_needs_room_for_the_apex() -> void:
	var g = _new_game()
	g.speed = 2.5
	g.distance = 10000.0   # deep enough that only the floor is talking
	var rock_floor: float = g.jump_ticks * g.speed
	var wall_floor: float = (g.jump_ticks + g._apex_off()) * g.speed
	expect_near(g._spawn_gap("rock"), rock_floor, 0.001)
	expect_near(g._spawn_gap("wall"), wall_floor, 0.001,
		"a wall buys extra spacing: the apex approach must be reachable")
	expect(g._spawn_gap("wall") > g._spawn_gap("rock"),
		"the wall floor is strictly wider")


func test_spawner_places_and_schedules() -> void:
	var g = _new_game()
	g.flyer_chance = 0.0
	g.wall_chance = 0.0
	g.speed = 1.0
	g.distance = 0.0
	var msg: String = g._spawn_obstacle()
	expect_eq(g.obstacles.size(), 1)
	expect_near(g.obstacles[0]["x"], float(g.track_length - 1), 0.001,
		"obstacles spawn on the horizon")
	expect_eq(g.obstacles[0]["kind"], "rock", "zero chances mean rocks")
	expect_eq(g.spawn_cd, int(ceil(g._spawn_gap("rock") / g.speed)),
		"the next spawn is one gap's travel away")
	expect(msg.contains("rock"), "the spawn is narrated")
	var g2 = _new_game()
	g2.flyer_chance = 1.0
	g2._spawn_obstacle()
	expect_eq(g2.obstacles[0]["kind"], "bird", "chance 1 means birds")


func test_walls_unlock_by_distance() -> void:
	var g = _new_game()
	g.flyer_chance = 0.0
	g.wall_chance = 1.0
	g.wall_min_m = 40
	g.distance = 10.0          # before the unlock
	g._spawn_obstacle()
	expect_eq(g.obstacles[0]["kind"], "rock",
		"a wall roll before wall_min_m falls back to rock")
	g.distance = 100.0         # past the unlock
	g._spawn_obstacle()
	expect_eq(g.obstacles[1]["kind"], "wall", "past the unlock walls spawn")


func test_seed_makes_identical_runs() -> void:
	var g1 = _new_game()
	var g2 = _new_game()
	g1.run_seed = 42
	g2.run_seed = 42
	var kinds1 := PackedStringArray()
	var kinds2 := PackedStringArray()
	# The RNG stream is global, so runs must be sampled SEQUENTIALLY —
	# which is also the real use case: re-seed at _start_run, replay the
	# same road on the next attempt.
	g1._start_run()
	for i in 6:
		kinds1.append(g1._spawn_obstacle().left(6))
		kinds1.append(String.num(g1.spawn_cd))
	g2._start_run()
	for i in 6:
		kinds2.append(g2._spawn_obstacle().left(6))
		kinds2.append(String.num(g2.spawn_cd))
	expect_eq("|".join(kinds1), "|".join(kinds2),
		"same seed, same road — kind and cooldown alike")
	var g3 = _new_game()
	g3.run_seed = 42
	g3._start_run()
	g3._spawn_obstacle()
	g3._start_run()   # re-seed per run — a second attempt replays the road
	expect_eq(g3._spawn_obstacle().left(6), kinds1[0],
		"run two of the same seed opens identically")


# --- Collision: the swept adjudication --------------------------------------------------

func test_rock_kills_grounded_feet() -> void:
	var g = _new_game()
	g.speed = 1.0
	g.player_cell = 4
	g.air_left = 0
	g.grace_left = 0
	g.obstacles = [_rock(5.5)]
	var parts := PackedStringArray()
	expect(g._advance_obstacles(parts).contains("legs out"),
		"a rock on your column while grounded is a crash")


func test_airborne_sails_over_the_rock() -> void:
	var g = _new_game()
	g.speed = 1.0
	g.player_cell = 4
	g.air_left = 2
	g.obstacles = [_rock(5.5)]
	var parts := PackedStringArray()
	expect_eq(g._advance_obstacles(parts), "", "airborne feet clear it")
	expect(g.obstacles[0]["met"], "the crossing is adjudicated once")
	expect(" ".join(parts).contains("sail clean"), "the dodge is narrated")


func test_landing_grace_skids_a_rock() -> void:
	var g = _new_game()
	g.speed = 1.0
	g.player_cell = 4
	g.air_left = 0
	g.grace_left = 1         # the tick after touchdown
	g.obstacles = [_rock(5.5)]
	var parts := PackedStringArray()
	expect_eq(g._advance_obstacles(parts), "",
		"landing grace forgives the rock")
	expect(" ".join(parts).contains("grace"), "the skid is narrated")
	var g2 = _new_game()
	g2.speed = 1.0
	g2.player_cell = 4
	g2.air_left = 0
	g2.grace_left = 0        # a tick later the forgiveness is gone
	g2.obstacles = [_rock(5.5)]
	var parts2 := PackedStringArray()
	expect(g2._advance_obstacles(parts2).contains("legs out"),
		"grace expired means the rock wins")


func test_grace_still_fed_the_birds() -> void:
	# Grace counts as grounded for birds — skidding low is safe.
	var g = _new_game()
	g.speed = 1.0
	g.player_cell = 4
	g.air_left = 0
	g.grace_left = 1
	g.obstacles = [_bird(5.5)]
	var parts := PackedStringArray()
	expect_eq(g._advance_obstacles(parts), "",
		"a bird during grace is just a bird")


func test_bird_clips_you_out_of_the_air() -> void:
	var g = _new_game()
	g.speed = 1.0
	g.player_cell = 4
	g.air_left = 2
	g.obstacles = [_bird(5.5)]
	var parts := PackedStringArray()
	expect(g._advance_obstacles(parts).contains("clips you"),
		"a bird on your column while airborne is a crash")


func test_grounded_ducks_under_the_bird() -> void:
	var g = _new_game()
	g.speed = 1.0
	g.player_cell = 4
	g.air_left = 0
	g.obstacles = [_bird(5.5)]
	var parts := PackedStringArray()
	expect_eq(g._advance_obstacles(parts), "", "grounded is safe from birds")
	expect(" ".join(parts).contains("whips past"), "the pass is narrated")


func test_wall_needs_exactly_the_apex() -> void:
	var g = _new_game()
	g.speed = 1.0
	g.player_cell = 4
	g.jump_ticks = 3
	# grounded
	g.air_left = 0
	g.obstacles = [_wall(5.5)]
	var parts := PackedStringArray()
	expect(g._advance_obstacles(parts).contains("stops you cold"),
		"a wall never lets grounded feet through")
	# airborne but off the apex (air_left 1 or 3, never 2)
	var g2 = _new_game()
	g2.speed = 1.0
	g2.player_cell = 4
	g2.jump_ticks = 3
	g2.air_left = 1
	g2.obstacles = [_wall(5.5)]
	var parts2 := PackedStringArray()
	expect(g2._advance_obstacles(parts2).contains("off the apex"),
		"late air still loses to the wall")
	# the apex itself
	var g3 = _new_game()
	g3.speed = 1.0
	g3.player_cell = 4
	g3.jump_ticks = 3
	g3.air_left = g3._apex_air()
	g3.obstacles = [_wall(5.5)]
	var parts3 := PackedStringArray()
	expect_eq(g3._advance_obstacles(parts3), "", "the apex clears the wall")
	expect(" ".join(parts3).contains("crest"), "the crest is narrated")


func test_swept_check_means_speed_never_tunnels() -> void:
	var g = _new_game()
	g.speed = 3.0                  # fast enough to skip cells outright
	g.player_cell = 4
	g.air_left = 0
	g.grace_left = 0
	g.obstacles = [_rock(6.9)]     # 6.9 - 3.0 = 3.9: crosses cell 4 between floors
	var parts := PackedStringArray()
	expect(g._advance_obstacles(parts).contains("legs out"),
		"the column check is swept — no cell can be skipped")


func test_cleared_obstacles_count_once() -> void:
	var g = _new_game()
	g.speed = 1.0
	g.player_cell = 4
	g.air_left = 0
	g.obstacles = [_rock(4.5)]     # already past adjudication, falling behind
	var parts := PackedStringArray()
	g._advance_obstacles(parts)
	expect_eq(g.cleared, 1, "falling behind you counts as cleared")
	expect_eq(g.total_cleared, 1)
	g._advance_obstacles(parts)
	expect_eq(g.cleared, 1, "it can only be cleared once")


func test_offscreen_obstacles_are_dropped() -> void:
	var g = _new_game()
	g.speed = 1.0
	g.player_cell = 4
	g.obstacles = [_rock(0.4), _rock(9.0)]
	var parts := PackedStringArray()
	g._advance_obstacles(parts)
	expect_eq(g.obstacles.size(), 1, "the left-edge straggler is culled")


# --- The tick and the jump ------------------------------------------------------------

func test_jump_sets_airtime_and_ticks_the_world() -> void:
	var g = _new_game()
	g.spawn_cd = 99              # keep the spawner out of this test
	g._take_turn(true)
	expect_eq(g.air_left, g.jump_ticks - 1,
		"the leap spends one tick of coverage immediately")
	expect_eq(g.jumps, 1)
	expect_near(g.distance, 1.0, 0.001, "every input is a meter of road")
	expect_near(g.speed, 1.02, 0.001, "the road speeds up with distance")
	expect(g.last_message.contains("leap"), "the jump is narrated")


func test_short_hop_is_a_smaller_window() -> void:
	var g = _new_game()
	g.spawn_cd = 99
	g._take_turn(true, true)
	expect_eq(g.air_left, g.hop_ticks - 1, "a hop is a shorter timer")
	expect_eq(g.jumps, 1, "a hop still counts as a jump")
	expect(g.last_message.contains("hop"), "the hop is narrated")


func test_no_double_jumps() -> void:
	var g = _new_game()
	g.spawn_cd = 99
	g.air_left = 2
	g._take_turn(true)
	expect_eq(g.jumps, 0, "no jump was spent")
	expect_eq(g.air_left, 1, "the tick still burns airtime")
	expect_eq(g.last_tone, "warn")
	expect(g.last_message.contains("Already airborne"), "the refusal is told")


func test_airtime_counts_down_to_touchdown_and_grace() -> void:
	var g = _new_game()
	g.spawn_cd = 99
	g.air_left = 1
	g._take_turn(false)
	expect_eq(g.air_left, 0)
	expect(g.last_message.contains("touch down"), "landing is narrated")
	expect_eq(g.grace_left, g.grace_ticks, "touchdown arms landing grace")


func test_milestone_banner_marks_the_pace() -> void:
	var g = _new_game()
	g.spawn_cd = 99
	g.milestone_m = 10
	g.next_milestone = 10
	g.distance = 9.5
	g.speed = 1.0
	g._take_turn(false)          # crosses 10 m this tick
	expect(g.last_message.contains("10 m"), "the banner names the distance")
	expect_eq(g.next_milestone, 20, "the next banner is queued")


func test_spawner_fires_on_cooldown() -> void:
	var g = _new_game()
	g.spawn_cd = 1
	g.flyer_chance = 0.0
	g.wall_chance = 0.0
	g._take_turn(false)
	expect_eq(g.obstacles.size(), 1, "cooldown zero means a spawn")
	expect(g.last_message.contains("horizon"), "the spawn is narrated")


func test_crash_ends_the_run_and_logs_it() -> void:
	var g = _new_game()
	g.player_cell = 4
	g.air_left = 0
	g.grace_left = 0
	g.obstacles = [_rock(5.0)]
	g.speed = 1.0
	g.distance = 11.5
	g._take_turn(false)          # the rock lands on cell 4 this tick
	expect_eq(g.state, Game.State.RUN_OVER)
	expect_eq(g.runs, 1, "the run is logged")
	expect_eq(g.session_best, 12, "meters become the score — tick counts first")
	expect(g.last_message.contains("Run over at 12 m"), "the crash is narrated")


func test_ghost_records_air_state_per_tick() -> void:
	var g = _new_game()
	g.spawn_cd = 99
	g._take_turn(true)           # jump_ticks of airborne ticks...
	g._take_turn(false)
	g._take_turn(false)
	g._take_turn(false)          # ...then grounded
	expect_eq(g.run_log, "aaag", "the log says what your feet did each tick")


func test_best_run_becomes_the_ghost() -> void:
	var g = _new_game()
	g.best_distance = 20
	g.run_log = "gagag"
	g.distance = 30.0
	g._log_run()
	expect_eq(g.session_ghost, "gagag")
	expect_eq(g.career_ghost, "gagag", "a career best becomes the shadow live")
	expect_eq(g.ghost_m, 30)
	var g2 = _new_game()
	g2.best_distance = 50
	g2.run_log = "gg"
	g2.distance = 30.0
	g2._log_run()
	expect_eq(g2.career_ghost, "", "a merely-session best leaves the career ghost alone")


func test_stale_ghost_signature_is_ignored() -> void:
	var g = _new_game()
	var config := ConfigFile.new()
	config.set_value("scores", "ghost", "agag")
	config.set_value("scores", "ghost_m", 99)
	config.set_value("scores", "ghost_sig", "tuning-from-another-game")
	g._load_scores(config)
	expect_eq(g.career_ghost, "", "a ghost under different tuning is ignored")
	var g2 = _new_game()
	var config2 := ConfigFile.new()
	config2.set_value("scores", "ghost", "agag")
	config2.set_value("scores", "ghost_m", 99)
	config2.set_value("scores", "ghost_sig", g2._ghost_sig())
	g2._load_scores(config2)
	expect_eq(g2.career_ghost, "agag", "same tuning means the shadow returns")
	expect_eq(g2.ghost_m, 99)


# --- Threat readout ---------------------------------------------------------------------

func test_threat_status_reads_the_nearest_rock() -> void:
	var g = _new_game()
	g.player_cell = 4
	g.speed = 1.0
	g.air_left = 0
	g.obstacles = [_rock(8.0)]
	expect(g._threat_status().contains("closes in"), "far rock is just a read")
	g.obstacles = [_rock(6.0)]
	expect(g._threat_status().contains("jump window is OPEN"),
		"inside jump_ticks the window is open")


func test_threat_status_warns_about_birds() -> void:
	var g = _new_game()
	g.player_cell = 4
	g.speed = 1.0
	g.obstacles = [_bird(6.0)]
	g.air_left = 0
	expect(g._threat_status().contains("stay DOWN"),
		"a near bird says do not jump")
	g.air_left = 5
	expect(g._threat_status().contains("stuck in the air"),
		"outlasting the jump next to a bird is the worst place to be")


func test_threat_status_coaches_the_apex() -> void:
	var g = _new_game()
	g.player_cell = 4
	g.speed = 1.0
	g.air_left = 0
	g.jump_ticks = 3
	g.hop_ticks = 2
	# Wall 6 cells out at speed 1 -> crosses in 2 ticks = apex_air: jump NOW.
	g.obstacles = [_wall(6.0)]
	expect(g._threat_status().contains("JUMP NOW"),
		"countdown == apex_air is the full-jump moment")
	# One tick later -> crosses next tick: the hop window.
	g.obstacles = [_wall(5.0)]
	expect(g._threat_status().contains("HOP NOW"),
		"countdown == 1 is the last-second hop apex")
	# Already airborne on the wrong phase -> off-apex warning.
	var g2 = _new_game()
	g2.player_cell = 4
	g2.speed = 1.0
	g2.jump_ticks = 3
	g2.air_left = 3              # wall lands next tick with air_left 3 — not apex
	g2.obstacles = [_wall(5.0)]
	expect(g2._threat_status().contains("off-apex"),
		"being airborne at the wrong phase is called out")
	# Airborne exactly at the apex on arrival -> locked.
	var g3 = _new_game()
	g3.player_cell = 4
	g3.speed = 1.0
	g3.jump_ticks = 3
	g3.air_left = g3._apex_air()       # wall lands next tick while air_left is apex_air
	g3.obstacles = [_wall(5.0)]
	expect(g3._threat_status().contains("apex locked"),
		"a well-timed jump is confirmed")


func test_tone_escalation_keeps_the_worst() -> void:
	var g = _new_game()
	g._tick_tone = "info"
	g._escalate("good")
	expect_eq(g._tick_tone, "good")
	g._escalate("warn")
	expect_eq(g._tick_tone, "warn")
	g._escalate("hint")
	expect_eq(g._tick_tone, "warn", "tones only escalate, never soften")


# --- Commands and run lifecycle -----------------------------------------------------------

func test_run_commands() -> void:
	var g = _new_game()
	g.spawn_cd = 99
	g.state = Game.State.PLAYING
	g._update("help")
	expect_near(g.distance, 0.0, 0.001, "help costs no road")
	g._update("bogus")
	expect_near(g.distance, 0.0, 0.001, "a typo costs no road")
	expect_eq(g.last_tone, "warn")
	g._update("j")
	expect(g.air_left > 0, "j jumps")
	var g2 = _new_game()
	g2.spawn_cd = 99
	g2.state = Game.State.PLAYING
	g2._update("s")
	expect_eq(g2.air_left, g2.hop_ticks - 1, "s is the short hop")
	var d: float = g.distance
	g._update("w")
	expect(g.distance > d, "w runs a tick of road")


func test_quit_mid_run_still_banks_the_meters() -> void:
	var g = _new_game()
	g.distance = 42.0
	g.state = Game.State.PLAYING
	g._update("q")
	expect(not g.game_running)
	expect_eq(g.runs, 1, "earned meters still count")
	expect_eq(g.session_best, 42)
	var g2 = _new_game()
	g2.distance = 0.0
	g2.state = Game.State.PLAYING
	g2._update("q")
	expect_eq(g2.runs, 0, "a zero-meter quit logs nothing")


func test_run_over_replay_flow() -> void:
	var g = _new_game()
	g.state = Game.State.RUN_OVER
	g._update_run_over("n")
	expect(not g.game_running)
	var g2 = _new_game()
	g2.state = Game.State.RUN_OVER
	g2.distance = 30.0
	g2.jumps = 9
	g2.run_log = "gaga"
	g2.tick = 30
	g2._update_run_over("y")
	expect_eq(g2.state, Game.State.PLAYING, "y starts a new run")
	expect_near(g2.distance, 0.0, 0.001, "distance resets")
	expect_eq(g2.jumps, 0, "jump count resets")
	expect_eq(g2.obstacles.size(), 0, "the road is clear")
	expect_eq(g2.spawn_cd, g2.spawn_delay, "the opening breather returns")
	expect_eq(g2.tick, 0, "the ghost index resets")
	expect_eq(g2.run_log, "", "the recorder is empty again")
