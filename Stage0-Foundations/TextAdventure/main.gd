extends SceneTree

## Dungeon Corridor — Stage 0 deliverable, improved edition.
## A 1D turn-based adventure exercising the game loop, 1D coordinates,
## and game states — now with chasing monsters, potions, an enum state
## machine, and depth progression (Exercises D1–D5 implemented).
##
## Each delve generates a RANDOM corridor:
## - you spawn in the middle third; the exit is a random end
## - a gate goblin guards the exit route; deeper delves add hunters
## - the sword always spawns where you can reach it without crossing
##   a living goblin — but goblins CHASE you now, so move fast
## - potions heal, gold piles wait at the vault end
##
## Escaping descends you one depth: longer corridor, more goblins.
## Dying or fleeing sends you back to depth 1.
##
## Run from a terminal inside this folder:
##     godot --headless --script main.gd      (or double-click run.bat)
##
## (stdin does not work inside the Godot editor — a real console is required.)

const MIN_CORRIDOR := 10
const MAX_CORRIDOR := 16
const CORRIDOR_GROWTH := 4       # extra cells per depth below 1
const MAX_CORRIDOR_SIZE := 28    # cap so the map still fits one line
const MAX_HUNTERS := 3           # extra goblins beyond the gate guard
const START_HEALTH := 20
const SWORD_FIGHT_DAMAGE := 2
const BARE_HANDS_DAMAGE := 8
const MONSTER_CLAW_DAMAGE := 3
const POTION_HEAL := 10
const GOLD_PER_PILE := 100
const VAULT_MONSTER_CHANCE := 0.5
const MONSTER_MIN_SPAWN := 2     # goblins never spawn next to you
const ESC := "\u001b"            # ANSI escape character

enum State { PLAYING, WON, LOST, QUIT }

# --- Map layout (regenerated every delve) ---
var corridor_size := 10
var exit_pos := 9
var vault_pos := 0               # end opposite the exit — bonus treasure
var sword_pos := 3
var monsters: Array = []         # positions of living goblins
var gold_positions: Array = []
var potions: Array = []

# --- Game state (the "what" of the game at this moment) ---
var state := State.PLAYING
var player_pos := 0
var health := START_HEALTH
var gold := 0
var has_sword := false
var turns := 0
var depth := 1                   # current corridor depth — grows on escape
var best_depth := 0              # deepest depth reached this session
var total_gold := 0              # banked across delves
var delves := 0
var escapes := 0
var last_message := ""
var last_tone := "info"          # info | hint | warn | bad | good
var _input_lines: Array = []     # queued lines when stdin delivers a chunk

# --- UI toggles (auto-disabled when output isn't a real console) ---
var use_color := true
var clear_screen := true


func _init() -> void:
	# Guard: without a real stdin (e.g. double-clicked binary), the read
	# below would return "" instantly and the loop would spin forever.
	if OS.get_stdin_type() == OS.STD_HANDLE_INVALID:
		print("This game reads commands from stdin — run it from a terminal:")
		print("    godot --headless --script main.gd   (or run.bat)")
		quit()
		return
	_detect_terminal()
	randomize()
	if not clear_screen:
		_print_intro()
	var play_again := true
	while play_again:
		_start_round()
		_render()
		while state == State.PLAYING:
			var command := _read_input()    # 1. INPUT
			_update(command)                # 2. UPDATE
			_render()                       # 3. RENDER
		_print_round_result()
		play_again = _ask_play_again()
	if clear_screen:
		_clear_screen()
	_print_outro()
	quit()


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


# --- Map generation --------------------------------------------------------

func _generate_map() -> void:
	# Depth scaling: each escape makes the next corridor longer and
	# adds a hunter (capped) — the reward for winning is a worse one.
	corridor_size = mini(
		randi_range(MIN_CORRIDOR, MAX_CORRIDOR) + (depth - 1) * CORRIDOR_GROWTH,
		MAX_CORRIDOR_SIZE)
	# Exit at a random end; the other end is the gold vault.
	exit_pos = 0 if randi() % 2 == 0 else corridor_size - 1
	vault_pos = corridor_size - 1 - exit_pos
	# Player spawns in the middle third — never on an end cell.
	player_pos = randi_range(corridor_size / 3, corridor_size * 2 / 3)

	monsters.clear()
	# GATE goblin: always on the route to the exit, never adjacent to spawn.
	var exit_dir := signi(exit_pos - player_pos)
	var exit_dist := absi(exit_pos - player_pos)
	monsters.append(player_pos + exit_dir * randi_range(MONSTER_MIN_SPAWN, exit_dist))
	# VAULT goblin: 50% chance, guards the treasure on the far side.
	var vault_dist := absi(vault_pos - player_pos)
	if randf() < VAULT_MONSTER_CHANCE and vault_dist >= 3:
		monsters.append(player_pos - exit_dir * randi_range(MONSTER_MIN_SPAWN, vault_dist))
	# HUNTERS: one extra per depth — they spawn already smelling you.
	for i in mini(depth - 1, MAX_HUNTERS):
		var lair := _random_lair_cell()
		if lair != -1:
			monsters.append(lair)

	# COMPLETENESS RULE: the sword must be reachable without crossing a
	# living monster. Walk both directions from spawn and stop at the
	# first goblin each way — any cell in that zone is fair game.
	# (Chasers can still cut you off afterwards — the guarantee is that
	# the sword is reachable NOW, not that it stays safe.)
	var reachable := _reachable_cells()
	reachable.erase(vault_pos)   # keep the vault free for its gold pile
	sword_pos = reachable[randi_range(0, reachable.size() - 1)]

	# Gold: a guaranteed pile at the vault end (if the cell is free),
	# plus 1-2 piles scattered on other empty cells.
	gold_positions.clear()
	if not monsters.has(vault_pos):
		gold_positions.append(vault_pos)
	var piles := randi_range(1, 2)
	for i in piles:
		var free := _free_cells()
		if not free.is_empty():
			gold_positions.append(free[randi_range(0, free.size() - 1)])

	# Potions: one per delve, plus more on deeper runs — you'll need them.
	potions.clear()
	for i in clampi(depth, 1, 3):
		var free := _free_cells()
		if not free.is_empty():
			potions.append(free[randi_range(0, free.size() - 1)])


func _random_lair_cell() -> int:
	# Hunter spawn: any cell far enough from the player and not already
	# holding a goblin. Exit/vault cells are fair game — it won't stay.
	var cells: Array = []
	for i in corridor_size:
		if absi(i - player_pos) >= MONSTER_MIN_SPAWN and not monsters.has(i):
			cells.append(i)
	if cells.is_empty():
		return -1
	return cells[randi_range(0, cells.size() - 1)]


func _reachable_cells() -> Array:
	# Cells the player can walk to without fighting — stops at the first
	# living monster in each direction. Guaranteed non-empty because the
	# nearest monster is always >= MONSTER_MIN_SPAWN cells from spawn.
	var cells: Array = []
	var i := player_pos - 1
	while i >= 0 and not monsters.has(i):
		cells.append(i)
		i -= 1
	i = player_pos + 1
	while i < corridor_size and not monsters.has(i):
		cells.append(i)
		i += 1
	return cells


func _free_cells() -> Array:
	var cells: Array = []
	for i in corridor_size:
		if i != player_pos and i != exit_pos and i != sword_pos \
				and not monsters.has(i) and not gold_positions.has(i) \
				and not potions.has(i):
			cells.append(i)
	return cells


# --- INPUT -----------------------------------------------------------------

func _read_input() -> String:
	printraw("\n> ")
	if _input_lines.is_empty():
		var chunk := OS.read_string_from_stdin()
		if chunk == "":
			# EOF on piped/redirected stdin -> quit instead of looping
			# forever. On a console, "" is just the Enter key.
			if OS.get_stdin_type() != OS.STD_HANDLE_CONSOLE:
				return "quit"
			return ""
		# A single read may contain several lines when stdin is piped —
		# split them so queued input isn't swallowed in one command.
		# Drop one trailing line ending first, or its empty tail becomes
		# a phantom wait turn.
		_input_lines = chunk.trim_suffix("\n").trim_suffix("\r").split("\n")
	var line: String = _input_lines.pop_front()
	return line.strip_edges().to_lower()


# --- UPDATE (game logic) ---------------------------------------------------

func _update(command: String) -> void:
	# Only actions that pass time tick the world — looking, checking the
	# map and asking for help are free. With goblins on your trail, that
	# distinction is the difference between scouting and being eaten.
	match command:
		"left", "l":
			_try_move(-1)
			_world_tick()
		"right", "r":
			_try_move(1)
			_world_tick()
		"wait", "w", "":
			_say("You hold your ground, listening.")
			_world_tick()
		"attack", "a":
			_attack()
			_world_tick()
		"look":
			_describe_cell()
		"map":
			_say("P=you  s=sword  g=gold  p=potion  M=goblin  E=exit  .=empty")
		"status":
			_say("HP %d/%d | Gold %d | Sword: %s | Goblins: %d | Position %d/%d | Depth %d" % [
				health, START_HEALTH, gold, "yes" if has_sword else "no",
				monsters.size(), player_pos, corridor_size - 1, depth])
		"help", "h", "?":
			_print_help()
		"quit", "q":
			state = State.QUIT
			_say("You flee back up the stairs.")
		_:
			_say("Unknown command. Type 'help' for options.", "warn")


func _world_tick() -> void:
	# One tick of the game world — the goblins always get their move.
	turns += 1
	if state != State.PLAYING:
		return    # you escaped/died this action — no last swipe
	_chase_monsters()
	_check_end()


func _chase_monsters() -> void:
	# Every goblin shambles one cell toward you. If it's already adjacent
	# it claws instead of moving — the corridor gives no room to pass.
	var claws := 0
	for i in range(monsters.size()):
		var step: int = monsters[i] + signi(player_pos - monsters[i])
		if step == player_pos:
			claws += 1
		elif not monsters.has(step) and (has_sword or step != sword_pos):
			monsters[i] = step
		# else: blocked — by another goblin, or the sword it would cover up
	if claws > 0:
		health -= MONSTER_CLAW_DAMAGE * claws
		var claw_msg := "A goblin claws you! (-%d HP)" % (MONSTER_CLAW_DAMAGE * claws)
		if claws > 1:
			claw_msg = "%d goblins claw you! (-%d HP)" % [
				claws, MONSTER_CLAW_DAMAGE * claws]
		_say(last_message + " " + claw_msg, "bad")


func _try_move(direction: int) -> void:
	var target := player_pos + direction
	if target < 0 or target >= corridor_size:
		_say("A cold stone wall blocks your way.", "warn")
		return
	if monsters.has(target):
		_fight_monster(target)
		return
	player_pos = target
	_resolve_cell()


func _resolve_cell() -> void:
	if player_pos == sword_pos and not has_sword:
		has_sword = true
		_say("A rusty sword lies on the floor. You take it.", "good")
	elif gold_positions.has(player_pos):
		gold_positions.erase(player_pos)
		gold += GOLD_PER_PILE
		_say("A pouch of gold! +%d gold." % GOLD_PER_PILE, "good")
	elif potions.has(player_pos):
		potions.erase(player_pos)
		var gain := mini(health + POTION_HEAL, START_HEALTH) - health
		health += gain
		_say("A corked potion — you drink it down. +%d HP." % gain, "good")
	elif player_pos == exit_pos:
		state = State.WON
		_say("You push open a heavy door — daylight!", "good")
	else:
		_say("You creep through the dark corridor.")


func _attack() -> void:
	# Hit any adjacent goblin, either side.
	for m in [player_pos - 1, player_pos + 1]:
		if monsters.has(m):
			_fight_monster(m)
			return
	_say("You swing at shadows. Nothing is there.", "warn")


func _fight_monster(pos: int) -> void:
	if has_sword:
		health -= SWORD_FIGHT_DAMAGE
		monsters.erase(pos)
		_say("You slay the goblin! It nicks you on the way down. (-%d HP)"
			% SWORD_FIGHT_DAMAGE, "good")
	else:
		health -= BARE_HANDS_DAMAGE
		_say("A goblin claws you savagely! (-%d HP) You need a weapon."
			% BARE_HANDS_DAMAGE, "bad")


func _describe_cell() -> void:
	var nearest := _nearest_monster()
	var distance := 99 if nearest == -1 else absi(nearest - player_pos)
	if player_pos == exit_pos:
		_say("A door stands here.")
	elif nearest != -1 and distance == 1:
		_say("Snarling one cell away — 'attack' or keep moving!", "warn")
	elif nearest != -1 and distance <= 3:
		_say("Footsteps shuffle closer through the dark.", "hint")
	elif player_pos == sword_pos and not has_sword:
		_say("Something metal glints on the floor.", "hint")
	elif gold_positions.has(player_pos):
		_say("A leather pouch sits in a niche.", "hint")
	elif potions.has(player_pos):
		_say("A corked vial glints in the gloom.", "hint")
	elif player_pos == vault_pos:
		_say("This is the deepest end of the corridor.")
	else:
		_say("Cold stone stretches in both directions.")


func _nearest_monster() -> int:
	var nearest := -1
	for m in monsters:
		if nearest == -1 or absi(m - player_pos) < absi(nearest - player_pos):
			nearest = m
	return nearest


func _check_end() -> void:
	if health <= 0:
		health = 0
		state = State.LOST
		_say("Your legs give out. The corridor goes dark...", "bad")


func _start_round() -> void:
	_generate_map()
	health = START_HEALTH
	gold = 0
	has_sword = false
	turns = 0
	state = State.PLAYING
	delves += 1
	best_depth = maxi(best_depth, depth)
	_say("Depth %d — a %d-cell corridor. The door is to the %s — and the goblins can smell you."
		% [depth, corridor_size, "left" if exit_pos == 0 else "right"])


func _ask_play_again() -> bool:
	while true:
		printraw("\nDelve again? (y/n): ")
		var answer := _read_input()
		if answer in ["y", "yes"]:
			return true
		if answer in ["n", "no", "quit", "q"]:
			return false
		print("Please answer 'y' or 'n'.")
	return false


# --- RENDER (drawing — in a text game, printing IS rendering) ---------------

func _render() -> void:
	if clear_screen:
		_clear_screen()
	elif last_message != "":
		print("")
	_print_hud()
	if last_message != "":
		print(_tone(last_message, last_tone))


func _print_hud() -> void:
	var cells := PackedStringArray()
	for i in corridor_size:
		if i == player_pos:
			cells.append(_c("P", "1;32"))
		elif monsters.has(i):
			cells.append(_c("M", "1;31"))
		elif i == exit_pos:
			cells.append(_c("E", "1;36"))
		elif i == sword_pos and not has_sword:
			cells.append(_c("s", "33"))
		elif gold_positions.has(i):
			cells.append(_c("g", "33"))
		elif potions.has(i):
			cells.append(_c("p", "1;35"))
		else:
			cells.append(_c(".", "90"))
	print(_c("=== DUNGEON CORRIDOR ===", "1;36"))
	print("[%s]" % " ".join(cells))
	var hp_code := "1;31" if health <= 5 else "32"
	print("%s   %s   %s   %s" % [
		_c("HP:%d" % health, hp_code),
		_c("Gold:%d" % gold, "33"),
		_c("Depth:%d" % depth, "1;35"),
		_c("Turn:%d" % turns, "90")])
	print(_c("P=you s=sword g=gold p=potion M=goblin E=exit", "90"))
	print(_c("-".repeat(44), "90"))


# --- Output helpers --------------------------------------------------------

func _say(text: String, tone := "info") -> void:
	# All status messages funnel through here so render() can color by tone.
	last_message = text
	last_tone = tone


func _tone(text: String, tone: String) -> String:
	match tone:
		"good": return _c(text, "1;32")   # bold green  — wins, pickups
		"bad":  return _c(text, "1;31")   # bold red    — defeat, damage
		"warn": return _c(text, "33")     # yellow      — invalid input
		"hint": return _c(text, "36")     # cyan        — clues, sounds
		_:      return text               # info        — plain


func _c(text: String, code: String) -> String:
	if not use_color:
		return text
	return ESC + "[" + code + "m" + text + ESC + "[0m"


func _clear_screen() -> void:
	printraw(ESC + "[2J" + ESC + "[H")


# --- Bookkeeping -----------------------------------------------------------

func _print_intro() -> void:
	print("=== DUNGEON CORRIDOR ===")
	print("Each delve is a different corridor — you spawn mid-way, the door")
	print("is at one end, gold at the other. Find the sword (s) before you")
	print("cross a goblin (M) — they CHASE you now. 'help' for commands.")


func _print_round_result() -> void:
	print("")
	match state:
		State.WON:
			escapes += 1
			total_gold += gold
			depth += 1
			print(_c("=== YOU ESCAPED in %d turns with %d gold — stairs spiral down to depth %d ==="
				% [turns, gold, depth], "1;32"))
		State.LOST:
			depth = 1
			print(_c("=== GAME OVER — the corridor claims another soul. ===", "1;31"))
		State.QUIT:
			depth = 1
			print("=== You abandoned the delve after %d turns. ===" % turns)


func _print_outro() -> void:
	print("")
	if delves > 0:
		print(_c("=== Session: %d/%d delves escaped | Deepest: %d | Gold banked: %d ==="
			% [escapes, delves, best_depth, total_gold], "1;36"))


func _print_help() -> void:
	# Route through _say() so the text survives the next _render()'s
	# screen clear — direct print() output would be wiped instantly.
	_say("Commands: left/l, right/r, wait/w, attack/a, look, map, status, quit/q\n"
		+ "Only moving, waiting and attacking pass time — goblins chase each tick.")
