class_name Brick extends StaticBody2D;


## Points given out when this brick is destroyed. Can be overridden
## by defining the get_points() function.
@export var points : int = 0;


# not sure whether this is used anywhere though
@onready var collision_shape := find_child("CollisionShape2D");

@onready var width : float = collision_shape.shape.size.x;
@onready var height : float = collision_shape.shape.size.y;


func _ready():
	pass


func hit(ball: Ball, damage: int):
	EventBus.brick_hit.emit(self, ball);


func destroy(ball: Ball):
	EventBus.brick_destroyed.emit(self, ball);


func get_points() -> int:
	return points;
