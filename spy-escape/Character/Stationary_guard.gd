extends CharacterBody2D

@export var walk_speed := 150
@export var run_speed := 250
@export var health := 3
@export var detection_range := 200.0

#AI stuff
@export_enum("stationary", "patrol") var guard_type := "stationary"
@export var patrol_points: Array[Vector2] = [] # patrol path points
@export var patrol_wait_time := 1.0 #waitime

var direction := "down"
var target: Node2D = null
var is_dead := false

#patrol state
var current_patrol_index := 0
var waiting := false
var wait_timer := 0.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	if target and global_position.distance_to(target.global_position) < detection_range:
		chase_target()
	else:
		if guard_type == "patrol":
			handle_patrol(delta)
		else:
			anim.play("idle_" + direction)
	
	move_and_slide()
	
#Patrol logic
func handle_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		anim.play("idle_" + direction)
		return
	
	if waiting:
		wait_timer -= delta
		if wait_timer <= 0:
			waiting = false
		return
		
	var target_point = patrol_points[current_patrol_index]
	var dir_vector = (target_point - global_position).normalized()
	velocity = dir_vector * walk_speed
	
	#set facing direction
	if abs(dir_vector.x) > abs(dir_vector.y):
		direction = "right" if dir_vector.x > 0 else "left"
	else:
		direction = "down" if dir_vector.y > 0 else "up"
	
	anim.play("walk_" + direction)
	
	#check if reached point
	if global_position.distance_to(target_point) < 10:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		waiting = true
		wait_timer = patrol_wait_time
		
#chase logic
func chase_target() -> void:
	var dir_vector = (target.global_position).normalized()
	velocity = dir_vector * run_speed
	
	if abs(dir_vector.x) > abs(dir_vector.y):
		direction = "right" if dir_vector.x > 0 else "left"
	else:
		direction = "down" if dir_vector.y > 0 else "up"
		
	anim.play("run_" + direction)
	
	if global_position.distance_to(target.global_position) < 40:
		anim.play ("attack_" + direction)
		
#damage system
func take_damage(amount: int) -> void:
	if is_dead:
		return
		
	health -= amount
	if health > 0 :
		anim.play("hit_" + direction)
	else:
		die()
	
func die() -> void:
	is_dead = true
	anim.play("death_" + direction)
	queue_free()
