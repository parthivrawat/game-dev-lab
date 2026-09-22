extends SceneTree

## Dungeon Corridor — Stage 0 deliverable.
## A 1D turn-based adventure that exercises the whole game loop:
## input -> update -> render, plus 1D coordinates and game states.
##
## Run from a terminal inside this folder:
##     godot --headless --script main.gd      (or double-click run.bat)
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
const ESC := "\u001b"   # ANSI escape character

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
var last_tone := "info"         # info | hint | warn | bad | good
var _input_lines: Array = []    # queued lines when stdin delivers a chunk

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
	if not clear_screen:
		_print_intro()
	_render()
	while game_running:
		var command := _read_input()    # 1. INPUT
		_update(command)                # 2. UPDATE
		_render()                       # 3. RENDER
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
			_say("HP %d/%d | Gold %d | Sword: %s | Position %d" % [
				health, START_HEALTH, gold, "yes" if has_sword else "no", player_pos])
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
	if target < 0 or target >= CORRIDOR_SIZE:
		_say("A cold stone wall blocks your way.", "warn")
		return
	if target == MONSTER_POS and monster_alive:
		_fight_monster()
		return
	player_pos = target
	_resolve_cell()


func _resolve_cell() -> void:
	if player_pos == SWORD_POS and not has_sword:
		has_sword = true
		_say("A rusty sword lies on the floor. You take it.", "good")
	elif player_pos == GOLD_POS and gold == 0:
		gold = 100
		_say("A pouch of gold! +100 gold.", "good")
	elif player_pos == EXIT_POS:
		won = true
		game_running = false
		_say("You push open a heavy door — daylight!", "good")
	else:
		_say("You creep through the dark corridor.")


func _attack() -> void:
	if not monster_alive:
		_say("Nothing left to fight.")
	elif player_pos == MONSTER_POS - 1:
		_fight_monster()
	else:
		_say("You swing at shadows. Nothing is there.", "warn")


func _fight_monster() -> void:
	if has_sword:
		health -= SWORD_FIGHT_DAMAGE
		monster_alive = false
		_say("You slay the goblin! It nicks you on the way down. (-%d HP)" % SWORD_FIGHT_DAMAGE, "good")
	else:
		health -= BARE_HANDS_DAMAGE
		_say("A goblin guards the way and claws you savagely! (-%d HP) You need a weapon." % BARE_HANDS_DAMAGE, "bad")


func _describe_cell() -> void:
	var distance := absi(MONSTER_POS - player_pos)
	if player_pos == MONSTER_POS and not monster_alive:
		_say("The goblin's corpse lies here. The exit is close.")
	elif monster_alive and distance == 1:
		_say("You hear snarling one cell ahead. 'attack' or turn back?", "warn")
	elif monster_alive and distance <= 3:
		_say("Something growls in the darkness ahead.", "hint")
	elif player_pos == SWORD_POS and not has_sword:
		_say("Something metal glints on the floor.", "hint")
	elif player_pos == GOLD_POS and gold == 0:
		_say("A leather pouch sits in a niche.", "hint")
	elif player_pos == EXIT_POS:
		_say("A door stands here.")
	else:
		_say("Cold stone stretches in both directions.")


func _check_end() -> void:
	if health <= 0:
		health = 0
		won = false
		game_running = false
		_say("Your legs give out. The corridor goes dark...", "bad")


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
	for i in CORRIDOR_SIZE:
		if i == player_pos:
			cells.append(_c("P", "1;32"))
		elif i == MONSTER_POS and monster_alive:
			cells.append(_c("M", "1;31"))
		elif i == EXIT_POS:
			cells.append(_c("E", "1;36"))
		elif i == SWORD_POS and not has_sword:
			cells.append(_c("s", "33"))
		elif i == GOLD_POS and gold == 0:
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
	print(_c("-".repeat(40), "90"))


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
	print("A 1D corridor, 10 cells. Reach the door (E) at the far end.")
	print("Beware the thing that guards it. Type 'help' for commands.")


func _print_outro() -> void:
	print("")
	if won:
		print(_c("=== YOU ESCAPED in %d turns with %d gold! ===" % [turns, gold], "1;32"))
	elif health <= 0:
		print(_c("=== GAME OVER — the corridor claims another soul. ===", "1;31"))
	else:
		print("=== You abandoned the delve after %d turns. ===" % turns)


func _print_help() -> void:
	_say("")
	print("Commands: left/l, right/r, attack/a, look, status, quit/q")
	print("Map: P=you  s=sword  g=gold  M=monster  E=exit  .=empty")
