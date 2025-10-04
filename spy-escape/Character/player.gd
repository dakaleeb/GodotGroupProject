extends CharacterBody2D

@export var walk_speed := 200
@export var run_speed := 350
@export var health := 6
@export var max_health := 6
@export var ammo := 6 #bullets in mag
@export var max_ammo := 6

var direction := "down" #default direction
var is_dead := false

signal health_changed(current_health: int, max_health: int)
signal ammo_changed(current_ammo: int, max_ammo: int)
signal player_dead

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	emit_signal("health_changed", health, max_health)
	emit_signal("ammo_changed", ammo, max_ammo)
	
func _physics_process(_delta: float) -> void:
	if is_dead:
		return
	
	handle_movement()
	handle_actions()
	move_and_slide()

#Movement
func handle_movement() -> void:
	velocity = Vector2.ZERO
	
	if Input.is_action_pressed("ui_right"):
		velocity.x += 1
		direction = "right"
	elif Input.is_action_pressed("ui_left"):
		velocity.x -= 1
		direction = "left"
		
	if Input.is_action_pressed("ui_down"):
		velocity.y += 1
		direction = "down"
	elif Input.is_action_pressed("ui_up"):
		velocity.y -= 1
		direction = "up"
		
	if velocity != Vector2.ZERO:
		velocity = velocity.normalized() * (run_speed if Input.is_action_pressed("run") else walk_speed)
		anim.play("walk_" + direction)
	else:
		anim.play("idle_" + direction)

#Actions
func handle_actions() -> void:
	if Input.is_action_just_pressed("attack"):
		anim.play("attack_" + direction)
	elif Input.is_action_just_pressed("shoot"):
		anim.play("shoot_" + direction)
	elif Input.is_action_just_pressed("interact"):
		print("Interact pressed") #placeholder

#Shooting
func take_damage(amount: int) -> void:
	if is_dead:
		return
	health -= amount
	emit_signal("health_changed", health, max_health)
	
	if health > 0:
		anim.play("hit_" + direction)
	else:
		die()
	
func die() -> void:
	is_dead = true
	anim.play("death_" + direction)
	emit_signal("player_dead")
