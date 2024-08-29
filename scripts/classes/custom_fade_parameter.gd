class_name CustomFadeParameter extends RefCounted;


const DEFAULT_FADE_DURATION := 0.2;


var object: Object;
var property : NodePath;
var initial_value : Variant;
var final_value : Variant;
var duration : float = DEFAULT_FADE_DURATION;


static func start(_obj: Object, _property: NodePath, _initial: Variant, _duration: float = DEFAULT_FADE_DURATION) -> CustomFadeParameter:
	var param := CustomFadeParameter.new();
	param.object = _obj;
	param.property = _property;
	param.initial_value = _initial;
	param.duration = _duration;
	return param;


static func finish(_obj: Object, _property: NodePath, _final: Variant, _duration: float = DEFAULT_FADE_DURATION) -> CustomFadeParameter:
	var param := CustomFadeParameter.new();
	param.object = _obj;
	param.property = _property;
	param.final_value = _final;
	param.duration = _duration;
	return param;
