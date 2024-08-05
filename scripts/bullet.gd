class_name Bullet extends Projectile;


# idk lol
@export_range(0.1, 10000) var speed : float = 1000;


func _physics_process(delta):
	var collision : KinematicCollision2D = move_and_collide(
		Vector2(0, -speed * delta)
	);
	if collision:
		var collider := collision.get_collider() as CollisionObject2D;
		if collider is Brick:
			if collider is RegularBrick:
				collider.hit(self, 1);
		elif collider is Ball:
			collider.apply_impulse(Vector2.UP * speed * mass / 3);
		elif collider.is_in_group(&'walls'):
			pass
		queue_free();
