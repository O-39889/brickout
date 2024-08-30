class_name Barrier extends StaticBody2D


# TODO: probably unused, remove?
signal hitted(barrier);


# Called when the node enters the scene tree for the first time.
func hit(by: Node2D, _damage: int):
	assert(by is Ball);
	if by is Ball:
		EventBus.barrier_hit.emit();
		queue_free();
	# otherwise idk lmao shouldn't happen
