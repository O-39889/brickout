class_name LevelRegularGUI extends Control;


@onready var score_label : Label = $Score;
@onready var lives_label : Label = $Lives;
# don't think i need this anymore though
@onready var score_timer : Timer = $ScoreTimer;
@onready var level_name : Label = $LevelAuthorName;
@onready var timers_container : VBoxContainer = $TimersEtc;
