extends CharacterBody2D

@export var walk_speed := 200
@export var run_speed := 350
@export var health := 8
@export var max_health := 8

var direction := "right"
var is_dead := false
var is_hit_anim := false
var is_attacking := false
var attack_hit_done := false
var attack_debug_printed := false

signal health_changed(current_health: int, max_health: int)
signal player_dead

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea

# Attack offsets to position Area2D in front of player
var attack_offsets := {
	"down": Vector2(0, 20),
	"left": Vector2(-20, 0),
	"up": Vector2(0, -20),
	"right": Vector2(20, 0)
}

var attack_cooldown := 0.2
var attack_timer := 0.0

func _ready():
	emit_signal("health_changed", health, max_health)
	anim.animation_finished.connect(_on_anim_finished)

func _physics_process(delta: float):
	if is_dead:
		return

	if attack_timer > 0:
		attack_timer -= delta

	handle_movement()
	handle_actions()

	# Position attack Area2D
	if attack_area:
		attack_area.position = attack_offsets.get(direction, Vector2.ZERO)

	# Attack logic
	if is_attacking:
		if not attack_debug_printed:
			print("Player attacking, bodies in range:", attack_area.get_overlapping_bodies().size())
			attack_debug_printed = true

		if attack_timer <= 0 and not attack_hit_done:
			for body in attack_area.get_overlapping_bodies():
				# Ensure we hit guards (layer 2) only
				if body.is_in_group("guards"):
					print("💥 Player hits guard:", body.name)
					body.take_damage(1)
					attack_hit_done = true
					attack_timer = attack_cooldown
	else:
		attack_hit_done = false
		attack_debug_printed = false

	move_and_slide()

func handle_movement():
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

func handle_actions():
	if is_dead or is_hit_anim or is_attacking:
		return
	if Input.is_action_just_pressed("attack"):
		is_attacking = true
		anim.play("attack_" + direction)
		attack_timer = 0

func take_damage(amount: int):
	if is_dead:
		return
	health -= amount
	emit_signal("health_changed", health, max_health)

	if health > 0:
		is_hit_anim = true
		anim.play("hit_" + direction)
	else:
		die()

func die():
	if is_dead:
		return
	is_dead = true
	anim.play("death_" + direction)
	emit_signal("player_dead")

func _on_anim_finished():
	if is_hit_anim:
		is_hit_anim = false
	if is_attacking:
		is_attacking = false
		attack_hit_done = false
		attack_debug_printed = false

	if not is_dead:
		anim.play("idle_" + direction)
