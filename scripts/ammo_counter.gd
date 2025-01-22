class_name AmmoCounter extends HBoxContainer;


var kind : Projectile.GunType;
var attributes : ProjectileAttributes;


func _ready() -> void:
	assert(attributes != null);
	%Label.text = str(attributes.amount);
	# just TEST-ing stuff!
	%Icon.rotation_degrees = 90 * kind;


func set_ammo_count(n: int) -> void:
	if n == 0:
		queue_free();
	%Label.text = str(n);
