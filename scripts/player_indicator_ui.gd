extends Control

@onready var player_name = $MarginContainer/CardContent/VBoxContainer/Header/PlayerName
@onready var vigor_label = $MarginContainer/CardContent/VBoxContainer/TypeIcons/VIG
@onready var flux_label = $MarginContainer/CardContent/VBoxContainer/TypeIcons/FLUX
@onready var fort_label = $MarginContainer/CardContent/VBoxContainer/TypeIcons/FORT

# Status indicators for curses
@onready var necromancy_indicator = $MarginContainer/CardContent/Indicators/NecromancyIndicator
@onready var darkness_indicator = $MarginContainer/CardContent/Indicators/DarknessIndicator
@onready var dispel_indicator = $MarginContainer/CardContent/Indicators/DispelIndicator
@onready var chaos_surge_indicator = $MarginContainer/CardContent/Indicators/ChaosSurgeIndicator
@onready var marked_indicator = $MarginContainer/CardContent/Indicators/MarkedIndicator
@onready var charmed_indicator = $MarginContainer/CardContent/Indicators/CharmedIndicator
@onready var illusion_indicator = $MarginContainer/CardContent/Indicators/IllusionIndicator

func _ready():
	# Add error checking to verify nodes are found
	if !player_name:
		push_error("PlayerIndicatorUI: player_name node not found")
		return
		
	if !vigor_label || !flux_label || !fort_label:
		push_error("PlayerIndicatorUI: stat labels not found")
		return
		
	if !necromancy_indicator || !darkness_indicator || !dispel_indicator || \
	   !chaos_surge_indicator || !marked_indicator || !charmed_indicator || \
	   !illusion_indicator:
		push_error("PlayerIndicatorUI: status indicators not found")
		return
	
	# Connect to signal only if all nodes are properly loaded
	MatchState.player_updated.connect(update_player_indicator)

func setup(player_data: Dictionary):
	# Add null check before updating
	if !player_name:
		push_error("PlayerIndicatorUI: Trying to setup with null nodes")
		return
	update_player_indicator(player_data)

func update_player_indicator(player_data: Dictionary):
	# Add null checks
	if !player_name || !vigor_label || !flux_label || !fort_label:
		push_error("PlayerIndicatorUI: Trying to update with null nodes")
		return
		
	print(player_data)
	var steam_id: int = player_data["steam_id"]["steam_id"]
	player_name.text = Steam.getFriendPersonaName(steam_id)
	
	# Update stats
	vigor_label.text = "VIG:" + str(player_data["vigor"])
	flux_label.text = "FLX:" + str(player_data["arcane_flux"])
	fort_label.text = "FORT:" + str(player_data["treasure"])
	
	# Update curse indicators
	update_status_indicators(player_data["curses"])

func update_status_indicators(curses: Array):
	# Add null checks
	if !necromancy_indicator || !darkness_indicator || !dispel_indicator || \
	   !chaos_surge_indicator || !marked_indicator || !charmed_indicator || \
	   !illusion_indicator:
		push_error("PlayerIndicatorUI: Trying to update indicators with null nodes")
		return
		
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
