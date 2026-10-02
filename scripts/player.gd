extends CharacterBody2D

@export var speed = 200
var movement_locked := false
var _movement_lock_owners: Dictionary = {}

func _ready() -> void:
	add_to_group("player")
	add_to_group("Player")

func _physics_process(_delta):
	if movement_locked or not _movement_lock_owners.is_empty():
		velocity = Vector2.ZERO
		return

	var direction = Vector2.ZERO

	if Input.is_action_pressed("move_right"):
		direction.x += 1
		
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
		
	if Input.is_action_pressed("move_down"):
		direction.y += 1
		
	if Input.is_action_pressed("move_up"):
		direction.y -= 1

	direction = direction.normalized()

	velocity = direction * speed

	move_and_slide()

func set_movement_locked(locked: bool) -> void:
	movement_locked = locked
	if locked:
		velocity = Vector2.ZERO

func acquire_movement_lock(owner: StringName) -> void:
	_movement_lock_owners[owner] = true
	velocity = Vector2.ZERO

func release_movement_lock(owner: StringName) -> void:
	_movement_lock_owners.erase(owner)
