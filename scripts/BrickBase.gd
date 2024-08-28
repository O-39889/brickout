class_name Brick extends StaticBody2D;


## Points given out when this brick is destroyed. Can be overridden
## by defining the get_points() function.
@export var points : int = 0;


# not sure whether this is used anywhere though
@onready var collision_shape := find_child("CollisionShape2D");

@onready var width : float = collision_shape.shape.size.x;
@onready var height : float = collision_shape.shape.size.y;
@onready var to_tween := [
	{
		'object': $Sprite2D,
		'property': 'scale',
		'final_val': Vector2(1, 1),
		'duration': 0.2
	},
];


func _ready():
	pass
	#if not Engine.is_editor_hint():
		#$Sprite2D.scale = Vect	or2(0, 0);
		#get_tree().create_timer((global_position.x - width / 2
		#+ global_position.y * (width / height) - height / 2) / 2220.2222)\
		#.timeout.connect(func():
			#var tween := create_tween();
			#tween.set_parallel(true);
			#for prop in to_tween:
				#var dur = prop['duration'] if prop.has('duration') else 0.2;
				#tween.tween_property(
					#prop['object'], prop['property'],
					#prop['final_val'], dur
				#);
			#);
	


func hit(by: Node2D, damage: int):
	EventBus.brick_hit.emit(self, by);


func destroy(by: Node2D):
	EventBus.brick_destroyed.emit(self, by);


func get_points() -> int:
	return points;
