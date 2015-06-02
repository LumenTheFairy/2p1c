if (emu.framecount() ~= 1) then
	client.reboot_core()
	savestate.saveslot(0)
	emu.frameadvance()
end

local guiClick = {}


local form1, text1, btnKeymap, btnPause, btnQuit, btnFrame0, btnHost, btnClient
local txbIP, lblIP, txbPort, lblPort, txbLatency, lblLatency
local txbModifyInputs, lblModifyInputs, chkModifyInputs
local txbInputDisplay, lblInputDisplay, chkInputDisplay
local chkPlayer2, chkPlayer1, lblPlayer
local btnSaveSlot, btnLoadSlot, ddnSaveSlot, lblSaveSlot
local btnSaveConfig, btnLoadConfig

config = dofile("2p1c\\config.lua")
local sync = require("2p1c\\sync")
config.input_display_enabled = true
config.modify_inputs_enabled = true

function printOutput(str) 
	local outputtext = forms.gettext(text1)
	outputtext = "[" .. os.date("%H:%M:%S", os.time()) .. "] " .. str .. "\r\n" .. outputtext
	forms.settext(text1, outputtext)
end

function updateGUI()
	forms.settext(txbIP, config.hostname)
	forms.settext(txbPort, config.port)
	forms.settext(txbLatency, config.latency)
	forms.settext(txbModifyInputs, config.input_modifier)
	forms.settext(txbInputDisplay, config.input_display)

	forms.setproperty(chkPlayer1, "Checked", config.player == 1)
	forms.setproperty(chkPlayer2, "Checked", config.player == 2)

	forms.setproperty(chkInputDisplay, "Checked", config.input_display_enabled)
	forms.setproperty(chkModifyInputs, "Checked", config.modify_inputs_enabled)

	if config.input_display == "inputdisplay_none.lua" then
		forms.setproperty(chkInputDisplay, "Enabled", false)
	else
		forms.setproperty(chkInputDisplay, "Enabled", true)
	end	

	if (config.input_modifier == "inputmodifier_none.lua" or syncStatus == "Idle") then
		forms.setproperty(chkModifyInputs, "Enabled", false)
	else
		forms.setproperty(chkModifyInputs, "Enabled", true)
	end	

	if syncStatus == "Pause" then
		forms.settext(btnPause, "Unpause")
	else
		forms.settext(btnPause, "Pause")		
	end

	if syncStatus == "Idle" then
		forms.setproperty(txbIP, "Enabled", true)
		forms.setproperty(txbPort, "Enabled", true)
		forms.setproperty(txbLatency, "Enabled", true)
		forms.setproperty(txbModifyInputs, "Enabled", true)
		forms.setproperty(txbInputDisplay, "Enabled", true)
		forms.setproperty(chkPlayer1, "Enabled", true)
		forms.setproperty(chkPlayer2, "Enabled", true)
		forms.setproperty(btnHost, "Enabled", true)
		forms.setproperty(btnClient, "Enabled", true)
		--forms.setproperty(btnFrame0, "Enabled", true)
		forms.setproperty(btnLoadConfig, "Enabled", true)
		forms.setproperty(btnPause, "Enabled", false)
		forms.settext(btnQuit, "Quit 2P1C")	

		forms.setproperty(ddnSaveSlot, "Enabled", false)
		forms.setproperty(btnSaveSlot, "Enabled", false)
		forms.setproperty(btnLoadSlot, "Enabled", false)
	else
		forms.setproperty(txbIP, "Enabled", false)
		forms.setproperty(txbPort, "Enabled", false)
		forms.setproperty(txbLatency, "Enabled", false)
		forms.setproperty(txbModifyInputs, "Enabled", false)
		forms.setproperty(txbInputDisplay, "Enabled", false)
		forms.setproperty(chkPlayer1, "Enabled", false)
		forms.setproperty(chkPlayer2, "Enabled", false)
		forms.setproperty(btnHost, "Enabled", false)
		forms.setproperty(btnClient, "Enabled", false)
		forms.setproperty(btnFrame0, "Enabled", false)
		forms.setproperty(btnLoadConfig, "Enabled", false)
		forms.setproperty(btnPause, "Enabled", true)
		forms.settext(btnQuit, "End Sync")	

		forms.setproperty(ddnSaveSlot, "Enabled", true)
		forms.setproperty(btnSaveSlot, "Enabled", true)
		forms.setproperty(btnLoadSlot, "Enabled", true)
	end
end

function cleanConnection()
	syncStatus = "Idle"
	client_socket = nil

	updateGUI()
end

function changePlayer1()
	if config.player == 1 then
		config.player = 2
		forms.setproperty(chkPlayer2, "Checked", true)
	else
		config.player = 1
		forms.setproperty(chkPlayer2, "Checked", false)
	end
end

function changePlayer2()
	if config.player == 1 then
		config.player = 2
		forms.setproperty(chkPlayer1, "Checked", false)
	else
		config.player = 1
		forms.setproperty(chkPlayer1, "Checked", true)
	end
end

function toggleInputDisplay()
	config.input_display = forms.gettext(txbInputDisplay)
	config.input_display_enabled = not config.input_display_enabled
end

function prepareConnection()
	config.hostname = forms.gettext(txbIP)
	config.port = tonumber(forms.gettext(txbPort))
	config.latency = tonumber(forms.gettext(txbLatency))
	config.input_modifier = forms.gettext(txbModifyInputs)
	config.input_display = forms.gettext(txbInputDisplay)
	
	forms.setproperty(txbIP, "Enabled", false)
	forms.setproperty(txbPort, "Enabled", false)
	forms.setproperty(txbLatency, "Enabled", false)
	forms.setproperty(txbModifyInputs, "Enabled", false)
	forms.setproperty(chkPlayer1, "Enabled", false)
	forms.setproperty(chkPlayer2, "Enabled", false)
	forms.setproperty(btnHost, "Enabled", false)
	forms.setproperty(btnClient, "Enabled", false)
	forms.setproperty(btnFrame0, "Enabled", false)
	forms.setproperty(btnPause, "Enabled", true)
end

function togglePause()
	if syncStatus == "Play" then
		sendMessage["Pause"] = true
		forms.settext(btnPause, "Unpause")
	else
		sendMessage["Unpause"] = true
		forms.settext(btnPause, "Pause")
	end
end

function quit2P1C()
	if syncStatus == "Idle" then
		forms.destroy(form1)
	else
		sendMessage["Quit"] = true
	end
end

function saveSlot()
	sendMessage["Save"] = tonumber(forms.gettext(ddnSaveSlot))
end

function loadConfig()
	config = dofile("2p1c\\config.lua")
	config.input_display_enabled = true
	config.modify_inputs_enabled = true

	updateGUI()
end

function saveConfig()
	config.hostname = forms.gettext(txbIP)
	config.port = tonumber(forms.gettext(txbPort))
	config.latency = tonumber(forms.gettext(txbLatency))
	config.input_modifier = forms.gettext(txbModifyInputs)
	config.input_display = forms.gettext(txbInputDisplay)

	local output = [[
local config = {}

--This determines which player you are. This is mainly used in input modifiers
--and input displays. Valid player numbers are 1 and 2. Make sure this is the
--other number from the person you are playing with.
config.player = ]] .. config.player .. [[


--This is the amount of time, in seconds, that the host will wait for the
--client to connect. If this timeout is reached, the host script will end.
--This value is only inportant for the host.
config.accept_timeout = ]] .. config.accept_timeout .. [[


--This is the amount of time, in seconds, that the input syncer will wait
--for the other player's input. If this timeout is reached, the connection
--will end, so a low timeout may ruin syncing if one player pauses emulation,
--has a slowdown in emulation, or has a slowdown in connection speed.
config.input_timeout = ]] .. config.input_timeout .. [[


--This is the port the connection will happen over. Make sure this is the same
--for both players before trying to sync.
config.port = ]] .. config.port .. [[


--This is the ip address or hostname of the player running host.lua (ip
--addresses should should still be in quotes.) This value is only inportant
--for the client.
config.hostname = "]] .. config.hostname .. [["

--This is the number of frames the network has to send the inputs back and
--forth. It is also the number of frames that all input will be delayed. If
--this is too low, the gameplay will be very slow and choppy due to the fact
--that the players must wait to recieve the other's input. If this is too high,
--there will be noticable input delay.
config.latency = ]] .. config.latency .. [[


--This is the file name (without the .lua extension) of the lua script that
--contains the input modifier you wish to use. If you do not wish to run any
--input modification, set this to "inputmodifier_none".
config.input_modifier = "]] .. config.input_modifier .. [["

--This is the file name (without the .lua extension) of the lua script that
--contains the input display code wish to use. If you do not wish to display
--input, set this to "inputdisplay_none".
config.input_display = "]] .. config.input_display .. [["


return config
]]

	f = assert(io.open("2p1c\\config.lua", "w"))
	f:write(output)
	f:close()
end

local keymapfunc = require("2p1c\\setkeymap")
local hostfunc = require("2p1c\\host")
local clientfunc = require("2p1c\\client")


form1 = forms.newform(580, 390, "2p1c")
forms.setproperty(form1, "ControlBox", false)

text1 = forms.textbox(form1, "", 260, 325, nil, 290, 10, true, false)
forms.setproperty(text1, "ReadOnly", true)

btnPause = forms.button(form1, "Pause", togglePause, 10, 10, 125, 30)
btnQuit = forms.button(form1, "Quit 2P1C", quit2P1C, 145, 10, 125, 30)
forms.setproperty(btnPause, "Enabled", false)

btnKeymap = forms.button(form1, "Set Controls", function() guiClick["Set Keymap"] = keymapfunc end, 10, 50, 80, 30)
btnHost = forms.button(form1, "Host", function() prepareConnection(); guiClick["Host Server"] = hostfunc end, 100, 50, 80, 30)
btnClient = forms.button(form1, "Join", function() prepareConnection(); guiClick["Join Server"] = clientfunc end, 190, 50, 80, 30)

txbIP = forms.textbox(form1, "", 140, 20, nil, 10, 110, false, false)
lblIP = forms.label(form1, "Host IP (Client only):", 15, 95, 120, 20)
txbPort = forms.textbox(form1, "", 60, 20, "UNSIGNED", 160, 110, false, false)
lblPort = forms.label(form1, "Port:", 165, 95, 50, 20)
txbLatency = forms.textbox(form1, "", 40, 20, "UNSIGNED", 230, 110, false, false)
lblLatency = forms.label(form1, "Latency:", 227, 95, 50, 20)

txbModifyInputs = forms.textbox(form1, "", 195, 20, nil, 10, 155, false, false)
lblModifyInputs = forms.label(form1, "Input Modifier:", 15, 140, 130, 20)
chkModifyInputs = forms.checkbox(form1, "Enable", 215, 154)

txbInputDisplay = forms.textbox(form1, "", 195, 20, nil, 10, 200, false, false)
lblInputDisplay = forms.label(form1, "Input Display:", 15, 185, 130, 20)
chkInputDisplay = forms.checkbox(form1, "Enable", 215, 199)

chkPlayer2 = forms.checkbox(form1, "2", 180, 235)
chkPlayer1 = forms.checkbox(form1, "1", 145, 235)
lblPlayer = forms.label(form1, "Select Player:", 65, 239, 150, 30)

forms.addclick(chkPlayer1, changePlayer1)
forms.addclick(chkPlayer2, changePlayer2)
forms.addclick(chkModifyInputs, function() sendMessage["ModifyInputs"] = not forms.ischecked(chkModifyInputs) end)
forms.addclick(chkInputDisplay, toggleInputDisplay)

btnSaveSlot = forms.button(form1, "Save", function() sendMessage["Save"] = tonumber(forms.gettext(ddnSaveSlot)) end, 160, 273, 50, 23)
btnLoadSlot = forms.button(form1, "Load", function() sendMessage["Load"] = tonumber(forms.gettext(ddnSaveSlot)) end, 220, 273, 50, 23)
ddnSaveSlot = forms.dropdown(form1, {"1", "2", "3", "4", "5", "6", "7", "8", "9"}, 120, 274, 30, 20)
lblSaveSlot = forms.label(form1, "Select savestate slot:", 10, 277, 200, 30)


btnSaveConfig = forms.button(form1, "Save Settings", function() guiClick["Save Settings"] = saveConfig end, 10, 310, 125, 25)
btnLoadConfig = forms.button(form1, "Discard Changes", function() guiClick["Discard Changes"] = loadConfig end, 145, 310, 125, 25)




event.onexit(function() forms.destroy(form1) end)


sendMessage = {}
syncStatus = "Idle"
local prev_syncStatus = "Idle"
local prev_modify_inputs_enabled = true
wclient_socket = nil

updateGUI()

local threads = {}

while 1 do
	if forms.gettext(form1) == "" then
		return
	end

	if (prev_syncStatus ~= syncStatus or prev_modify_inputs_enabled ~= config.modify_inputs_enabled) then
		prev_syncStatus = syncStatus
		prev_modify_inputs_enabled = config.modify_inputs_enabled
		updateGUI()
	end

	for k,v in pairs(guiClick) do
		threads[coroutine.create(v)] = k
	end
	guiClick = {}

	for k,v in pairs(threads) do
		if coroutine.status(k) == "dead" then
			threads[k] = nil
		else
			local status, err = coroutine.resume(k)
			if (status == false) then
				if (err ~= nil) then
					printOutput("Error during " .. v .. ": " .. err)
				else
					printOutput("Error during " .. v .. ": No error message")
				end
			end						
		end
	end

	if syncStatus == "Play" then
		local thread = coroutine.create(sync.syncallinput)
		local status, err = coroutine.resume(thread, client_socket)

		if (status == false and err ~= nil) then
			printOutput("Error during sync inputs (Play): " .. err)
		end
	end

	if syncStatus == "Pause" then
		local thread = coroutine.create(sync.syncpause)
		local status, err = coroutine.resume(thread, client_socket)

		if (status == false and err ~= nil) then
			printOutput("Error during sync inputs (Pause): " .. err)
		end

		emu.yield()
	else
		emu.frameadvance()		
	end

	--clear all input so that actual inputs do not interfere
  	joypad.set(controller.unset)
end