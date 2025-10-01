extends CharacterBody2D

@export var walk_speed := 200
@export var run_speed := 350
@export var health := 6 #hearts
@export var ammo := 6 #bullets in mag
@export var max_ammo := 6

var last_direction := "down" #default direction
var box_target = null

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hud = get_node("/root/Main/HUD") #update with file location

func _physics_process(delta: float) -> void:
	handle_movement(delta)
	handle_actions()
	move_and_slide()
	
#Movement
func handle_movement(delta: float) -> void:
	velocity = Vector2.ZERO
	
	if Input.is_action_pressed("left"):
		velocity.x = -walk_speed
		last_direction = "left"
	elif Input.is_action_pressed("right"):
		velocity.x = walk_speed
		last_direction = "right"
	elif Input.is_action_pressed("up"):
		velocity.y = -walk_speed
		last_direction = "up"
	elif Input.is_action_pressed("down"):
		velocity.y = walk_speed
		last_direction = "down"
		
	#Running (Shift to go fast)
	if Input.is_action_pressed("run"):
		velocity = velocity.normalized() * run_speed
		
	#Animations
	if velocity == Vector2.ZERO:
		anim.play("idle_" + last_direction)
	else:
		if velocity.length() > walk_speed:
			anim.play("run_" + last_direction)
		else:
			anim.play("walk_" + last_direction)
	
#Actions (attack, shoot, push, pull, climb)
func handle_actions():
	if Input.is_action_just_pressed("attack"):
		anim.play("attack_" + last_direction)
		#ToDo: melee damage box/guard in front
		
	if Input.is_action_just_pressed("shoot"):
		shoot()
	
	if box_target:
		if Input.is_action_pressed("push"):
			anim.play("push_" + last_direction)
			box_target.push(velocity)
		elif Input.is_action_pressed("pull"):
			anim.play("pull_" + last_direction)
			box_target.pull(velocity)
			
	if box_target and Input.is_action_just_pressed("climb"):
		anim.play("climb_" + last_direction)
		global_position.y -= 32

#Shooting (hitscan)
func shoot():
	if ammo <= 0:
		return
	ammo -= 1
	hud.update_ammo(ammo)
	
	anim.play("shoot_" + last_direction)
	
	var ray = RayCast2D.new()
	match last_direction:
		"up": ray.target_position = Vector2(0, -500)
		"down": ray.target_position = Vector2(0, 500)
		"left": ray.target_position = Vector2(-500, 0)
		"right": ray.target_position = Vector2(500, 0)
	
	add_child(ray)
	ray.force_raycast_update()
	
	if ray.is_colliding():
		var target = ray.get_collider()
		if target.is_in_group("guards"):
			target.take_damage(1)
		
	ray.queue_free()
	
#Health
func take_damage(amount: int):
	health -= amount
	hud.update_health(health)
	anim.play("hit_" + last_direction)
	
	if health <= 0:
		die()
		
func die():
	anim.play("death_" + last_direction)
	queue_free()
	
#Box Detection
func _on_Area2D_body_entered(body):
	if body.is_in_group("boxes"):
		box_target = body
		
func _on_Area2D_body_exited(body):
	if body == box_target:
		box_target = null
