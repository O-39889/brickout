class_name Brick extends StaticBody2D


@export var initial_durability : int = 1;
@export var points : int = 0;


@onready var durability : int = initial_durability;
# not sure whether this is used anywhere though
@onready var collision_shape := find_child("CollisionShape2D");

@onready var width : float = collision_shape.shape.size.x;
@onready var height : float = collision_shape.shape.size.y;


# Called when the node enters the scene tree for the first time.
func _ready():
	#find_child("Sprite2D").texture.size.x = width;
	#find_child("Sprite2D").texture.size.y = height;
	pass


func hit(ball: Ball, damage: int):
	EventBus.brick_hit.emit(self, ball);


func destroy(ball: Ball):
	EventBus.brick_destroyed.emit(self, ball);


func get_points() -> int:
	return points;
