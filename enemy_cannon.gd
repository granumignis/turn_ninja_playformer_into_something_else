extends Node2D

const SPARK_PARTICLE_BURST_EFFECT = preload("res://sparks_particle_burst_effect.tscn")
const IMPACT_PARTICLE_BURST_EFFECT = preload("res://impact_particle_burst_effect.tscn")
const BULLET_SCENE = preload("res://bullet.tscn")

@onready var muzzle: Marker2D = $Muzzle
@onready var sprite_2d: Sprite2D = $Sprite2D
@export var stats: Stats :
	set(value):
		stats = value
		if stats is not Stats: return
		stats = stats.duplicate()


@onready var hurtbox = $Hurtbox
@onready var effects_animation_player: AnimationPlayer = $Effects_AnimationPlayer

@onready var shaker = Shaker.new(sprite_2d)
@onready var timer: Timer = $Timer



# Called when the node enters the scene tree for the first time.
func _ready():
	var effects_material = sprite_2d.material

	hurtbox.hurt.connect(func(other_hitbox: Hitbox):
		var spark_particle = SPARK_PARTICLE_BURST_EFFECT.instantiate()
		get_tree().current_scene.add_child(spark_particle)
		spark_particle.global_position = sprite_2d.global_position
		
		var impact_particle = IMPACT_PARTICLE_BURST_EFFECT.instantiate()
		get_tree().current_scene.add_child(impact_particle)
		impact_particle.global_position = sprite_2d.global_position.move_toward(other_hitbox.global_position, -8)
		impact_particle.rotation = sprite_2d.global_position.direction_to(other_hitbox.global_position).angle()
		
		print(str(self.name) + " got hit by " + str(other_hitbox.name))
		stats.health -= other_hitbox.damage
		effects_animation_player.play("hitflash")
		shaker.shake(2.0, 0.2)
	)
	

	stats.no_health.connect(func():
		queue_free()
	)
	timer.timeout.connect(fire_bullet)
	
	randomize()
	await get_tree().create_timer(randf_range(0,2.0)).timeout
	timer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func fire_bullet() -> void:
	var bullet = BULLET_SCENE.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = muzzle.global_position
	bullet.direction = Vector2.LEFT 
