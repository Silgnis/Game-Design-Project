extends Resource
class_name ShopItem

@export var id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var price := 0
@export var is_consumable := false # False for keys/upgrades, True for potions/ammo
