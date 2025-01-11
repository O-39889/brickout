class_name Savedata extends RefCounted;


const CURRENT_VERSION : int = 2;

## A separate class for holding the session data
## (if a session was started)
class SessionData:
	## Index of the level at which the session started
	## (where the player started the new game or restarted after game over)
	var session_started_idx : int;
	## Index of the last level the player **cleared**,
	## whether they've already went to the next one or not.
	var highest_cleared_idx : int;
	## Time (Unix timestamp) when the session has started.
	var session_started_time : float;
	## Time (Unix timestamp) when the last level was cleared.
	var left_time : float;
	## Total amount of time elapsed on all levels.
	var time_elapsed : float;
	## Score after clearing the last level.
	var score : int;
	## Lives after clearing the last level.
	var lives : int;
	func _init(_session_started_idx: int,
			_highest_cleared_idx: int,
			_session_started_time: float, _left_time: float,
			_time_elapsed: float, _score: int, _lives: int
	) -> void:
		session_started_idx = _session_started_idx;
		highest_cleared_idx = _highest_cleared_idx;
		session_started_time = _session_started_time;
		left_time = _left_time;
		time_elapsed = _time_elapsed;
		score = _score;
		lives = _lives;


## The current session data (if there is a session).
var session : SessionData = null;
## The highest level ever reached on this savefile.
var max_level_reached : int;
## The savefile format version (for interoperability and backwards compatibility, probably)
var version : int = CURRENT_VERSION;


func has_session() -> bool:
	return session != null;


func _init(_max_level_reached : int,
		_session : SessionData = null,
		_version : int = CURRENT_VERSION,
		) -> void:
	session = _session;
	max_level_reached = _max_level_reached;
	version = _version;


func to_dict() -> Dictionary:
	return {
		&'max_level_reached': max_level_reached,
		&'version': version,
		&'session': null if session == null else {
			&'session_started_idx': session.session_started_idx,
			&'highest_cleared_idx': session.highest_cleared_idx,
			&'session_started_time': session.session_started_time,
			&'left_time': session.left_time,
			&'time_elapsed': session.time_elapsed,
			&'score': session.score,
			&'lives': session.lives,
		},
	};


static func from_dict(dict: Dictionary) -> Savedata:
	for key in [
		&'max_level_reached', &'session', &'version'
	]:
		if !dict.has(key):
			push_error('No key %s in the dictionary' % key);
			return null;
	var session_var;
	if dict[&'session'] != null:
		if !(dict[&'session'] is Dictionary):
			push_error('Invalid session data');
			return null;
		for key in [
			&'session_started_idx', &'highest_cleared_idx',
			&'session_started_time', &'left_time',
			&'time_elapsed', &'score', &'lives'
		]:
			if !dict[&'session'].has(key):
				push_error('Invalid session data, no key %s' % key);
				return null;
		session_var = SessionData.new(
			dict[&'session'][&'session_started_idx'],
			dict[&'session'][&'highest_cleared_idx'],
			dict[&'session'][&'session_started_time'],
			dict[&'session'][&'left_time'],
			dict[&'session'][&'time_elapsed'],
			dict[&'session'][&'score'],
			dict[&'session'][&'lives']
		);
	else: # no session
		session_var = null;
	return Savedata.new(
		dict[&'max_level_reached'],
		session_var,
		dict[&'version']
	);
