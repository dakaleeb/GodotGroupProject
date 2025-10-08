extends CharacterBody2D

@export var walk_speed := 200
@export var run_speed := 350
@export var health := 6
@export var max_health := 6

var direction := "down"
var is_dead := false
var is_hit_anim := false
var is_attacking := false

signal health_changed(current_health: int, max_health: int)
signal player_dead

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	emit_signal("health_changed", health, max_health)
	anim.animation_finished.connect(_on_anim_finished)

func _physics_process(_delta: float) -> void:
	if is_dead:
		return

	handle_movement()
	handle_actions()
	move_and_slide()

func _input(event):
	# Temporary debug keys for testing hit and death
	if event.is_action_pressed("debug_hit"):
		take_damage(1)
	elif event.is_action_pressed("debug_die"):
		die()

func handle_movement() -> void:
	if is_dead or is_hit_anim or is_attacking:
		return

	velocity = Vector2.ZERO
	var moving = false

	if Input.is_action_pressed("right"):
		velocity.x += 1
		direction = "right"
		moving = true
	elif Input.is_action_pressed("left"):
		velocity.x -= 1
		direction = "left"
		moving = true

	if Input.is_action_pressed("down"):
		velocity.y += 1
		direction = "down"
		moving = true
	elif Input.is_action_pressed("up"):
		velocity.y -= 1
		direction = "up"
		moving = true

	if moving:
		var is_running = Input.is_action_pressed("run")
		velocity = velocity.normalized() * (run_speed if is_running else walk_speed)
		var anim_name = ("run_" if is_running else "walk_") + direction
		if anim.animation != anim_name:
			anim.play(anim_name)
	else:
		var idle_name = "idle_" + direction
		if anim.animation != idle_name:
			anim.play(idle_name)

func handle_actions() -> void:
	if is_dead or is_hit_anim or is_attacking:
		return

	if Input.is_action_just_pressed("attack"):
		is_attacking = true
		anim.play("attack_" + direction)
	elif Input.is_action_just_pressed("interact"):
		print("Interact pressed")

func take_damage(amount: int) -> void:
	if is_dead:
		return
	health -= amount
	emit_signal("health_changed", health, max_health)

	if health > 0:
		is_hit_anim = true
		anim.play("hit_" + direction)
	else:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	anim.play("death_" + direction)
	emit_signal("player_dead")

func _on_anim_finished() -> void:
	# Reset flags when animations finish
	if is_hit_anim:
		is_hit_anim = false
	if is_attacking:
		is_attacking = false

	# Return to idle if not dead
	if not is_dead:
		anim.play("idle_" + direction)
