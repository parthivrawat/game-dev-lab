extends SceneTree

## Dungeon Corridor — Stage 0 deliverable.
## A 1D turn-based adventure that exercises the whole game loop:
## input -> update -> render, plus 1D coordinates and game states.
##
## Each delve generates a RANDOM but always completable corridor:
## - player spawns in the middle third
## - the exit is a random end; the far end is a gold "vault"
## - 1-2 monsters block paths (one always guards the exit route)
## - the sword always spawns where you can reach it without crossing
##   a living monster — that's what makes every map winnable.
##
## Run from a terminal inside this folder:
##     godot --headless --script main.gd      (or double-click run.bat)
##
## (stdin does not work inside the Godot editor — a real console is required.)

const MIN_CORRIDOR := 10
const MAX_CORRIDOR := 16
const START_HEALTH := 20
const SWORD_FIGHT_DAMAGE := 2
const BARE_HANDS_DAMAGE := 8
const GOLD_PER_PILE := 100
const VAULT_MONSTER_CHANCE := 0.5
const ESC := "\u001b"          # ANSI escape character

# --- Map layout (regenerated every delve) ---
var corridor_size := 10
var exit_pos := 9
var vault_pos := 0             # end opposite the exit — bonus treasure
var sword_pos := 3
var monsters: Array = []       # positions of living goblins
var gold_positions: Array = []

# --- Game state (the "what" of the game at this moment) ---
var player_pos := 0
var health := START_HEALTH
var gold := 0
var has_sword := false
var game_running := true       # current round is active
var won := false
var turns := 0
var delves := 0                # corridors attempted this session
var escapes := 0
var last_message := ""
var last_tone := "info"        # info | hint | warn | bad | good
var _input_lines: Array = []   # queued lines when stdin delivers a chunk

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
		while game_running:
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
	corridor_size = randi_range(MIN_CORRIDOR, MAX_CORRIDOR)
	# Exit at a random end; the other end is the gold vault.
	exit_pos = 0 if randi() % 2 == 0 else corridor_size - 1
	vault_pos = corridor_size - 1 - exit_pos
	# Player spawns in the middle third — never on an end cell.
	player_pos = randi_range(corridor_size / 3, corridor_size * 2 / 3)

	monsters.clear()
	# GATE monster: always on the route to the exit, never adjacent to spawn.
	var exit_dir := signi(exit_pos - player_pos)
	var exit_dist := absi(exit_pos - player_pos)
	# offset 2..exit_dist — may sit ON the exit cell itself.
	monsters.append(player_pos + exit_dir * randi_range(2, exit_dist))
	# VAULT monster: 50% chance, guards the treasure on the far side.
	var vault_dist := absi(vault_pos - player_pos)
	if randf() < VAULT_MONSTER_CHANCE and vault_dist >= 3:
		monsters.append(player_pos - exit_dir * randi_range(2, vault_dist))

	# COMPLETENESS RULE: the sword must be reachable without crossing a
	# living monster. Walk both directions from spawn and stop at the
	# first monster each way — any cell in that zone is fair game.
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


func _reachable_cells() -> Array:
	# Cells the player can walk to without fighting — stops at the first
	# living monster in each direction. Guaranteed non-empty because the
	# nearest monster is always >= 2 cells from spawn.
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
				and not monsters.has(i) and not gold_positions.has(i):
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
		_input_lines = chunk.split("\n")
	var line: String = _input_lines.pop_front()
	return line.strip_edges().to_lower()


# --- UPDATE (game logic) ---------------------------------------------------

func _update(command: String) -> void:
	match command:
		"left", "l":
			_try_move(-1)
		"right", "r":
			_try_move(1)
		"attack", "a":
			_attack()
		"look":
			_describe_cell()
		"status":
			_say("HP %d/%d | Gold %d | Sword: %s | Goblins: %d | Position %d/%d" % [
				health, START_HEALTH, gold, "yes" if has_sword else "no",
				monsters.size(), player_pos, corridor_size - 1])
		"help", "h", "?":
			_print_help()
		"quit", "q":
			game_running = false
			_say("You flee back up the stairs.")
		"":
			pass
		_:
			_say("Unknown command. Type 'help' for options.", "warn")
	turns += 1
	_check_end()


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
	elif player_pos == exit_pos:
		won = true
		game_running = false
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
		_say("You hear snarling one cell away. 'attack' or turn back?", "warn")
	elif nearest != -1 and distance <= 3:
		_say("Something growls in the darkness.", "hint")
	elif player_pos == sword_pos and not has_sword:
		_say("Something metal glints on the floor.", "hint")
	elif gold_positions.has(player_pos):
		_say("A leather pouch sits in a niche.", "hint")
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
		won = false
		game_running = false
		_say("Your legs give out. The corridor goes dark...", "bad")


func _start_round() -> void:
	_generate_map()
	health = START_HEALTH
	gold = 0
	has_sword = false
	game_running = true
	won = false
	turns = 0
	delves += 1
	_say("You descend into a %d-cell corridor. The door is to the %s — the far end smells of gold."
		% [corridor_size, "left" if exit_pos == 0 else "right"])


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
		else:
			cells.append(_c(".", "90"))
	print(_c("=== DUNGEON CORRIDOR ===", "1;36"))
	print("[%s]" % " ".join(cells))
	var hp_code := "1;31" if health <= 5 else "32"
	print("%s   %s   %s" % [
		_c("HP:%d" % health, hp_code),
		_c("Gold:%d" % gold, "33"),
		_c("Turn:%d" % turns, "90")])
	print(_c("P=you s=sword g=gold M=monster E=exit", "90"))
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
	print("Each delve is a different random corridor — you spawn mid-way.")
	print("The door (E) is at one end, gold waits at the other. Find the")
	print("sword (s) before you cross any monster (M). 'help' for commands.")


func _print_round_result() -> void:
	print("")
	if won:
		escapes += 1
		print(_c("=== YOU ESCAPED in %d turns with %d gold! ===" % [turns, gold], "1;32"))
	elif health <= 0:
		print(_c("=== GAME OVER — the corridor claims another soul. ===", "1;31"))
	else:
		print("=== You abandoned the delve after %d turns. ===" % turns)


func _print_outro() -> void:
	print("")
	if delves > 0:
		print(_c("=== Session: %d/%d delves escaped ===" % [escapes, delves], "1;36"))


func _print_help() -> void:
	# Route through _say() so the text survives the next _render()'s
	# screen clear — direct print() output would be wiped instantly.
	_say("Commands: left/l, right/r, attack/a, look, status, quit/q\n"
		+ "Map: P=you  s=sword  g=gold  M=monster  E=exit  .=empty")
