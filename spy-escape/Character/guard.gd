extends CharacterBody2D

@export var walk_speed := 150
@export var run_speed := 250
@export var health := 3
@export var detection_range := 200.0
@export var lose_sight_range := 300.0
@export var patrol_wait_time := 2.0  # seconds to wait at each patrol point

var direction := "down"
var is_dead := false
var target: Node2D = null

var patrol_points: Array[Vector2] = []
var current_patrol_index := 0
var patrol_forward := true  # direction along patrol points
var waiting := false
var wait_timer := 0.0
var chasing := false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Auto-assign player if not set
	if target == null:
		var scene_root = get_tree().get_current_scene() as Node
		if scene_root:
			target = scene_root.find_node("Player", true, false)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	velocity = Vector2.ZERO

	if target and is_instance_valid(target):
		var distance = global_position.distance_to(target.global_position)

		if chasing:
			if distance > lose_sight_range:
				chasing = false
			else:
				chase_target()
				move_and_slide()
				return
		else:
			if distance < detection_range:
				chasing = true
				chase_target()
				move_and_slide()
				return

	handle_patrol(delta)
	move_and_slide()

func handle_patrol(delta: float) -> void:
	if patrol_points.size() < 2:
		velocity = Vector2.ZERO
		anim.play("idle_" + direction)
		return

	if waiting:
		wait_timer -= delta
		if wait_timer <= 0:
			waiting = false
			# Reverse direction at ends
			if patrol_forward and current_patrol_index >= patrol_points.size() - 1:
				patrol_forward = false
			elif not patrol_forward and current_patrol_index <= 0:
				patrol_forward = true
		else:
			velocity = Vector2.ZERO
			anim.play("idle_" + direction)
			return

	var target_point = patrol_points[current_patrol_index]
	var dir_vector = (target_point - global_position).normalized()
	velocity = dir_vector * walk_speed

	# Set facing direction
	if abs(dir_vector.x) > abs(dir_vector.y):
		direction = "right" if dir_vector.x > 0 else "left"
	else:
		direction = "down" if dir_vector.y > 0 else "up"

	anim.play("walk_" + direction)

	# Check if reached patrol point
	if global_position.distance_to(target_point) < 10:
		waiting = true
		wait_timer = patrol_wait_time

		if patrol_forward:
			current_patrol_index += 1
		else:
			current_patrol_index -= 1

func chase_target() -> void:
	var dir_vector = (target.global_position - global_position).normalized()
	velocity = dir_vector * run_speed

	# Set facing direction
	if abs(dir_vector.x) > abs(dir_vector.y):
		direction = "right" if dir_vector.x > 0 else "left"
	else:
		direction = "down" if dir_vector.y > 0 else "up"

	anim.play("run_" + direction)

	# Attack animation when close
	if global_position.distance_to(target.global_position) < 40:
		anim.play("attack_" + direction)
		velocity = Vector2.ZERO  # stop while attacking

func take_damage(amount: int) -> void:
	if is_dead:
		return

	health -= amount
	if health > 0:
		anim.play("hit_" + direction)
	else:
		die()

func die() -> void:
	is_dead = true
	anim.play("death_" + direction)
	queue_free()
