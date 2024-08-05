## Still breakable btw! By acid and explosions.
class_name UnbreakableBrick extends Brick;


func hit(by: Node2D, damage: int):
	if damage > 1:
		EventBus.brick_destroyed.emit(self, by);
		queue_free();
	else:
		EventBus.brick_hit.emit(self, by);
