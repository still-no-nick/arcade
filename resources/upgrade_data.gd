class_name UpgradeData
extends Resource

@export var id: StringName
@export var title: String
@export_multiline var desc: String
@export var stat: StringName
@export var multiplier: float = 1.0
@export var additive: float = 0.0
@export var secondary_stat: StringName
@export var secondary_multiplier: float = 1.0
@export var secondary_additive: float = 0.0
@export var tags: Array[StringName] = []
