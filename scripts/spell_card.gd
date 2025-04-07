extends Control

# UI References

@onready var card_name_label: Label = $MarginContainer/CardContent/Header/Label
@onready var attibute_icons: HBoxContainer = $MarginContainer/CardContent/AttributeIcons
@onready var star: TextureRect = $MarginContainer/CardContent/AttributeIcons/AttibuteIcon
@onready var card_artwork: TextureRect = $MarginContainer/CardContent/CardArtwork
@onready var atk_label: Label = $MarginContainer/CardContent/TypeIcons/Atk
@onready var def_label: Label = $MarginContainer/CardContent/TypeIcons/Def
@onready var card_button: Button = $Button

# Card Data
var card_data: Dictionary = {
	"name": "test",
	"attribute": "fire",  # Elemental attribute: normal, fire, air, earth, water, darkness, holy
	"attack": 20,
	"defense": 20,
	"artwork": "res://assets/textures/texture_00021_.png"
}

# Elemental Attribute Star Textures (Replace with your assets)
var attribute_star_textures: Dictionary = {
	"normal": preload("res://assets/textures/texture_00021_.png"),
	"fire": preload("res://assets/textures/texture_00021_.png"),
	"air": preload("res://assets/textures/texture_00021_.png"),
	"earth": preload("res://assets/textures/texture_00021_.png"),
	"water": preload("res://assets/textures/texture_00021_.png"),
	"darkness": preload("res://assets/textures/texture_00021_.png"),
	"holy": preload("res://assets/textures/texture_00021_.png")
}

# Signals
signal card_clicked(card_data)

func _ready():
	# Ensure only one star exists in LevelStars
	update_card_ui()
	card_button.connect("pressed", _on_card_clicked)

func is_ui_initialized() -> bool:
	return (
		card_name_label != null and
		attibute_icons != null and
		star != null and
		card_artwork != null and
		atk_label != null and
		def_label != null and
		card_button != null
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
		star.modulate = {
			"Non-element": Color("#A68A64"),  # Arcane gold (default)
			"Fire": Color("#B04A5A"),    # Crimson (fire)
			"Air": Color("#6A8299"),     # Mystical blue (wind)
			"Earth": Color("#4A3C2F"),   # Parchment brown (earth)
			"Water": Color("#3F5A3C"),   # Muted green (water)
			"Necromancy": Color("#2A1B1F"),  # Dark crimson-tinged black
			"Holy": Color("#D9A66F")     # Warm arcane amber (light)
		}[element]

	# Card Artwork
	if card_data.get("texture_path"):
		card_artwork.texture = load(card_data["texture_path"])

	# Attack and Defense
	if card_data.get("atk"):
		atk_label.text = "Atk: %d" % card_data["atk"]
	if card_data.get("def"):
		def_label.text = "Def: %d" % card_data["def"]

func set_card_data(data: Dictionary):
	card_data = data
	update_card_ui()

func update_card_by_id(card_id: String):
	var card_data = CardLibrary.get_card_data(card_id)
	if card_data:
		set_card_data(card_data)
	else:
		printerr("Card ID not found: ", card_id)

func _on_card_clicked():
	print(card_data)
	emit_signal("card_clicked", card_data)
