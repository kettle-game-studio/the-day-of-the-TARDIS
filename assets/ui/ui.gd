extends CanvasLayer
class_name UIContoller

@onready var ui_dialog = $PanelContainer/UI/GridContainer/MarginContainer/DialogText

var formats = {
	"Doctor": {
		"format": "%s"
	},
	"TARDIS": {
		"format": "[i]%s[/i]"
	}
}

func display_speech_line(line: Dictionary):
	var who = line.get("who")
	ui_dialog.text = formats[who].format % line.get("text")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
