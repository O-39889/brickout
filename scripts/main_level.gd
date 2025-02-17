class_name MainLevel extends Level;


const BARRIER_PACKED : PackedScene = preload("res://scenes/Barrier.tscn");
### Bonus points for each ball left in play when clearing the level.
const BALL_BONUS := 1000;


@export var level_name : String = 'New Level';
@export var level_author : String = 'Someone';
@export var allow_level_finish_powerup : bool = true;

var barrier : Barrier;
### Score earned in this particular level.
var points_earned : int = 0;
### Time passed in this particular level.
### Counts up during gameplay, not when game is overed or after clearing
### a level or (TODO) when the game is paused.
var time_elapsed : float = 0.0;
# set on init by the parent template scene
var template : MainLevelTemplate;

@onready var author_name_lbl : Label = %LevelAuthorName;


func _enter_tree():
	super();


func _ready():
	add_paddle = true;
	EventBus.ball_lost.connect(handle_ball_lost);
	EventBus.barrier_hit.connect(_on_barrier_hit);
	EventBus.score_changed.connect(func(amount: int):
		# NOTE: right now, it doesn't count the
		# ball scores into the total either
		# well, we could just do it ourselves instead
		# actually probably still should add points
		# even during the level clear state (for example,
		# in case a ball breaks a leftover brick while
		# stopping
		if state != Level.LevelCompletionState.Clear:
			points_earned += amount);
	# actually no, we'll need another signal on bullet collision just so that
	# we can handle the cases where it just bonks into the top wall
	EventBus.projectile_collided.connect(_on_projectile_collided);
	EventBus.brick_destroyed.connect(_on_brick_destroyed);
	var author_name_string : String = '[%d]' % (GameProgression.current_level_idx + 1);
	if not level_author.is_empty():
		author_name_string += ' ' + level_author + ' —';
	author_name_string += ' ' + 'New Level' if level_name.is_empty() else level_name;
	author_name_lbl.text = author_name_string;
	super();


func create_paddle() -> void:
	super();
	paddle.projectile_shot.connect(template._on_paddle_projectile_shot);


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
		await get_tree().create_timer(1.0, false).timeout;
		restart();


func restart():
	state = LevelCompletionState.None;
	create_paddle();
	paddle.accept_input = true;


func handle_game_over():
	if state != LevelCompletionState.Lost and state != LevelCompletionState.None:
		return;
	GameProgression.time_total += time_elapsed;
	mouse_captured = false;
	state = LevelCompletionState.GameOver;
	GameProgression.clear_autosave();
	template.show_game_over();


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
func activate_stinky_powerup():
	print('Eww, you stink!');


func activate_acid_powerup():
	if ball_component:
		ball_component.enable_acid();


func activate_freeze_powerup():
	if paddle:
		paddle.state = Paddle.PaddleState.Frozen;


# OVERRIDE FROM Level
func finish():
	if state != Level.LevelCompletionState.None:
		return;
	state = Level.LevelCompletionState.Clear;
	GameProgression.time_total += time_elapsed;
	mouse_captured = false;
	EventBus.level_cleared.emit();
	if GameProgression.current_level_idx ==	GameProgression.level_campaign.size() - 1:
		get_tree().change_scene_to_file("res://scenes/title_screen.tscn");
		GameProgression.reset_current_data(0);
		return;
	# NOTE: this thing would probably be better
	# to put in GameProgression as a handler of the signal
	# above; however, this signal gets emitted not only
	# in regular levels but also on the title screen
	# so that's kind of an oversight so whatever ig
	GameProgression.set_next_current_level();
	GameProgression.max_level_reached = maxi(
		GameProgression.max_level_reached,
		GameProgression.current_level_idx);

	await get_tree().create_timer(1.0).timeout;
	
	for ball : Ball in get_tree().get_nodes_in_group(&'balls'):
		GameProgression.add_score(BALL_BONUS);
		points_earned += BALL_BONUS;
		# lmao
		await get_tree().create_timer(BALL_BONUS / 600.0).timeout;
	
	# how about we still have it update the last level data lol xd :DDDDDDDDDDDDDD
	GameProgression.update_last_level_stats();
	# oops! indeed, should have done it in here lol xd
	GameProgression.save_to_autosave();
	template.show_level_clear();


func _physics_process(delta):
	if state == LevelCompletionState.None or\
	state == LevelCompletionState.Lost:
		time_elapsed += delta; # 🔥


func _on_projectile_collided(_projectile: Projectile, _with: CollisionObject2D):
	handle_life_lost();


func _on_brick_destroyed(brick: Brick, by: Node2D):
	if brick.is_in_group(&'destructible_bricks') and by is Projectile:
		handle_life_lost();


func _input(event):
	if OS.is_debug_build():
		if event.is_action_pressed("debug_exit"):
			return;
		if event.is_action_pressed("debug_restart"):
			return;
		if event.is_action_pressed("debug_1"):
			powerup_component._request_powerup('gun',
				paddle.position - Vector2(0, 69));
		if event.is_action_pressed("debug_2"):
			powerup_component._request_powerup('add_ball',
				paddle.position - Vector2(0, 69));
		if event.is_action_pressed('debug_3'):
			powerup_component._request_powerup('double_balls',
				paddle.position - Vector2(0, 69));
		if event.is_action_pressed('debug_4'):
			powerup_component._request_powerup('triple_ball',
				paddle.position - Vector2(0, 69));
		if event.is_action_pressed('debug_5'):
			powerup_component._request_powerup('pop_ball',
				paddle.position - Vector2(0, 69));
		if event.is_action_pressed('debug_6'):
			powerup_component._request_powerup('pop_all_balls',
				paddle.position - Vector2(0, 69));
		if event.is_action_pressed("debug_7"):
			var briccs := get_tree().get_nodes_in_group(&'destructible_bricks');
			var ninety_five := int(briccs.size() * 0.950001);
			briccs.shuffle();
			for i in ninety_five:
				briccs[i].queue_free();
			return;
			powerup_component._request_powerup('paddle_freeze',
				paddle.position - Vector2(0, 69))
