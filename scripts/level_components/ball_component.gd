extends Node2D;
# TODO: make it also manage other stuff such as creating balls etc


const ACID_TIME : float = 20.0;
const BALL_LIMIT := 20;


# Key: string, two concatenated instance ids,
# sorted by ascending, underscore in-between
# Value: number of ticks after that collision (when it reaches 0, remove
# from the dictionary)
var collisions : Dictionary = {};
var level : Level;
var audio_players : Array[AudioStreamPlayer2D];
@onready var acid_timer : Timer = (func():
	var t : Timer = Timer.new();
	t.autostart = false;
	t.one_shot = true;
	t.wait_time = ACID_TIME;
	add_child(t)
	return t).call();


func _ready():
	audio_players.assign(get_children().filter(func(a): return a is AudioStreamPlayer2D));
	Ball.reset_target_speed();
	EventBus.ball_collision.connect(handle_collision);
	acid_timer.timeout.connect(_on_acid_timer_timeout);
	EventBus.ball_lost.connect(_on_ball_lost);
	EventBus.level_cleared.connect(func():
		acid_timer.timeout.disconnect(_on_acid_timer_timeout);
		for ball : Ball in get_tree().get_nodes_in_group(&'balls'):
			pass);


func enable_acid():
	for b : Ball in get_tree().get_nodes_in_group(&'balls'):
		b.state = Ball.BallState.Acid;
	@warning_ignore('static_called_on_instance')
	Globals.start_or_extend_timer(acid_timer, ACID_TIME);


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
	
	# TODO: ACTUALLY MAKE THIS NOT BADLY IMPLEMENTED
	# also should crop the audio files a bit more so that there's no
	# silence in the beginning
	# all credit goes to some guy from freesound
	# thank you very much
	# the developers of the site, not that much
	# WHY did you make it so that you need to LOGIN to download sounds
	# but when you login it just throws you onto your profile page
	# and NOT to the previous page from where you were before (the one
	# with the sound I wanted to download)
	# scandalous!
	var player : AudioStreamPlayer2D = audio_players.pick_random();
	player.play();
	
	collisions[id] = 2;
	var v1 = b1.velocity;
	var v2 = b2.velocity;
	var x1 = b1.global_position;
	var x2 = b2.global_position;
	var v1_new = v1 - (v1 - v2).dot(x1 - x2) / (x1 - x2).length_squared() * (x1 - x2);
	var v2_new = v2 - (v2 - v1).dot(x2 - x1) / (x2 - x1).length_squared() * (x2 - x1);
	b1.velocity = v1_new;
	b2.velocity = v2_new;


func _physics_process(_delta):
	for k in collisions:
		collisions[k] -= 1;
		if collisions[k] == 0:
			collisions.erase(k);


func _on_acid_timer_timeout():
	for ball : Ball in get_tree().get_nodes_in_group(&'balls'):
		if ball.state == Ball.BallState.Acid:
			ball.state = Ball.BallState.Normal;


func _on_ball_lost(_ball: Ball):
	await get_tree().physics_frame;
	if get_tree().get_nodes_in_group(&'balls').any(
		func(b): return b.state == Ball.BallState.Acid):
			return;
	else:
		# reset the acid timer ig
		acid_timer.stop();
