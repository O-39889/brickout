class_name ProjectileAttributes extends Resource;


## The amount of projectiles in a single round (given by a single power-up).
@export var amount : int = 1;
## The maximum speed a projectile can reach, in pixels per second.
@export var speed : float = 100.0;
## The projectile's acceleration, in pixels per second per second.
## Leave this at 0 or a negative number for the projectile to move
## instantenously with max speed without accelerating.
@export var acceleration : float = 0.0;
## The "mass" of the projectile. This isn't considered in the velocity
## calculations or anywhere else, only when determining the impulse given
## to a ball when colliding with it.
@export var mass : float = 1.0;

func _init(init_amount: int = 1, init_speed : float = 100.0,
	init_acceleration : float = 0.0, init_mass : float = 1.0):
	if not (amount >= 1):
		amount = 1;
	if not (is_finite(speed) and speed > 0.0):
		speed = 100.0;
	if not (is_finite(acceleration) and acceleration > 0.0):
		acceleration = 0.0;
	if not (is_finite(mass) and mass > 0.0):
		mass = 1.0;
