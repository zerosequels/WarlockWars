# MatchState.gd
# Singleton to manage the current match state in Warlock Wars, using Globals.LOBBY_MEMBERS

extends Node

# Player data stored as a dictionary with Steam IDs as keys
var players := {}
var current_turn := 0  # Index in turn_order
var turn_order := []   # Array of Steam IDs from LOBBY_MEMBERS
var cantrips_played := {}  # Tracks Cantrips played this turn per player
var match_started: bool = false

# Called when singleton is initialized
func _ready():
	print("MatchState initialized")
	
func start_new_match():
	if match_started == false:
		match_started = true
		reset_match()
	
# Reset the match state using players from Globals.LOBBY_MEMBERS
func reset_match():
	players.clear()
	turn_order.clear()
	current_turn = 0
	cantrips_played.clear()
	
	# Use LOBBY_MEMBERS from Globals to initialize players
	if Globals.LOBBY_MEMBERS.is_empty():
		printerr("No players in LOBBY_MEMBERS. Cannot reset match.")
		return
	
	for steam_id in Globals.LOBBY_MEMBERS:
		var player = {
			"steam_id": steam_id,
			"vigor": 20,
			"arcane_flux": 10,
			"treasure": 20,
			"hand": [],
			"summons": [],
			"equipment": [],
			"curses": [],
			"eliminated": false
		}
		# Draw initial hand (9 cards)
		for j in range(9):
			player["hand"].append(_draw_random_card())
		players[steam_id] = player
		turn_order.append(steam_id)
	
	# Shuffle turn order
	turn_order.shuffle()
	print("Match reset with ", turn_order.size(), " players from LOBBY_MEMBERS")

# Add a player mid-game (for testing or dynamic joins)
func add_player(steam_id: int):
	if steam_id in players:
		printerr("Player with Steam ID ", steam_id, " already exists")
		return false
	var player = {
		"steam_id": steam_id,
		"vigor": 20,
		"arcane_flux": 10,
		"treasure": 20,
		"hand": [],
		"summons": [],
		"equipment": [],
		"curses": [],
		"eliminated": false
	}
	for i in range(9):
		player["hand"].append(_draw_random_card())
	players[steam_id] = player
	turn_order.append(steam_id)
	return true

# Get current player's data
func get_current_player() -> Dictionary:
	return players[turn_order[current_turn]]

# Advance to the next turn
func next_turn():
	current_turn = (current_turn + 1) % turn_order.size()
	while players[turn_order[current_turn]]["eliminated"]:
		current_turn = (current_turn + 1) % turn_order.size()
	# Reset Cantrips played for the new turn
	cantrips_played[get_current_player()["steam_id"]] = 0
	# Replenish hand to 9 cards
	var player = get_current_player()
	while player["hand"].size() < 9 and player["hand"].size() < 18:
		player["hand"].append(_draw_random_card())

# Play a card from hand
func play_card(steam_id: int, card_id: String, target_steam_id: int = -1):
	var player = players[steam_id]
	var card_data = CardLibrary.get_card_data(card_id)
	
	if card_id not in player["hand"]:
		printerr("Card ", card_id, " not in player ", steam_id, "'s hand")
		return false
	
	# Special check for Cantrips: 1 per turn limit
	if card_data["type"] == "cantrip":
		if not steam_id in cantrips_played:
			cantrips_played[steam_id] = 0
		if cantrips_played[steam_id] >= 1 and not card_data.get("combo", false):
			printerr("Only 1 non-combo Cantrip allowed per turn")
			return false
	
	# Check costs (only deduct if > 0)
	if card_data["treasure_cost"] > 0 and player["treasure"] < card_data["treasure_cost"]:
		printerr("Not enough Treasure for ", card_data["name"])
		return false
	if "flux_cost" in card_data and card_data["flux_cost"] > 0 and player["arcane_flux"] < card_data["flux_cost"]:
		printerr("Not enough Arcane Flux for ", card_data["name"])
		return false
	
	# Deduct costs if applicable
	if card_data["treasure_cost"] > 0:
		player["treasure"] -= card_data["treasure_cost"]
	if "flux_cost" in card_data and card_data["flux_cost"] > 0:
		player["arcane_flux"] -= card_data["flux_cost"]
	
	# Handle card type
	match card_data["type"]:
		"cantrip":
			_apply_attack(steam_id, target_steam_id, card_data)
			cantrips_played[steam_id] = cantrips_played.get(steam_id, 0) + 1
		"abjuration":
			printerr("Abjuration cards are played defensively, not proactively")
			return false
		"magic_item":
			_apply_magic_item(steam_id, target_steam_id, card_data)
		"spell":
			_apply_spell(steam_id, target_steam_id, card_data)
		"summon":
			_apply_summon(steam_id, card_data)
		"equipment":
			_apply_equipment(steam_id, card_data)
		"curse":
			printerr("Curse cards auto-activate on draw")
			return false
		"wish":
			_apply_wish(card_data)
	
	# Remove card from hand (except reusable spells)
	if card_data["type"] != "spell":
		player["hand"].erase(card_id)
	return true

# Apply attack (simplified for testing)
func _apply_attack(attacker_id: int, target_id: int, card_data: Dictionary):
	var target = players[target_id]
	var damage = card_data["atk"]
	if card_data["element"] == "Necromancy":
		_apply_or_worsen_curse(target)
	else:
		target["vigor"] -= damage
		_check_elimination(target_id)
	print("Player ", attacker_id, " attacks Player ", target_id, " for ", damage)

# Apply magic item (placeholder for specific effects)
func _apply_magic_item(player_id: int, target_id: int, card_data: Dictionary):
	if card_data["name"] == "Healing Salve":
		players[player_id]["vigor"] += 10
	elif card_data["name"] == "Illustrious Gem" and target_id != -1:
		_sell_card(player_id, target_id, card_data["id"])
	print("Player ", player_id, " uses ", card_data["name"])

# Apply spell (placeholder for specific effects)
func _apply_spell(player_id: int, target_id: int, card_data: Dictionary):
	if card_data["name"] == "Necrotic Touch":
		_apply_attack(player_id, target_id, card_data)
	print("Player ", player_id, " casts ", card_data["name"])

# Apply summon
func _apply_summon(player_id: int, card_data: Dictionary):
	players[player_id]["summons"].append({"id": card_data["id"], "hp": card_data["hp"]})
	print("Player ", player_id, " summons ", card_data["name"])

# Apply equipment
func _apply_equipment(player_id: int, card_data: Dictionary):
	players[player_id]["equipment"].append({"id": card_data["id"], "hp": card_data["hp"]})
	print("Player ", player_id, " equips ", card_data["name"])

# Apply wish (placeholder for global effect)
func _apply_wish(card_data: Dictionary):
	for steam_id in players:
		if not players[steam_id]["eliminated"]:
			players[steam_id]["vigor"] -= 5  # Example global effect
			_check_elimination(steam_id)
	print("Wish card ", card_data["name"], " triggered globally")

# Sell a card to another player
func _sell_card(seller_id: int, buyer_id: int, card_id: String):
	var seller = players[seller_id]
	var buyer = players[buyer_id]
	seller["hand"].erase(card_id)
	buyer["hand"].append(card_id)
	if buyer["hand"].size() > 18:
		buyer["hand"].remove_at(randi() % buyer["hand"].size())
	print("Player ", seller_id, " sells ", card_id, " to Player ", buyer_id)

# Apply or worsen curse
func _apply_or_worsen_curse(player: Dictionary):
	if player["curses"].is_empty():
		player["curses"].append("Life Steal")
	else:
		var current_curse = player["curses"][-1]
		if randf() < 0.05:  # 5% chance to worsen
			match current_curse:
				"Life Steal": player["curses"].append("Life Drain")
				"Life Drain": player["curses"].append("Undeath")
				"Undeath": player["curses"].append("Lich")
				"Lich": player["curses"].append("Divine Wrath")
	print("Curse applied/worsened for Player ", player["steam_id"])

# Check if a player is eliminated
func _check_elimination(steam_id: int):
	var player = players[steam_id]
	if player["vigor"] <= 0 or "Divine Wrath" in player["curses"]:
		player["eliminated"] = true
		print("Player ", steam_id, " eliminated")

# Draw a random card from CardLibrary
func _draw_random_card() -> String:
	var card_ids = CardLibrary.get_all_card_ids()
	return card_ids[randi() % card_ids.size()]

# Redistribute stats (1:1:1 ratio)
func redistribute_stats(steam_id: int, vigor: int, arcane_flux: int, treasure: int):
	var player = players[steam_id]
	var total = player["vigor"] + player["arcane_flux"] + player["treasure"]
	if vigor + arcane_flux + treasure == total and vigor >= 0 and arcane_flux >= 0 and treasure >= 0:
		player["vigor"] = vigor
		player["arcane_flux"] = arcane_flux
		player["treasure"] = treasure
		print("Player ", steam_id, " stats redistributed: ", vigor, "/", arcane_flux, "/", treasure)
	else:
		printerr("Invalid stat redistribution for Player ", steam_id)
