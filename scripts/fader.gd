## A node for managing fade-in and fade-out effects in the level
class_name Fader extends Node;


# bruh
signal fade_in_started;
signal fade_in_finished;
signal fade_out_started;
signal fade_out_finished;


# width / height ratio for fadeables
const FADE_RATIO := 2.0;
const FADE_MULT := 1.0 / 3333.333333333;
# prolly gonna delete that custom ahh fader param class anyway
const FADE_DURATION := 0.2;

## Whether the node should start the fade-in automatically during the [code]_ready()[/code] callback.
@export var on_ready : bool = false;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if get_tree().current_scene != get_parent()\
		or get_parent().get_child(0) != self:
			pass
			# just shut up
			#print("Warning: the Fader node works best when used as the first child of a top-level node so that it can access all nodes in the scene tree properly (because of the order the _ready() callback is called). Printing it in here bc I don't know how else to push warnings lol");
	if on_ready:
		fade_in();


func fade_in() -> void:
	fade_in_started.emit();
	var max_fade_delay := 0.0;
	for fadeable : Node2D in get_tree().get_nodes_in_group(&'fadeable'):
		var initial_scale : Vector2 = fadeable.scale;
		fadeable.scale = Vector2(0, 0);
		if fadeable is GPUParticles2D and fadeable.get_parent() is Brick:
			fadeable.amount_ratio = 0.0;
		var fade_delay := maxf(fadeable.global_position.x +
			fadeable.global_position.y * FADE_RATIO, 1.0) * FADE_MULT;
		max_fade_delay = maxf(max_fade_delay, fade_delay) if max_fade_delay != 0.0 else fade_delay;
		get_tree().create_timer(fade_delay, false).timeout.connect((func(to_fade: Node2D):
			if not is_instance_valid(to_fade):
				return;
			var tween := to_fade.create_tween();
			tween.set_parallel(true);
			# idk why did I need the pause thingy anyway
			tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP);
			tween.tween_property(to_fade, 'scale',
				initial_scale, FADE_DURATION);
			# bruh hardcoded ahhh thing lmao
			if to_fade is GPUParticles2D and to_fade.get_parent() is Brick:
				tween.tween_property(to_fade, 'amount_ratio',
				1.0, FADE_DURATION
				);
			).bind(fadeable));
	get_tree().create_timer(max_fade_delay + FADE_DURATION, false)\
	.timeout.connect(self.fade_in_finished.emit);


func fade_out() -> void:
	#EventBus.fade_end_started.emit();
	fade_out_started.emit();
	var max_fade_delay := 0.0;
	for fadeable : Node2D in get_tree().get_nodes_in_group(&'fadeable'):
		# don't need to calculate initial/final scale or anything
		# since we're just gonna scale everything down to 0
		var fade_delay := maxf(fadeable.global_position.x +
			fadeable.global_position.y * FADE_RATIO, 1.0) * FADE_MULT;
		max_fade_delay = maxf(max_fade_delay, fade_delay) if max_fade_delay != 0.0 else fade_delay;
		get_tree().create_timer(fade_delay, false).timeout.connect((func(to_fade : Node2D):
			if not is_instance_valid(to_fade):
				return;
			var tween := to_fade.create_tween();
			tween.set_parallel(true);
			tween.set_pause_mode(Tween.TWEEN_PAUSE_STOP);
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
	get_tree().create_timer(max_fade_delay, false).timeout\
	.connect(self.fade_out_finished.emit);
	# my goodness lmao! this code was still in there all that time xd
	#EventBus.fade_end_finished.connect(func(): get_window().title = 'AJFKLJSD');
