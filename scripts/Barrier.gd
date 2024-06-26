class_name Barrier extends StaticBody2D


signal hitted(barrier);


# Called when the node enters the scene tree for the first time.
func hit(_b: Ball, _damage: int):
	hitted.emit(self);
