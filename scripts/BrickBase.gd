class_name Brick extends StaticBody2D;


## Points given out when this brick is destroyed. Can be overridden
## by defining the get_points() function.
@export var points : int = 0;


# not sure whether this is used anywhere though
@onready var collision_shape := find_child("CollisionShape2D");

@onready var width : float = collision_shape.shape.size.x;
@onready var height : float = collision_shape.shape.size.y;


func _ready() -> void:
	# this is to counteract the godot grid snap limitation
	# (23 instead of 22.5 lol)
	if not Engine.is_editor_hint():
		self.position.y -= 0.5;


# TODO: maybe functions for adjacent bricks? sounds useful
# (potentially):
# 1) for frail bricks, just so that I don't have to always do
# the type checking
# 2) for reinforced bricks: for example, it could allow us
# to add lone corner pieces for the armor pattern continuity


func hit(by: Node2D, _damage: int) -> void:
	EventBus.brick_hit.emit(self, by);


func destroy(by: Node2D) -> void:
	# wait why is it not calling queue free lol
	# ah whatever the subclasses are gonna do that anyway ig
	EventBus.brick_destroyed.emit(self, by);


func get_points() -> int:
	return points;
