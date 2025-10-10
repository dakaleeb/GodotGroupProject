extends CharacterBody2D

@export var walk_speed := 150
@export var run_speed := 250
@export var health := 3
@export var detection_range := 100.0
@export var lose_sight_range := 200.0
@export var patrol_wait_time := 2.0  # seconds to wait at each patrol point

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
@onready var attack_area := $AttackArea

# Hitbox direction offsets
var attack_offsets := {
	"down": Vector2(0, 30),
	"left": Vector2(-30, 0),
	"up": Vector2(0, -30),
	"right": Vector2(30, 0)
}


func _ready():
	patrol_points.clear()

	# Get patrol points from group
	for node in get_tree().get_nodes_in_group("patrol_points"):
		patrol_points.append(node.global_position)

	if patrol_points.size() == 0:
		print("⚠️ No patrol points found for ", name)
	else:
		print("✅ Patrol points found: ", patrol_points)
		nav_agent.target_position = patrol_points[0]

	# Find the player automatically
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


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	velocity = Vector2.ZERO

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

	if returning:
		handle_return(delta)
	else:
		handle_patrol(delta)

	move_and_slide()


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

	# Set facing direction
	if abs(dir_vector.x) > abs(dir_vector.y):
		direction = "right" if dir_vector.x > 0 else "left"
	else:
		direction = "down" if dir_vector.y > 0 else "up"

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

	anim.play("walk_" + direction)


func chase_target() -> void:
	var dir_vector = (target.global_position - global_position).normalized()
	velocity = dir_vector * run_speed

	if abs(dir_vector.x) > abs(dir_vector.y):
		direction = "right" if dir_vector.x > 0 else "left"
	else:
		direction = "down" if dir_vector.y > 0 else "up"

	var attack_distance = 40.0
	if global_position.distance_to(target.global_position) < attack_distance:
		anim.play("attack_" + direction)
		velocity = Vector2.ZERO
		update_attack_area_position()
	else:
		anim.play("run_" + direction)


func update_attack_area_position():
	if attack_area and attack_offsets.has(direction):
		attack_area.position = attack_offsets[direction]


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
