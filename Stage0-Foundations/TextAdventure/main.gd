extends SceneTree

## Dungeon Corridor — Stage 0 deliverable.
## A 1D turn-based adventure that exercises the whole game loop:
## input -> update -> render, plus 1D coordinates and game states.
##
## Run from a terminal inside this folder:
##     godot --headless --script main.gd
##
## (stdin does not work inside the Godot editor — a real console is required.)

const CORRIDOR_SIZE := 10
const EXIT_POS := 9
const SWORD_POS := 3
const GOLD_POS := 7
const MONSTER_POS := 8
const START_HEALTH := 20
const SWORD_FIGHT_DAMAGE := 2
const BARE_HANDS_DAMAGE := 8

# --- Game state (the "what" of the game at this moment) ---
var player_pos := 0
var health := START_HEALTH
var gold := 0
var has_sword := false
var monster_alive := true
var game_running := true
var won := false
var turns := 0
var last_message := ""


func _init() -> void:
	# Guard: without a real stdin (e.g. double-clicked binary), the read
	# below would return "" instantly and the loop would spin forever.
	if OS.get_stdin_type() == OS.STD_HANDLE_INVALID:
		print("This game reads commands from stdin — run it from a terminal:")
		print("    godot --headless --script main.gd")
		quit()
		return
	_print_intro()
	_render()
	while game_running:
		var command := _read_input()    # 1. INPUT
		_update(command)                # 2. UPDATE
		_render()                       # 3. RENDER
	_print_outro()
	quit()


# --- INPUT -----------------------------------------------------------------

func _read_input() -> String:
	printraw("\n> ")
	var line := OS.read_string_from_stdin().strip_edges().to_lower()
	# On piped/redirected stdin an empty read means EOF — exit cleanly
	# instead of spinning. (On a console, "" is just the Enter key.)
	if line == "" and OS.get_stdin_type() != OS.STD_HANDLE_CONSOLE:
		return "quit"
	return line


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
			last_message = "HP %d/%d | Gold %d | Sword: %s | Position %d" % [
				health, START_HEALTH, gold, "yes" if has_sword else "no", player_pos]
		"help", "h", "?":
			_print_help()
		"quit", "q":
			game_running = false
			last_message = "You flee back up the stairs."
		"":
			pass
		_:
			last_message = "Unknown command. Type 'help' for options."
	turns += 1
	_check_end()


func _try_move(direction: int) -> void:
	var target := player_pos + direction
	if target < 0 or target >= CORRIDOR_SIZE:
		last_message = "A cold stone wall blocks your way."
		return
	if target == MONSTER_POS and monster_alive:
		_fight_monster()
		return
	player_pos = target
	_resolve_cell()


func _resolve_cell() -> void:
	if player_pos == SWORD_POS and not has_sword:
		has_sword = true
		last_message = "A rusty sword lies on the floor. You take it."
	elif player_pos == GOLD_POS and gold == 0:
		gold = 100
		last_message = "A pouch of gold! +100 gold."
	elif player_pos == EXIT_POS:
		won = true
		game_running = false
		last_message = "You push open a heavy door — daylight!"
	else:
		last_message = "You creep through the dark corridor."


func _attack() -> void:
	if not monster_alive:
		last_message = "Nothing left to fight."
	elif player_pos == MONSTER_POS - 1:
		_fight_monster()
	else:
		last_message = "You swing at shadows. Nothing is there."


func _fight_monster() -> void:
	if has_sword:
		health -= SWORD_FIGHT_DAMAGE
		monster_alive = false
		last_message = "You slay the goblin! It nicks you on the way down. (-%d HP)" % SWORD_FIGHT_DAMAGE
	else:
		health -= BARE_HANDS_DAMAGE
		last_message = "A goblin guards the way and claws you savagely! (-%d HP) You need a weapon." % BARE_HANDS_DAMAGE


func _describe_cell() -> void:
	var distance := abs(MONSTER_POS - player_pos)
	if player_pos == MONSTER_POS and not monster_alive:
		last_message = "The goblin's corpse lies here. The exit is close."
	elif monster_alive and distance == 1:
		last_message = "You hear snarling one cell ahead. 'attack' or turn back?"
	elif monster_alive and distance <= 3:
		last_message = "Something growls in the darkness ahead."
	elif player_pos == SWORD_POS and not has_sword:
		last_message = "Something metal glints on the floor."
	elif player_pos == GOLD_POS and gold == 0:
		last_message = "A leather pouch sits in a niche."
	elif player_pos == EXIT_POS:
		last_message = "A door stands here."
	else:
		last_message = "Cold stone stretches in both directions."


func _check_end() -> void:
	if health <= 0:
		health = 0
		won = false
		game_running = false
		last_message = "Your legs give out. The corridor goes dark..."


# --- RENDER (drawing — in a text game, printing IS rendering) ---------------

func _render() -> void:
	var cells := PackedStringArray()
	for i in CORRIDOR_SIZE:
		if i == player_pos:
			cells.append("P")
		elif i == MONSTER_POS and monster_alive:
			cells.append("M")
		elif i == EXIT_POS:
			cells.append("E")
		elif i == SWORD_POS and not has_sword:
			cells.append("s")
		elif i == GOLD_POS and gold == 0:
			cells.append("g")
		else:
			cells.append(".")
	print("\n[%s]   HP:%d  Gold:%d" % [" ".join(cells), health, gold])
	if last_message != "":
		print(last_message)


# --- Bookkeeping -----------------------------------------------------------

func _print_intro() -> void:
	print("=== DUNGEON CORRIDOR ===")
	print("A 1D corridor, 10 cells. Reach the door (E) at the far end.")
	print("Beware the thing that guards it. Type 'help' for commands.")


func _print_outro() -> void:
	print("")
	if won:
		print("=== YOU ESCAPED in %d turns with %d gold! ===" % [turns, gold])
	elif health <= 0:
		print("=== GAME OVER — the corridor claims another soul. ===")
	else:
		print("=== You abandoned the delve after %d turns. ===" % turns)


func _print_help() -> void:
	last_message = ""
	print("Commands: left/l, right/r, attack/a, look, status, quit/q")
	print("Map: P=you  s=sword  g=gold  M=monster  E=exit  .=empty")
