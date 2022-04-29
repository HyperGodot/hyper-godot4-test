extends Node

@onready var map_test_environment = preload("res://game/maps/map_test/map_test.tscn")
@onready var map_cyber_environment = preload("res://game/maps/map_cyber/map_cyber.tscn")
@onready var map_cyber1_environment = preload("res://game/maps/map_cyber1/map_cyber1.tscn")

func _ready():
	pass

func _process(_delta):
	pass

func getSpawnLocation(_bodyNode, mapNode) -> Vector3:
	# Get Number of Maps
	var childCount : int = self.get_child(0).get_child_count()
	
	# Get Random Spawn Location from Map
	var playerSpawnNodes = mapNode.find_node("PlayerSpawnNodes", true, false)
	# Get Number of Spawn Nodes
	childCount = playerSpawnNodes.get_child_count()
	# Get Random Spawn Node
	var spawnNode : Node3D = playerSpawnNodes.get_child( randi() % childCount )
	
	# Return!
	return spawnNode.global_transform.origin
	
func PurgeAllWorldEnvironmentNodes():
	var worldEnvironment = get_tree().get_current_scene().get_node("Maps").get_node("map_test").get_node("WorldEnvironment")
	if(worldEnvironment != null):
		worldEnvironment.free()
	worldEnvironment = get_tree().get_current_scene().get_node("Maps").get_node("map_cyber").get_node("WorldEnvironment")
	if(worldEnvironment != null):
		worldEnvironment.free()
	worldEnvironment = get_tree().get_current_scene().get_node("Maps").get_node("map_cyber1").get_node("WorldEnvironment")
	if(worldEnvironment != null):
		worldEnvironment.free()
