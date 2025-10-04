extends CharacterBody3D

var player: Node3D
var state_machine
const SPEED := 4.0
const ATTACK_RANGE := 2.5

@export var player_path: NodePath = ^"/root/World/Map/NavigationRegion3D/Player"
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var anim_tree: AnimationTree = $AnimationTree

func _ready() -> void:
	player = get_node_or_null(player_path) as Node3D
	if player == null:
		player = get_node_or_null(^"../Player") as Node3D
	if player == null:
		push_error("ไม่พบ Player ที่: %s" % str(player_path))

	anim_tree.active = true
	state_machine = anim_tree.get("parameters/playback")

func _process(_delta: float) -> void:
	if player == null:
		return

	# เงื่อนไขเข้า state
	var in_range := global_position.distance_to(player.global_position) <= ATTACK_RANGE
	anim_tree.set("parameters/conditions/attack", in_range)
	anim_tree.set("parameters/conditions/run", not in_range)

	# บังคับ StateMachine ให้ตรงชื่อในกราฟ
	if state_machine:
		if in_range and state_machine.get_current_node() != "Armature|Armature|Attack":
			state_machine.travel("Armature|Armature|Attack")
		elif not in_range and state_machine.get_current_node() != "Running":
			state_machine.travel("Running")

	velocity = Vector3.ZERO

	match state_machine.get_current_node():
		"Running":
			# เดินตามผู้เล่นด้วย NavigationAgent3D
			nav_agent.target_position = player.global_position
			var next_nav_point := nav_agent.get_next_path_position()
			var dir := (next_nav_point - global_position)
			if dir.length() > 0.01:
				velocity = dir.normalized() * SPEED
				# หมุนหันทิศทางการเคลื่อนที่ (ใช้ _delta)
				var yaw := atan2(-velocity.x, -velocity.z)
				rotation.y = lerp_angle(rotation.y, yaw, _delta * 10.0)

		"Armature|Armature|Attack":
			# หันหน้าเข้าหาผู้เล่นขณะโจมตี
			var face := Vector3(player.global_position.x, global_position.y, player.global_position.z)
			look_at(face, Vector3.UP)

	move_and_slide()

func _hit_finished() -> void:
	if player and global_position.distance_to(player.global_position) <= ATTACK_RANGE + 1.0:
		var dir := global_position.direction_to(player.global_position)
		if "hit" in player:
			player.hit(dir)
