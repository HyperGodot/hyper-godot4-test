extends Node3D

@onready var playerSpawnNodes : Node = get_node("PlayerSpawnNodes")

@export var map_name : String = ""

func _ready():
	randomize()
	addGrapplingHookCollisionMaskToMap()

func _process(_delta):
	pass
	
func getSpawnLocation() -> Vector3:
	var childCount : int = playerSpawnNodes.get_child_count()
	var spawnNode : Node3D = playerSpawnNodes.get_child( randi() % childCount )
	return spawnNode.global_transform.origin
	
func getInstanceOfMapWorldEnvironmentScene():
	# var new_environment_node = WorldEnvironment.new()
	var path = "res://assets/maps/" + map_name + "/" + map_name + "_environment.scn"
	var newNode = load(path).instantiate()
	# new_environment_node.environment = load(path)
	# new_environment_node.name = "WorldEnvironment"
	
	return newNode
	
func updateMapWorldEnvironmentScene():
	# First check to see if we need to delete any existing World Environments
	get_tree().get_current_scene().PurgeAllWorldEnvironmentNodes()
		
	# Spawn in new World Environment
	var worldEnvironment = getInstanceOfMapWorldEnvironmentScene()
	if(worldEnvironment != null):
		add_child(worldEnvironment)

func addGrapplingHookCollisionMaskToMap():
	var _name = self.name
	# var currentMap : Node = get_tree().get_current_scene().get_node("Maps").find_node(_name, true, false)
	# var assetMap : Spatial = currentMap.find_node("asset_" + currentMap.name)
	checkAndSetChildrenGrapplingHookMask(self, 0)
				
func checkAndSetChildrenGrapplingHookMask(_Node, indentLevel : int):
	var _strIndents : String = ""
	for _i in range(indentLevel):
		_strIndents += "\t"
		
	if(_Node is StaticBody3D):
		_Node.collision_layer += 2
		
	var childCount = _Node.get_child_count()
	for i in range(childCount):
		checkAndSetChildrenGrapplingHookMask(_Node.get_child(i), indentLevel + 1)


func _on_Area_body_entered(body, _map_name):
	if(body is CharacterBody3D):
		var mapNodes = get_tree().get_current_scene().get_node("Maps").find_children(_map_name, "", true, false)
		for i in range(0, mapNodes.size()):
			if mapNodes[i].name == _map_name:
				body.currentMap = mapNodes[i]
				body.playerWantsNewWorldEnvironment = true
		
