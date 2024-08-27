extends CanvasLayer
class_name CombatCanvas

signal end_combat

var combat : Combat : set = _set_combat


func _ready() -> void:
	%ExitGame.connect("pressed", _on_exit_game_pressed)
	%Undo.connect("pressed", _on_undo_pressed)
	%Retreat.connect("pressed", _on_retreat_pressed)
	%EndTurn.connect("pressed", _on_end_turn_pressed)


func _set_combat(_combat: Combat) -> void:
	
	# --
	if combat != null:
		if combat.is_connected("combat_ended", _on_combat_ended):
			combat.disconnect("combat_ended", _on_combat_ended)
		if combat.is_connected("turn_started", _on_combat_turn_started):
			combat.disconnect("turn_started", _on_combat_turn_started)
		if combat.is_connected("square_attacked", _on_combat_square_attacked):
			combat.disconnect("square_attacked", _on_combat_square_attacked)
		if combat.is_connected("square_occupied", _on_combat_square_occupied):
			combat.disconnect("square_occupied", _on_combat_square_occupied)
		if combat.is_connected("movement_undone", _on_combat_movement_undone):
			combat.disconnect("movement_undone", _on_combat_movement_undone)
	
	# --
	combat = _combat
	
	%StatusInformation.text = "Two Armies Enter, One Army Leaves"
	
	# --
	flash_message("FIGHT!", 0.5)
	
	# --
	combat.connect("combat_ended", _on_combat_ended)
	combat.connect("turn_started", _on_combat_turn_started)
	combat.connect("square_attacked", _on_combat_square_attacked)
	combat.connect("square_occupied", _on_combat_square_occupied)
	combat.connect("movement_undone", _on_combat_movement_undone)


func flash_message(_message: String, _delay: float, _callback:Callable = Callable()) -> void:
	var _on_flash_finished : Callable = func() -> void:
		%FlashMessage.hide()
		if not _callback.is_null():
			_callback.call()
	
	%FlashMessage.text = _message
	%FlashMessage.modulate = Color(Color.RED, 0.0)
	%FlashMessage.show()
	
	var tween : Tween = create_tween()
	tween.tween_property(%FlashMessage, "modulate", Color(Color.RED, 1.0), _delay)
	tween.tween_property(%FlashMessage, "modulate", Color(Color.RED, 0.0), _delay)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(_on_flash_finished)


#region EVENT HANDLERS
func _on_combat_turn_started(_turn_group: CombatGroup, _defend_group: CombatGroup) -> void:
	"""
	[EVENT]
	
	CombatGroup turn has started.
	"""
	
	if combat.turn_group.is_human_player():
		%TurnInformation.text = "Player's Turn"
	else:
		%TurnInformation.text = "AI's Turn"
		
	%AttacksLeft.text = str(_turn_group.num_attacks) + " Attacks Left"
	
	%Undo.disabled    = true
	%EndTurn.disabled = not _turn_group.is_human_player()
	%Retreat.disabled = not _turn_group.is_human_player() or _turn_group.has_attacked_this_turn()


func _on_combat_square_attacked(_square: CombatSquare, _assault: CombatAssault) -> void:
	"""
	[EVENT]
	
	CombatSquare has been attacked.
	"""
	%StatusInformation.text = "Square Attacked"
	%AttacksLeft.text = str(combat.turn_group.num_attacks) + " Attacks Left"

	if combat.turn_group.is_human_player():
		%Undo.disabled    = not combat.can_undo_last_move()
		%Retreat.disabled = false
	else:
		%Undo.disabled    = true
		%Retreat.disabled = true
		

func _on_combat_square_occupied(_square: CombatSquare, _movement: CombatMovement) -> void:
	"""
	[EVENT]
	
	CombatSquare has been occupied.
	"""
	%StatusInformation.text = "Square Occupied"
	
	if combat.turn_group.is_human_player():
		%Undo.disabled    = not combat.can_undo_last_move()
		%Retreat.disabled = combat.turn_group.has_attacked_this_turn()
	else:
		%Undo.disabled    = true
		%Retreat.disabled = true
	

func _on_undo_pressed() -> void:
	"""
	[EVENT]
	
	CombatGroup undo has been requested.
	"""
	combat.undo_last_move()


func _on_retreat_pressed() -> void:
	"""
	[EVENT]
	
	CombatGroup has retreated.
	"""
	#TODO: add confirmation pop-up (i.e. are you sure?)
	pass


func _on_end_turn_pressed() -> void:
	"""
	[EVENT]
	
	CombatGroup has ended their turn.
	"""
	#TODO: add confirmation pop-up (i.e. are you sure?)
	combat.end_turn()


func _on_combat_movement_undone() -> void:
	"""
	[EVENT]
	
	CombatGroup has undone the last move.
	"""
	%Undo.disabled = not combat.can_undo_last_move()


func _on_exit_game_pressed() -> void:
	"""
	Exit game.
	"""
	end_combat.emit()


func _on_combat_ended(_victory_group: CombatGroup) -> void:
	var _callback : Callable = func() -> void:
		end_combat.emit()
		
	if _victory_group.is_human_player():
		flash_message("PLAYER WINS!", 1.0, _callback)
	else:
		flash_message("COMPUTER WINS!", 1.0, _callback)

#endregion
