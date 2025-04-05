extends Control

@onready var player_name = $MarginContainer/CardContent/VBoxContainer/Header/PlayerName
@onready var vigor_label = $MarginContainer/CardContent/VBoxContainer/TypeIcons/VIG
@onready var flux_label = $MarginContainer/CardContent/VBoxContainer/TypeIcons/FLUX
@onready var fort_label = $MarginContainer/CardContent/VBoxContainer/TypeIcons/FORT

# Status indicators for curses
@onready var necromancy_indicator = $MarginContainer/CardContent/HBoxContainer/NecromancyIndicator
@onready var darkness_indicator = $MarginContainer/CardContent/HBoxContainer/DarknessIndicator
@onready var dispel_indicator = $MarginContainer/CardContent/HBoxContainer/DispelIndicator
@onready var chaos_surge_indicator = $MarginContainer/CardContent/HBoxContainer/ChaosSurgeIndicator
@onready var marked_indicator = $MarginContainer/CardContent/HBoxContainer/MarkedIndicator
@onready var charmed_indicator = $MarginContainer/CardContent/HBoxContainer/CharmedIndicator
@onready var illusion_indicator = $MarginContainer/CardContent/HBoxContainer/IllusionIndicator

func setup(player_data: Dictionary):
	update_player_indicator(player_data)

func update_player_indicator(player_data: Dictionary):
	# Set player name using Steam persona name
	player_name.text = Steam.getFriendPersonaName(player_data["steam_id"])
	
	# Update stats
	vigor_label.text = "VIG:" + str(player_data["vigor"])
	flux_label.text = "FLX:" + str(player_data["arcane_flux"])
	fort_label.text = "FORT:" + str(player_data["treasure"])
	
	# Update curse indicators
	update_status_indicators(player_data["curses"])

func update_status_indicators(curses: Array):
	# Reset all indicators to hidden first
	necromancy_indicator.visible = false
	darkness_indicator.visible = false
	dispel_indicator.visible = false
	chaos_surge_indicator.visible = false
	marked_indicator.visible = false
	charmed_indicator.visible = false
	illusion_indicator.visible = false
	
	# Show relevant curse indicators
	for curse in curses:
		match curse:
			"Life Steal", "Life Drain", "Undeath", "Lich", "Divine Wrath":
				necromancy_indicator.visible = true
			"Darkness":
				darkness_indicator.visible = true
			"Dispel":
				dispel_indicator.visible = true
			"Chaos Surge":
				chaos_surge_indicator.visible = true
			"Marked":
				marked_indicator.visible = true
			"Charmed":
				charmed_indicator.visible = true
			"Illusion":
				illusion_indicator.visible = true

func _ready():
	MatchState.player_updated.connect(update_player_indicator)
