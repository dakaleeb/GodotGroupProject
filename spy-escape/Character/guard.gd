extends CharacterBody2D

@export var walk_speed := 150
@export var run_speed := 250
@export var health := 3
@export var detection_range := 30.0
@export var lose_sight_range := 100.0
@export var patrol_wait_time := 1.0
@export var patrol_points_paths: Array[NodePath] = []

var direction := "down"
var is_dead := false
var target: Node2D = null
var chasing := false
var returning := false

var patrol_points: Array[Vector2] = []
var current_patrol_index := 0
var waiting := false
var wait_timer := 0.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var detector: Area2D = $Detector
@onready var sight_ray: RayCast2D = $SightRay

var attack_distance := 40.0
var attack_cooldown := 0.5
var attack_timer := 0.0

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

	nav_agent.avoidance_enabled = true
	nav_agent.radius = 12.0
	nav_agent.max_speed = run_speed
	nav_agent.path_max_distance = 4.0

	sight_ray.enabled = true
	sight_ray.collide_with_bodies = true
	sight_ray.collide_with_areas = false

func _find_node_recursive(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var result = _find_node_recursive(child, target_name)
		if result:
			return result
	return null

func _physics_process(delta: float):
	if is_dead:
		return

	attack_timer = max(attack_timer - delta, 0)
	velocity = Vector2.ZERO

	if target and is_instance_valid(target):
		var distance = global_position.distance_to(target.global_position)

		if chasing:
			if distance > lose_sight_range or not _can_see_player():
				chasing = false
				returning = true
				current_patrol_index = _get_closest_patrol_point()
				nav_agent.target_position = patrol_points[current_patrol_index]
			else:
				chase_target()
		elif distance < detection_range and _can_see_player():
			chasing = true
			returning = false
			chase_target()

	if returning:
		handle_return(delta)
	else:
		handle_patrol(delta)

	if target and is_instance_valid(target):
		var dist = global_position.distance_to(target.global_position)
		if dist <= attack_distance:
			if attack_timer <= 0:
				if "take_damage" in target:
					target.take_damage(1)
				attack_timer = attack_cooldown
			anim.play("attack_" + direction)

	move_and_slide()

func chase_target() -> void:
	if nav_agent == null or target == null:
		return

	nav_agent.target_position = target.global_position

	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		return

	var next_pos = nav_agent.get_next_path_position()
	var dir_vector = (next_pos - global_position).normalized()
	velocity = dir_vector * run_speed

	if abs(dir_vector.x) > abs(dir_vector.y):
		direction = "right" if dir_vector.x > 0 else "left"
	else:
		direction = "down" if dir_vector.y > 0 else "up"

	update_detector_direction()

	if global_position.distance_to(target.global_position) < attack_distance:
		anim.play("attack_" + direction)
		velocity = Vector2.ZERO
	else:
		anim.play("run_" + direction)

func handle_patrol(delta: float) -> void:
	if patrol_points.size() < 2:
		anim.play("idle_" + direction)
		return

	if waiting:
		wait_timer -= delta
		if wait_timer <= 0:
			waiting = false
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

	update_detector_direction()
	anim.play("walk_" + direction)

	if global_position.distance_to(target_point) < 10:
		waiting = true
		wait_timer = patrol_wait_time
		current_patrol_index += 1
		if current_patrol_index >= patrol_points.size():
			current_patrol_index = 0

func handle_return(_delta: float) -> void:
	if patrol_points.size() == 0:
		returning = false
		return

	if nav_agent.is_navigation_finished():
		returning = false
		return

	var next_position = nav_agent.get_next_path_position()
	var dir_vector = (next_position - global_position).normalized()
	velocity = dir_vector * walk_speed

	if abs(dir_vector.x) > abs(dir_vector.y):
		direction = "right" if dir_vector.x > 0 else "left"
	else:
		direction = "down" if dir_vector.y > 0 else "up"

	update_detector_direction()
	anim.play("walk_" + direction)

func _can_see_player() -> bool:
	if target == null or not is_instance_valid(target):
		return false

	var local_target = to_local(target.global_position)
	sight_ray.target_position = local_target
	sight_ray.force_raycast_update()

	if sight_ray.is_colliding():
		var collider = sight_ray.get_collider()
		return collider.name == "Player"
	return true

func _get_closest_patrol_point() -> int:
	var closest_index := 0
	var closest_distance := INF
	for i in patrol_points.size():
		var dist = global_position.distance_to(patrol_points[i])
		if dist < closest_distance:
			closest_distance = dist
			closest_index = i
	return closest_index

func update_detector_direction():
	if detector == null:
		return
	match direction:
		"up": detector.rotation_degrees = 90
		"down": detector.rotation_degrees = -90
		"left": detector.rotation_degrees = 0
		"right": detector.rotation_degrees = 180

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
			queue_free())

func _on_Detector_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	if body.name == "Player":
		target = body
		chasing = true
		returning = false
		chase_target()
		move_and_slide()
