extends SceneTree

## Tests for Number Guessing (main.gd).
## Run from a terminal inside this folder:
##     godot --headless --script test_main.gd      (or run_tests.bat)
##
## How it works: the game lives in _initialize() — Godot only calls that
## for the script it launches as the main loop. Instantiating main.gd
## here builds a game object WITHOUT starting a session, so each test
## sets the state up directly (e.g. picks the secret itself) and calls
## the logic functions one at a time. No file is written: settings.cfg
## is only touched by _load_config/_save_scores, which tests avoid.

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


# --- Config -------------------------------------------------------------------

func test_validate_config_repairs_bad_values() -> void:
	var g = _new_game()
	g.min_number = 50
	g.max_number = 10
	g.max_attempts = 0
	g.mode = "weird"
	g.difficulty = "weird"
	g._validate_config()
	expect_eq(g.min_number, 10, "reversed bounds are swapped")
	expect_eq(g.max_number, 50)
	expect_eq(g.max_attempts, 1, "attempts clamp to at least 1")
	expect_eq(g.mode, "normal", "unknown mode falls back")
	expect_eq(g.difficulty, "custom", "unknown difficulty falls back")


func test_apply_difficulty_swaps_in_presets() -> void:
	var g = _new_game()
	g.difficulty = "hard"
	g._apply_difficulty()
	expect_eq(g.max_number, 500, "hard preset uses 1-500")
	expect_eq(g.max_attempts, 10, "hard preset gives 10 attempts")
	var g2 = _new_game()
	g2.min_number = 3
	g2.difficulty = "custom"
	g2._apply_difficulty()
	expect_eq(g2.min_number, 3, "custom keeps the [game] values")
	g2.difficulty = "bogus"
	g2._apply_difficulty()
	expect_eq(g2.min_number, 3, "unknown preset leaves values alone")


func test_optimal_attempts_is_binary_search_depth() -> void:
	var g = _new_game()
	g.min_number = 1
	for span in [1, 2, 4, 100, 500, 1000]:
		g.max_number = span
		var expected := int(ceil(log(span + 1) / log(2.0)))
		expect_eq(g._optimal_attempts(), expected,
			"span %d needs ceil(log2(%d))" % [span, span + 1])
	expect_eq(g._optimal_attempts(), 10, "sanity: 1-1000 always winnable in 10")


# --- Normal mode -----------------------------------------------------------------

func test_invalid_guesses_cost_nothing() -> void:
	var g = _new_game()
	g.secret = 50
	g.state = Game.State.PLAYING
	for input in ["abc", "12.5", "0", "101", ""]:
		g._update_guessing(input)
		expect_eq(g.attempts_used, 0, "'%s' is rejected, not counted" % input)
		expect_eq(g.last_tone, "warn")
		expect_eq(g.state, Game.State.PLAYING, "round continues")


func test_correct_guess_wins_and_records_best() -> void:
	var g = _new_game()
	g.secret = 50
	g.difficulty = "custom"
	g.state = Game.State.PLAYING
	g._update_guessing("50")
	expect_eq(g.state, Game.State.ROUND_OVER, "round ends on a hit")
	expect_eq(g.rounds_won, 1)
	expect_eq(g.rounds_played, 1)
	expect_eq(g.attempts_used, 1, "the winning guess still counts")
	expect_eq(g.best_scores["custom"], 1, "best score recorded")
	expect(g.last_message.contains("Correct"), "win is announced")


func test_wrong_guesses_hint_direction_and_temperature() -> void:
	var g = _new_game()
	g.secret = 50
	g.state = Game.State.PLAYING
	g.max_attempts = 10
	# Distance ladder: <=2 blazing, <=5 hot, <=15 warm, <=40 cool, else freezing.
	var cases := {
		"49": "blazing", "45": "hot", "40": "warm", "90": "cool", "1": "freezing"}
	for guess in cases:
		g._update_guessing(guess)
		expect(g.last_message.contains(cases[guess]),
			"guess %s at distance %d says '%s'" % [
				guess, absi(int(guess) - 50), cases[guess]])
		expect_eq(g.last_tone, "hint")
	expect(g.last_message.contains("Higher"), "below the secret says higher")
	g._update_guessing("90")
	expect(g.last_message.contains("Lower"), "above the secret says lower")
	expect_eq(g.attempts_used, 6, "every valid guess costs an attempt")


func test_proximity_hints_can_be_disabled() -> void:
	var g = _new_game()
	g.secret = 50
	g.proximity_hints = false
	g.state = Game.State.PLAYING
	g._update_guessing("40")
	expect_eq(g.last_message, "Higher!", "no temperature word when off")


func test_running_out_of_attempts_loses() -> void:
	var g = _new_game()
	g.secret = 50
	g.max_attempts = 2
	g.state = Game.State.PLAYING
	g._update_guessing("10")
	expect_eq(g.state, Game.State.PLAYING, "one attempt left")
	g._update_guessing("20")
	expect_eq(g.state, Game.State.ROUND_OVER)
	expect(g.last_message.contains("Out of attempts"), "loss is announced")
	expect(g.last_message.contains("50"), "the secret is revealed")
	expect_eq(g.rounds_won, 0)


func test_quit_mid_round_reveals_secret() -> void:
	var g = _new_game()
	g.secret = 50
	g.state = Game.State.PLAYING
	g._update_guessing("quit")
	expect(not g.game_running, "quit stops the session")
	expect(g.last_message.contains("50"), "quit reveals the number")


func test_best_score_only_improves() -> void:
	var g = _new_game()
	g.difficulty = "custom"
	g.best_scores["custom"] = 5
	g.attempts_used = 3
	g._win_round()
	expect_eq(g.best_scores["custom"], 3, "a faster win replaces the best")
	g.attempts_used = 7
	g.state = Game.State.PLAYING
	g._win_round()
	expect_eq(g.best_scores["custom"], 3, "a slower win keeps the best")


# --- Reverse mode -----------------------------------------------------------------

func test_reverse_round_opens_with_full_window() -> void:
	var g = _new_game()
	g.mode = "reverse"
	g.min_number = 1
	g.max_number = 100
	g._start_round()
	expect_eq(g.comp_lo, 1)
	expect_eq(g.comp_hi, 100)
	expect_eq(g.comp_guess, 50, "first guess is the midpoint")
	expect_eq(g.attempts_used, 1, "the guess is counted")


func test_reverse_answers_narrow_the_window() -> void:
	var g = _new_game()
	g.mode = "reverse"
	g.comp_lo = 1
	g.comp_hi = 100
	g.comp_guess = 50
	g.attempts_used = 1
	g.state = Game.State.PLAYING
	g._update_reverse("h")
	expect_eq(g.comp_lo, 51, "higher moves the floor up")
	expect_eq(g.comp_guess, 75, "it re-guesses the new midpoint")
	g._update_reverse("l")
	expect_eq(g.comp_hi, 74, "lower pulls the ceiling down")
	expect_eq(g.comp_guess, 62)
	expect_eq(g.attempts_used, 3)


func test_reverse_contradiction_is_called_out() -> void:
	var g = _new_game()
	g.mode = "reverse"
	g.comp_lo = 50
	g.comp_hi = 50
	g.comp_guess = 50
	g.attempts_used = 1
	g.state = Game.State.PLAYING
	g._update_reverse("h")
	expect_eq(g.comp_lo, 51)
	expect_eq(g.state, Game.State.ROUND_OVER, "empty window ends the round")
	expect(g.last_message.contains("fibbed"), "contradiction is called out")


func test_reverse_out_of_attempts_loses() -> void:
	var g = _new_game()
	g.mode = "reverse"
	g.comp_lo = 1
	g.comp_hi = 100
	g.comp_guess = 50
	g.attempts_used = g.max_attempts
	g.state = Game.State.PLAYING
	g._update_reverse("h")
	expect_eq(g.state, Game.State.ROUND_OVER)
	expect(g.last_message.contains("beat the machine"),
		"surviving the attempt budget beats the CPU")


func test_reverse_correct_wins() -> void:
	var g = _new_game()
	g.mode = "reverse"
	g.attempts_used = 3
	g.state = Game.State.PLAYING
	g._update_reverse("c")
	expect_eq(g.state, Game.State.ROUND_OVER)
	expect_eq(g.rounds_won, 1, "a confirmed guess is a win")
	expect(g.last_message.contains("3 attempts"), "reports the attempt count")


func test_reverse_invalid_input_is_free() -> void:
	var g = _new_game()
	g.mode = "reverse"
	g.comp_lo = 1
	g.comp_hi = 100
	g.comp_guess = 50
	g.attempts_used = 1
	g.state = Game.State.PLAYING
	g._update_reverse("maybe")
	expect_eq(g.comp_lo, 1)
	expect_eq(g.comp_hi, 100)
	expect_eq(g.attempts_used, 1, "a non-answer costs no attempt")
	expect_eq(g.last_tone, "warn")


# --- Replay -----------------------------------------------------------------------

func test_round_over_replay_flow() -> void:
	var g = _new_game()
	g.state = Game.State.ROUND_OVER
	g._update_round_over("n")
	expect(not g.game_running, "n ends the session")
	var g2 = _new_game()
	g2.state = Game.State.ROUND_OVER
	g2._update_round_over("y")
	expect_eq(g2.state, Game.State.PLAYING, "y starts a fresh round")
	expect_eq(g2.attempts_used, 0)
	g2.state = Game.State.ROUND_OVER
	g2._update_round_over("maybe")
	expect_eq(g2.state, Game.State.ROUND_OVER, "non-answer keeps waiting")
	expect_eq(g2.last_tone, "warn")
