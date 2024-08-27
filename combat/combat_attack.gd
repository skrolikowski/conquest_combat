extends Node2D
class_name CombatAttack

const DICE_ROLL : float = 40.0

var attacker : CombatUnit
var defender : CombatUnit

var offense      : int = 0
var defense      : int = 0
var bonus_points : int = 0
var chance       : float = 0.0
var damage       : int = 0


func roll() -> bool:
    chance = (offense + bonus_points - defense) / DICE_ROLL

    printt("ATTACK", attacker.stat.title + "(" + str(attacker.stat.health) + ")", defender.stat.title + "(" + str(defender.stat.health) + ")")
    printt("-- Offense", str(offense) + " [" + str(bonus_points) + "]")
    printt("-- Defense", str(defense))
    printt("-- Chance ", str(chance * 100) + "%")

    var is_successful : bool = randf() < chance
    if is_successful:
        damage = 1
        printt("-- Damage", str(damage))
    else:
        printt("-- Miss")
    
    return is_successful