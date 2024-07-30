# I think this is unused now and the actual title screen now uses the
# title_screen.gd file

extends "res://scripts/Level.gd";


var balls_created : int = 0;
# this is supposed to generate 2 twice as more than either 1 or 3 lmao
var max_balls : int = randi_range(0, 1) + randi_range(1, 2);


# Called when the node enters the scene tree for the first time.
func _ready():
	find_child("MeLbl").text += str(Time.get_date_dict_from_system()['year']);
	await get_tree().create_timer(1.0).timeout;
	spawn_ball();


func spawn_ball():
	var new_ball : Ball = BALL_PACKED.instantiate();
	new_ball.position = get_viewport_rect().size / 2;
	new_ball.direction = Vector2.UP.rotated(randf() * TAU);
	add_ball(new_ball);
	balls_created += 1;
	if balls_created >= max_balls:
		return;
	await get_tree().create_timer(0.25).timeout;
	spawn_ball();
