extends CharacterBody3D

var hyperGossip : HyperGossip

# TODO : These probably should not be in player_core, though I am uncertain yet if they belong elsewhere
const EVENT_PLAYER_SNAPSHOT = 'player_snapshot'
const EVENT_PLAYER_WANTSTOJUMP = 'player_wantstojump'
const EVENT_PLAYER_DIRECTION = 'player_direction'
const EVENT_PLAYER_RESPAWNPLAYER = 'player_respawnplayer'
const EVENT_PLAYER_SHOOT_GRAPPLINGHOOK = 'player_shoot_grapplinghook'
const EVENT_PLAYER_RELEASE_GRAPPLINGHOOK = 'player_release_grapplinghook'
const EVENT_PLAYER_TOGGLE_LIGHT = 'player_toggle_light'

@export var mouseSensitivity : float = 0.3
@export var movementSpeed : float = 14
@export var fallAcceleration : float = 27
@export var movementAcceleration : float = 4
@export var canJumpHeight : float = 10
@export var jumpHeight : float = 15
@export var turn_velocity : float = 15
@export var cameraLerpAmount : float = 40
@export var currentSpeed : float = 0

@onready var meshNode : Node3D = $Model
@onready var meshSkeletonNode : Skeleton3D = $Model/Armature/Skeleton3D
@onready var meshSkeletalIKNode : SkeletonIK3D = $Model/Armature/Skeleton3D/SkeletonIK3D
@onready var meshSkeletonHiddenHand : MeshInstance3D = $Model/Armature/Skeleton3D/player001
@onready var meshHandBone : int = meshSkeletonNode.find_bone("DEF-hand.R")
@onready var meshHandBonePos : Transform3D = meshSkeletonNode.get_bone_pose(meshHandBone)

@onready var clippedCamera : Node3D = $CameraHead/CameraPivot/ClippedCamera
@onready var clippedCameraHead : Node3D = $CameraHead
@onready var clippedCameraPivot : Node3D = $CameraHead/CameraPivot

@onready var meshCollisionShape : CollisionShape3D = $CollisionShape

@onready var grappleHookCast : RayCast3D = $CameraHead/CameraPivot/GrappleHookCast

@onready var grappleVisualPoint_1 = $GrapplingHook/GrappleVisualPoint_1
# onready var grappleVisualPoint_2 = $GrapplingHook/GrappleVisualPoint_2
@onready var grappleVisualPoint = grappleVisualPoint_1

@onready var grappleLineHelper : Node3D = $Model/GrappleLineHelper
@onready var grappleVisualLine : CSGCylinder3D = $Model/GrappleLineHelper/GrappleVisualLine_1
# onready var grappleVisualLine : = $Model/GrappleLineHelper/GrappleVisualLine_2

@onready var grappleIKTarget : Position3D = $GrapplingHook/IKTarget
@onready var grapplingHandOriginalScale : Vector3 = Vector3.ZERO

@onready var omniLight : OmniLight3D = $OmniLight

var grapplingHook_GrapplePosition : Vector3 = Vector3.ZERO
var grapplingHook_IsHooked : bool = false
var playerWantsToShootGrapplingHook : bool = false
var playerWantsToReleaseGrapplingHook : bool = false

# TODO : Make Debug UI dynamic and not hardcoded in the core Hyper scripts.
#onready var hyperdebugui : Control = $HyperGodotDebugUI
#onready var hyperdebugui_gateway_startstop_button : Button = $HyperGodotDebugUI/HypercoreDebugPanel/HypercoreDebugContainer/GatewayStartStopButton
#onready var hyperdebugui_gossipid_list : ItemList = get_tree().get_current_scene().get_node("HyperGodot").get_node("HyperGateway")

@onready var currentMap = get_tree().get_current_scene().get_node("Maps").get_child(0)
var originalOrigin : Vector3 = Vector3.ZERO
var currentSpawnLocation : Vector3 = Vector3.ZERO

var currentDirection : Vector3 = Vector3.ZERO
var moveNetworkUpdateAllowed : bool = true

var playerWantsToRespawn : bool = false
var jumpFloorDirection : Vector3 = Vector3(0,1,0)
var playerWantsToJump : bool = false

var playerWantsNewWorldEnvironment : bool = true
var playerWantsToToggleLight : bool = false

var f_input : float
var h_input : float

var snapVector : float

var collisions : Dictionary = {}

# TODO : Godot 4 cannot parse this particle format
# var Particles_Land = preload("res://game/player/particles.tscn")

func _ready():
	# Sanitize Velocity
	velocity = Vector3.ZERO
	# Backup Origin
	originalOrigin = self.position
	
	# Spawn into Map
	currentSpawnLocation = getSpawnLocationForMapName(currentMap.map_name)
	playerWantsToRespawn = true
	
	# Get HyperGossip
	hyperGossip = get_tree().get_current_scene().get_node("HyperGodot").get_node("HyperGossip")
	
func snapShotUpdate(_position : Vector3, _meshDirection : Vector3, _lookingDirection : Vector3):
	self.position = _position
	self.meshNode.rotation = _meshDirection
	self.currentDirection = _lookingDirection

func directionUpdate(_direction : Vector3):
	self.currentDirection = _direction
	
func getSpawnLocationForMapName(mapName : String) -> Vector3:
	# Get Map Node
	var mapNodes = get_tree().get_current_scene().get_node("Maps").find_children(mapName, "", true, false)
	if(mapNodes == null or mapNodes.size() == 0):
		return get_tree().get_current_scene().get_node("Maps").get_node("map_test").getSpawnLocation()
	else:
		return mapNodes[0].getSpawnLocation()

func _process(_delta):
	if(currentDirection != Vector3.ZERO):
		meshNode.rotation.y = lerp_angle(meshNode.rotation.y, atan2(-currentDirection.x, -currentDirection.z), turn_velocity * _delta)
	
func grapplingHook_Process():
	grapplingHook_CheckActivation()
	var length : float = grapplingHook_UpdatePlayerVelocityAndReturnHookLength()
	grapplingHook_UpdateVisualLine(length)
	# TODO : BIG Hack to prevent running on remote players
	var _name = self.name
	if(self.name == "PlayerCoreLocal"):
		grapplingHook_UpdateVisualPoint()
	
func grapplingHook_CheckActivation():
	# Activate hook
	if(playerWantsToShootGrapplingHook):
		playerWantsToShootGrapplingHook = false
		playerWantsToReleaseGrapplingHook = false
		grapplingHook_IsHooked = true
		grappleVisualLine.show()
		$Model/Sound_Shoot_GrapplingHook_2.play()
		grappleIKTarget.position = grapplingHook_GrapplePosition
		grapplingHook_DisappearHand()
		
	elif(playerWantsToReleaseGrapplingHook):
		# Stop grappling
		if(grapplingHook_IsHooked):
			grapplingHook_IsHooked = false
			playerWantsToReleaseGrapplingHook = false
			grappleVisualLine.hide()
			$Model/Sound_Release_GrapplingHook.play()
			grapplingHook_ReappearHand()
	
func grapplingHook_UpdateVisualPoint():
	if grappleHookCast.is_colliding():
		grappleVisualPoint.visible = true
		grappleVisualPoint.position = grappleHookCast.get_collision_point()
	else:
		grappleVisualPoint.visible = false
		
func grapplingHook_UpdateVisualLine(length : float):
	if(grapplingHook_IsHooked):
		grappleLineHelper.look_at(grapplingHook_GrapplePosition, Vector3.UP)
		grappleVisualLine.height = length
		grappleVisualLine.position.z = length / -1.80
		
func grapplingHook_UpdatePlayerVelocityAndReturnHookLength() -> float:
	var grapple_speed : float = 0.5
	var rest_length : float = 1
	var max_grapple_speed : float = 2.75
	
	var player2hook := grapplingHook_GrapplePosition - position # vector from player to hook
	var length := player2hook.length()
	if(grapplingHook_IsHooked):
		# if we more than 4 away from line, don't dampen speed as much
		if(length > 4):
			velocity *= .999
		# Otherwise dampen speed more
		else:
			velocity *= .9
		
		# Hook's law equation
		var force := grapple_speed * (length - rest_length)
		
		# Clamp force to be less than max_grapple_speed
		if abs(force) > max_grapple_speed:
			force = max_grapple_speed
		
		# Preserve direction, but scale by force
		velocity += player2hook.normalized() * force
	
	return length
	
func grapplingHook_DisappearHand():
	meshSkeletonHiddenHand.visible = false
	#var bone = meshSkeletonNode.find_bone("DEF-hand.R")
	#var bonePos = meshSkeletonNode.get_bone_pose(bone)
	#bonePos = bonePos.scaled( Vector3(0.1, 0.1, 0.1) )
	#meshSkeletonNode.set_bone_custom_pose(bone, bonePos)
	
func grapplingHook_ReappearHand():
	meshSkeletonHiddenHand.visible = true
	#var bone = meshSkeletonNode.find_bone("DEF-hand.R")
	#var bonePos = meshSkeletonNode.get_bone_pose(bone)
	#bonePos = bonePos.( Vector3(1, 1, 1) )
	#meshSkeletonNode.set_bone_custom_pose(bone, bonePos)

var jumpingUp : bool
func _physics_process(_delta):
	# Respawn Player here first
	if(playerWantsToRespawn):
		playerWantsToRespawn = false
		respawnPlayer()
		return
	
	# Check for New World Environment
	if(playerWantsNewWorldEnvironment):
		playerWantsNewWorldEnvironment = false
		currentMap.updateMapWorldEnvironmentScene()
		
	# Check for Toggle Light
	if(playerWantsToToggleLight):
		playerWantsToToggleLight = false
		omniLight.visible = !omniLight.visible
		$Model/Sound_ToggleLight_1.play()
	
	# Moving the character
	# Do NOT interpolate gravity / jumping / falling, so backup the y velocity
	var y_cache : float = velocity.y
	velocity = velocity.lerp(currentDirection * movementSpeed, movementAcceleration * _delta)
	# Restore the y velocity after the interpolation, since we don't interpolate gravity / jumping / falling
	velocity.y = y_cache
	
	# Vertical velocity
	if(!grapplingHook_IsHooked):
		# Apply Gravity
		velocity.y -= fallAcceleration * _delta
		# Check for a Jump
		if(playerWantsToJump):
			playerWantsToJump = false
			if( playerCanJump() ):
				velocity.y = jumpHeight
				jumpingUp = true
				$Model/Sound_Jump.play()
	var bPrevOnFloor = is_on_floor()
	y_cache = velocity.y
	move_and_slide()
	if( !bPrevOnFloor and is_on_floor() and y_cache < -17.0):
		# var particles = Particles_Land.instance()
		#$Model.add_child(particles)
		$Model/Sound_Land.play()
	
	# Calculate Potential Jumping Animation
	if( !is_on_floor() ):
		if(velocity.y > 0.1):
			$AnimationTree.set("parameters/air_transition/current", 0)
			$AnimationTree.set("parameters/air_blend/blend_amount", -1)
		elif(velocity.y < -0.1):
			$AnimationTree.set("parameters/air_transition/current", 0)
			$AnimationTree.set("parameters/air_blend/blend_amount", 0)
	else:
		$AnimationTree.set("parameters/air_transition/current", 1)
	
	# Calculate Running Animation
	currentSpeed = ( (abs(velocity.x) + abs(velocity.z) - 7) / 7)
	$AnimationTree.set("parameters/iwr_blend/blend_amount", currentSpeed)
	
	# Update Grappling Hook
	grapplingHook_Process()
	
	# Check for Hand IK from Grappling Hook
	if(grapplingHook_IsHooked):
		meshSkeletalIKNode.start()
	else:
		meshSkeletalIKNode.stop()
		
	
	#	self.linear_velocity.y += jumpHeight
	#	playerWantsToJump = false
		
	#var y_cache = linear_velocity.y
	#linear_velocity = linear_velocity.linear_interpolate(currentDirection * movementSpeed, movementAcceleration * _delta)
	#linear_velocity.y = y_cache
	#linear_velocity = Vector3(currentDirection.x, 0, currentDirection.z).normalized() * movementSpeed * _delta
	#linear_velocity.y = y_cache
	
	#linear_velocity.x += currentDirection.x * movementSpeed * _delta
	#linear_velocity.x = clamp(linear_velocity.x, -3, 3)
	#linear_velocity.z += currentDirection.z * movementSpeed * _delta
	#linear_velocity.z = clamp(linear_velocity.z, -3, 3)
	
	# Handle Jumping / Gravity
	#if is_on_floor():
	#if true:
	#	snapVector = -get_floor_normal()
	#	gravity_vec = Vector3.ZERO
	#else:
	#	snap = Vector3.DOWN
	#	accel = ACCEL_AIR
	#	gravity_vec += Vector3.DOWN * gravity * delta
		
	#if Input.is_action_just_pressed("jump") and is_on_floor():
	#	snap = Vector3.ZERO
	#	gravity_vec = Vector3.UP * jump
	
	# Actually Movement
	#velocityAmount = velocityAmount.linear_interpolate(currentDirection * movementSpeed, accelerationDefault * delta)
	# finalMovement = velocityAmount + finalgravityVelociy
	
func respawnPlayer():
	velocity = Vector3.ZERO
	grapplingHook_IsHooked = false
	playerWantsToShootGrapplingHook = false
	playerWantsToReleaseGrapplingHook = true
	$Model/Sound_Teleport_1.play()
	global_transform.origin = currentSpawnLocation

func playerCanJump() -> bool:
	if( self.is_on_floor() ):
		return true
	else:
		return false

func _on_input_player_mousemotion_event(event):
	clippedCameraHead.rotate_y(deg2rad(-event.relative.x * mouseSensitivity))
	clippedCameraPivot.rotate_x(deg2rad(-event.relative.y * mouseSensitivity))
	clippedCameraPivot.rotation.x = clamp(clippedCameraPivot.rotation.x, deg2rad(-89), deg2rad(89))


func _on_input_player_move(direction : Vector3):
	currentDirection = direction
	
	if(moveNetworkUpdateAllowed):
		hyperGossip.broadcast_event(EVENT_PLAYER_DIRECTION, getPlayerLocalCoreNetworkData() )
		moveNetworkUpdateAllowed = false
	#var h_rot = clippedCameraHead.global_transform.basis.get_euler().y
	# Adjust Current Direction based on Mouse Direction
	#currentDirection = Vector3(direction.x, 0, direction.z).rotated(Vector3.UP, h_rot).normalized()


func _on_input_player_respawn_player() -> void:
	playerWantsToRespawn = true
	var spawnLocation : Vector3 = getSpawnLocationForMapName(currentMap.map_name)
	currentSpawnLocation = spawnLocation
	
	var data : Dictionary = {
	#"profile": profile,
	"spawnLocation": {
		"x": spawnLocation.x,
		"y": spawnLocation.y,
		"z": spawnLocation.z
		}
	}
	
	hyperGossip.broadcast_event(EVENT_PLAYER_RESPAWNPLAYER, data)

func _on_input_player_jump():
	playerWantsToJump = true
	hyperGossip.broadcast_event(EVENT_PLAYER_WANTSTOJUMP, getPlayerLocalCoreNetworkData() )
	
func _on_input_player_shoot_grapplinghook():
	if( Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE ):
		if( grappleHookCast.is_colliding() ):
			playerWantsToShootGrapplingHook = true
			grapplingHook_GrapplePosition = grappleHookCast.get_collision_point()
			hyperGossip.broadcast_event(EVENT_PLAYER_SHOOT_GRAPPLINGHOOK, getPlayerLocalShootGrapplingHookData() )
			
func _on_input_player_release_grapplinghook():
	if( Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE ):
		if(grapplingHook_IsHooked):
			playerWantsToReleaseGrapplingHook = true
			hyperGossip.broadcast_event(EVENT_PLAYER_RELEASE_GRAPPLINGHOOK, getPlayerLocalCoreNetworkData() )
			
func _on_input_player_toggle_light():
	playerWantsToToggleLight = true
	hyperGossip.broadcast_event(EVENT_PLAYER_TOGGLE_LIGHT, getPlayerLocalCoreNetworkData() )

func _on_Player_body_entered(body : Node) -> void:
	if(!collisions.has(body.get_instance_id()) ):
		collisions[body.get_instance_id()] = body.name
		$CollisionUI.onNewollision(body, collisions)
		

func _on_Player_body_exited(body : Node) -> void:
	if(collisions.has(body.get_instance_id()) ):
		collisions.erase(body.get_instance_id())
		$CollisionUI.onRemovedCollision(body, collisions)

func _on_MoveNetworkTimer_timeout():
	moveNetworkUpdateAllowed = true
	
func getPlayerLocalCoreNetworkData() -> Dictionary:
	# TODO : Fix finding the local player, and get it out of player_core into player_core_local
	var localPlayer : CharacterBody3D = get_tree().get_current_scene().get_node("Players").get_node("PlayerCoreLocal")
	var _position : Vector3 = localPlayer.position
	var direction : Vector3 = localPlayer.currentDirection

	var data : Dictionary = {
	#"profile": profile,
	"position": {
		"x": _position.x,
		"y": _position.y,
		"z": _position.z
		},
	"direction": {
		"x": direction.x,
		"y": direction.y,
		"z": direction.z
		},
	"velocity": {
		"x": velocity.x,
		"y": velocity.y,
		"z": velocity.z
		}
	}

	return data
	
func getPlayerLocalShootGrapplingHookData() -> Dictionary:
	# TODO : Fix finding the local player, and get it out of player_core into player_core_local
	var localPlayer : CharacterBody3D = get_tree().get_current_scene().get_node("Players").get_node("PlayerCoreLocal")
	var _position : Vector3 = localPlayer.position
	var direction : Vector3 = localPlayer.currentDirection

	var data : Dictionary = {
	#"profile": profile,
	"position": {
		"x": _position.x,
		"y": _position.y,
		"z": _position.z
		},
	"direction": {
		"x": direction.x,
		"y": direction.y,
		"z": direction.z
		},
	"velocity": {
		"x": velocity.x,
		"y": velocity.y,
		"z": velocity.z
		},
	"grapple_position": {
		"x": grapplingHook_GrapplePosition.x,
		"y": grapplingHook_GrapplePosition.y,
		"z": grapplingHook_GrapplePosition.z
		}
	}

	return data

func playerCoreNetworkDataUpdate(data : Dictionary):
	self.position = Vector3(data.position.x, data.position.y, data.position.z)
	self.currentDirection = Vector3(data.direction.x, data.direction.y, data.direction.z)
	self.velocity = Vector3(data.velocity.x, data.velocity.y, data.velocity.z)

func playerCoreNetworkDataUpdate_Types(_position : Vector3, _currentDirection : Vector3, _kinematicVelocity : Vector3):
	self.position = _position
	self.currentDirection = _currentDirection
	self.velocity = _kinematicVelocity
