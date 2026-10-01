extends Node
class_name StateMachine
## Durumlar arasi gecis beyni. Altindaki State cocuklarini isme gore kaydeder,
## `initial_state` ile baslar. Her kafa karsisinda bir StateMachine vardir
## (Unit.tscn icinde).

@export var initial_state: State

var current_state: State
var states: Dictionary = {}

@onready var unit: Unit = get_parent() as Unit

func _ready() -> void:
	for child in get_children():
		if child is State:
			states[child.name] = child
			child.unit = unit
			child.state_machine = self
	if initial_state != null:
		change_state(initial_state.name)
	elif not states.is_empty():
		change_state(str(states.keys()[0]))

func change_state(new_state_name: String) -> void:
	if not states.has(new_state_name):
		push_error("StateMachine: durum yok: %s" % new_state_name)
		return
	if current_state != null:
		current_state.exit()
	current_state = states[new_state_name] as State
	current_state.enter()

func current_state_name() -> String:
	return current_state.name if current_state != null else ""

func _physics_process(delta: float) -> void:
	if current_state != null:
		current_state.physics_update(delta)

func _process(delta: float) -> void:
	if current_state != null:
		current_state.update(delta)
