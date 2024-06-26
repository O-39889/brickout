class_name Powerup extends RefCounted


const POWERUP_POOL = {
	'good': [
		'double_balls',
		'paddle_enlarge',
		'add_ball',
		'triple_ball',
		'sticky_paddle',
		'barrier',
		'fire_ball',
		'acid_ball',
	],
	'neutral': [
		'ball_speed_up',
		'ball_slow_down',
	],
	'bad': [
		'paddle_shrink',
		'pop_ball',
		'pop_all_balls',
		'ghost_paddle',
		'paddle_freeze',
	],
};


var id : String;
var type: String;
var weight: float = 1.0;


func _init(_id: String, _type: String, _weight: float = 1.0):
	self.id = _id;
	self.type = _type;
	self.weight = _weight;


static func get_default_weight_pool() -> Array[Powerup]:
	var arr : Array[Powerup] = [];
	var good_weight := 1.0;
	var neutral_weight := 1.25;
	var bad_weight := float(POWERUP_POOL['good'].size()) / float(POWERUP_POOL['bad'].size()) * 0.5;
	for gp_id in POWERUP_POOL['good']:
		var gp : Powerup = Powerup.new(gp_id, 'good', good_weight);
		arr.append(gp);
	for np_id in POWERUP_POOL['neutral']:
		var np : Powerup = Powerup.new(np_id, 'neutral', neutral_weight);
		arr.append(np);
	for bp_id in POWERUP_POOL['bad']:
		var bp : Powerup = Powerup.new(bp_id, 'bad', bad_weight);
		arr.append(bp);
	return arr;
