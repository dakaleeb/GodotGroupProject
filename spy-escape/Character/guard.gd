extends CharacterBody2D

@export var walk_speed := 150
@export var run_speed := 250
@export var health := 3
@export var detection_range := 30.0
@export var lose_sight_range := 150.0
@export var patrol_wait_time := 2.0
@export var patrol_points_paths: Array[NodePath] = []

var direction := "down"
var is_dead := false
var target: Node2D = null
var chasing := false
var returning := false

var patrol_points: Array[Vector2] = []
var current_patrol_index := 0
var patrol_forward := true
var waiting := false
var wait_timer := 0.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var detector: Area2D = $Detector

var attack_offsets := {
	"down": Vector2(0, 20),
	"left": Vector2(-20, 0),
	"up": Vector2(0, -20),
	"right": Vector2(20, 0)
}

var attack_distance := 40.0
var attack_cooldown := 0.5
var attack_timer := 0.0
var attack_hit_done := false

func _ready():
	patrol_points.clear()
	for path in patrol_points_paths:
		var node = get_node(path)
		if node:
			patrol_points.append(node.global_position)

	if patrol_points.size() == 0:
		print("⚠️ No patrol points assigned for ", name)
	else:
		nav_agent.target_position = patrol_points[0]

	var scene_root = get_tree().get_current_scene()
	if scene_root:
		target = _find_node_recursive(scene_root, "Player")

func _find_node_recursive(node: Node, name: String) -> Node:
	if node.name == name:
		return node
	for child in node.get_children():
		var result = _find_node_recursive(child, name)
		if result:
			return result
	return null

func _physics_process(delta: float):
	if is_dead:
		return

	if attack_timer > 0:
		attack_timer -= delta
	else:
		attack_hit_done = false  # keep, harmless if unused

	velocity = Vector2.ZERO

	# --- Chasing logic ---
	if target and is_instance_valid(target):
		var distance = global_position.distance_to(target.global_position)
		if chasing:
			if distance > lose_sight_range:
				chasing = false
				returning = true
				nav_agent.target_position = patrol_points[0]
			else:
				chase_target()
				move_and_slide()
				return
		elif distance < detection_range:
			chasing = true
			chase_target()
			move_and_slide()
			return

	# --- Patrol/Return ---
	if returning:
		handle_return(delta)
	else:
		handle_patrol(delta)

	# --- Attack logic ---
	if target and is_instance_valid(target):
		var dist = global_position.distance_to(target.global_position)
		if dist <= attack_distance:
			if attack_timer <= 0:
				print("💥 Guard hits player:", target.name)
				target.take_damage(1)
				attack_timer = attack_cooldown
			anim.play("attack_" + direction)
		else:
			# optionally play other anims here
			pass

	move_and_slide()

# --- Patrol/Return/Chase functions ---
func handle_patrol(delta: float) -> void:
	if patrol_points.size() < 2:
		anim.play("idle_" + direction)
		return

	if waiting:
		wait_timer -= delta
		if wait_timer <= 0:
			waiting = false
			if patrol_forward and current_patrol_index >= patrol_points.size() - 1:
				patrol_forward = false
			elif not patrol_forward and current_patrol_index <= 0:
				patrol_forward = true
		else:
			anim.play("idle_" + direction)
			return

	var target_point = patrol_points[current_patrol_index]
	var dir_vector = (target_point - global_position).normalized()
	velocity = dir_vector * walk_speed

	if abs(dir_vector.x) > abs(dir_vector.y):
		direction = "right" if dir_vector.x > 0 else "left"
	else:
		direction = "down" if dir_vector.y > 0 else "up"

	update_detector_direction()  # 👈 added to rotate cone
	anim.play("walk_" + direction)

	if global_position.distance_to(target_point) < 10:
		waiting = true
		wait_timer = patrol_wait_time
		if patrol_forward:
			current_patrol_index += 1
		else:
			current_patrol_index -= 1
		current_patrol_index = clamp(current_patrol_index, 0, patrol_points.size() - 1)

func handle_return(delta: float) -> void:
	if patrol_points.size() == 0:
		returning = false
		return

	if nav_agent.is_navigation_finished():
		returning = false
		current_patrol_index = 0
		return

	var next_position = nav_agent.get_next_path_position()
	var dir_vector = (next_position - global_position).normalized()
	velocity = dir_vector * walk_speed

	if abs(dir_vector.x) > abs(dir_vector.y):
		direction = "right" if dir_vector.x > 0 else "left"
	else:
		direction = "down" if dir_vector.y > 0 else "up"

	update_detector_direction()  # 👈 added to rotate cone
	anim.play("walk_" + direction)

func chase_target() -> void:
	var dir_vector = (target.global_position - global_position).normalized()
	velocity = dir_vector * run_speed

	if abs(dir_vector.x) > abs(dir_vector.y):
		direction = "right" if dir_vector.x > 0 else "left"
	else:
		direction = "down" if dir_vector.y > 0 else "up"

	update_detector_direction()  # 👈 added to rotate cone

	if global_position.distance_to(target.global_position) < attack_distance:
		anim.play("attack_" + direction)
		velocity = Vector2.ZERO
	else:
		anim.play("run_" + direction)

# --- Rotate Detector Cone ---
func update_detector_direction():
	if detector == null:
		return
	match direction:
		"up":
			detector.rotation_degrees = 90
		"down":
			detector.rotation_degrees = -90
		"left":
			detector.rotation_degrees = 0
		"right":
			detector.rotation_degrees = 180

# --- Damage / Death ---
func take_damage(amount: int):
	if is_dead:
		return
	health -= amount
	if health > 0:
		anim.play("hit_" + direction)
	else:
		die()

func die():
	if is_dead:
		return
	is_dead = true
	anim.play("death_" + direction)
	anim.animation_finished.connect(func(anim_name):
		if anim_name.begins_with("death"):
			queue_free()
)

func _on_Detector_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	if body.name == "Player":
		print("Player has entered Detector Body!")
		target = body
		chasing = true
		returning = false
		attack_hit_done = false
		chase_target()
		move_and_slide()
