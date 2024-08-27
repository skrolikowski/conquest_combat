extends Resource
class_name UnitStats

signal health_changed(_health:int, _max_health:int)

@export var title         : String
@export var unit_name     : String
@export var unit_type     : Term.UnitType = Term.UnitType.NONE
@export var unit_state    : Term.UnitState = Term.UnitState.IDLE
@export var unit_category : Term.UnitCategory = Term.UnitCategory.NONE

var player    : Player
var level     : int : set = _set_level
var max_level : int = 5
var health    : int : set = _set_health

# -- Non-Leader Units only..
var leader : UnitStats

# -- Leader Units only..
var stat_points	: int = 0
var stat_props  : Dictionary = {
	"attacks_in_combat": 0,
	"move_bonus": 0,
	"charisma": 0,
	"reputation": 0
}


func _set_level(_level : int) -> void:
	level  = _level
	_set_health(level)
	

func _set_health(_health : int) -> void:
	if health != _health:
		health = _health
		health_changed.emit(health, level)

func level_up() -> void:
	level = min(level + 1, max_level)


func heal() -> void:
	health = min(health + 1, level)


func is_dead() -> bool:
	return health <= 0


func get_population() -> int:
	return get_stat().population


func get_stat() -> Dictionary:
	return Def.get_unit_stat(unit_type, level)


#func get_cost() -> Transaction:
	#return Def.get_unit_cost(unit_type, level)


#region COMBAT
var combat_stats : Dictionary = {
	"battles": 0,
	"battles_won": 0,
}
#endregion


#region UNIT ATTACHMENT
@export var attached_units : Array[UnitStats] = []
var max_attached_units : int = 0

func attach_unit(_unit: UnitStats) -> void:
	if not has_capacity():
		return
	
	_unit.leader = self
	attached_units.append(_unit)


func detach_unit(_unit:UnitStats) -> void:
	if attached_units.has(_unit):
		_unit.leader = null
		attached_units.erase(_unit)


func can_attach_units() -> bool:
	return unit_type == Term.UnitType.LEADER or unit_type == Term.UnitType.SHIP


func has_capacity() -> bool:
	if not can_attach_units():
		return false
		
	return attached_units.size() < max_attached_units
#endregion


#region STATIC METHODS
static func New_Unit(_unit_type : Term.UnitType, _level : int=1) -> UnitStats:
	var r:UnitStats = UnitStats.new()
	r.title      = Def.get_unit_name_by_unit_type(_unit_type)
	r.unit_type  = _unit_type
	r.unit_state = Term.UnitState.IDLE
	r.level      = _level
	return r

#endregion
