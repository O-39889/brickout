class_name MainLevel extends Level;


const BARRIER_PACKED : PackedScene = preload("res://scenes/Barrier.tscn");


@export var level_name : String = 'New Level';
@export var level_author : String = 'Someone';


var barrier : Barrier;


func _ready():
	EventBus.ball_lost.connect(handle_ball_lost);
	EventBus.barrier_hit.connect(_on_barrier_hit);
	# actually no, we'll need another signal on bullet collision just so that
	# we can handle the cases where it just bonks into the top wall
	EventBus.projectile_collided.connect(_on_projectile_collided);
	EventBus.brick_destroyed.connect(_on_brick_destroyed);
	var author_name_string : String = '[0]';
	if not level_author.is_empty():
		author_name_string += ' ' + level_author + ' —';
	author_name_string += ' ' + 'New Level' if level_name.is_empty() else level_name;
	$GUI/LevelAuthorName.text = author_name_string;
	super();


func add_barrier():
	if barrier:
		return;
	barrier = BARRIER_PACKED.instantiate();
	barrier.position.y = get_viewport_rect().size.y - (Globals.PADDLE_OFFSET / 2.0);
	add_child(barrier);


func _on_barrier_hit():
	barrier = null;


func life_lost_check():
	# So, basically:
	# Even if there is no balls in play,
	# we still see if the player maybe has a gun
	# then they can maybe shoot and destroy the last bricks
	return get_tree().get_nodes_in_group(&'balls').is_empty()\
	and not paddle.has_gun\
	and get_tree().get_nodes_in_group(&'projectiles').is_empty()\
	and not get_tree().get_nodes_in_group(&'destructible_bricks').is_empty();


# don't lose a life yet if the player still has gun and there are currently
# projectiles on screen
func handle_ball_lost(ball: Ball):
	murder_ball(ball);
	# because the ball is queue'd free on the next frame so for now
	# we still have it in the tree so will have to wait fur the next frame
	handle_life_lost();


func handle_life_lost():
	await get_tree().physics_frame;
	if life_lost_check():
		reset_level();


func reset_level():
	Ball.reset_target_speed();
	paddle.queue_free();
	paddle = null;
	EventBus.life_lost.emit();
	await get_tree().create_timer(1.0).timeout;
	create_paddle();


# TODO: take advantage of the new bool return types of add ball functions
func clone_balls(b: Ball, n: int):
	var angle_range : float = PI if b.stuck else TAU;
	var cloned_balls : Array[Ball] = [];
	for i in range(n):
		var new_ball : Ball = BALL_PACKED.instantiate();
		var angle_offset : float = (i + 1) * angle_range / (n + 1);
		var launch_vector : Vector2;
		if b.stuck:
			new_ball.position = b.global_position;
			new_ball.position.y -= 1; # "just in case"
			launch_vector = Vector2.LEFT.rotated(angle_offset);
		else:
			new_ball.position = b.position;
			launch_vector = b.velocity.normalized().rotated(angle_offset);
		add_ball(new_ball);
		cloned_balls.append(new_ball);
		new_ball.launch(launch_vector);
	b.handle_cloned(cloned_balls);


func murder_ball(b: Ball):	
	if paddle:
		paddle.balls.erase(b);
	b.queue_free();


func _on_projectile_collided(_projectile: Projectile, with: CollisionObject2D):
	handle_life_lost();


func _on_brick_destroyed(brick: Brick, by: Node2D):
	if brick.is_in_group(&'destructible_bricks') and by is Projectile:
		handle_life_lost();


func _input(event):
	if OS.is_debug_build():
		if event.is_action_pressed("debug_exit"):
			get_tree().quit();
		if event.is_action_pressed("debug_restart"):
			get_tree().reload_current_scene();
		if event.is_action_pressed("debug_1"):
			powerup_component._request_powerup('gun',
				paddle.position - Vector2(0, 69));
		if event.is_action_pressed("debug_2"):
			powerup_component._request_powerup('paddle_enlarge',
				paddle.position - Vector2(0, 69));
		if event.is_action_pressed('debug_3'):
			powerup_component._request_powerup('paddle_shrink',
				paddle.position - Vector2(0, 69));
		if event.is_action_pressed('debug_4'):
			Engine.time_scale = 1.0 if not is_equal_approx(Engine.time_scale, 1.0) else 0.02;
		if event.is_action_pressed('debug_5'):
			var ball := BALL_PACKED.instantiate() as Ball;
			ball.position = Vector2(1590, 440);
			ball_component.add_child(ball);
			ball.launch(Vector2(-0.1, -1));
