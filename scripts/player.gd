extends CharacterBody2D

@export var speed: float = 200.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var movement_locked := false
var _movement_lock_owners: Dictionary = {}

var active_keys: Array[String] = []
var last_key: String = "move_down"

func _ready() -> void:
	add_to_group("player")
	add_to_group("Player")

func _input(event: InputEvent) -> void:
	# Jeśli ruch jest zablokowany (np. podczas rozmowy), ignorujemy wciskanie klawiszy
	if movement_locked or not _movement_lock_owners.is_empty():
		return

	if event is InputEventKey and not event.is_echo():
		for action in ["move_up", "move_down", "move_left", "move_right"]:
			if event.is_action(action):
				if event.pressed:
					if not active_keys.has(action):
						active_keys.append(action)
				else:
					active_keys.erase(action)

func _physics_process(_delta: float) -> void:
	# Jeśli ruch jest zablokowany przez NPC/dialog
	if movement_locked or not _movement_lock_owners.is_empty():
		velocity = Vector2.ZERO
		active_keys.clear() # Czyścimy klawisze, żeby nie szedł sam po dialogu
		update_animation()
		return

	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
	
	update_animation()

func update_animation() -> void:
	# Podczas blokady ruchu włączamy odpowiedni Idle
	if movement_locked or not _movement_lock_owners.is_empty():
		play_idle_animation()
		return

	# Jeśli trzymamy klawisze – BIEG (Run)
	if not active_keys.is_empty():
		var current_key = active_keys[0]
		last_key = current_key
		
		match current_key:
			"move_up":
				animated_sprite.play("RunUp")
				animated_sprite.flip_h = false
			"move_down":
				animated_sprite.play("RunDown")
				animated_sprite.flip_h = false
			"move_left":
				animated_sprite.play("RunLeft")
				animated_sprite.flip_h = false
			"move_right":
				animated_sprite.play("RunLeft")
				animated_sprite.flip_h = true
	# Jeśli stoję w miejscu – IDLE
	else:
		play_idle_animation()

func play_idle_animation() -> void:
	match last_key:
		"move_up":
			animated_sprite.play("IdleBack")
			animated_sprite.flip_h = false
		"move_down":
			animated_sprite.play("IdleFront")
			animated_sprite.flip_h = false
		"move_left":
			animated_sprite.play("IdleLeft")
			animated_sprite.flip_h = false
		"move_right":
			animated_sprite.play("IdleLeft")
			animated_sprite.flip_h = true

# --- FUNKCJE DLA NPC / DIALOGÓW ---

func set_movement_locked(locked: bool) -> void:
	movement_locked = locked
	if locked:
		velocity = Vector2.ZERO

func acquire_movement_lock(owner_name: StringName) -> void:
	_movement_lock_owners[owner_name] = true
	velocity = Vector2.ZERO

func release_movement_lock(owner_name: StringName) -> void:
	_movement_lock_owners.erase(owner_name)
