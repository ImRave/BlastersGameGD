extends Control

@onready var tab_container: TabContainer = $Panel/MarginContainer/VBox/TabContainer
@onready var back_button: Button = $Panel/MarginContainer/BackButton
@onready var click_sfx: AudioStreamPlayer2D = $sfx_PressButons

# --- VIDEO ---
@onready var fps_check: CheckBox = $Panel/MarginContainer/VBox/TabContainer/Video/VBox/FPSRow/FPSCheck
@onready var fps_option: OptionButton = $Panel/MarginContainer/VBox/TabContainer/Video/VBox/FPSRow/FPSOption
@onready var fullscreen_check: CheckBox = $Panel/MarginContainer/VBox/TabContainer/Video/VBox/FullscreenCheck
@onready var brightness_slider: HSlider = $Panel/MarginContainer/VBox/TabContainer/Video/VBox/BrightnessRow/BrightnessSlider
@onready var brightness_label: Label = $Panel/MarginContainer/VBox/TabContainer/Video/VBox/BrightnessRow/ValueLabel
@onready var more_button: Button = $Panel/MarginContainer/VBox/TabContainer/Video/MoreButton

# --- CONTROLS ---
@onready var up_button: Button = $Panel/MarginContainer/VBox/TabContainer/Controles/Grid/UpButton
@onready var down_button: Button = $Panel/MarginContainer/VBox/TabContainer/Controles/Grid/DownButton
@onready var left_button: Button = $Panel/MarginContainer/VBox/TabContainer/Controles/Grid/LeftButton
@onready var right_button: Button = $Panel/MarginContainer/VBox/TabContainer/Controles/Grid/RightButton
@onready var shoot_button: Button = $Panel/MarginContainer/VBox/TabContainer/Controles/Grid/ShootButton
@onready var mouse_check: CheckBox = $Panel/MarginContainer/VBox/TabContainer/Controles/MouseShootCheck

# --- AUDIO ---
@onready var master_slider: HSlider = $Panel/MarginContainer/VBox/TabContainer/Audio/VBox/MasterRow/MasterSlider
@onready var music_slider: HSlider = $Panel/MarginContainer/VBox/TabContainer/Audio/VBox/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $Panel/MarginContainer/VBox/TabContainer/Audio/VBox/SFXRow/SFXSlider
@onready var master_label: Label = $Panel/MarginContainer/VBox/TabContainer/Audio/VBox/MasterRow/ValueLabel
@onready var music_label: Label = $Panel/MarginContainer/VBox/TabContainer/Audio/VBox/MusicRow/ValueLabel
@onready var sfx_label: Label = $Panel/MarginContainer/VBox/TabContainer/Audio/VBox/SFXRow/ValueLabel

var awaiting_action: String = ""
var awaiting_button: Button = null

# Helper para reproducir el sonido sin repetir código
func _play_click() -> void:
	if click_sfx:
		click_sfx.play()

func _ready() -> void:
	# Forzar el tamaño de los sliders (evita que se vean como un punto)
	_force_slider_sizes()

	back_button.pressed.connect(_on_back)
	_setup_video()
	_setup_controls()
	_setup_audio()

func _force_slider_sizes() -> void:
	var sliders := [brightness_slider, master_slider, music_slider, sfx_slider]
	for s in sliders:
		s.custom_minimum_size = Vector2(280, 24)
		s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		s.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	for row_name in ["BrightnessRow", "MasterRow", "MusicRow", "SFXRow"]:
		var row := find_child(row_name, true, false)
		if row:
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			for c in row.get_children():
				if c is Label and c.name != "ValueLabel":
					c.custom_minimum_size.x = 140
				elif c is Label and c.name == "ValueLabel":
					c.custom_minimum_size.x = 60
					c.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

# =========================================================
#  VIDEO
# =========================================================
func _setup_video() -> void:
	fps_check.button_pressed = Globals.show_fps
	fps_check.toggled.connect(func(v):
		_play_click()
		Globals.show_fps = v
		Globals.save_settings()
	)

	fps_option.add_item("Sin límite", 0)
	fps_option.add_item("30 FPS", 30)
	fps_option.add_item("60 FPS", 60)
	fps_option.add_item("120 FPS", 120)
	fps_option.add_item("144 FPS", 144)
	for i in fps_option.item_count:
		if fps_option.get_item_id(i) == Globals.fps_limit:
			fps_option.select(i)
			break
	fps_option.item_selected.connect(func(i):
		_play_click()
		Globals.fps_limit = fps_option.get_item_id(i)
		Globals.apply_video()
		Globals.save_settings()
	)

	fullscreen_check.button_pressed = Globals.fullscreen
	fullscreen_check.toggled.connect(func(v):
		_play_click()
		Globals.fullscreen = v
		Globals.apply_video()
		Globals.save_settings()
	)

	brightness_slider.min_value = 0.3
	brightness_slider.max_value = 2.0
	brightness_slider.step = 0.05
	brightness_slider.value = Globals.brightness
	_update_brightness_label(Globals.brightness)
	brightness_slider.value_changed.connect(func(v):
		Globals.brightness = v
		_update_brightness_label(v)
		_apply_brightness(v)
		Globals.save_settings()
	)
	_apply_brightness(Globals.brightness)

	

func _update_brightness_label(v: float) -> void:
	brightness_label.text = "%d%%" % int(v * 100)

func _apply_brightness(v: float) -> void:
	var root := get_tree().current_scene
	if root:
		for child in root.find_children("*", "WorldEnvironment", true, false):
			if child.environment:
				child.environment.adjustment_enabled = true
				child.environment.adjustment_brightness = v

# =========================================================
#  CONTROLES
# =========================================================
func _setup_controls() -> void:
	up_button.text = Globals.key_up
	down_button.text = Globals.key_down
	left_button.text = Globals.key_left
	right_button.text = Globals.key_right
	shoot_button.text = Globals.key_shoot

	up_button.pressed.connect(func(): _start_rebind("up", up_button))
	down_button.pressed.connect(func(): _start_rebind("down", down_button))
	left_button.pressed.connect(func(): _start_rebind("left", left_button))
	right_button.pressed.connect(func(): _start_rebind("right", right_button))
	shoot_button.pressed.connect(func(): _start_rebind("shoot", shoot_button))

	mouse_check.button_pressed = Globals.mouse_shoot
	mouse_check.toggled.connect(func(v):
		_play_click()
		Globals.mouse_shoot = v
		Globals.apply_controls()
		Globals.save_settings()
	)

func _start_rebind(action: String, btn: Button) -> void:
	_play_click()
	awaiting_action = action
	awaiting_button = btn
	btn.text = "Pulsa una tecla..."

func _input(event: InputEvent) -> void:
	if awaiting_action == "":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			awaiting_action = ""
			_refresh_control_labels()
			get_viewport().set_input_as_handled()
			return
		_set_key(awaiting_action, event)
		awaiting_action = ""
		_refresh_control_labels()
		get_viewport().set_input_as_handled()

func _set_key(action: String, event: InputEventKey) -> void:
	var key_str := OS.get_keycode_string(event.physical_keycode)
	match action:
		"up": Globals.key_up = key_str
		"down": Globals.key_down = key_str
		"left": Globals.key_left = key_str
		"right": Globals.key_right = key_str
		"shoot": Globals.key_shoot = key_str
	Globals.apply_controls()
	Globals.save_settings()

func _refresh_control_labels() -> void:
	up_button.text = Globals.key_up
	down_button.text = Globals.key_down
	left_button.text = Globals.key_left
	right_button.text = Globals.key_right
	shoot_button.text = Globals.key_shoot

# =========================================================
#  AUDIO
# =========================================================
func _setup_audio() -> void:
	master_slider.min_value = 0
	master_slider.max_value = 1
	master_slider.step = 0.01
	master_slider.value = Globals.volume_master
	music_slider.min_value = 0
	music_slider.max_value = 1
	music_slider.step = 0.01
	music_slider.value = Globals.volume_music
	sfx_slider.min_value = 0
	sfx_slider.max_value = 1
	sfx_slider.step = 0.01
	sfx_slider.value = Globals.volume_sfx

	_update_audio_labels()
	master_slider.value_changed.connect(func(v):
		Globals.volume_master = v
		Globals.apply_audio()
		_update_audio_labels()
		Globals.save_settings()
	)
	music_slider.value_changed.connect(func(v):
		Globals.volume_music = v
		Globals.apply_audio()
		_update_audio_labels()
		Globals.save_settings()
	)
	sfx_slider.value_changed.connect(func(v):
		Globals.volume_sfx = v
		Globals.apply_audio()
		_update_audio_labels()
		Globals.save_settings()
	)

func _update_audio_labels() -> void:
	master_label.text = "%d%%" % int(Globals.volume_master * 100)
	music_label.text = "%d%%" % int(Globals.volume_music * 100)
	sfx_label.text = "%d%%" % int(Globals.volume_sfx * 100)

# =========================================================
#  BOTONES
# =========================================================
func _on_back() -> void:
	_play_click()
	Globals.save_settings()

	# Intenta volver al menú principal o al menú de pausa, el que exista
	var parent := get_parent()
	var target: Node = null

	if parent.has_node("MainMenu"):
		target = parent.get_node("MainMenu")
	elif parent.has_node("PauseMenu"):
		target = parent.get_node("PauseMenu")

	if target:
		target.visible = true

	self.visible = false

func _on_more_button_pressed() -> void:
	_play_click()
	$TextureRect2.visible = true
	await get_tree().create_timer(0.2).timeout
	$TextureRect2.visible = false
