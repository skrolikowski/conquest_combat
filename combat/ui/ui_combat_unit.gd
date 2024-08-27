extends Control
class_name UICombatUnit

@export var combat_unit : CombatUnit



func _ready() -> void:
	combat_unit.stat.connect("health_changed", _on_health_changed)
	
	var health     : int = combat_unit.stat.health
	var max_health : int = combat_unit.stat.level
	%HealthLabel.text = str(combat_unit.stat.health) + "*".repeat(max_health - health)


func _on_health_changed(_health:int, _max_health:int) -> void:
	%HealthLabel.text = str(_health) + "*".repeat(_max_health - _health)
