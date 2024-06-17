extends CharacterBody2D


enum BallSpeed {
	BALL_SPEED_SLOW,
	BALL_SPEED_NORMAL,
	BALL_SPEED_FAST,
}

# random data fur now
const BALL_SPEEDS = [
	380,
	500,
	700,	
];
const BALL_RADIUS = 20;


var speed := BALL_SPEEDS[BallSpeed.BALL_SPEED_NORMAL];
var direction : Vector2 = Vector2(1, -1).normalized();


@onready var collision_shape : CollisionShape2D = find_child("CollisionShape2D");


func _ready():
	collision_shape.shape.radius = BALL_RADIUS;
	launch();


func launch():
	velocity = direction * speed;


func handle_collision(collision: KinematicCollision2D):
	velocity = velocity.bounce(collision.get_normal());


func _physics_process(delta):
	var collision: KinematicCollision2D = move_and_collide(velocity * delta);
	if collision:
		handle_collision(collision);
	else:
		pass;
