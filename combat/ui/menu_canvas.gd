extends CanvasLayer
class_name MenuCanvas

signal new_combat(_attacker:UnitStats, _defender:UnitStats)


const INFANTRY_COST  : int = 1
const CALVARY_COST   : int = 2
const ARTILLARY_COST : int = 2
const LEADER_COST    : int = 3

var is_player_attacker : bool = true
var points_infantry    : int = 0
var points_calvary     : int = 0
var points_artillary   : int = 0
var points_leader      : int = 0
var points_max         : int
var points_available   : int


func _ready() -> void:
	%PlayerOption.connect("item_selected", _on_player_option_changed)
	%PointsMax.connect("value_changed", _on_points_value_changed)
	%ResetPoints.connect("pressed", _on_reset_points_pressed)
	
	%InfantryCount.connect("value_changed", _on_infantry_count_changed)
	%CalvaryCount.connect("value_changed", _on_calvary_count_changed)
	%RangedCount.connect("value_changed", _on_artillary_count_changed)
	%LeaderCount.connect("value_changed", _on_leader_count_changed)
	
	%InfantryClear.connect("pressed", _on_infantry_clear_pressed)
	%CalvaryClear.connect("pressed", _on_calvary_clear_pressed)
	%RangedClear.connect("pressed", _on_artillary_clear_pressed)
	%LeaderClear.connect("pressed", _on_leader_clear_pressed)
	
	%StartGame.connect("pressed", _on_start_game_pressed)
	%StartGame.disabled = true
	
	%ExitGame.connect("pressed", _on_exit_game_pressed)
	
	# --
	points_max = %PointsMax.value
	_on_reset_points_pressed()


#region COMBAT
func get_unit_points_used() -> int:
	var infantry_cost  : int = points_infantry * INFANTRY_COST
	var calvary_cost   : int = points_calvary * CALVARY_COST
	var artillary_cost : int = points_artillary * ARTILLARY_COST
	return infantry_cost + calvary_cost + artillary_cost


func get_total_points_used() -> int:
	var infantry_cost  : int = points_infantry * INFANTRY_COST
	var calvary_cost   : int = points_calvary * CALVARY_COST
	var artillary_cost : int = points_artillary * ARTILLARY_COST
	var leader_cost    : int = points_leader * LEADER_COST
	return infantry_cost + calvary_cost + artillary_cost + leader_cost


func update_points_available() -> void:
	points_available = points_max - get_total_points_used()
	%PointsAvailable.text = "Points Available: " + str(points_available)
	
	%InfantryCount.editable = can_add_value(INFANTRY_COST)
	%CalvaryCount.editable  = can_add_value(CALVARY_COST)
	%RangedCount.editable   = can_add_value(ARTILLARY_COST)
	%LeaderCount.editable   = can_add_value(LEADER_COST)
	
	%StartGame.disabled = get_unit_points_used() == 0


func can_add_value(_value: int) -> bool:
	return points_available >= _value


func create_combat_demo() -> void:
	var attacker : UnitStats = _generate_combat_leader(is_player_attacker)
	var defender : UnitStats = _generate_combat_leader(not is_player_attacker)

	new_combat.emit(attacker, defender)	


func _generate_combat_leader(_is_human:bool) -> UnitStats:
	var player : Player = Preload.player.instantiate() as Player
	player.is_human = _is_human
	
	# -- Create leader..
	var stat : UnitStats = UnitStats.New_Unit(Term.UnitType.LEADER)
	stat.max_attached_units           = 24
	stat.stat_props.attacks_in_combat = points_leader + 1
	stat.stat_props.charisma          = floor(points_leader * 1.25)
	stat.stat_props.reputation        = floor(points_leader * 1.75)
	stat.player = player

	# -- Create army..
	var army : Array[UnitStats] = []
	
	# -- Infantry units..
	for i in range(points_infantry):
		army.append(UnitStats.New_Unit(Term.UnitType.INFANTRY, 2))

	# -- Calvary units..
	for i in range(points_calvary):
		army.append(UnitStats.New_Unit(Term.UnitType.CALVARY, 2))

	# -- Artillary units..
	for i in range(points_artillary):
		army.append(UnitStats.New_Unit(Term.UnitType.ARTILLARY, 2))

	# -- Attach units to leader..
	for unit : UnitStats in army:
		unit.player = player
		stat.attach_unit(unit)

	return stat

#endregion


#region EVENT HANDLERS
func _on_reset_points_pressed() -> void:
	%InfantryCount.value = 6
	%CalvaryCount.value  = 2
	%RangedCount.value   = 2
	%LeaderCount.value   = 2
		
	points_infantry  = 6
	points_calvary   = 2
	points_artillary = 2
	points_leader    = 2
	
	update_points_available()

	
func _on_exit_game_pressed() -> void:
	"""
	Exit game.
	"""
	get_tree().quit()
	

func _on_start_game_pressed() -> void:
	"""
	Start combat demo.
	"""
	create_combat_demo()


func _on_player_option_changed(_index:int) -> void:
	is_player_attacker = _index == 0
	
	if is_player_attacker:
		(%ComputerOption as OptionButton).selected = 1
	else:
		(%ComputerOption as OptionButton).selected = 0


func _on_points_value_changed(_value: float) -> void:
	points_max = int(_value)
	
	var points_used : int = points_available + get_total_points_used()
	if points_used >= points_max:
		%InfantryCount.value -= 1
		%CalvaryCount.value  -= 1
		%RangedCount.value   -= 1
		%LeaderCount.value   -= 1
		
		points_infantry  -= 1
		points_calvary   -= 1
		points_artillary -= 1
		points_leader    -= 1
	
	update_points_available()


func _on_infantry_count_changed(_value: float) -> void:
	points_infantry = int(_value)
	update_points_available()


func _on_infantry_clear_pressed() -> void:
	points_infantry = 0
	%InfantryCount.value = 0
	update_points_available()


func _on_calvary_count_changed(_value: float) -> void:
	points_calvary = int(_value)
	update_points_available()


func _on_calvary_clear_pressed() -> void:
	points_calvary = 0
	%CalvaryCount.value = 0
	update_points_available()


func _on_artillary_count_changed(_value: float) -> void:
	points_artillary = int(_value)
	update_points_available()


func _on_artillary_clear_pressed() -> void:
	points_artillary = 0
	%RangedCount.value = 0
	update_points_available()


func _on_leader_count_changed(_value: float) -> void:
	points_leader = int(_value)
	update_points_available()


func _on_leader_clear_pressed() -> void:
	points_leader = 0
	%LeaderCount.value = 0
	update_points_available()

#endregion
