extends Node3D

@onready var collisionShape : CollisionShape3D = $spawnpad/spawn_pad/spawn_pad/CollisionShape3D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	# Disable Collision Mesh
	if(collisionShape != null):
		collisionShape.disabled = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
