class_name TitleScreenLevel extends Level;


@export_dir var layout_directory : String;

var spawned_balls_amount : int;
# to prevent the same brick layout getting shown to a player over and over (scandalous!)
var last_layout_name : String = '';
var brick_layout : TitleScreenBrickComponent;

@onready var fader : Fader = %Fader;


func _ready() -> void:
	# add_paddle should be false by default heheheha
	# set up walls and everything
	super();
	$Walls/WallBottom.position.y = get_viewport_rect().size.y;
	reset_brick_layout();


func reset_brick_layout() -> void:
	if is_instance_valid(brick_layout):
		fader.fade_out();
		await EventBus.fade_end_finished;
		for b : Ball in get_tree().get_nodes_in_group(&"balls"):
			# I think I added this line in the old code
			# so that the balls wouldn't collide with
			# the newly appeared bricks since the balls
			# would get deleted only on the next frame
			b.process_mode = Node.PROCESS_MODE_DISABLED;
			b.queue_free();
		brick_layout.queue_free();
		brick_layout = null;
	Ball.reset_target_speed();
	Ball.target_speed_override = Ball.BALL_SPEEDS[Ball.BallSpeed.BALL_SPEED_NORMAL];
	var to_choose : PackedStringArray = DirAccess.get_files_at(layout_directory);
	if not last_layout_name.is_empty() and to_choose.size() > 1:
		to_choose.remove_at(to_choose.find(last_layout_name));
	# this stuff is supposed to make the layouts
	# with the "rare" suffix... well, rare to see compared
	# to regular ones
	# would be more noticeable once there's more title screen
	# layouts though
	var rare_considered := to_choose.duplicate();
	for entry : String in to_choose:
		if entry.ends_with("_rare.tscn") and randf() < 0.9 and rare_considered.size() > 1:
			rare_considered.remove_at(rare_considered.find(entry));
	var scene_name = rare_considered[randi_range(0, rare_considered.size() - 1)];
	last_layout_name = scene_name;
	var absolute_name = layout_directory.path_join(scene_name);
	brick_layout = load(absolute_name).instantiate() as TitleScreenBrickComponent;
	brick_layout.level = self;
	# has to have a hardcoded position to match the z index
	# I mean, I could just change the z index manually
	# but who wants to do all that?
	# also it's funny how the correct order is the alphabetical one
	# (ball, brick, powerup)
	ball_component.add_sibling(brick_layout);
	fader.fade_in();
	# kinda sucks, maybe should have made this a signal
	# for the fader node instead of putting that on le event bus
	await EventBus.fade_start_finished;
	
	await get_tree().create_timer(2.0).timeout;
	spawned_balls_amount = randi_range(2, 3);
	ball_component.spawn_balls(spawned_balls_amount);


# OVERRIDDEN FROM LEVEL CLASS
func finish() -> void:
	EventBus.level_cleared.emit();
	await get_tree().create_timer(1.5).timeout;
	reset_brick_layout();


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_2"):
		for b : Brick in get_tree().get_nodes_in_group(&"destructible_bricks"):
			if randf() < 0.950001997:
				b.destroy(get_tree().get_first_node_in_group(&'balls'));
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			Ball.target_speed_override = clamp(
				Ball.target_speed_override + 5,
				Ball.BALL_SPEEDS[Ball.BallSpeed.BALL_SPEED_SLOW] - 50,
				Ball.BALL_SPEEDS[Ball.BallSpeed.BALL_SPEED_FAST] + 100,
			);
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			Ball.target_speed_override = clamp(
				Ball.target_speed_override - 5,
				Ball.BALL_SPEEDS[Ball.BallSpeed.BALL_SPEED_SLOW] - 50,
				Ball.BALL_SPEEDS[Ball.BallSpeed.BALL_SPEED_FAST] + 100,
			);
		# the second easter egg (when right clicking on the screen),
		# I don't think I'm gonna do it today though
