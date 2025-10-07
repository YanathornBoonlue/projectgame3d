extends Node3D

@export var container: Node3D            # ลากโหนด Environment มาใส่
@export var sky_shader: Shader           # res://environment/SeaSky_sky.shader
@export var ocean_shader: Shader         # res://environment/SeaOcean.shader
@export var add_fog := true

func _ready() -> void:
	var target := container if container else get_parent() as Node3D
	if target == null:
		push_error("SetupSeaTheme: container not set."); return

	# WorldEnvironment
	if target.get_node_or_null("WorldEnvironment") == null:
		var we := WorldEnvironment.new()
		we.name = "WorldEnvironment"
		we.environment = Environment.new()
		target.add_child(we)
		var e := we.environment
		e.background_mode = Environment.BG_MODE_SKY
		if sky_shader:
			var sm := ShaderMaterial.new()
			sm.shader = sky_shader
			var sky := ShaderSky.new()
			sky.shader = sm
			e.sky = sky
		e.tonemap_mode = Environment.TONE_MAPPER_ACES
		e.tonemap_exposure = 0.10
		e.adjustment_enabled = true
		e.adjustment_saturation = 1.10
		e.glow_enabled = true
		e.glow_intensity = 1.10
		e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		e.ambient_light_energy = 0.8

	# Sea plane
	if target.get_node_or_null("SeaPlane") == null:
		var sea := MeshInstance3D.new()
		sea.name = "SeaPlane"
		var plane := PlaneMesh.new()
		plane.size = Vector2(600, 600)
		sea.mesh = plane
		sea.position.y = -10.0
		if ocean_shader:
			var om := ShaderMaterial.new()
			om.shader = ocean_shader
			sea.material_override = om
		target.add_child(sea)

	# Fog
	if add_fog and target.get_node_or_null("SeaFog") == null:
		var fog := FogVolume.new()
		fog.name = "SeaFog"
		fog.size = Vector3(1000, 30, 1000)
		fog.material = FogMaterial.new()
		var fm := fog.material as FogMaterial
		fm.density = 0.02
		fm.albedo = Color8(207, 233, 255, 204) # #cfe9ff ca. A~0.8
		fm.height_falloff = 0.2
		target.add_child(fog)

	# เสร็จแล้วลบตัวช่วย (ของที่สร้างอยู่ต่อ)
	queue_free()
