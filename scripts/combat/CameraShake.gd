extends Camera2D
class_name CameraShake
## Travma tabanli sarsinti: offset = max * trauma^2 * noise.
## Savas sahnelerinde viewport merkezinde durur ("battle_camera" grubu);
## tetikleyiciler grup uzerinden erisir (sahne bagimliligi yok).

var trauma: float = 0.0
var trauma_power: float = 2.0
var decay: float = 0.8
var max_offset: Vector2 = Vector2(25, 25)
var max_roll: float = 0.05

static func find_camera(tree: SceneTree) -> CameraShake:
	if tree == null:
		return null
	return tree.get_first_node_in_group("battle_camera") as CameraShake

func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)

func _process(delta: float) -> void:
	if trauma > 0.0:
		trauma = maxf(0.0, trauma - decay * delta)
		var shake_amount := pow(trauma, trauma_power)
		offset.x = max_offset.x * shake_amount * randf_range(-1.0, 1.0)
		offset.y = max_offset.y * shake_amount * randf_range(-1.0, 1.0)
		rotation = max_roll * shake_amount * randf_range(-1.0, 1.0)
	else:
		offset = Vector2.ZERO
		rotation = 0.0
