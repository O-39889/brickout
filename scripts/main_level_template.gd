# no idea how to name it lol
class_name MainLevelTemplate extends Node;


# so it's apparently 10 per 1/60s frame which is 600 per second
# which is 1.(6) seconds for 1000 points for a ball
const SCORE_CHANGE_SPEED := 10; # framerate dependent i don't care lmao

const TIMER_CONTAINER_PACKED := preload("res://scenes/gui/timer_container.tscn");
const LEVEL_CLEAR_PACKED := preload("res://scenes/gui/level_clear_screen.tscn");
const GAME_OVER_PACKED := preload("res://scenes/gui/game_over_screen.tscn");
const PAUSE_MENU_PACKED := preload("res://scenes/gui/paws_menu.tscn");
const AMMO_COUNTER_PACKED := preload("res://scenes/gui/ammo_counter.tscn");


var display_score : int = GameProgression.score:
	get:
		return display_score;
	set(value):
		display_score = value;
		score_match = display_score == GameProgression.score;
		update_score_counter();

## Set to true when the display score reaches the actual score,
## set to false when they don't match and it's necessary
## to update the display score.
var score_match : bool = true;

var timers : Dictionary = {
	Powerup.TimedPowerup.StickyPaddle: null,
	Powerup.TimedPowerup.AcidBall: null,
	Powerup.TimedPowerup.GhostPaddle: null,
	Powerup.TimedPowerup.PaddleFreeze: null,
};

var pause_menu : PauseMenu;
var fader_finished : bool = false;
var data : bool = true;

@onready var score_lbl : Label = %ScoreLbl;
@onready var lives_lbl : Label = %LivesLbl;
@onready var timer_lbl : Label = %LevelTime;
@onready var barrier_indicator : Label = %BarrierIndicator;

@onready var main_container : MarginContainer = %UglyWorkaround;
@onready var timers_container : Container = %PowerupTimersContainer;
@onready var ammo_container : Container = %AmmoContainer;

@onready var current_ammo_counter : AmmoCounter;

@onready var fader : Fader = %Fader;

@onready var game_viewport : SubViewport = %GameVPort;
# GETS SET BEFORE READY
# so you gotta first change the current level in the game progression
# then load this and it will do everything itself
@onready var lvl : MainLevel = GameProgression.current_level;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(is_instance_valid(lvl), "Level gameplay scene not provided by the GameProgression singleton!!!");
	lvl.template = self;
	game_viewport.add_child(lvl);
	
	EventBus.score_changed.connect(func(_amount: int) -> void:
		score_match = false);
	# ???
	EventBus.lives_changed.connect(update_lives_counter);
	EventBus.powerup_collected.connect(_on_powerup_collected);
	EventBus.barrier_hit.connect(barrier_indicator.hide);

	fader.fade_in_started.connect(lvl.paddle._on_fade_in_start);
	fader.fade_in_finished.connect(lvl.paddle._on_fade_in_end);
	fader.fade_in_finished.connect(func():
		fader_finished = true);
	fader.fade_in();
	update_score_counter();
	update_lives_counter();


func update_score_counter() -> void:
	score_lbl.text = "Score: " + "%06d" % display_score;


func update_lives_counter() -> void:
	lives_lbl.text = "Lives: " + str(GameProgression.lives);


func show_game_over() -> void:
	clear_timers();
	var gover_node := GAME_OVER_PACKED.instantiate() as GameOverScreen;
	main_container.add_child(gover_node);
	gover_node.restart_btn.pressed.connect(func():
		fader.fade_out_finished.connect(
			GameProgression.new_game.bind(
				GameProgression.current_level_idx));
		fader.fade_out();
	);
	gover_node.exit_btn.pressed.connect(func():
		fader.fade_out_finished.connect(
			GameProgression.exit_after_game_over);
		fader.fade_out();
	);
	gover_node.set_score(GameProgression.score);


func show_level_clear() -> void:
	clear_timers();
	var clear_node := LEVEL_CLEAR_PACKED.instantiate() as LevelClearScreen;
	# also bind signals ofc
	main_container.add_child(clear_node);
	clear_node.continue_btn.pressed.connect(func():
		fader.fade_out_finished.connect(GameProgression.next_level);
		fader.fade_out();
	);
	clear_node.exit_btn.pressed.connect(func():
		fader.fade_out_finished.connect(GameProgression.exit_after_clear);
		fader.fade_out();
	);
	# TODO: score and time only for the current level
	clear_node.set_score(lvl.points_earned);
	clear_node.set_time(lvl.time_elapsed);


func add_or_extend_timer(timer: Timer, what: Powerup.TimedPowerup) -> void:
	if timers[what] == null:
		timers[what] = TIMER_CONTAINER_PACKED.instantiate() as TimerContainer;
		timers[what].assigned_powerup = what;
		timers[what].bound_timer = timer;
		timers[what].tree_exiting.connect(remove_timer.bind(what));
		var children := timers_container.get_children();
		if children.is_empty():
			timers_container.add_child(timers[what]);
		else:
			timers_container.add_child(timers[what]);
			timers_container.move_child(timers[what], mini(
				timers_container.get_child_count(), what
			));


func remove_timer(what: Powerup.TimedPowerup) -> void:
	if is_instance_valid(timers[what]):
		timers[what].queue_free();
	timers[what] = null;


func clear_timers() -> void:
	for id in Powerup.TimedPowerup:
		remove_timer(Powerup.TimedPowerup[id]);


## When showing a new ammo counter (when picking up a new power-up)
func show_ammo_counter(kind: Projectile.GunType) -> void:
	if current_ammo_counter != null:
		remove_ammo_counter();
	var ammo_counter := AMMO_COUNTER_PACKED.instantiate() as AmmoCounter;
	ammo_counter.attributes = Projectile.ATTR_DICT[kind];
	ammo_counter.set_ammo_count(ammo_counter.attributes.amount);
	current_ammo_counter = ammo_counter;
	ammo_container.add_child(current_ammo_counter);	

func update_ammo_counter() -> void:
	if current_ammo_counter == null:
		return;
	if lvl.paddle.ammo_left != 0:
		current_ammo_counter.set_ammo_count(lvl.paddle.ammo_left);
	else:
		remove_ammo_counter();


func remove_ammo_counter() -> void:
	current_ammo_counter.queue_free();
	current_ammo_counter = null;


func show_pause() -> void:
	if pause_menu == null:
		pause_menu = PAUSE_MENU_PACKED.instantiate();
		pause_menu.dialog_pos_setter = func(d: ConfirmationDialog):
			d.position = main_container.position\
			+ main_container.size / 2\
			- Vector2(d.size) / 2;
		main_container.add_child(pause_menu);
		pause_menu.level_number_lbl.text = 'Level ' + str(GameProgression.current_level_idx + 1);
		pause_menu.continue_btn.pressed.connect(hide_pause);
	else:
		main_container.add_child(pause_menu);
	if (randf() < 0.00696969696969\
	or randf() < pow(0.00696969696969, 2)\
	or randf() < pow(0.00696969696969, 6))\
	and data:
		data = false;
		pause_menu.pause_lbl.text = 'Paws';
	else:
		pause_menu.pause_lbl.text = 'Pause';
		
	pause_menu.level_name_lbl.text = 'Score on this level: ' + str(lvl.points_earned);
	
	pause_menu.previous_mouse_captured = lvl.mouse_captured;
	lvl.mouse_captured = false;
	# also set the mouse position somewhere in the middle
	# of the pause menu
	# it doesn't work the first time though because
	# we kinda haven't rendered that label yet lol
	# maybe as a lazy workaround I could silently render it
	# behind the scenes (invisible) then just remove it
	# from the tree again lol (sounds like such a stupid thing really)
	
	get_tree().set_pause(true);
	Input.warp_mouse(main_container.global_position +
			main_container.size / 2);


func hide_pause() -> void:
	main_container.remove_child(pause_menu);
	lvl.mouse_captured = pause_menu.previous_mouse_captured;
	get_tree().set_pause(false);


func _on_powerup_collected(powerup: Powerup) -> void:
	match powerup.id:
		&'sticky_paddle':
			add_or_extend_timer(lvl.paddle.sticky_timer,
				Powerup.TimedPowerup.StickyPaddle);
		&'acid_ball':
			add_or_extend_timer(lvl.ball_component.acid_timer,
				Powerup.TimedPowerup.AcidBall);
		&'paddle_freeze':
			add_or_extend_timer(lvl.paddle.frozen_timer,
				Powerup.TimedPowerup.PaddleFreeze);
		&'barrier':
			barrier_indicator.show();
		&'gun':
			show_ammo_counter(Projectile.GunType.Regular);


func _on_paddle_projectile_shot(p: Projectile, kind: Projectile.GunType) -> void:
	update_ammo_counter();


func _on_life_lost() -> void:
	# wait a sec this one also doesn't make sense
	# as we don't lose lives until the last bullets are shot
	remove_ammo_counter();
	clear_timers(); # probably unnecessary rn but whatever


func _process(delta: float) -> void:
	if not score_match:
		display_score = int(move_toward(display_score, GameProgression.score, SCORE_CHANGE_SPEED));
	timer_lbl.text = "Time: " + Globals.display_time(lvl.time_elapsed);


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&'paws')\
	and (lvl.state == Level.LevelCompletionState.None\
	or lvl.state == Level.LevelCompletionState.Lost)\
	and fader_finished:
		show_pause();
		get_tree().root.set_input_as_handled();
