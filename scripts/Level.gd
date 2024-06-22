extends Node2D


var mouse_captured := false;

@onready var wall_right = find_child("WallRight");
@onready var paddle = find_child("Paddle");
@onready var ball_packed = preload("res://scenes/Ball.tscn");
@onready var powerup_packed = preload("res://scenes/Powerup.tscn");


# Called when the node enters the scene tree for the first time.
func _ready():
	paddle.spawn_ball = true;
	paddle.position.x = (get_viewport_rect().size.x - paddle.width) / 2;
	paddle.position.y = get_viewport_rect().size.y - Globals.PADDLE_OFFSET;
	set_mouse_capture(true);
	for b in get_tree().get_nodes_in_group("balls"):
		b.lost.connect(_on_ball_lost);
	for b in get_tree().get_nodes_in_group("bricks"):
		b.hitted.connect(_on_brick_hit);


func set_mouse_capture(captured: bool):
	if captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED;
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE;
	mouse_captured = captured;


func _on_ball_lost(ball: Ball):
	print(ball);
	ball.queue_free();
	# because the ball is queue'd free on the next frame so for now
	# we still have it in the tree so will have to wait fur the next frame
	await get_tree().physics_frame;
	if get_tree().get_nodes_in_group("balls").size() == 0:
		get_tree().reload_current_scene();


func _on_brick_hit(brick: Brick, ball: Ball):
	if brick is RegularBrick:
		if brick.durability == 1:
			print("Goodbye, cruel world!");
			if randf() < 0.33333 or true:
				var powerup := powerup_packed.instantiate();
				powerup.position = brick.position;
				add_child(powerup);
		else:
			print("Ow!");
	if brick is UnbreakableBrick:
		print("Fat chance!");


func _input(event):
	if event.is_action_pressed("debug_exit"):
		get_tree().quit();
	if event.is_action_pressed("debug_restart"):
		set_mouse_capture(not mouse_captured);
	if event.is_action_pressed("debug_do"):
		pass
