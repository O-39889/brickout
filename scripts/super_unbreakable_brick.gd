## Okay, this one actually cannot be destroyed by anything.
class_name SuperUnbreakableBrick extends Brick;


func _ready():
	$Sprite2D.region_rect.size.x = width;
	$Sprite2D.region_rect.size.y = height;
	super();


func hit(by: Node2D, _damage: int):
	EventBus.brick_hit.emit(self, by);
