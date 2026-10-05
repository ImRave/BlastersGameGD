extends Node

# Configuración de Video
var show_fps: bool = false
var fps_limit: int = 0  # 0 = sin límite
var fullscreen: bool = false
var brightness: float = 1.0

# Audio
var volume_master: float = 1.0
var volume_music: float = 1.0
var volume_sfx: float = 1.0

# Controles (por defecto)
var key_up: String = "W"
var key_down: String = "S"
var key_left: String = "A"
var key_right: String = "D"
var key_shoot: String = "SPACE"
var mouse_shoot: bool = true

const CONFIG_PATH := "user://settings.cfg"

func _ready() -> void:
	load_settings()
	apply_all()

func apply_all() -> void:
	apply_video()
	apply_audio()
	apply_controls()

func apply_video() -> void:
	# Fullscreen
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	# FPS limit
	Engine.max_fps = fps_limit
	# FPS visible
	# (se controla desde el nodo que muestra FPS en el HUD, aquí solo guardamos)

func apply_audio() -> void:
	_set_bus_volume("Master", volume_master)
	_set_bus_volume("Music", volume_music)
	_set_bus_volume("SFX", volume_sfx)

func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	var db := linear_to_db(linear)
	AudioServer.set_bus_volume_db(idx, db)
	AudioServer.set_bus_mute(idx, linear <= 0.001)

func apply_controls() -> void:
	# Actualiza InputMap con las teclas seleccionadas
	_remap_action("move_up", key_up)
	_remap_action("move_down", key_down)
	_remap_action("move_left", key_left)
	_remap_action("move_right", key_right)
	_remap_action("shoot", key_shoot)

func _remap_action(action: String, key_name: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)

	var keycode := OS.find_keycode_from_string(key_name)
	if keycode != KEY_NONE:
		var ev := InputEventKey.new()
		ev.physical_keycode = keycode
		InputMap.action_add_event(action, ev)

	# Añadir mouse para disparar
	if action == "shoot" and mouse_shoot:
		var mouse_ev := InputEventMouseButton.new()
		mouse_ev.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event(action, mouse_ev)

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("video", "show_fps", show_fps)
	cfg.set_value("video", "fps_limit", fps_limit)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("video", "brightness", brightness)
	cfg.set_value("audio", "master", volume_master)
	cfg.set_value("audio", "music", volume_music)
	cfg.set_value("audio", "sfx", volume_sfx)
	cfg.set_value("controls", "up", key_up)
	cfg.set_value("controls", "down", key_down)
	cfg.set_value("controls", "left", key_left)
	cfg.set_value("controls", "right", key_right)
	cfg.set_value("controls", "shoot", key_shoot)
	cfg.set_value("controls", "mouse_shoot", mouse_shoot)
	cfg.save(CONFIG_PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	show_fps = cfg.get_value("video", "show_fps", show_fps)
	fps_limit = cfg.get_value("video", "fps_limit", fps_limit)
	fullscreen = cfg.get_value("video", "fullscreen", fullscreen)
	brightness = cfg.get_value("video", "brightness", brightness)
	volume_master = cfg.get_value("audio", "master", volume_master)
	volume_music = cfg.get_value("audio", "music", volume_music)
	volume_sfx = cfg.get_value("audio", "sfx", volume_sfx)
	key_up = cfg.get_value("controls", "up", key_up)
	key_down = cfg.get_value("controls", "down", key_down)
	key_left = cfg.get_value("controls", "left", key_left)
	key_right = cfg.get_value("controls", "right", key_right)
	key_shoot = cfg.get_value("controls", "shoot", key_shoot)
	mouse_shoot = cfg.get_value("controls", "mouse_shoot", mouse_shoot)
