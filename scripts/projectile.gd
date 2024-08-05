class_name Projectile extends CharacterBody2D;


## Determines the amount of momentum that will be given to a ball
## when colliding with it.
@export_range(0.01, 10) var mass : float = 1.0;
