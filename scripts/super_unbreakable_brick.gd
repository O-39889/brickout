## Okay, this one actually cannot be destroyed by anything.
class_name SuperUnbreakableBrick extends Brick;


func hit(by: Node2D, _damage: int):
	EventBus.brick_hit.emit(self, by);
