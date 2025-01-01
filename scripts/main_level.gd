class_name MainLevel extends Level;


const BARRIER_PACKED : PackedScene = preload("res://scenes/Barrier.tscn");


@export var level_name : String = 'New Level';
@export var level_author : String = 'Someone';
@export var allow_level_finish_powerup : bool = true;

var barrier : Barrier;
var points_earned : int = 0;
var time_passed : float = 0.0;

@onready var author_name_lbl : Label = %LevelAuthorName;


func _enter_tree():
	super();


func _ready():
	add_paddle = true;
	EventBus.ball_lost.connect(handle_ball_lost);
	EventBus.barrier_hit.connect(_on_barrier_hit);
	EventBus.score_changed.connect(func(amount: int): 
		if state != Level.LevelCompletionState.Clear:
			points_earned += amount);
	# actually no, we'll need another signal on bullet collision just so that
	# we can handle the cases where it just bonks into the top wall
	EventBus.projectile_collided.connect(_on_projectile_collided);
	EventBus.brick_destroyed.connect(_on_brick_destroyed);
	var author_name_string : String = '[0]';
	if not level_author.is_empty():
		author_name_string += ' ' + level_author + ' —';
	author_name_string += ' ' + 'New Level' if level_name.is_empty() else level_name;
	author_name_lbl.text = author_name_string;
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
	return state == LevelCompletionState.None\
	and get_tree().get_nodes_in_group(&'balls').is_empty()\
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
	if state == Level.LevelCompletionState.Clear:
		return;
	await get_tree().physics_frame;
	if life_lost_check():
		reset_level();


func reset_level():
	if state != LevelCompletionState.None:
		return;
	state = LevelCompletionState.Lost;
	Ball.reset_target_speed();
	paddle.queue_free();
	paddle = null;
	EventBus.life_lost.emit();
	if GameProgression.lives == 0:
		handle_game_over();
	else:
		# TODO: actually handle life lost thing later
		await get_tree().create_timer(1.0).timeout;
		restart();


func restart():
	state = LevelCompletionState.None;
	create_paddle();
	paddle.accept_input = true;


func handle_game_over():
	if state != LevelCompletionState.Lost and state != LevelCompletionState.None:
		return;
	mouse_captured = false;
	state = LevelCompletionState.GameOver;


func handle_powerup_activated(powerup: Powerup):
	if powerup.type == &'sticky_paddle':
		pass


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
		if add_ball(new_ball):
			cloned_balls.append(new_ball);
			new_ball.launch(launch_vector);
		else:
			new_ball.queue_free();
	b.handle_cloned(cloned_balls);


func murder_ball(b: Ball):	
	if paddle:
		paddle.balls.erase(b);
	b.queue_free();


func activate_sticky_powerup():
	if paddle:
		paddle.state = Paddle.PaddleState.Sticky;
		#gui.add_or_extend_timer(paddle.sticky_timer,
			#Powerup.TimedPowerup.StickyPaddle);
		#gui.remove_timer(Powerup.TimedPowerup.PaddleFreeze);
		#gui.remove_timer(Powerup.TimedPowerup.GhostPaddle);


func activate_acid_powerup():
	if ball_component:
		ball_component.enable_acid();
		#gui.add_or_extend_timer(ball_component.acid_timer,
			#Powerup.TimedPowerup.AcidBall);


func activate_freeze_powerup():
	if paddle:
		paddle.state = Paddle.PaddleState.Frozen;
		#gui.add_or_extend_timer(paddle.frozen_timer,
			#Powerup.TimedPowerup.PaddleFreeze);
		#gui.remove_timer(Powerup.TimedPowerup.StickyPaddle);
		#gui.remove_timer(Powerup.TimedPowerup.GhostPaddle);


# OVERRIDE FROM Level
func finish():
	if state != Level.LevelCompletionState.None:
		return;
	state = Level.LevelCompletionState.Clear;
	mouse_captured = false;
	EventBus.level_cleared.emit();
	#gui.show_level_clear(func(): get_window().title = 'Next level!',
		#func(): get_window().title = 'Main menu!');
	await get_tree().create_timer(1.0).timeout;
	for ball : Ball in get_tree().get_nodes_in_group(&'balls'):
		GameProgression.add_score(1000);
		# lmao
		await get_tree().create_timer(1000.0 / 600.0).timeout;
	await get_tree().create_timer(1.0).timeout;
	# TODO: ADD LEVEL CLEAR MENU AND OTHER STUFF
	# WAIT WHICH ONE I WAS SUPPOSED TO BE USING
	#assert(false and false and false or false or false, 'Hi!');
	# whatever, fur now I'll just make it forcibly go to the next level
	# to test out the next level thing too
	# maybe not even continue with the same points etc but just start
	# the new game with the next levle
	GameProgression.new_game(GameProgression.current_level_idx + 1);
	return;
	get_tree().physics_frame.connect(func():
		if randf() < 0.0001: # ??? lmao idk lol let's see
			get_tree().reload_current_scene());


func _physics_process(delta):
	time_passed += delta;


func _on_projectile_collided(_projectile: Projectile, _with: CollisionObject2D):
	handle_life_lost();


func _on_brick_destroyed(brick: Brick, by: Node2D):
	if brick.is_in_group(&'destructible_bricks') and by is Projectile:
		handle_life_lost();


func _input(event):
	if OS.is_debug_build():
		#if event is InputEventMouseButton:
			#if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
				#mouse_captured = not mouse_captured;
		if event.is_action_pressed("debug_exit"):
			get_tree().quit();
		if event.is_action_pressed("debug_restart"):
			get_tree().reload_current_scene();
		if event.is_action_pressed("debug_1"):
			return;
			Engine.time_scale = 1.0 if not is_equal_approx(Engine.time_scale, 1.0) else 0.05;
			return;
			finish();
			return
			powerup_component._request_powerup('finish_level',
				paddle.position - Vector2(0, 69));
		if event.is_action_pressed("debug_2"):
			powerup_component._request_powerup('acid_ball',
				paddle.position - Vector2(0, 69));
		if event.is_action_pressed('debug_3'):
			powerup_component._request_powerup('fire_ball',
				paddle.position - Vector2(0, 69));
		if event.is_action_pressed('debug_4'):
			powerup_component._request_powerup('sticky_paddle',
				paddle.position - Vector2(0, 69));
		if event.is_action_pressed("debug_5"):
			var briccs := get_tree().get_nodes_in_group(&'destructible_bricks');
			var ninety_five := int(briccs.size() * 0.95);
			briccs.shuffle();
			for i in ninety_five:
				briccs[i].queue_free();
			return;
			powerup_component._request_powerup('paddle_freeze',
				paddle.position - Vector2(0, 69))
