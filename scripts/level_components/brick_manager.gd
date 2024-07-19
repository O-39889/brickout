extends Node2D;

@onready var level : Node2D = get_parent();


func _ready():
	EventBus.brick_hit.connect(_on_brick_hit);


func _on_brick_hit(brick: Brick, ball: Ball):
	if brick is RegularBrick:
		if brick.durability == 1:
			# handle stuff like decrementing the brick counter etc idk
			await get_tree().physics_frame;
			if get_tree().get_nodes_in_group(&'destructible_bricks').is_empty():
				print('Win!');
				# something something
