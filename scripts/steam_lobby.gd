extends Control

enum lobby_status {Private, Friends, Public, Invisible}
enum search_distance {Close, Default, Far, Worldwide}

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

func _ready():
	#Set Steam Name
	steamName.text = Globals.STEAM_NAME
	#Steamwork Connections
	Steam.lobby_created.connect(_on_Lobby_Created)
	Steam.lobby_match_list.connect(_on_Lobby_Match_List)
	Steam.lobby_joined.connect(_on_Lobby_Joined)
	Steam.lobby_chat_update.connect(_on_Lobby_Chat_Update)
	Steam.lobby_message.connect(_on_Lobby_Message)
	#Steam.lobby_data_update.connect(_on_Lobby_Data_Update)
	#Steam.join_requested.connect(_on_Lobby_Join_Requested)
	
	check_Command_Line()
	
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
		

func _on_Lobby_Joined(lobbyID, permissions, locked, response):
	# Set lobby ID
	Globals.LOBBY_ID = lobbyID
	
	# Get the lobby name
	var lobby_name = Steam.getLobbyData(lobbyID, "name")
	lobbyGetName.text = str(lobby_name)
	
	# Get lobby members
	get_Lobby_Members()

func _on_Lobby_Join_Requested(lobbyID, friendID):
	# Get lobby owners name
	var OWNER_NAME = Steam.getFriendPersonaName(friendID)
	display_Message("Joining " + str(OWNER_NAME) + " lobby...")
	
	# Join Lobby
	join_Lobby(lobbyID)
	
func _on_Lobby_Data_Update(success, lobbyID, memberID, key):
	print("Success: "+str(success)+", Lobby ID: "+str(lobbyID)+", Member ID: "+str(memberID)+", Key: "+str(key))
	
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
		#Grab desired lobby data
		var LOBBY_NAME = Steam.getLobbyData(LOBBY, "name")
		
		# Get the current number of members
		var LOBBY_MEMBERS = Steam.getNumLobbyMembers(LOBBY)
		
		# Create Label for each lobby
		var LOBBY_LABEL = Label.new()
		LOBBY_LABEL.set_text("Lobby Name: " + str(LOBBY_NAME) + "\nPlayers:(" + str(LOBBY_MEMBERS) + "/12)")
		
		# Create button for each lobby
		var LOBBY_BUTTON = Button.new()
		LOBBY_BUTTON.text = "Join Lobby"
		
		
		var LOBBY_HBOX = HBoxContainer.new()
		
		lobbyList.add_child(LOBBY_HBOX)
		LOBBY_HBOX.add_child(LOBBY_LABEL)
		LOBBY_HBOX.add_child(LOBBY_BUTTON)
		
		LOBBY_BUTTON.pressed.connect(join_Lobby(LOBBY))

func _on_Lobby_Message(result, user, message,type):
	# Sender and their message
	var SENDER = Steam.getFriendPersonaName(user)
	display_Message(str(SENDER) + " : " + str(message))
	
# Button callback functions
func _on_create_lobby_pressed():
	if lobbySetName.text == "":
		lobbySetName.text = ""+steamName.text+"'s Lobby" 
	create_Lobby()

func _on_join_lobby_pressed():
	lobbyPanel.hide()
	lobbySearch.show()
	display_Message("Searching for lobbies...")
	Steam.addRequestLobbyListDistanceFilter(search_distance.Worldwide)
	Steam.requestLobbyList()
	
func _on_leave_lobby_pressed():
	leave_Lobby()
	
func _on_start_game_pressed():
	pass # Replace with function body.
	
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
