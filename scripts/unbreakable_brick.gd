## Still breakable btw! By acid and explosions.
class_name UnbreakableBrick extends Brick;


func hit(ball: Ball, damage: int):
	if damage > 1:
		EventBus.brick_destroyed.emit(self, ball);
		queue_free();
	else:
		EventBus.brick_hit.emit(self, ball);
