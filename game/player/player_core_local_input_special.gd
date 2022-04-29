extends Node

var bDebugPaused : bool = false
var mouseModeBackup
var UINode = null

func _ready():
	bDebugPaused = false
	get_tree().paused = false
	mouseModeBackup = Input.get_mouse_mode()
	
func CheckAndUpdateUINode():
	if(UINode == null):
		UINode = get_tree().get_current_scene().get_node("UI").get_node("Menu_Main")
		
func HandleMouseToggle():
	if Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		mouseModeBackup = Input.get_mouse_mode()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(mouseModeBackup)
	
func _input(_event):
	if Input.is_action_just_pressed("ui_cancel"):
		# Toggle UI
		CheckAndUpdateUINode()
		if(UINode._getIsMenuShowing() ):
			UINode.hideUI()
		else:
			UINode.resetUI()
			UINode.showUI()
	if Input.is_action_just_pressed("toggleMouse"):
		# HandleMouseToggle()
		return

func _process(_delta):
	pass
