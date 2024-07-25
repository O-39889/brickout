extends Node2D;


# Key: string, two concatenated instance ids,
# sorted by ascending, underscore in-between
# Value: number of ticks after that collision (when it reaches 0, remove
# from the dictionary)
var collisions : Dictionary = {};
var level;


func _ready():
	EventBus.ball_collision.connect(handle_collision);


func handle_collision(b1: Ball, b2: Ball):
	var id : String;
	var id_1 := b1.get_instance_id();
	var id_2 := b2.get_instance_id();
	if id_1 < id_2:
		id = str(id_1) + '_' + str(id_2);
	else:
		id = str(id_2) + '_' + str(id_1);
	if collisions.has(id):
		return;
	
	collisions[id] = 2;
	var v1 = b1.velocity;
	var v2 = b2.velocity;
	var x1 = b1.global_position;
	var x2 = b2.global_position;
	var v1_new = v1 - (v1 - v2).dot(x1 - x2) / (x1 - x2).length_squared() * (x1 - x2);
	var v2_new = v2 - (v2 - v1).dot(x2 - x1) / (x2 - x1).length_squared() * (x2 - x1);
	b1.velocity = v1_new;
	b1.direction = v1_new.normalized();
	b2.velocity = v2_new;
	b2.direction = v2_new.normalized();



func _physics_process(delta):
	for k in collisions:
		collisions[k] -= 1;
		if collisions[k] == 0:
			collisions.erase(k);
