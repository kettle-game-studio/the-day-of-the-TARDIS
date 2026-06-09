extends Node

enum DeviceType {
	UNKNOWN = -1,
	KEYBOARD = 0,
	GAMEPAD = 1
}

signal device_changed(new_device: DeviceInfo)

var controls_help: Array[ActionDescriptor] = [
	ActionDescriptor.new(&"move_left", &"Влево"),
	ActionDescriptor.new(&"move_right", &"Вправо"),
	ActionDescriptor.new(&"move_forward", &"Вперёд"),
	ActionDescriptor.new(&"move_backward", &"Назад"),
	ActionDescriptor.new(&"run", &"Бег"),
	ActionDescriptor.new(&"jump", &"Прыжок"),
	ActionDescriptor.new(&"main_action", &"Поставить портал"),
	ActionDescriptor.new(&"restart_level", &"Перезапустить уровень"),
	ActionDescriptor.new(&"next_dialog", &"Следующий диалог"),
	ActionDescriptor.new(&"skip_dialog", &"Пропустить диалог"),
	#ActionDescriptor.new(&"rotate_left", &"Повернуть камеру влево"),
	#ActionDescriptor.new(&"rotate_right", &"Повернуть камеру вправо"),
	#ActionDescriptor.new(&"rotate_up", &"Повернуть камеру вверх"),
	#ActionDescriptor.new(&"rotate_down", &"Повернуть камеру вниз"),
]

class DeviceInfo:
	var type: DeviceType
	var index: int
	func _init(ttype: DeviceType, iindex: int):
		type = ttype
		index = iindex

var last_used_device: DeviceInfo = DeviceInfo.new(DeviceType.KEYBOARD, -1);

func _init():
	for action in InputMap.get_actions():
		for input in InputMap.action_get_events(action):
			if input is InputEventKey:
				add_action_input(DeviceType.KEYBOARD, action, PromptFont.get_bbcode_str("KEYBOARD_" + OS.get_keycode_string(input.physical_keycode).to_upper()))
			elif input is InputEventMouseButton:
				add_action_input(DeviceType.KEYBOARD, action, PromptFont.wrap_bbcode(mouse_buttons_icons[input.button_index]))
			elif input is InputEventJoypadButton:
				add_action_input(DeviceType.GAMEPAD, action, PromptFont.wrap_bbcode(joy_buttons_icons[input.button_index]))
			elif input is InputEventJoypadMotion:
				add_action_input(DeviceType.GAMEPAD, action, PromptFont.wrap_bbcode(joy_axis_icons[input.axis]))
			else:
				print_debug(input)

func _input(event):
	var device_type = device_type_from_event(event)
	if device_type == DeviceType.UNKNOWN:
		return
	var device_index = event.device
	if device_type != last_used_device.type or device_index != last_used_device.index:
		last_used_device = DeviceInfo.new(device_type, device_index)
		device_changed.emit(last_used_device)

func device_type_from_event(event: InputEvent):
	if event is InputEventKey or event is InputEventMouseButton:
		return DeviceType.KEYBOARD
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return DeviceType.GAMEPAD
	return DeviceType.UNKNOWN

func render_actions_table(label: RichTextLabel):
	label.push_table(5, INLINE_ALIGNMENT_CENTER)
	for cell in ["Действие", "   ", PromptFont.wrap_bbcode("%s+%s" % [PromptFont.DEVICE_KEYBOARD, PromptFont.DEVICE_MOUSE]), "  ", PromptFont.wrap_bbcode(PromptFont.DEVICE_GAMEPAD)]:
			label.push_cell()
			label.append_text("[center]%s[/center]" % cell)
			label.pop()
	for control in controls_help:
		for cell in [control.title, "   ", actions_maps[DeviceType.KEYBOARD].get(control.key, "-"), "   ", actions_maps[DeviceType.GAMEPAD].get(control.key, "-")]:
			label.push_cell()
			label.append_text("[center]%s[/center]" % cell)
			label.pop()
	label.pop()

func format_actions(text: String) -> String:
	return text.format(actions_maps[last_used_device.type])

	
var joy_buttons_icons: Dictionary = {
	JoyButton.JOY_BUTTON_A: PromptFont.GAMEPAD_A,
	JoyButton.JOY_BUTTON_B: PromptFont.GAMEPAD_B,
	JoyButton.JOY_BUTTON_X: PromptFont.GAMEPAD_X,
	JoyButton.JOY_BUTTON_Y: PromptFont.GAMEPAD_Y,
	JoyButton.JOY_BUTTON_BACK: PromptFont.GAMEPAD_SELECT,
	JoyButton.JOY_BUTTON_GUIDE: PromptFont.GAMEPAD_HOME,
	JoyButton.JOY_BUTTON_START: PromptFont.GAMEPAD_START,
	JoyButton.JOY_BUTTON_LEFT_STICK: PromptFont.ANALOG_L_CLICK,
	JoyButton.JOY_BUTTON_RIGHT_STICK: PromptFont.ANALOG_R_CLICK,
	JoyButton.JOY_BUTTON_LEFT_SHOULDER: PromptFont.XBOX_LEFT_SHOULDER,
	JoyButton.JOY_BUTTON_RIGHT_SHOULDER: PromptFont.XBOX_RIGHT_SHOULDER,
	JoyButton.JOY_BUTTON_DPAD_UP: PromptFont.DPAD_UP,
	JoyButton.JOY_BUTTON_DPAD_DOWN: PromptFont.DPAD_DOWN,
	JoyButton.JOY_BUTTON_DPAD_LEFT: PromptFont.DPAD_LEFT,
	JoyButton.JOY_BUTTON_DPAD_RIGHT: PromptFont.DPAD_RIGHT,
}

var joy_axis_icons: Dictionary = {
	JoyAxis.JOY_AXIS_LEFT_X: PromptFont.ANALOG_L_LEFT_RIGHT,
	JoyAxis.JOY_AXIS_LEFT_Y: PromptFont.ANALOG_L_UP_DOWN,
	JoyAxis.JOY_AXIS_RIGHT_X: PromptFont.ANALOG_R_LEFT_RIGHT,
	JoyAxis.JOY_AXIS_RIGHT_Y: PromptFont.ANALOG_R_UP_DOWN,
	JoyAxis.JOY_AXIS_TRIGGER_LEFT: PromptFont.XBOX_LEFT_TRIGGER,
	JoyAxis.JOY_AXIS_TRIGGER_RIGHT: PromptFont.XBOX_RIGHT_TRIGGER
}

var mouse_buttons_icons: Dictionary = {
	# Primary mouse button, usually assigned to the left button.
	MouseButton.MOUSE_BUTTON_LEFT: PromptFont.MOUSE_1,
	# Secondary mouse button, usually assigned to the right button.
	MouseButton.MOUSE_BUTTON_RIGHT: PromptFont.MOUSE_2,
	# Middle mouse button.
	MouseButton.MOUSE_BUTTON_MIDDLE: PromptFont.MOUSE_3,
	# Mouse wheel scrolling up.
	MouseButton.MOUSE_BUTTON_WHEEL_UP: PromptFont.MOUSE_SCROLL_UP,
	# Mouse wheel scrolling down.
	MouseButton.MOUSE_BUTTON_WHEEL_DOWN: PromptFont.MOUSE_SCROLL_DOWN,
	# Mouse wheel left button (only present on some mice).
	MouseButton.MOUSE_BUTTON_WHEEL_LEFT: PromptFont.MOUSE_SCROLL_LEFT,
	# Mouse wheel right button (only present on some mice).
	MouseButton.MOUSE_BUTTON_WHEEL_RIGHT: PromptFont.MOUSE_SCROLL_RIGHT,
	# Extra mouse button 1. This is sometimes present, usually to the sides of the mouse.
	MouseButton.MOUSE_BUTTON_XBUTTON1: PromptFont.MOUSE_4,
	# Extra mouse button 2. This is sometimes present, usually to the sides of the mouse.
	MouseButton.MOUSE_BUTTON_XBUTTON2: PromptFont.MOUSE_5
}

var actions_maps: Array[Dictionary] = [{},{}]

class ActionDescriptor:
	var title: StringName
	var key: StringName
	func _init(p_key: StringName, p_title: StringName) -> void:
		title = p_title
		key = p_key

func add_action_input(mapKey: DeviceType, action: StringName, input: String):
	var map = actions_maps[mapKey]
	if map.has(action):
		map[action] = map[action] + "/" + input
	else:
		map[action] = input

func start_joy_vibration(weak_magnitude: float, strong_magnitude: float, duration: float = 0):
	if last_used_device.type == DeviceType.GAMEPAD:
		Input.start_joy_vibration(last_used_device.index, weak_magnitude, strong_magnitude, duration)
