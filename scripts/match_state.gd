# MatchState.gd
# Singleton to manage the current match state in Warlock Wars, using Globals.LOBBY_MEMBERS

extends Node

# Constants
const MAX_HAND_SIZE: int = 7
const MAX_HAND_SIZE_ABSOLUTE: int = 18  # Absolute maximum to prevent hand overflow

# Player data stored as a dictionary with Steam IDs as keys
var players := {}
var current_turn := 0  # Index in turn_order
var turn_order := []   # Array of Steam IDs from LOBBY_MEMBERS
var match_started: bool = false
var is_host: bool = false  # Tracks if this player is the host of the current match

# Attack/Defense tracking
var attacker: int = -1
var defender: int = -1
var attack_cards_data: Array = []
var defense_cards_data: Array = []

# Signals
signal populate_player_list(players: Dictionary, turn_order: Array)
signal player_updated(player_data: Dictionary)
signal replenish_player_hand(player_id: int, new_cards: Array)
signal current_player_turn(steam_id: int)  # New signal for current player's turn
signal forward_attack_lock_in_to_host(steam_id: int, target_steam_id: int, attack_cards: Array)
signal update_player_area_with_locked_in_attack(steam_id: int, target_steam_id: int, attack_cards: Array)
signal forward_defense_lock_in_to_host(steam_id: int, target_steam_id: int, defense_cards: Array)
signal update_player_area_with_locked_in_defense(steam_id: int, target_steam_id: int, defense_cards: Array)
signal update_damage_indicator(attack_value: int, attack_type: String)
signal clear_play_area()  # New signal to clear play area

# Called when singleton is initialized
func _ready():
	print("MatchState initialized")
	
func start_new_match():
	if not is_host:
		return
	if match_started == false:
		print("MatchState: Starting new match as host")
		match_started = true
		reset_match()
		# Emit the signal after match is reset
		print("MatchState: Emitting populate_player_list signal")
		emit_signal("populate_player_list", players, turn_order)
		print("MatchState: Emitting current_player_turn signal")
		emit_signal("current_player_turn", turn_order[current_turn]["steam_id"])
		print("Players: ", players)
	
# Replenish a player's hand up to MAX_HAND_SIZE
func replenish_hand(player: Dictionary):
	print("Replenishing hand for player ", player["steam_id"])
	var new_cards := []
	while player["hand"].size() < MAX_HAND_SIZE and player["hand"].size() < MAX_HAND_SIZE_ABSOLUTE:
		var card = _draw_random_card()
		player["hand"].append(card)
		new_cards.append(card)
	
	if not new_cards.is_empty():
		print("Emitting replenish_player_hand signal for player ", player["steam_id"], " with cards: ", new_cards)
		emit_signal("replenish_player_hand", player["steam_id"]["steam_id"], new_cards)

# Reset the match state using players from Globals.LOBBY_MEMBERS
func reset_match():
	if not is_host:
		return
		
	players.clear()
	turn_order.clear()
	current_turn = 0
	
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
		# Draw initial hand
		replenish_hand(player)
		players[steam_id] = player
		turn_order.append(steam_id)
	
	# Shuffle turn order
	turn_order.shuffle()
	print("Match reset with ", turn_order.size(), " players from LOBBY_MEMBERS")
	# Emit current player's turn
	emit_signal("current_player_turn", turn_order[current_turn]["steam_id"])

# Add a player mid-game (for testing or dynamic joins)
func add_player(steam_id: int):
	if not is_host:
		return false
		
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
	replenish_hand(player)
	players[steam_id] = player
	turn_order.append(steam_id)
	return true

# Get current player's data
func get_current_player() -> Dictionary:
	return players[turn_order[current_turn]]

# Advance to the next turn
func next_turn():
	if not is_host:
		return
		
	current_turn = (current_turn + 1) % turn_order.size()
	while players[turn_order[current_turn]]["eliminated"]:
		current_turn = (current_turn + 1) % turn_order.size()
	# Replenish hand
	replenish_hand(get_current_player())
	# Emit current player's turn
	emit_signal("current_player_turn", turn_order[current_turn])

# Play a card from hand
func play_card(steam_id: int, card_id: String, target_steam_id: int = -1):
	if not is_host:
		return false
		
	var player = players[steam_id]
	var card_data = CardLibrary.get_card_data(card_id)
	
	if card_id not in player["hand"]:
		printerr("Card ", card_id, " not in player ", steam_id, "'s hand")
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
		emit_signal("player_updated", target)
	print("Player ", attacker_id, " attacks Player ", target_id, " for ", damage)

# Apply magic item (placeholder for specific effects)
func _apply_magic_item(player_id: int, target_id: int, card_data: Dictionary):
	if card_data["name"] == "Healing Salve":
		players[player_id]["vigor"] += 10
		emit_signal("player_updated", players[player_id])
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
	emit_signal("player_updated", player)

# Check if a player is eliminated
func _check_elimination(steam_id: int):
	var player = players[steam_id]
	if player["vigor"] <= 0 or "Divine Wrath" in player["curses"]:
		player["eliminated"] = true
		print("Player ", steam_id, " eliminated")
		emit_signal("player_updated", player)

# Draw a random card from CardLibrary
func _draw_random_card() -> String:
	var card_ids = CardLibrary.get_all_card_ids()
	return card_ids[randi() % card_ids.size()]

# Lock in the current attack and process it
func lock_in_attack(steam_id: int, target_steam_id: int, attack_cards: Array):
	if not is_host:
		print("Forwarding attack lock-in to host")
		emit_signal("forward_attack_lock_in_to_host", steam_id, target_steam_id, attack_cards)
		return
		
	print("Locking in attack for player ", steam_id, " targeting player ", target_steam_id)
	attacker = steam_id
	defender = target_steam_id
	attack_cards_data = attack_cards
	
	# Process the attack cards here
	# This is where we'll handle the attack logic
	# For now, just print the cards
	print("Attack cards: ", attack_cards)
	# Emit the new signal to update the UI
	emit_signal("update_player_area_with_locked_in_attack", steam_id, target_steam_id, attack_cards)

# Lock in the current defense and process it
func lock_in_defense(steam_id: int, target_steam_id: int, defense_cards: Array):
	if not is_host:
		print("Forwarding defense lock-in to host")
		emit_signal("forward_defense_lock_in_to_host", steam_id, target_steam_id, defense_cards)
		return
		
	print("Locking in defense for player ", steam_id, " targeting player ", target_steam_id)
	defense_cards_data = defense_cards
	
	# Emit the new signal to update the UI
	emit_signal("update_player_area_with_locked_in_defense", steam_id, target_steam_id, defense_cards)
	
	# Process the attack and defense
	process_attack_and_defense()

func process_attack_and_defense():
	print("Attacker ID: ", attacker)
	print("Defender ID: ", defender)
	print("Attack Cards: ", attack_cards_data)
	print("Defense Cards: ", defense_cards_data)
	
	# Handle case where no defense cards are played
	if defense_cards_data.is_empty():
		var attack_element = calculate_attack_element(attack_cards_data)
		var total_damage = 0
		for card in attack_cards_data:
			if card.has("atk"):
				total_damage += card["atk"]
		print("Defender accepts attack")
		print("Attack deals ", total_damage, " ", attack_element, " damage")
		emit_signal("update_damage_indicator", total_damage, attack_element)
		apply_damage_to_player(defender, total_damage)
		return
	
	# Calculate attack and defense elements
	var attack_element = calculate_attack_element(attack_cards_data)
	var defense_element = calculate_defense_element(defense_cards_data)
	print("Attack Element Type: ", attack_element)
	print("Defense Element Type: ", defense_element)
	
	if can_defend_against_attack(attack_element, defense_element):
		# Calculate total attack and defense values
		var total_attack = 0
		var total_defense = 0
		
		for card in attack_cards_data:
			if card.has("atk"):
				total_attack += card["atk"]
				
		for card in defense_cards_data:
			if card.has("def"):
				total_defense += card["def"]
		
		var final_damage = total_attack - total_defense
		if final_damage <= 0:
			print("Attack was completely blocked!")
			emit_signal("update_damage_indicator", 0, attack_element)
		else:
			print("Attack deals ", final_damage, " ", attack_element, " damage after defense")
			emit_signal("update_damage_indicator", final_damage, attack_element)
			apply_damage_to_player(defender, final_damage)
	else:
		# If defense can't block the attack, calculate total damage
		var total_damage = 0
		for card in attack_cards_data:
			if card.has("atk"):
				total_damage += card["atk"]
		print("Defense ineffective! Attack deals ", total_damage, " ", attack_element, " damage")
		emit_signal("update_damage_indicator", total_damage, attack_element)
		apply_damage_to_player(defender, total_damage)
		
	# Clear the variables after processing
	attacker = -1
	defender = -1
	attack_cards_data.clear()
	defense_cards_data.clear()
	emit_signal("clear_play_area")

func calculate_attack_element(cards: Array) -> String:
	# Determine attack element type
	var attack_elements = []
	for card in cards:
		if card.has("element"):
			attack_elements.append(card["element"])
	
	var element = "Non-element"  # Default to Non-element
	
	if attack_elements.size() == 1:
		# Single element attack
		element = attack_elements[0]
	elif attack_elements.size() > 1:
		# Check if all elements are the same
		var all_same = true
		var first_element = attack_elements[0]
		for attack_element in attack_elements:
			if attack_element != first_element:
				all_same = false
				break
		
		if all_same:
			element = first_element
		else:
			# Mixed elements result in Non-element
			element = "Non-element"
	
	return element

func calculate_defense_element(cards: Array) -> String:
	# Determine defense element type
	var defense_elements = []
	for card in cards:
		if card.has("element"):
			defense_elements.append(card["element"])
	
	var element = "Non-element"  # Default to Non-element
	
	if defense_elements.size() == 1:
		# Single element defense
		element = defense_elements[0]
	elif defense_elements.size() > 1:
		# Check if all elements are the same
		var all_same = true
		var first_element = defense_elements[0]
		for defense_element in defense_elements:
			if defense_element != first_element:
				all_same = false
				break
		
		if all_same:
			element = first_element
		else:
			# Mixed elements result in Non-element
			element = "Non-element"
	
	return element

# Redistribute stats (1:1:1 ratio)
func redistribute_stats(steam_id: int, vigor: int, arcane_flux: int, treasure: int):
	if not is_host:
		return
		
	var player = players[steam_id]
	var total = player["vigor"] + player["arcane_flux"] + player["treasure"]
	if vigor + arcane_flux + treasure == total and vigor >= 0 and arcane_flux >= 0 and treasure >= 0:
		player["vigor"] = vigor
		player["arcane_flux"] = arcane_flux
		player["treasure"] = treasure
		print("Player ", steam_id, " stats redistributed: ", vigor, "/", arcane_flux, "/", treasure)
		emit_signal("player_updated", player)
	else:
		printerr("Invalid stat redistribution for Player ", steam_id)

func can_defend_against_attack(attack_element: String, defense_element: String) -> bool:
	# Holy defense can block any attack
	if defense_element == "Holy":
		return true
		
	# Non-element can be defended by any element
	if attack_element == "Non-element":
		return true
	
	# Holy cannot be defended by any element (except Holy defense)
	if attack_element == "Holy":
		return false
	
	# Check element matchups
	match attack_element:
		"Fire":
			return defense_element == "Water"
		"Water":
			return defense_element == "Fire"
		"Earth":
			return defense_element == "Air"
		"Air":
			return defense_element == "Earth"
		"Necromancy":
			# Necromancy can be defended by any element
			return true
		_:
			# Default case (shouldn't happen with current elements)
			return false

func apply_damage_to_player(player_id: int, damage: int):
	if not is_host:
		print("Non-host machine, skipping damage application")
		return
		
	print("\n=== Applying Damage ===")
	print("Target player_id: ", player_id)
	print("Current players dictionary: ", players)
	
	# Search through all players to find the matching one
	var target_player = null
	for player_key in players:
		var player = players[player_key]
		print("Checking player with steam_id: ", player["steam_id"]["steam_id"])
		if player["steam_id"]["steam_id"] == player_id:
			target_player = player
			print("Found matching player: ", player)
			break
	
	if target_player == null:
		printerr("Player ID not found: ", player_id)
		return
		
	target_player["vigor"] -= damage
	print("Updated vigor to: ", target_player["vigor"])
	
	# Check if player is eliminated
	if target_player["vigor"] <= 0:
		target_player["vigor"] = 0
		target_player["eliminated"] = true
		print("Player ", player_id, " has been eliminated!")
	
	print("Emitting player_updated signal with data: ", target_player)
	# Emit signal to update player data
	emit_signal("player_updated", target_player)
	print("=== Damage Application Complete ===\n")
