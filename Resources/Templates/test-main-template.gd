extends SceneTree

## Test Harness Template — automated checks for console games.
## Copy this file as test_main.gd next to your game's main.gd, then
## write one test_* function per promise your game makes.
##
## Run from a terminal inside the game folder:
##     godot --headless --script test_main.gd      (or run_tests.bat)
##
## How it works: the game lives in _initialize() — Godot only calls that
## for the script it launches as the main loop. Instantiating main.gd
## here builds a game object WITHOUT starting a session, so each test
## sets the board up directly and calls the logic functions one at a
## time — the automated version of the manual checklist habit from
## ../Theory/06-Debugging-and-Testing.md.

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
	# Disable cosmetic output while testing. Delete these two lines if
	# your game doesn't have these toggles.
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


# --- Tests ----------------------------------------------------------------------
## Every function named test_* runs automatically, in alphabetical order.
## Replace this example with real checks of YOUR game's rules — see any
## Stage 1 game's test_main.gd for working examples.

func test_fresh_game_state() -> void:
	var g = _new_game()
	expect_eq(g.score, 0, "a fresh game starts at zero score")
	expect_eq(g.state, Game.State.PLAYING, "a fresh game starts in PLAYING")
