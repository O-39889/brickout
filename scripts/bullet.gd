class_name Bullet extends Projectile;


func handle_collision(collision: KinematicCollision2D):
	var collider := collision.get_collider();
	if collider.has_method('hit'):
		if collider is RegularBrick and collider.is_reinforced:
			if collider.is_valid_hit(collision.get_normal()):
				collider.hit(self, 1);
		else:
			collider.hit(self, 1);
	elif collider is Ball:
		collider.apply_impulse(Vector2.UP * absf(velocity.y) * mass);
	super(collision);
