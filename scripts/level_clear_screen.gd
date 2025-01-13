class_name LevelClearScreen extends Control;


@onready var score_lbl : Label = %ScoreLbl;
@onready var time_lbl : Label = %TimeLbl;
@onready var tip_lbl : Label = %Tip;
@onready var continue_btn : Button = %ContinueBtn;
@onready var exit_btn : Button = %ExitBtn;


# to prevent repeating tips
# | 1024 for the rare ones
static var last_tip_idx := -1;
static var tip_dict := ResourceLoader.load("res://data/loading_screen_tips.json").data as Dictionary;


func _ready() -> void:
	_set_tip();
	return;
	tip_lbl.queue_free();


func _set_tip() -> void:
	var tip_text : String;
	if randf() < 0.011111111111111111111:
		# use rare tip
		# idk how else to make that work bruh
		var rare_idx : int;
		while true:
			rare_idx = int(randf() * tip_dict['rare'].size());
			if last_tip_idx == -1 or rare_idx | 1024 != last_tip_idx:
				break;
		last_tip_idx = rare_idx | 1024;
		tip_text = tip_dict['rare'][rare_idx];
	else:
		# otherwise, use common tip
		var common_idx : int;
		while true:
			common_idx = int(randf() * tip_dict['common'].size());
			if last_tip_idx == -1 or common_idx != last_tip_idx:
				break;
		last_tip_idx = common_idx;
		tip_text = tip_dict['common'][common_idx];

	tip_text = tip_text.replace('EXTRA_LIFE_MULTIPLIER',
		str(GameProgression.EXTRA_LIFE_MULTIPLIER))\
		.replace('WHEREVER_THE_HECK_ARE_THEY_DISPLAYED',
		'the level clear screen')\
		.replace('OS_NAME', OS.get_name())\
		.replace('OS_JUDGEMENTAL_TEXT',
		"I've yet to come up with customized judgemental messages for every supported OS though")\
		.replace('ABABA',
		'fewer' if randf() < 0.5 else 'less')\
		.replace('№',
		(func() -> String:
			var counter := 0;
			for tip : String in tip_dict['common']:
				counter += tip.countn('ball');
			for tip : String in tip_dict['rare']:
				counter += tip.countn('ball');
			return str(counter);
			).call());
	if not(tip_text.begins_with('Fun fact')
	or tip_text.begins_with('News')):
		tip_text = 'Tip: ' + tip_text;
	tip_lbl.text = tip_text;

# NOTE: in the level clear screen, time should be the score in the current level,
# not the total score
func set_score(score: int) -> void:
	score_lbl.text = 'Score: %d' % score;


# NOTE: in the level clear screen, time should be the time in the current level,
# not the total time
func set_time(time: float) -> void:
	time_lbl.text = 'Time: %s' % Globals.display_time(time);
