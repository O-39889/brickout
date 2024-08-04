## Okay, this one actually cannot be destroyed by anything.
class_name SuperUnbreakableBrick extends Brick;


func hit(ball: Ball, _damage: int):
	EventBus.brick_hit.emit(self, ball);
