extends Node
class_name PreloadsRef

const player      : PackedScene = preload("res://combat/player.tscn")

# COMBAT
const combat      : PackedScene = preload("res://combat/combat.tscn")
const combat_unit : PackedScene = preload("res://combat/combat_unit.tscn")

# COMBAT RESOURCES
const combat_artillary_unit : Resource = preload("res://combat/resources/artillary_animations.tres")
const combat_calvary_unit   : Resource = preload("res://combat/resources/calvary_animations.tres")
const combat_infantry_unit  : Resource = preload("res://combat/resources/infantry_animations.tres")
const combat_orc_artillary_unit : Resource = preload("res://combat/resources/orc_artillary_animations.tres")
const combat_orc_calvary_unit   : Resource = preload("res://combat/resources/orc_calvary_animations.tres")
const combat_orc_infantry_unit  : Resource = preload("res://combat/resources/orc_infantry_animations.tres")
