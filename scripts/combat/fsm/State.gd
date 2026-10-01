extends Node
class_name State
## Tum durumlarin tureyecegi temel sinif. Orneklenmez; Idle/Move/Attack/Dead
## bunu genisletir. `unit` ve `state_machine` StateMachine._ready'de atanir.

var unit: Unit
var state_machine: StateMachine

func enter() -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass
