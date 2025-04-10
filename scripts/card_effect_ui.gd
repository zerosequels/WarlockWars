extends Control

# UI References
@onready var card_name_label: Label = $Panel/CardContent/VBoxContainer/Header/Label
@onready var attribute_icons: VBoxContainer = $Panel/CardContent/AttributeIcons
@onready var star: TextureRect = $Panel/CardContent/AttributeIcons/AttributeIcon
@onready var card_artwork: TextureRect = $Panel/CardContent/CardArtwork
@onready var atk_label: Label = $Panel/CardContent/VBoxContainer/TypeIcons/Atk
@onready var def_label: Label = $Panel/CardContent/VBoxContainer/TypeIcons/Def
@onready var description_label: Label = $Panel/CardContent/VBoxContainer/TypeIcons/Desciption

# Card Data
var card_data: Dictionary

# Elemental Attribute Star Textures (Replace with your assets)
var attribute_star_textures: Dictionary = {
	"Non-element": preload("res://assets/textures/elements/non_element.png"),
	"Fire": preload("res://assets/textures/elements/fire_element.png"),
	"Water": preload("res://assets/textures/elements/water_element.png"),
	"Earth": preload("res://assets/textures/elements/earth_element.png"),
	"Air": preload("res://assets/textures/elements/air_element.png"),
	"Necromancy": preload("res://assets/textures/elements/necromancy.png"),
	"Holy": preload("res://assets/textures/elements/holy.png")
}

func _ready():
	card_data = CardLibrary.get_card_data("002")
	#print(card_data)
	update_card_ui()

func is_ui_initialized() -> bool:
	return (
		card_name_label != null and
		attribute_icons != null and
		star != null and
		card_artwork != null and
		atk_label != null and
		def_label != null and
		description_label != null and
		!card_data.is_empty()
	)

func update_card_ui():
	if not is_ui_initialized():
		return
		
	# Card Name
	card_name_label.text = card_data["name"]

	# Elemental Attribute Star
	var element = card_data.get("element", "Non-element")
	if element in attribute_star_textures:
		star.texture = attribute_star_textures[element]
		star.visible = true
		# Add purple modulation for Non-element
		if element == "Non-element":
			star.modulate = Color(1.0, 0.4, 1.0)  # Electric magenta-purple with bright core
		else:
			star.modulate = Color(1, 1, 1)  # Reset to white for other elements
	else:
		star.visible = false

	# Card Artwork
	if card_data.get("texture_path"):
		card_artwork.texture = load(card_data["texture_path"])

	# Attack and Defense
	if card_data.get("atk"):
		atk_label.text = "Atk: %d" % card_data["atk"]
	if card_data.get("def"):
		def_label.text = "Def: %d" % card_data["def"]
		
	# Description
	if card_data.get("description"):
		description_label.text = card_data["description"]

func set_card_data(data: Dictionary):
	card_data = data
	update_card_ui()

func update_card_by_id(card_id: String):
	card_data = CardLibrary.get_card_data(card_id)
	if card_data:
		set_card_data(card_data)
	else:
		printerr("Card ID not found: ", card_id)
