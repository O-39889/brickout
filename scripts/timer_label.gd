class_name TimerContainer extends HBoxContainer;


var bound_timer : Timer;
var assigned_powerup : Powerup.TimedPowerup;

@onready var label : Label = $Label;
@onready var icon : TextureRect = $Icon;


func _ready():
	assert(bound_timer);
	assert(assigned_powerup != null);
	bound_timer.tree_exiting.connect(func(): queue_free());
	bound_timer.timeout.connect(func(): queue_free());
	match assigned_powerup:
		Powerup.TimedPowerup.StickyPaddle:
			icon.modulate = Color.MAGENTA;
		Powerup.TimedPowerup.AcidBall:
			icon.modulate = Color.LIME;
		Powerup.TimedPowerup.PaddleFreeze:
			icon.modulate = Color.CYAN;
		Powerup.TimedPowerup.GhostPaddle:
			icon.modulate = Color.LIGHT_SLATE_GRAY;
			icon.modulate.a = 0.3333;
		


func _physics_process(delta):
	if bound_timer != null:
		# not exactly too helpful with my case of, like, stuff
		#if bound_timer.is_stopped():
			#queue_free();
		label.text = Globals.display_time(bound_timer.time_left);
