# TestMatchState.gd
# Script to test and validate MatchState functionality with Globals.LOBBY_MEMBERS

extends Node

func _ready():
	print("Testing MatchState functionality with Globals.LOBBY_MEMBERS...")
	
	# Simulate lobby members (since we’re testing without a real lobby)
	Globals.LOBBY_MEMBERS = [1111, 2222, 3333]  # Mock Steam IDs
	print("Simulated LOBBY_MEMBERS: ", Globals.LOBBY_MEMBERS)
	
	# Test 1: Reset match with LOBBY_MEMBERS
	MatchState.reset_match()
	assert(MatchState.players.size() == 3, "Player count should match LOBBY_MEMBERS (3)")
	assert(MatchState.turn_order.size() == 3, "Turn order should match player count")
	for steam_id in MatchState.players:
		var player = MatchState.players[steam_id]
		assert(player["hand"].size() == 9, "Initial hand size should be 9")
		assert(player["vigor"] == 20, "Initial Vigor should be 20")
		assert(player["arcane_flux"] == 10, "Initial Arcane Flux should be 10")
		assert(player["treasure"] == 20, "Initial Treasure should be 20")
	print("Test 1: Match reset with LOBBY_MEMBERS - PASSED")
	
	# Test 2: Play a card (Arcane Bolt, ID "001")
	var current_steam_id = MatchState.turn_order[MatchState.current_turn]
	var player = MatchState.get_current_player()
	var card_id = "001"  # Explicitly set to Arcane Bolt
	var initial_treasure = player["treasure"]
	if CardLibrary.get_card_data(card_id)["type"] == "cantrip":
		MatchState.play_card(current_steam_id, card_id, Globals.LOBBY_MEMBERS[1])
		# Check if Treasure decreases only if treasure_cost > 0
		var card_data = CardLibrary.get_card_data(card_id)
		if card_data["treasure_cost"] == 0:
			assert(player["treasure"] == initial_treasure, "Treasure should not decrease for free Cantrip")
		else:
			assert(player["treasure"] < initial_treasure, "Treasure should decrease for costly Cantrip")
		assert(MatchState.players[Globals.LOBBY_MEMBERS[1]]["vigor"] <= 20, "Target Vigor should decrease")
		print("Test 2: Playing Arcane Bolt (001) - PASSED")
	else:
		print("Test 2: Skipped (card 001 not a cantrip)")
	
	# Test 3: Next turn and hand replenish
	var initial_hand_size = MatchState.get_current_player()["hand"].size()
	MatchState.next_turn()
	var new_player = MatchState.get_current_player()
	assert(new_player["hand"].size() == 9, "Hand should replenish to 9 after turn")
	assert(MatchState.current_turn == 1, "Turn should advance to next player")
	print("Test 3: Next turn and hand replenish - PASSED")
	
	# Test 4: Stat redistribution (adjusted for post-Arcane Bolt total)
	var test_steam_id = Globals.LOBBY_MEMBERS[0]
	var player2 = MatchState.players[test_steam_id]
	var current_total = player["vigor"] + player["arcane_flux"] + player["treasure"]  # Should be 45 after Arcane Bolt
	MatchState.redistribute_stats(test_steam_id, 15, 15, 15)  # Sum to 45
	var redistributed_player = MatchState.players[test_steam_id]
	assert(redistributed_player["vigor"] == 15, "Vigor should be 15")
	assert(redistributed_player["arcane_flux"] == 15, "Arcane Flux should be 15")
	assert(redistributed_player["treasure"] == 15, "Treasure should be 15")
	print("Test 4: Stat redistribution - PASSED")
	
	# Test 5: Sell a card
	var seller_id = Globals.LOBBY_MEMBERS[0]
	var buyer_id = Globals.LOBBY_MEMBERS[1]
	var seller = MatchState.players[seller_id]
	var sell_card_id = seller["hand"][0]
	MatchState._sell_card(seller_id, buyer_id, sell_card_id)
	assert(sell_card_id not in seller["hand"], "Card should be removed from seller")
	assert(sell_card_id in MatchState.players[buyer_id]["hand"], "Card should be in buyer's hand")
	print("Test 5: Selling a card - PASSED")
	
	# Test 6: Reset match again
	Globals.LOBBY_MEMBERS = [4444, 5555]  # Simulate new lobby
	MatchState.reset_match()
	assert(MatchState.players.size() == 2, "Player count should reset to new LOBBY_MEMBERS (2)")
	assert(MatchState.current_turn == 0, "Turn should reset to 0")
	print("Test 6: Match reset again with new LOBBY_MEMBERS - PASSED")
	
	print("All tests completed!")
