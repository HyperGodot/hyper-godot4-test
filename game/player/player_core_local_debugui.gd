extends Control

@onready var playerNode = get_tree().get_current_scene().get_node("Players").get_node("PlayerCoreLocal")

@onready var currentmapValue : Label = $Panel/MarginContainer/GridContainer/Current_Map_Value
@onready var inputValue : Label = $Panel/MarginContainer/GridContainer/Input_Value
@onready var velocityValue : Label = $Panel/MarginContainer/GridContainer/Velocity_Value
@onready var speedValue : Label = $Panel/MarginContainer/GridContainer/Speed_Value
@onready var onfloorValue : Label = $Panel/MarginContainer/GridContainer/OnFloor_Value


const EVENT_PLAYER_MAPCHANGE = 'player_mapchange'

var actualMapNode : Node
var hyperGossip : HyperGossip


func _ready():
	inputValue.text = str(Vector3.ZERO)
	velocityValue.text = str(Vector3.ZERO)
	onfloorValue.text = "N/A"
	
	# Update Actual Map Node
	actualMapNode = playerNode.currentMap
	
	# Get HyperGossip
	hyperGossip = get_tree().get_current_scene().get_node("HyperGodot").get_node("HyperGossip")

func _process(_delta):
	currentmapValue.text = str(playerNode.currentMap.map_name)
	inputValue.text = str(playerNode.currentDirection)
	velocityValue.text = str(playerNode.velocity)
	speedValue.text = str(playerNode.currentSpeed)
	if( playerNode.is_on_floor() ):
		onfloorValue.text = "Yes"
	else:
		onfloorValue.text = "No"

func _on_map_test_button_up():
	$Panel2/MarginContainer/GridContainer/map_test.release_focus()
	tryMapChange("map_test", true)

func _on_map_cyber_button_up():
	$Panel2/MarginContainer/GridContainer/map_cyber.release_focus()
	tryMapChange("map_cyber", true)
	
func _on_map_cyber1_button_up():
	$Panel2/MarginContainer/GridContainer/map_cyber1.release_focus()
	tryMapChange("map_cyber1", true)
	
func tryMapChange(mapChangeName : String, sendGossip : bool):
	var mapCurrentName = actualMapNode.name
	var _mapNode = null
	if(mapCurrentName != mapChangeName):
		actualMapNode.queue_free()
		if(mapChangeName == "map_test"):
			_mapNode = get_tree().get_current_scene().map_test
		elif(mapChangeName == "map_cyber"):
			_mapNode = get_tree().get_current_scene().map_cyber
		elif(mapChangeName == "map_cyber1"):
			_mapNode = get_tree().get_current_scene().map_cyber1
		# Update Current Map
		playerNode.currentMap = get_tree().get_current_scene().get_node("CurrentMap").get_child(1)
		# Update Actual Map
		actualMapNode = playerNode.currentMap
		# Find a Respawn Point
		playerNode.currentSpawnLocation = playerNode.getSpawnLocation()
		playerNode.playerWantsToRespawn = true
		
		if(sendGossip):
			var data : Dictionary = {
			"map": {
				"name": mapChangeName
				}
			}
			hyperGossip.broadcast_event(EVENT_PLAYER_MAPCHANGE, data)
