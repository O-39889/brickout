# no idea how to name it lol
class_name MainLevelTemplate extends Node;


const SCORE_CHANGE_SPEED := 10; # framerate dependent i don't care lmao

const TIMER_CONTAINER_PACKED := preload("res://scenes/gui/timer_container.tscn");

# width / height ratio for fadeables
const FADE_RATIO := 2.0;
const FADE_MULT := 1.0 / 3333.333333333;
const FADE_DURATION := CustomFadeParameter.DEFAULT_FADE_DURATION;


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

@onready var score_lbl : Label = %ScoreLbl;
@onready var lives_lbl : Label = %LivesLbl;
@onready var timer_lbl : Label = %LevelTime;
@onready var barrier_indicator : Label = %BarrierIndicator;

@onready var main_container : MarginContainer = %UglyWorkaround;
@onready var timers_container : Container = %PowerupTimersContainer;

@onready var lvl : MainLevel = %MainLevelGameplay;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_window().min_size = Vector2i(1024, 576);
	
	EventBus.score_changed.connect(func(_amount: int) -> void:
		score_match = false);
	EventBus.lives_changed.connect(update_lives_counter);
	EventBus.powerup_collected.connect(_on_powerup_collected);
	EventBus.barrier_hit.connect(barrier_indicator.hide);

	fade_in();	
	update_score_counter();
	update_lives_counter();


func fade_in() -> void:
	EventBus.fade_start_started.emit();
	var max_fade_delay := 0.0;
	for fadeable : Node2D in get_tree().get_nodes_in_group(&'fadeable'):
		var initial_scale : Vector2 = fadeable.scale;
		fadeable.scale = Vector2(0, 0);
		if fadeable is GPUParticles2D and fadeable.get_parent() is Brick:
			fadeable.amount_ratio = 0.0;
		var fade_delay := (fadeable.global_position.x +
		fadeable.global_position.y * FADE_RATIO) * FADE_MULT;
		max_fade_delay = maxf(max_fade_delay, fade_delay) if max_fade_delay != 0.0 else fade_delay;
		get_tree().create_timer(fade_delay).timeout.connect((func(to_fade: Node2D):
			if not is_instance_valid(to_fade):
				return;
			var tween := to_fade.create_tween();
			tween.set_parallel(true);
			tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS);
			tween.tween_property(to_fade, 'scale',
				initial_scale, FADE_DURATION);
			if to_fade is GPUParticles2D and to_fade.get_parent() is Brick:
				tween.tween_property(to_fade, 'amount_ratio',
				1.0, FADE_DURATION
				);
			).bind(fadeable));
	get_tree().create_timer(max_fade_delay + FADE_DURATION)\
	.timeout.connect(EventBus.fade_start_finished.emit);


func fade_out() -> void:
	EventBus.fade_end_started.emit();
	var max_fade_delay := 0.0;
	for fadeable : Node2D in get_tree().get_nodes_in_group(&'fadeable'):
		# don't need to calculate initial/final scale or anything
		# since we're just gonna scale everything down to 0
		var fade_delay := (fadeable.global_position.x +
			fadeable.global_position.y * FADE_RATIO) * FADE_MULT;
		max_fade_delay = maxf(max_fade_delay, fade_delay) if max_fade_delay != 0.0 else fade_delay;
		get_tree().create_timer(fade_delay).timeout.connect((func(to_fade : Node2D):
			if not is_instance_valid(to_fade):
				return;
			var tween := to_fade.create_tween();
			tween.set_parallel(true);
			tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS);
			tween.tween_property(to_fade, 'scale',
				Vector2.ZERO, FADE_DURATION);
			if to_fade is GPUParticles2D and to_fade.get_parent() is Brick:
				# maybe ALL of this at the same time is too much idk lmao
				tween.tween_property(to_fade.process_material, 'scale_min',
					0.0, FADE_DURATION - 0.05);
				tween.tween_property(to_fade.process_material ,'scale_max',
					0.0, FADE_DURATION);
				tween.tween_property(to_fade.process_material, 'emission_shape_scale',
					Vector3.ZERO, FADE_DURATION);
				tween.tween_property(to_fade, 'amount_ratio',
					0.0, FADE_DURATION);
			).bind(fadeable));
	get_tree().create_timer(max_fade_delay).timeout\
	.connect(EventBus.fade_end_finished.emit);
	EventBus.fade_end_finished.connect(func(): get_window().title = 'AJFKLJSD');


func update_score_counter() -> void:
	score_lbl.text = "Score: " + "%06d" % display_score;


func update_lives_counter() -> void:
	lives_lbl.text = "Lives: " + str(GameProgression.lives);


func show_game_over() -> void:
	clear_timers();


func show_level_clear() -> void:
	clear_timers();


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


func _process(delta: float) -> void:
	if not score_match:
		display_score = int(move_toward(display_score, GameProgression.score, SCORE_CHANGE_SPEED));
	timer_lbl.text = "Time: " + Globals.display_time(lvl.time_passed);


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_1"):
		fade_out();
