extends Control

enum lobby_status {Private, Friends, Public, Invisible}
enum search_distance {Close, Default, Far, Worldwide}

const LOBBY_SEARCH_OPTION = preload("res://scenes/ui/networking/join_lobby_info_panel.tscn")

@onready var steamName = $LobbyPanel/MarginContainer/HBoxContainer/VBoxContainer2/SteamName
@onready var lobbySetName = $LobbyPanel/MarginContainer/HBoxContainer/VBoxContainer/VBoxContainer/TextEdit
@onready var lobbyGetName = $LobbyPanel/MarginContainer/HBoxContainer/VBoxContainer2/LobbyName
@onready var lobbyPlayerCount = $LobbyPanel/MarginContainer/HBoxContainer/VBoxContainer/Players/VBoxContainer/Label
@onready var lobbyOutput = $LobbyPanel/MarginContainer/HBoxContainer/VBoxContainer/Players/VBoxContainer/RichTextLabel
@onready var lobbyPanel = $LobbyPanel
@onready var lobbySearch = $FindLobbyPanel
@onready var lobbyList = $FindLobbyPanel/MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer
@onready var chatInput = $LobbyPanel/MarginContainer/HBoxContainer/VBoxContainer2/HBoxContainer/TextEdit
@onready var chatOutput = $LobbyPanel/MarginContainer/HBoxContainer/VBoxContainer2/RichTextLabel
@onready var joinLobbyButton = $LobbyPanel/MarginContainer/HBoxContainer/VBoxContainer/JoinLobby
@onready var createLobbyButton = $LobbyPanel/MarginContainer/HBoxContainer/VBoxContainer/VBoxContainer/CreateLobby
@onready var startMatchButton = $LobbyPanel/MarginContainer/HBoxContainer/VBoxContainer2/StartGame
@onready var matchUi = $MatchUI

var host_steam_id: int = 0

func _ready():
	#Set Steam Name
	steamName.text = Globals.STEAM_NAME
	#Steamwork Connections
	Steam.lobby_created.connect(_on_Lobby_Created)
	Steam.lobby_match_list.connect(_on_Lobby_Match_List)
	Steam.lobby_joined.connect(_on_Lobby_Joined)
	Steam.lobby_chat_update.connect(_on_Lobby_Chat_Update)
	Steam.lobby_message.connect(_on_Lobby_Message)
	Steam.lobby_data_update.connect(_on_Lobby_Data_Update)
	Steam.join_requested.connect(_on_Lobby_Join_Requested)
	Steam.p2p_session_request.connect(_on_P2p_Session_Request)
	Steam.p2p_session_connect_fail.connect(_on_p2p_session_connect_fail)
	
	# Connect to MatchState signals
	MatchState.replenish_player_hand.connect(_on_replenish_player_hand)
	MatchState.current_player_turn.connect(_on_current_player_turn)
	MatchState.populate_player_list.connect(_on_populate_player_list)
	MatchState.forward_attack_lock_in_to_host.connect(_on_forward_attack_lock_in_to_host)
	MatchState.forward_defense_lock_in_to_host.connect(_on_forward_defense_lock_in_to_host)
	MatchState.update_player_area_with_locked_in_attack.connect(_on_update_player_area_with_locked_in_attack)
	MatchState.update_player_area_with_locked_in_defense.connect(_on_update_player_area_with_locked_in_defense)
	MatchState.player_updated.connect(_on_player_updated)
	MatchState.update_damage_indicator.connect(_on_update_damage_indicator)
	MatchState.clear_play_area.connect(_on_clear_play_area)
	
	check_Command_Line()
	
func _process(delta):
	if Globals.LOBBY_ID > 0:
		read_p2p_packet()

#networking functions
func create_Lobby():
	#Check no other Lobby is running
	if Globals.LOBBY_ID == 0:
		Steam.createLobby(lobby_status.Public,12)

func join_Lobby(lobbyID):
	lobbySearch.hide()
	var lobby_name = Steam.getLobbyData(lobbyID,"name")
	display_Message("Joining lobby:" + str(lobby_name) + "...")
	#Clear previous lobby members lists
	Globals.LOBBY_MEMBERS.clear()
	#Steam join request
	Steam.joinLobby(lobbyID)
	
	
# Steam callbacks
func _on_Lobby_Created(connect_status, lobbyID):
	if connect_status == 1:
		Globals.LOBBY_ID = lobbyID
		display_Message("Created lobby: " + lobbySetName.text)
		
		# Set yourself as the host when creating the lobby
		MatchState.is_host = true
		host_steam_id = Globals.STEAM_ID
		
		#Set Lobby Data
		Steam.setLobbyData(lobbyID, "name", lobbySetName.text)
		Steam.setLobbyData(lobbyID, "host_id", str(host_steam_id))  # Store host ID in lobby data
		var lobby_name = Steam.getLobbyData(lobbyID, "name")
		lobbyGetName.text = str(lobby_name)
		toggle_join_lobby_button(false)
		toggle_start_match_button(true)

func _on_Lobby_Joined(lobbyID, permissions, locked, response):
	# Set lobby ID
	Globals.LOBBY_ID = lobbyID
	
	# Get the lobby name and host ID
	var lobby_name = Steam.getLobbyData(lobbyID, "name")
	host_steam_id = int(Steam.getLobbyData(lobbyID, "host_id"))
	MatchState.is_host = (Globals.STEAM_ID == host_steam_id)
	
	lobbyGetName.text = str(lobby_name)
	toggle_join_lobby_button(false)
	toggle_start_match_button(MatchState.is_host)  # Only host can start the game
	lobbyPanel.show()
	lobbySearch.hide()
	# Get lobby members
	get_Lobby_Members()
	
	make_p2p_handshake()

func _on_Lobby_Join_Requested(lobbyID, friendID):
	# Get lobby owners name
	var OWNER_NAME = Steam.getFriendPersonaName(friendID)
	display_Message("Joining " + str(OWNER_NAME) + " lobby...")
	
	# Join Lobby
	join_Lobby(lobbyID)
	
func _on_Lobby_Data_Update(success: int, lobby_id: int, member_id: int):
	print("Success: "+str(success)+", Lobby ID: "+str(lobby_id)+", Member ID: "+str(member_id))
	
func _on_Lobby_Chat_Update(lobbyID, changedID, makingChangeID, chatState):
	#Get Lobby Members
	get_Lobby_Members()
	#User who made lobby change
	var CHANGER = Steam.getFriendPersonaName(makingChangeID)
	
	# chatState change made
	match chatState:
		1:
			display_Message(str(CHANGER)+ " has joined the lobby.")
			toggle_start_match_button(MatchState.is_host)  # Recheck start button state
		2:
			display_Message(str(CHANGER)+ " has left the lobby.")
			if changedID == host_steam_id:  # Host left, need to migrate
				migrate_host()
			toggle_start_match_button(MatchState.is_host)  # Recheck start button state
		4:
			display_Message(str(CHANGER)+ " has disconnected from the lobby.")
			if changedID == host_steam_id:  # Host disconnected, need to migrate
				migrate_host()
			toggle_start_match_button(MatchState.is_host)  # Recheck start button state
		8:
			display_Message(str(CHANGER)+ " has been kicked from the lobby.")
			toggle_start_match_button(MatchState.is_host)  # Recheck start button state
		16:
			display_Message(str(CHANGER)+ " has been banned from the lobby.")
			toggle_start_match_button(MatchState.is_host)  # Recheck start button state
		_:
			display_Message(str(CHANGER)+ " has has done ... something")


func _on_Lobby_Match_List(lobbies):
	for LOBBY in lobbies:
		var lobby_join_option = LOBBY_SEARCH_OPTION.instantiate()
		
		lobbyList.add_child(lobby_join_option)
		lobby_join_option.join_button_setup(LOBBY)
		lobby_join_option.lobby_search_panel_join_request.connect(join_Lobby)

func _on_Lobby_Message(result, user, message,type):
	# Sender and their message
	var SENDER = Steam.getFriendPersonaName(user)
	display_Message(str(SENDER) + " : " + str(message))
	
	
func _on_P2p_Session_Request(remote_steam_id: int):
	Steam.acceptP2PSessionWithUser(remote_steam_id)
	print("Accepted P2P session with ", Steam.getFriendPersonaName(remote_steam_id))
	make_p2p_handshake()
	
func _on_p2p_session_connect_fail(steam_id: int, session_error: int):
	# If no error was given
	if session_error == 0:
		print("WARNING: Session failure with %s: no error given" % steam_id)

	# Else if target user was not running the same game
	elif session_error == 1:
		print("WARNING: Session failure with %s: target user not running the same game" % steam_id)

	# Else if local user doesn't own app / game
	elif session_error == 2:
		print("WARNING: Session failure with %s: local user doesn't own app / game" % steam_id)

	# Else if target user isn't connected to Steam
	elif session_error == 3:
		print("WARNING: Session failure with %s: target user isn't connected to Steam" % steam_id)

	# Else if connection timed out
	elif session_error == 4:
		print("WARNING: Session failure with %s: connection timed out" % steam_id)

	# Else if unused
	elif session_error == 5:
		print("WARNING: Session failure with %s: unused" % steam_id)

	# Else no known error
	else:
		print("WARNING: Session failure with %s: unknown error %s" % [steam_id, session_error])
	
# Button callback functions
func _on_create_lobby_pressed():
	if lobbySetName.text == "":
		lobbySetName.text = ""+steamName.text+"'s Lobby" 
	create_Lobby()

func _on_join_lobby_pressed():
	leave_Lobby()
	lobbyPanel.hide()
	lobbySearch.show()
	display_Message("Searching for lobbies...")
	Steam.addRequestLobbyListDistanceFilter(search_distance.Worldwide)
	Steam.requestLobbyList()
	
func _on_leave_lobby_pressed():
	leave_Lobby()
	
func _on_start_game_pressed():
	var player_count = Steam.getNumLobbyMembers(Globals.LOBBY_ID)
	if MatchState.is_host and player_count >= 2:
		send_p2p_packet(0,{"message":"START_MATCH","from":Steam.getFriendPersonaName(Globals.STEAM_ID)})
		start_match()
	else:
		if !MatchState.is_host:
			display_Message("Only the host can start the game.")
		else:
			display_Message("At least 2 players are required to start the game.")

func _on_send_message_pressed():
	send_Chat_Message()

func _on_lobby_search_exit_button_pressed():
	lobbySearch.hide()
	lobbyPanel.show()

#Utility functions
func check_Command_Line():
	var ARGUMENTS = OS.get_cmdline_args()
	
	if ARGUMENTS.size() > 0:
		for argument in ARGUMENTS:
			#Invite argument passed
			if Globals.LOBBY_INVITE_ARG:
				join_Lobby(int(argument))
			
			#Steam connection argument
			if argument == "+connect_lobby":
				Globals.LOBBY_INVITE_ARG = true

func display_Message(message):
	chatOutput.add_text("\n" + str(message))

func get_Lobby_Members():
	#Clear previous lobby members list
	Globals.LOBBY_MEMBERS.clear()
	
	# Get number of members in lobby
	var MEMBERCOUNT = Steam.getNumLobbyMembers(Globals.LOBBY_ID)
	# Update player list count
	lobbyPlayerCount.set_text("Players ("+str(MEMBERCOUNT)+")")
	
	for MEMBER in range(0, MEMBERCOUNT):
		#Members Steam ID 
		var MEMBER_STEAM_ID = Steam.getLobbyMemberByIndex(Globals.LOBBY_ID,MEMBER)
		#Members Steam Name
		var MEMBER_STEAM_NAME = Steam.getFriendPersonaName(MEMBER_STEAM_ID)
		#Add members to list
		add_Player_List(MEMBER_STEAM_ID, MEMBER_STEAM_NAME)
		
func add_Player_List(steam_id, steam_name):
	#Add players to list
	Globals.LOBBY_MEMBERS.append({"steam_id":steam_id,"steam_name":steam_name})
	#Ensure list is cleared
	lobbyOutput.clear()
	# Populate player list
	for MEMBER in Globals.LOBBY_MEMBERS:
		lobbyOutput.add_text(str(MEMBER['steam_name'])+"\n")

func send_Chat_Message():
	# Get chat input
	var MESSAGE = chatInput.text
	# Pass message to steam 
	var SENT = Steam.sendLobbyChatMsg(Globals.LOBBY_ID, MESSAGE)
	# Check message sent
	if not SENT:
		display_Message("Error: Chat message failed to send")
	#Clear chat input
	chatInput.text = ""

func leave_Lobby():
	#If in a lobby, leave it
	if Globals.LOBBY_ID != 0:
		display_Message("Leaving lobby...")
		#Send leave request
		Steam.leaveLobby(Globals.LOBBY_ID)
		#Wipe LOBBY_ID
		Globals.LOBBY_ID = 0
		
		lobbyGetName.text = "Lobby Name"
		lobbySetName.text = ""
		lobbyPlayerCount.text = "Players (0)"
		lobbyOutput.clear()
		
		# Close Session with all users
		for MEMBERS in Globals.LOBBY_MEMBERS:
			Steam.closeP2PSessionWithUser(MEMBERS['steam_id'])
		
		# Clear lobby list
		Globals.LOBBY_MEMBERS.clear()
		toggle_join_lobby_button(true)
		toggle_start_match_button(false)

func make_p2p_handshake():
	print("Sending P2P handshake to the lobby")
	
	send_p2p_packet(0,{"message":"handshake","from":Steam.getFriendPersonaName(Globals.STEAM_ID)})

func read_p2p_packet() -> void:
	var packet_size: int = Steam.getAvailableP2PPacketSize(0)
	if packet_size > 0:
		var this_packet = Steam.readP2PPacket(packet_size, 0)
		if this_packet == null:
			print("Error: readP2PPacket returned null!")
			return
			
		var packet_dict: Dictionary = this_packet
		var packet_sender: int = packet_dict['remote_steam_id']
		var packet_code: PackedByteArray = packet_dict['data']
		
		var decompressed_data: PackedByteArray = packet_code.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
		if decompressed_data.is_empty():
			print("Error: Decompression failed!")
			return
			
		var readable_data = bytes_to_var(decompressed_data)
		if readable_data == null:
			print("Error: bytes_to_var failed! Data may not be a Godot variant.")
			return
			
		print("Packet contents: %s" % readable_data)
		
		# Handle different message types
		if readable_data.has("message"):
			match readable_data["message"]:
				"START_MATCH":
					print("START_MATCH command received from %d!" % packet_sender)
					start_match()
				"REPLENISH_HAND":
					if readable_data.has("cards"):
						print("Received cards to replenish hand: ", readable_data["cards"])
						matchUi.replenish_hand(readable_data["cards"])
				"PLAYER_TURN":
					if readable_data.has("steam_id"):
						var turn_steam_id = readable_data["steam_id"]
						var player_name = Steam.getFriendPersonaName(turn_steam_id)
						
						if turn_steam_id == Globals.STEAM_ID:
							print("It's my turn!")
							matchUi.set_is_player_turn(true)
						else:
							print("It's not my turn!")
							matchUi.set_is_player_turn(false)
							
						matchUi.update_turn_indicators(turn_steam_id)
						matchUi.update_attacker_label(player_name)
						matchUi.update_defender_label("")  # Clear defender label until target is selected
				"POPULATE_PLAYER_LIST":
					if readable_data.has("players") and readable_data.has("turn_order"):
						print("Received player list update from host")
						matchUi._on_populate_player_list(readable_data["players"], readable_data["turn_order"])
				"FORWARD_ATTACK_LOCK_IN":
					if readable_data.has("steam_id") and readable_data.has("target_steam_id") and readable_data.has("attack_cards"):
						if MatchState.is_host:
							print("Host processing forwarded attack lock-in")
							MatchState.lock_in_attack(readable_data["steam_id"], readable_data["target_steam_id"], readable_data["attack_cards"])
						else:
							print("Non-host received forwarded attack lock-in data: ", readable_data)
				"FORWARD_DEFENSE_LOCK_IN":
					if readable_data.has("steam_id") and readable_data.has("target_steam_id") and readable_data.has("defense_cards"):
						if MatchState.is_host:
							print("Host processing forwarded defense lock-in")
							MatchState.lock_in_defense(readable_data["steam_id"], readable_data["target_steam_id"], readable_data["defense_cards"])
						else:
							print("Non-host received forwarded defense lock-in data: ", readable_data)
				"UPDATE_PLAYER_AREA_ON_ATTACK":
					if readable_data.has("steam_id") and readable_data.has("target_steam_id") and readable_data.has("attack_cards"):
						print("Updating player area with attack data")
						matchUi._on_update_player_area_with_locked_in_attack(
							readable_data["steam_id"],
							readable_data["target_steam_id"],
							readable_data["attack_cards"]
						)
				"UPDATE_PLAYER_AREA_ON_DEFENSE":
					if readable_data.has("steam_id") and readable_data.has("target_steam_id") and readable_data.has("defense_cards"):
						print("Updating player area with defense data")
						matchUi._on_update_player_area_with_locked_in_defense(
							readable_data["steam_id"],
							readable_data["target_steam_id"],
							readable_data["defense_cards"]
						)
				"PLAYER_UPDATED":
					if readable_data.has("player_data"):
						print("Received player update: ", readable_data["player_data"])
						matchUi._on_player_updated(readable_data["player_data"])
				"UPDATE_DAMAGE_INDICATOR":
					if readable_data.has("attack_value") and readable_data.has("attack_type"):
						print("Received damage indicator update: ", readable_data["attack_value"], " ", readable_data["attack_type"], " damage")
				"CLEAR_PLAY_AREA":
					print("Received clear play area signal")
					matchUi.clear_play_area()

func send_p2p_packet(this_target: int, packet_data: Dictionary):
	print("Sending P2P packet")
	print(packet_data)
	var send_type: int = Steam.P2P_SEND_RELIABLE
	var channel: int = 0
	
	var this_data: PackedByteArray = var_to_bytes(packet_data).compress(FileAccess.COMPRESSION_GZIP)
	
	# If sending to everyone
	if this_target == 0:
		if Globals.LOBBY_MEMBERS.size() > 1:
			for this_member in Globals.LOBBY_MEMBERS:
				if this_member['steam_id'] != Globals.STEAM_ID:
					Steam.sendP2PPacket(this_member['steam_id'], this_data, send_type, channel)
					
	else:
		Steam.sendP2PPacket(this_target, this_data, send_type, channel)

func toggle_join_lobby_button(is_pressable:bool):
	if is_pressable:
		joinLobbyButton.disabled = false
		createLobbyButton.disabled = false
	else:
		createLobbyButton.disabled = true
		joinLobbyButton.disabled = true
	
func toggle_start_match_button(is_pressable):
	# Only enable the button if we're the host AND have 2+ players
	var player_count = Steam.getNumLobbyMembers(Globals.LOBBY_ID)
	startMatchButton.disabled = !(is_pressable && player_count >= 2)
		
func start_match():
	lobbyPanel.hide()
	lobbySearch.hide()
	matchUi.show()
	matchUi.begin_match()

func migrate_host():
	if Globals.LOBBY_MEMBERS.size() > 0:
		# Get the first remaining member as the new host
		var new_host_id = Globals.LOBBY_MEMBERS[0]["steam_id"]
		host_steam_id = new_host_id
		Steam.setLobbyData(Globals.LOBBY_ID, "host_id", str(host_steam_id))
		
		# Update local host status
		MatchState.is_host = (Globals.STEAM_ID == host_steam_id)
		toggle_start_match_button(MatchState.is_host)
		
		if MatchState.is_host:
			display_Message("You are now the host of this lobby.")
		else:
			var host_name = Steam.getFriendPersonaName(host_steam_id)
			display_Message(str(host_name) + " is now the host of this lobby.")

func _on_replenish_player_hand(player_id: int, new_cards: Array):
	#print("Received replenish_player_hand signal for player ", player_id, " with cards: ", new_cards)
	if player_id == host_steam_id:
		matchUi.replenish_hand(new_cards)
	else:
		# Send the cards to the specific player
		send_p2p_packet(player_id, {
			"message": "REPLENISH_HAND",
			"cards": new_cards
		})

func _on_current_player_turn(steam_id: int):
	print("_on_current_player_turn called with steam_id: ", steam_id)
	var player_name = Steam.getFriendPersonaName(steam_id)
	matchUi.update_turn_indicators(steam_id)
	matchUi.update_attacker_label(player_name)
	matchUi.update_defender_label("")  # Clear defender label until target is selected
	
	if steam_id == Globals.STEAM_ID:
		# This is our turn - we'll build out the turn handling logic later
		matchUi.set_is_player_turn(true)
	else:
		# This is another player's turn - we'll build out the opponent turn handling logic later
		matchUi.set_is_player_turn(false)
		
	# Send P2P packet to all players about whose turn it is
	send_p2p_packet(0, {
		"message": "PLAYER_TURN",
		"steam_id": steam_id
	})

func _on_populate_player_list(players: Dictionary, turn_order: Array):
	# Only the host should send this packet
	if MatchState.is_host:
		send_p2p_packet(0, {
			"message": "POPULATE_PLAYER_LIST",
			"players": players,
			"turn_order": turn_order
		})

func _on_forward_attack_lock_in_to_host(steam_id: int, target_steam_id: int, attack_cards: Array):
	print("Forwarding attack lock-in to host")
	send_p2p_packet(0, {
		"message": "FORWARD_ATTACK_LOCK_IN",
		"steam_id": steam_id,
		"target_steam_id": target_steam_id,
		"attack_cards": attack_cards
	})

func _on_update_player_area_with_locked_in_attack(steam_id: int, target_steam_id: int, attack_cards: Array):
	print("Sending update player area packet for attack")
	send_p2p_packet(0, {
		"message": "UPDATE_PLAYER_AREA_ON_ATTACK",
		"steam_id": steam_id,
		"target_steam_id": target_steam_id,
		"attack_cards": attack_cards
	})

func _on_forward_defense_lock_in_to_host(steam_id: int, target_steam_id: int, defense_cards: Array):
	print("Forwarding defense lock-in to host")
	send_p2p_packet(0, {
		"message": "FORWARD_DEFENSE_LOCK_IN",
		"steam_id": steam_id,
		"target_steam_id": target_steam_id,
		"defense_cards": defense_cards
	})

func _on_update_player_area_with_locked_in_defense(steam_id: int, target_steam_id: int, defense_cards: Array):
	print("Sending update player area packet for defense")
	send_p2p_packet(0, {
		"message": "UPDATE_PLAYER_AREA_ON_DEFENSE",
		"steam_id": steam_id,
		"target_steam_id": target_steam_id,
		"defense_cards": defense_cards
	})

func _on_player_updated(player_data: Dictionary):
	print("\n=== Steam Lobby: Player Update ===")
	print("Is host: ", MatchState.is_host)
	print("Received player data: ", player_data)
	print("Sending player update packet")
	send_p2p_packet(0, {
		"message": "PLAYER_UPDATED",
		"player_data": player_data
	})
	print("=== Player Update Packet Sent ===\n")

func _on_update_damage_indicator(attack_value: int, attack_type: String):
	print("Sending damage indicator update to all players")
	send_p2p_packet(0, {
		"message": "UPDATE_DAMAGE_INDICATOR",
		"attack_value": attack_value,
		"attack_type": attack_type
	})

func _on_clear_play_area():
	print("Sending clear play area signal to all players")
	send_p2p_packet(0, {
		"message": "CLEAR_PLAY_AREA"
	})
	# Also clear the host's play area
	matchUi.clear_play_area()
