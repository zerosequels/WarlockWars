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
		
		#Set Lobby Data
		Steam.setLobbyData(lobbyID, "name", lobbySetName.text)
		var lobby_name = Steam.getLobbyData(lobbyID, "name")
		lobbyGetName.text = str(lobby_name)
		toggle_join_lobby_button(false)
		toggle_start_match_button(true)
		

func _on_Lobby_Joined(lobbyID, permissions, locked, response):
	# Set lobby ID
	Globals.LOBBY_ID = lobbyID
	
	# Get the lobby name
	var lobby_name = Steam.getLobbyData(lobbyID, "name")
	lobbyGetName.text = str(lobby_name)
	toggle_join_lobby_button(false)
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
	#User who made lobby change
	var CHANGER = Steam.getFriendPersonaName(makingChangeID)
	
	# chatState change made
	match chatState:
		1:
			display_Message(str(CHANGER)+ " has joined the lobby.")
		2:
			display_Message(str(CHANGER)+ " has left the lobby.")
		4:
			display_Message(str(CHANGER)+ " has disconnected from the lobby.")
		8:
			display_Message(str(CHANGER)+ " has been kicked from the lobby.")
		16:
			display_Message(str(CHANGER)+ " has been banned from the lobby.")
		_:
			display_Message(str(CHANGER)+ " has has done ... something")
	#Get Lobby Members
	get_Lobby_Members()

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
	MatchState
	start_match()
	send_p2p_packet(0,{"message":"START_MATCH","from":Steam.getFriendPersonaName(Globals.STEAM_ID)})
	
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
		# Check for START_MATCH message
		if readable_data.has("message") and readable_data["message"] == "START_MATCH":
			print("START_MATCH command received from %d!" % packet_sender)
			start_match()
			
func send_p2p_packet(this_target: int, packet_data: Dictionary):
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
	if is_pressable:
		startMatchButton.disabled = false
	else:
		startMatchButton.disabled = true
		
func start_match():
	lobbyPanel.hide()
	lobbySearch.hide()
	matchUi.show()
	matchUi.begin_match()
