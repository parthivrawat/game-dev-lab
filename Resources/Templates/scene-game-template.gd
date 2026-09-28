extends Node2D

## Scene Game Template — a real-time game skeleton for Stage 2+.
## Attach this to the root Node2D of your main scene, then fill in the
## UPDATE section with your game's rules.
##
## Scene setup:
##     Main (Node2D)  ← this script
##     ├── ScoreLabel (Label)
##     └── MessageLabel (Label)
##
## Uses the default ui_* input actions (arrow keys, Enter, Esc) — no
## Input Map setup required for the skeleton to run.

enum State { MENU, PLAYING, PAUSED, GAME_OVER }

# --- Configuration ---
@export var move_speed := 300.0          # pixels per second

# --- Game state ---
var state := State.MENU
var score := 0
var player_pos := Vector2(400, 300)

# --- Node references (safe once the scene tree is built) ---
@onready var score_label: Label = $ScoreLabel
@onready var message_label: Label = $MessageLabel


func _ready() -> void:
	_show_menu()


# --- INPUT -----------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	match state:
		State.MENU:
			if event.is_action_pressed("ui_accept"):
				_start_game()
		State.PLAYING:
			if event.is_action_pressed("ui_cancel"):
				state = State.PAUSED
				_say("Paused — Esc resumes, Enter restarts.")
		State.PAUSED:
			if event.is_action_pressed("ui_cancel"):
				state = State.PLAYING
				_say("")
			elif event.is_action_pressed("ui_accept"):
				_start_game()
		State.GAME_OVER:
			if event.is_action_pressed("ui_accept"):
				_start_game()
			elif event.is_action_pressed("ui_cancel"):
				_show_menu()


# --- UPDATE (game logic) ---------------------------------------------------

func _process(delta: float) -> void:
	if state != State.PLAYING:
		return
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	player_pos += dir * move_speed * delta
	player_pos = player_pos.clamp(Vector2.ZERO, get_viewport_rect().size)
	# --- replace with your game's rules: spawning, collisions, scoring ---
	_render()


func _start_game() -> void:
	state = State.PLAYING
	score = 0
	player_pos = get_viewport_rect().size / 2.0
	_say("Go! Arrows move, Esc pauses.")


func _end_game() -> void:
	state = State.GAME_OVER
	_say("Game over! Score: %d — Enter to retry, Esc for menu." % score)


func _show_menu() -> void:
	state = State.MENU
	_say("MY GAME — press Enter to start.")


# --- RENDER ----------------------------------------------------------------

func _render() -> void:
	score_label.text = "Score: %d" % score
	queue_redraw()   # triggers _draw() below


func _draw() -> void:
	if state == State.MENU:
		return
	draw_circle(player_pos, 12.0, Color.GREEN)


func _say(msg: String) -> void:
	message_label.text = msg
