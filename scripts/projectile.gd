class_name Projectile extends CharacterBody2D;


enum GunType {
	Regular,
	Missile
};

const ATTR_DICT := {
	GunType.Regular : preload("res://resources/projectiles/bullet.tres"),
	GunType.Missile : null
};


## Determines the amount of momentum that will be given to a ball
## when colliding with it.
@export var attributes : ProjectileAttributes;

@onready var speed : float = attributes.speed;
@onready var acceleration : float = attributes.acceleration;
@onready var mass : float = attributes.mass;


func _enter_tree():
	assert(attributes != null, 'No projectile attributes were given');
	if attributes == null:
		attributes = ProjectileAttributes.new();


func _ready():
	velocity = Vector2.ZERO if not is_zero_approx(acceleration)\
		else Vector2.UP * speed;
	queue_redraw();


func handle_collision(collision: KinematicCollision2D):
	EventBus.projectile_collided.emit(self, collision.get_collider());
	queue_free();


func _physics_process(delta):
	velocity = (velocity + Vector2.UP * acceleration * delta).limit_length(speed);
	var collision : KinematicCollision2D = move_and_collide(velocity * delta);
	if collision:
		handle_collision(collision);
