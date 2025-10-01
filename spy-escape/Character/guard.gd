extends CharacterBody2D

@export var speed := 80
@export var health := 3

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var player = get_node("/root/Main/Player")

func _physics_process(delta):
	if global_position.distance_to(player.global_position) < 200:
		var dir = (player.globale_position - global_position).normalized()
		velocity = dir * speed
		move_and_slide()
		anim.play("Walk down") #set correct direction depending on guard
	else:
		velocity = Vector2.ZERO
		anim.play("Idle down")
		
func take_damage(amount: int):
	health -= amount
	if health <= 0:
		anim.play("Death down")
		queue_free()
	
