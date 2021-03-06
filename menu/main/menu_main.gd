extends Node

signal replace_main_scene
#warning-ignore:unused_signal
signal quit # Useless, but needed as there is no clean way to check if a node exposes a signal

@onready var ui = $CenterContainer
@onready var uiProper = $CenterContainer

@onready var main = uiProper.get_node("Main")
@onready var resume_button : Button = main.get_node("Resume")
@onready var settings_button : Button = main.get_node("Settings")
@onready var multiplayer_button : Button = main.get_node("Multiplayer")
@onready var quit_button : Button = main.get_node("Quit")

@onready var settings_menu = uiProper.get_node("Settings")
@onready var settings_actions = settings_menu.get_node("Actions")
@onready var settings_action_apply = settings_actions.get_node("Apply")
@onready var settings_action_cancel = settings_actions.get_node("Cancel")

@onready var multiplayer_menu = uiProper.get_node("Multiplayer")
@onready var multiplayer_menu_proper = multiplayer_menu.get_node("VBoxContainer")
@onready var multiplayer_LabelGWStatus = multiplayer_menu_proper.get_node("HyperGatewayStatus").get_node("LabelGWStatus")
@onready var multiplayer_StartGW = multiplayer_menu_proper.get_node("Gateway").get_node("Start")
@onready var multiplayer_StopGW = multiplayer_menu_proper.get_node("Gateway").get_node("Stop")
@onready var multiplayer_LabelGossipStatus = multiplayer_menu_proper.get_node("HyperGossipStatus").get_node("LabelGossipStatus")
@onready var multiplayer_PortInput = multiplayer_menu_proper.get_node("HyperGatewayPort").get_node("LineEdit")
@onready var multiplayer_GossipURLInput = multiplayer_menu_proper.get_node("GossipURL").get_node("LineEdit")
@onready var multiplayer_actions_ok = multiplayer_menu_proper.get_node("Actions").get_node("OK")

@onready var shadows_menu = settings_menu.get_node("Shadows")
@onready var shadows_4096 = shadows_menu.get_node("4096")
@onready var shadows_2048 = shadows_menu.get_node("2048")
@onready var shadows_1024 = shadows_menu.get_node("1024")
@onready var shadows_disabled = shadows_menu.get_node("Disabled")

@onready var gi_menu = settings_menu.get_node("GI")
@onready var gi_full = gi_menu.get_node("Full")
@onready var gi_half = gi_menu.get_node("Half")
@onready var gi_disabled = gi_menu.get_node("Disabled")

@onready var aa_menu = settings_menu.get_node("AA")
@onready var aa_8x = aa_menu.get_node("8x")
@onready var aa_4x = aa_menu.get_node("4x")
@onready var aa_2x = aa_menu.get_node("2x")
@onready var aa_disabled = aa_menu.get_node("Disabled")

@onready var bloom_menu = settings_menu.get_node("Bloom")
@onready var bloom_high = bloom_menu.get_node("High")
@onready var bloom_low = bloom_menu.get_node("Low")
@onready var bloom_disabled = bloom_menu.get_node("Disabled")

var hyperGatewayNode : HyperGateway = null
var hyperGatewayPID : int = 0
var hyperGatewayPort : int = 0

var hyperGossipNode : HyperGossip = null
var hyperGossipURL : String = ""

var hyperGWPortInputBackup : String = ""

var world_environment : WorldEnvironment = null

func _ready():
	# get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_2D, SceneTree.STRETCH_ASPECT_KEEP, Vector2(1440, 810))
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Setup Signals
	var callable
	callable = Callable(self, "_on_resume_pressed")
	resume_button.connect("pressed", callable)
	callable = Callable(self, "_on_settings_pressed")
	settings_button.connect("pressed", callable)
	callable = Callable(self, "_on_multiplayer_pressed")
	multiplayer_button.connect("pressed", callable)
	callable = Callable(self, "_on_quit_pressed")
	quit_button.connect("pressed", callable)
	
	callable = Callable(self, "_on_settings_apply_pressed")
	settings_action_apply.connect("pressed", callable)
	callable = Callable(self, "_on_settings_cancel_pressed")
	settings_action_cancel.connect("pressed", callable)
	
	callable = Callable(self, "_on_multiplayer_start_pressed")
	multiplayer_StartGW.connect("pressed", callable)
	callable = Callable(self, "_on_multiplayer_stop_pressed")
	multiplayer_StopGW.connect("pressed", callable)
	callable = Callable(self, "_on_multiplayer_ok_pressed")
	multiplayer_actions_ok.connect("pressed", callable)
	
func _getIsMenuShowing() -> bool:
	return ui.visible

func _on_quit_pressed():
	get_tree().quit()
	
func hideUI():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	ui.hide()
	
func showUI():
	# resetUI()
	ui.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
func resetUI():
	settings_menu.hide()
	multiplayer_menu.hide()
	main.show()

func _on_settings_pressed():
	main.hide()
	settings_menu.show()
	settings_action_cancel.grab_focus()
	
	# Find Environment Node
	if(world_environment == null or !is_instance_valid(world_environment) ):
		world_environment = get_tree().get_current_scene().find_child("WorldEnvironment", true, false)
	
	if Settings.gi_quality == Settings.GIQuality.HIGH:
		gi_full.button_pressed = true
	elif Settings.gi_quality == Settings.GIQuality.LOW:
		gi_half.button_pressed = true
	elif Settings.gi_quality == Settings.GIQuality.DISABLED:
		gi_disabled.button_pressed = true

	if Settings.aa_quality == Settings.AAQuality.AA_8X:
		aa_8x.button_pressed = true
	elif Settings.aa_quality == Settings.AAQuality.AA_4X:
		aa_4x.button_pressed = true
	elif Settings.aa_quality == Settings.AAQuality.AA_2X:
		aa_2x.button_pressed = true
	elif Settings.aa_quality == Settings.AAQuality.DISABLED:
		aa_disabled.button_pressed = true

	if Settings.bloom_quality == Settings.BloomQuality.HIGH:
		bloom_high.button_pressed = true
	elif Settings.bloom_quality == Settings.BloomQuality.LOW:
		bloom_low.button_pressed = true
	elif Settings.bloom_quality == Settings.BloomQuality.DISABLED:
		bloom_disabled.button_pressed = true
		
func _UpdateHyperGatewayInfo():
	multiplayer_StartGW.disabled = false
	multiplayer_StopGW.disabled = true
	multiplayer_LabelGWStatus.text = "Not Running"
	
	if(hyperGatewayNode != null):
		if(hyperGatewayNode is HyperGateway):
			hyperGatewayPID = hyperGatewayNode.getGatewayPID()
			hyperGatewayPort = hyperGatewayNode.getGatewayPort()
			
			if( hyperGatewayNode.getIsGatewayRunning() ):
				multiplayer_StopGW.disabled = false
				multiplayer_StartGW.disabled = true
				multiplayer_LabelGWStatus.text = "Running (PID " + str(hyperGatewayPID) + ") on Port " + str(hyperGatewayPort)
				
func _UpdateHyperGossipInfo():
	multiplayer_LabelGossipStatus.text = "N/A"
	if(hyperGossipNode != null):
		if(hyperGossipNode is HyperGossip):
			if( hyperGatewayNode.getIsGatewayRunning() ):
				hyperGossipURL = hyperGossipNode._get_url()
				multiplayer_LabelGossipStatus.text = hyperGossipURL
			

func _on_multiplayer_pressed():
	main.hide()
	# Check for HyperGateway Node
	if(hyperGatewayNode == null):
		hyperGatewayNode = get_tree().get_current_scene().find_child("HyperGateway")
	_UpdateHyperGatewayInfo()
	# Check for HyperGossip Node
	if(hyperGossipNode == null):
		hyperGossipNode = get_tree().get_current_scene().find_child("HyperGossip")
	_UpdateHyperGossipInfo()
	
			
	multiplayer_menu.show()
	
func ChangeGIProbeVisibility(_visible : bool):
	pass

func _on_settings_apply_pressed():
	main.show()
	# play_button.grab_focus()
	settings_menu.hide()
	
	if shadows_4096.button_pressed:
		Settings.shadows_quality = Settings.ShadowsQuality.SHADOWS_4096
		ProjectSettings["rendering/shadows/directional_shadow/size"] = 4096
		ProjectSettings["rendering/shadows/shadow_atlas/size"] = 4096
		ProjectSettings["rendering/shadows/directional_shadow/soft_shadow_quality"] = 2
	elif shadows_2048.button_pressed:
		Settings.shadows_quality = Settings.ShadowsQuality.SHADOWS_2048
		ProjectSettings["rendering/shadows/directional_shadow/size"] = 2048
		ProjectSettings["rendering/shadows/shadow_atlas/size"] = 2048
		ProjectSettings["rendering/shadows/directional_shadow/soft_shadow_quality"] = 2
	elif shadows_1024.button_pressed:
		Settings.shadows_quality = Settings.ShadowsQuality.SHADOWS_1024
		ProjectSettings["rendering/shadows/directional_shadow/size"] = 1024
		ProjectSettings["rendering/shadows/shadow_atlas/size"] = 1024
		ProjectSettings["rendering/shadows/directional_shadow/soft_shadow_quality"] = 2
	elif shadows_disabled.button_pressed:
		Settings.shadows_quality = Settings.ShadowsQuality.DISABLED
		ProjectSettings["rendering/shadows/directional_shadow/size"] = 0
		ProjectSettings["rendering/shadows/shadow_atlas/size"] = 0
		ProjectSettings["rendering/shadows/directional_shadow/soft_shadow_quality"] = 2

	if gi_full.button_pressed:
		Settings.gi_quality = Settings.GIQuality.HIGH
		ProjectSettings["rendering/quality/voxel_cone_tracing/high_quality"] = true
	elif gi_half.button_pressed:
		Settings.gi_quality = Settings.GIQuality.LOW
		ProjectSettings["rendering/quality/voxel_cone_tracing/high_quality"] = false
	elif gi_disabled.button_pressed:
		Settings.gi_quality = Settings.GIQuality.DISABLED

	if aa_8x.button_pressed:
		Settings.aa_quality = Settings.AAQuality.AA_8X
		ProjectSettings["rendering/anti_aliasing/quality/msaa"] = 3
		get_viewport().msaa = Viewport.MSAA_8X
	elif aa_4x.button_pressed:
		Settings.aa_quality = Settings.AAQuality.AA_4X
		ProjectSettings["rendering/anti_aliasing/quality/msaa"] = 2
		get_viewport().msaa = Viewport.MSAA_4X
	elif aa_2x.button_pressed:
		Settings.aa_quality = Settings.AAQuality.AA_2X
		ProjectSettings["rendering/anti_aliasing/quality/msaa"] = 1
		get_viewport().msaa = Viewport.MSAA_2X
	elif aa_disabled.button_pressed:
		Settings.aa_quality = Settings.AAQuality.DISABLED
		ProjectSettings["rendering/anti_aliasing/quality/msaa"] = 0
		get_viewport().msaa = Viewport.MSAA_DISABLED

	if bloom_high.button_pressed:
		Settings.bloom_quality = Settings.BloomQuality.HIGH
		if(world_environment != null):
			world_environment.environment.glow_enabled = true
			ProjectSettings["rendering/environment/glow/upscale_mode"] = 1
	elif bloom_low.button_pressed:
		Settings.bloom_quality = Settings.BloomQuality.LOW
		if(world_environment != null):
			world_environment.environment.glow_enabled = true
			ProjectSettings["rendering/environment/glow/upscale_mode"] = 0
	elif bloom_disabled.button_pressed:
		Settings.bloom_quality = Settings.BloomQuality.DISABLED
		if(world_environment != null):
			world_environment.environment.glow_enabled = false
			ProjectSettings["rendering/environment/glow/upscale_mode"] = 0

	Settings.save_settings()


func _on_settings_cancel_pressed():
	main.show()
	# play_button.grab_focus()
	settings_menu.hide()

func _on_multiplayer_ok_pressed():
	main.show()
	# play_button.grab_focus()
	multiplayer_menu.hide()


func _on_multiplayer_start_pressed():
	hyperGatewayNode.port = multiplayer_PortInput.text.to_int()
	hyperGossipNode.url = multiplayer_GossipURLInput.text
	hyperGatewayNode.start()
	_UpdateHyperGatewayInfo()
	_UpdateHyperGossipInfo()


func _on_multiplayer_stop_pressed():
	hyperGatewayNode.stop()
	_UpdateHyperGatewayInfo()
	_UpdateHyperGossipInfo()


func _on_HyperGWPort_LineEdit_text_changed(new_text : String):
	if(new_text.length() < 1 or new_text.is_valid_int() or new_text.to_int() > 65535):
		hyperGWPortInputBackup = new_text
	else:
		multiplayer_PortInput.text = hyperGWPortInputBackup


func _on_resume_pressed():
	# Hide UI (for now)
	hideUI()
