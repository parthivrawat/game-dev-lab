extends SceneTree

## Tests for Dungeon Corridor (main.gd).
## Run from a terminal inside this folder:
##     godot --headless --script test_main.gd      (or run_tests.bat)
##
## How it works: the game lives in _initialize() — Godot only calls that
## for the script it launches as the main loop. Instantiating main.gd
## here builds a game object WITHOUT starting a session, so each test
## sets the board up directly and calls the logic functions one at a
## time, the same way the manual checklist drives a play session.

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


# --- Map generation -------------------------------------------------------------

func test_generated_map_respects_layout_rules() -> void:
	for s in [1, 7, 42, 1999]:
		seed(s)
		for depth in [1, 3]:
			var g = _new_game()
			g.depth = depth
			g._generate_map()
			var n: int = g.corridor_size
			expect(n >= Game.MIN_CORRIDOR and n <= Game.MAX_CORRIDOR_SIZE,
				"corridor size within caps (seed %d, depth %d)" % [s, depth])
			expect(g.exit_pos == 0 or g.exit_pos == n - 1, "exit on an end cell")
			expect_eq(g.vault_pos, n - 1 - g.exit_pos, "vault on the far end")
			expect(g.player_pos >= n / 3 and g.player_pos <= n * 2 / 3,
				"spawn in the middle third")
			expect(not g.monsters.is_empty(), "gate goblin always spawns")
			for m in g.monsters:
				expect(absi(m - g.player_pos) >= Game.MONSTER_MIN_SPAWN,
					"no goblin spawns next to the player")
			# The gate goblin (always first) sits on the route to the exit.
			var gate: int = g.monsters[0]
			expect_eq(signi(gate - g.player_pos), signi(g.exit_pos - g.player_pos),
				"gate goblin guards the exit route")
			# The sword lands in the monster-free zone around the spawn.
			expect(g._reachable_cells().has(g.sword_pos),
				"sword reachable without crossing a goblin")
			for p in g.gold_positions:
				expect(p != g.exit_pos and p != g.player_pos
					and p != g.sword_pos and not g.monsters.has(p),
					"gold never shares a cell")
			for p in g.potions:
				expect(p != g.exit_pos and p != g.player_pos
					and p != g.sword_pos and not g.monsters.has(p)
					and not g.gold_positions.has(p),
					"potion never shares a cell")


func test_reachable_cells_stops_at_first_monster() -> void:
	var g = _new_game()
	g.corridor_size = 10
	g.player_pos = 5
	g.monsters = [2, 8]
	var cells := g._reachable_cells()
	cells.sort()
	expect_eq(cells, [3, 4, 6, 7], "walk zone bounded by nearest goblins")
	expect(not cells.has(g.player_pos), "own cell is not in the list")


func test_free_cells_excludes_everything_occupied() -> void:
	var g = _new_game()
	g.corridor_size = 10
	g.player_pos = 5
	g.exit_pos = 9
	g.sword_pos = 3
	g.monsters = [7]
	g.gold_positions = [0]
	g.potions = [1]
	var free := g._free_cells()
	free.sort()
	expect_eq(free, [2, 4, 6, 8], "only unclaimed cells are free")


# --- Movement and fighting ------------------------------------------------------

func test_wall_bump_costs_a_turn() -> void:
	var g = _new_game()
	g.corridor_size = 10
	g.player_pos = 0
	g.monsters = [5]
	g._update("left")
	expect_eq(g.player_pos, 0, "the wall blocks the move")
	expect_eq(g.turns, 1, "a wall bump still ticks the world")
	expect_eq(g.last_tone, "warn")
	expect(g.last_message.contains("wall"), "player is told about the wall")


func test_bumping_a_goblin_fights_bare_handed() -> void:
	var g = _new_game()
	g.player_pos = 4
	g.monsters = [5]
	g.has_sword = false
	g._try_move(1)
	expect_eq(g.health, Game.START_HEALTH - Game.BARE_HANDS_DAMAGE,
		"bare hands cost full damage")
	expect(g.monsters.has(5), "the goblin survives")
	expect_eq(g.player_pos, 4, "you do not enter the goblin's cell")
	expect_eq(g.last_tone, "bad")


func test_sword_fight_removes_the_goblin() -> void:
	var g = _new_game()
	g.player_pos = 4
	g.monsters = [5]
	g.has_sword = true
	g._try_move(1)
	expect_eq(g.health, Game.START_HEALTH - Game.SWORD_FIGHT_DAMAGE,
		"a clean kill only nicks you")
	expect(g.monsters.is_empty(), "the goblin dies")
	expect_eq(g.player_pos, 4, "the cleared cell still needs a step")
	expect_eq(g.last_tone, "good")


func test_attack_hits_only_adjacent_goblins() -> void:
	var g = _new_game()
	g.player_pos = 5
	g.monsters = [4, 8]
	g.has_sword = true
	g._attack()
	expect(not g.monsters.has(4), "adjacent goblin is hit")
	expect(g.monsters.has(8), "distant goblin is safe")
	var g2 = _new_game()
	g2.player_pos = 5
	g2.monsters = [8]
	g2._attack()
	expect_eq(g2.health, Game.START_HEALTH, "a whiff costs nothing")
	expect(g2.last_message.contains("shadows"), "whiff is reported")


# --- Cell pickups -----------------------------------------------------------------

func test_gold_pile_pays_out_once() -> void:
	var g = _new_game()
	g.player_pos = 3
	g.sword_pos = 7           # clear of the test cell so gold resolves
	g.gold_positions = [3]
	g._resolve_cell()
	expect_eq(g.gold, Game.GOLD_PER_PILE, "the pile pays out")
	expect(g.gold_positions.is_empty(), "the pile is spent")
	expect_eq(g.last_tone, "good")


func test_potion_heals_but_never_past_full() -> void:
	var g = _new_game()
	g.player_pos = 3
	g.sword_pos = 7           # clear of the test cell so the potion resolves
	g.potions = [3]
	g.health = Game.START_HEALTH - 4
	g._resolve_cell()
	expect_eq(g.health, Game.START_HEALTH, "healing is capped at max HP")
	expect(g.potions.is_empty(), "the potion is drunk")


func test_sword_and_exit_cells() -> void:
	var g = _new_game()
	g.player_pos = 3
	g.sword_pos = 3
	g.has_sword = false
	g._resolve_cell()
	expect(g.has_sword, "the sword is picked up")
	var g2 = _new_game()
	g2.exit_pos = 9
	g2.player_pos = 9
	g2._resolve_cell()
	expect_eq(g2.state, Game.State.WON, "reaching the door wins the delve")


# --- Chasing goblins ---------------------------------------------------------------

func test_goblins_close_distance_each_tick() -> void:
	var g = _new_game()
	g.player_pos = 5
	g.monsters = [8]
	g._chase_monsters()
	expect_eq(g.monsters, [7], "goblin shambles one cell closer")
	expect_eq(g.health, Game.START_HEALTH, "no claw from range")


func test_adjacent_goblins_claw_instead_of_moving() -> void:
	var g = _new_game()
	g.player_pos = 5
	g.monsters = [6]
	g._chase_monsters()
	expect_eq(g.health, Game.START_HEALTH - Game.MONSTER_CLAW_DAMAGE,
		"one adjacent goblin claws once")
	expect_eq(g.monsters, [6], "a clawing goblin holds its ground")


func test_goblins_do_not_stack() -> void:
	var g = _new_game()
	g.player_pos = 5
	g.monsters = [6, 7]
	g._chase_monsters()
	expect_eq(g.health, Game.START_HEALTH - Game.MONSTER_CLAW_DAMAGE,
		"only the adjacent goblin claws")
	expect_eq(g.monsters, [6, 7], "the second goblin is blocked, not stacked")


func test_goblins_wont_cover_an_untaken_sword() -> void:
	var g = _new_game()
	g.player_pos = 5
	g.sword_pos = 6
	g.monsters = [7]
	g.has_sword = false
	g._chase_monsters()
	expect_eq(g.monsters, [7], "goblin will not step onto the sword")
	g.has_sword = true
	g._chase_monsters()
	expect_eq(g.monsters, [6], "once carried, the cell is free")


func test_nearest_monster_reports_closest() -> void:
	var g = _new_game()
	g.player_pos = 5
	g.monsters = [2, 9]
	expect_eq(g._nearest_monster(), 2, "closer side wins")
	g.monsters = []
	expect_eq(g._nearest_monster(), -1, "no goblins means -1")


# --- Turn rules and state ----------------------------------------------------------

func test_free_commands_do_not_tick_the_world() -> void:
	var g = _new_game()
	g.corridor_size = 10
	g.player_pos = 5
	g.monsters = [8]
	for cmd in ["look", "map", "status", "help", "nonsense"]:
		g._update(cmd)
		expect_eq(g.turns, 0, "'%s' is free — goblins do not move" % cmd)
	expect_eq(g.monsters, [8], "scouting never moves the goblins")
	g._update("wait")
	expect_eq(g.turns, 1, "waiting is a real action")


func test_quit_and_death_states() -> void:
	var g = _new_game()
	g._update("quit")
	expect_eq(g.state, Game.State.QUIT, "quit abandons the delve")
	var g2 = _new_game()
	g2.corridor_size = 10
	g2.player_pos = 5
	g2.monsters = [6]
	g2.health = Game.MONSTER_CLAW_DAMAGE
	g2._update("wait")
	expect_eq(g2.state, Game.State.LOST, "lethal claw ends the run")
	expect_eq(g2.health, 0, "HP is clamped at zero, not negative")


# --- Round bookkeeping ---------------------------------------------------------------

func test_start_round_resets_the_delve() -> void:
	var g = _new_game()
	seed(99)
	g.health = 3
	g.gold = 500
	g.has_sword = true
	g.state = Game.State.LOST
	g._start_round()
	expect_eq(g.health, Game.START_HEALTH, "HP restored")
	expect_eq(g.gold, 0, "gold reset")
	expect(not g.has_sword, "sword lost")
	expect_eq(g.state, Game.State.PLAYING, "back to playing")
	expect_eq(g.delves, 1, "delve counted")
	expect_eq(g.best_depth, g.depth, "depth recorded")


func test_escape_banks_gold_and_descends() -> void:
	var g = _new_game()
	g.state = Game.State.WON
	g.depth = 1
	g.gold = 120
	g._print_round_result()
	expect_eq(g.escapes, 1, "escape counted")
	expect_eq(g.total_gold, 120, "gold banked for the session")
	expect_eq(g.depth, 2, "the next delve is deeper")
	g.state = Game.State.LOST
	g._print_round_result()
	expect_eq(g.depth, 1, "dying sends you back to depth 1")
	g.depth = 3
	g.state = Game.State.QUIT
	g._print_round_result()
	expect_eq(g.depth, 1, "fleeing sends you back to depth 1")
