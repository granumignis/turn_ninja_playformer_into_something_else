extends CharacterBody2D

enum STATE { MOVE, CLIMB, HIT }

@export var stats: Stats

@export var state: = STATE.MOVE

@export var max_speed: = 120
@export var acceleration: = 1000
@export var air_acceleration: = 2000
@export var friction: = 1000
@export var air_friction: = 500
@export var up_gravity: = 500
@export var down_gravity: = 600
@export var jump_amount: = 200
@onready var sprite_anchor: Node2D = $Anchor/SpriteAnchor
@onready var camera_2d: Camera2D = $Camera2D


var coyote_time: = 0

@onready var anchor = $Anchor
@onready var animation_player_lower = $AnimationPlayerLower
@onready var animation_player_upper = $AnimationPlayerUpper
@onready var effect_animation_player: AnimationPlayer = $EffectAnimationPlayer
@onready var ray_cast_upper = $Anchor/RayCastUpper
@onready var ray_cast_lower = $Anchor/RayCastLower
@onready var hurtbox = $Anchor/Hurtbox
@onready var shaker = Shaker.new(sprite_anchor)
@onready var sprite_upper: Sprite2D = $Anchor/SpriteAnchor/SpriteUpper
@onready var sprite_lower: Sprite2D = $Anchor/SpriteAnchor/SpriteLower



func _ready() -> void:	
	
	stats.no_health.connect(func():
		queue_free()
		camera_2d.reparent(get_tree().current_scene)
	)
	
	animation_player_lower.current_animation_changed.connect(_on_lower_animation_changed)
	animation_player_upper.animation_finished.connect(on_upper_animation_finished)

	hurtbox.hurt.connect(func(other_hitbox: Hitbox):
		var x_direction = sign(other_hitbox.global_position.direction_to(global_position).x)
		if x_direction == 0: x_direction = -1
		velocity.x = x_direction *  max_speed
		jump(jump_amount/2)
		state = STATE.HIT
		shaker.shake(3, 0.3)
		animation_player_lower.play("jump")
		effect_animation_player.play("hitflash")
		stats.health -= other_hitbox.damage
	)

func _on_lower_animation_changed(animation_name: String) -> void:
	if animation_player_upper.current_animation == "attack":
		return
	animation_player_upper.play(animation_name)
	
func on_upper_animation_finished(animation_name: String) -> void:
	if animation_name != "attack":
		return
	animation_player_upper.play(animation_player_lower.current_animation)
	animation_player_upper.seek(animation_player_lower.current_animation_position)



func _physics_process(delta:float) -> void:
	match state:
		STATE.MOVE:
			coyote_time -= delta
			
			var x_input = Input.get_axis("move_left","move_right")
			
			apply_gravity(delta)

			if Input.is_action_just_pressed("jump") and (is_on_floor() or coyote_time>0):
				jump()

			if Input.is_action_just_pressed("attack"):
				animation_player_upper.play("attack")
			
			if x_input == 0:
				apply_friction(delta)
				animation_player_lower.play("stand")
			else:
				accelerate_horizontally(x_input, delta)
				anchor.scale.x = sign(x_input)
				animation_player_lower.play("run")

			if not is_on_floor():
				animation_player_lower.play("jump")
						
			var was_on_floor: = is_on_floor()
			move_and_slide()
			if was_on_floor and not is_on_floor() and velocity.y >= 0:
				coyote_time = 0.2
			if should_wall_climb():
				animation_player_upper.play("hang")
				state = STATE.CLIMB

		STATE.CLIMB:
			var wall_normal = get_wall_normal()
			
			var y_axis = Input.get_axis("move_up", "move_down")
			var x_axis = Input.get_axis("move_left", "move_right")
			velocity.y = y_axis * max_speed * 0.8
			
			move_and_slide()
			
			if y_axis != 0:
				animation_player_lower.play("climb")
			else:
				animation_player_lower.play("hang")
				
			var request_detach: bool =(sign(x_axis) == wall_normal.x)
			
			var request_wall_jump: bool = (
				(request_detach or Input.is_action_just_pressed("jump"))
				and not Input.is_action_pressed("move_down")
			)
			
			if request_wall_jump:
				velocity.x = wall_normal.x * max_speed
				anchor.scale.x = sign(velocity.x)
				jump()
				state = STATE.MOVE
			
			if not should_wall_climb() or request_detach:
				if Input.is_action_pressed("move_up"): jump()
				state = STATE.MOVE
		
		STATE.HIT:
			move_and_slide()
			apply_friction(delta)
			apply_gravity(delta)

func jump(amount: = jump_amount) -> void:
	velocity.y = -amount

func accelerate_horizontally(horizontal_direction: float, delta: float) -> void:
	var acceleration_amount: = acceleration
	if not is_on_floor(): acceleration_amount = air_acceleration
	velocity.x = move_toward(velocity.x, max_speed * horizontal_direction, acceleration * delta *abs(horizontal_direction))

func apply_friction(delta) -> void:
	var friction_amount: = friction
	if not is_on_floor(): friction_amount = air_friction
	velocity.x = move_toward(velocity.x, 0.0, friction_amount * delta)

func apply_gravity(delta) -> void:
	if not is_on_floor():
		if velocity.y <= 0:
			velocity.y += up_gravity * delta
		else:
			velocity.y += down_gravity * delta

func should_wall_climb() -> bool:
	return (
		ray_cast_upper.is_colliding()
		and ray_cast_lower.is_colliding()
		and not is_on_floor()
	)
