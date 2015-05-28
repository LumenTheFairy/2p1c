config = require("config")
local sync = require("sync")

local guiClick = {}

event.onexit(function() forms.destroy(form1) end)

function printOutput(str) 
	outputtext = outputtext .. str .. "\r\n"
	flushOutput()
end

function updateGUI()
	forms.settext(txbIP, config.hostname)
	forms.settext(txbPort, config.port)
	forms.settext(txbModifyInputs, config.input_modifier)

	if config.player == 1 then
		forms.setproperty(chkPlayer1, "Checked", true)
		forms.setproperty(chkPlayer2, "Checked", false)
	else
		forms.setproperty(chkPlayer1, "Checked", false)
		forms.setproperty(chkPlayer2, "Checked", true)
	end

	if config.input_display ~= "inputdisplay_none" then
		forms.setproperty(chkInputDisplay, "Checked", true)
	elseif config.input_display_temp == nil then
		forms.setproperty(chkInputDisplay, "Enabled", false)
	end	

	if syncStatus == "Pause" then
		forms.settext(btnPause, "Unpause")
	else
		forms.settext(btnPause, "Pause")		
	end

	if syncStatus == "Idle" then
		forms.setproperty(txbIP, "Enabled", true)
		forms.setproperty(txbPort, "Enabled", true)
		forms.setproperty(txbModifyInputs, "Enabled", true)
		forms.setproperty(chkPlayer1, "Enabled", true)
		forms.setproperty(chkPlayer2, "Enabled", true)
		forms.setproperty(btnHost, "Enabled", true)
		forms.setproperty(btnClient, "Enabled", true)
		forms.setproperty(btnFrame0, "Enabled", true)
		forms.setproperty(btnPause, "Enabled", false)
		forms.settext(btnQuit, "Quit 2P1C")	

		for k,v in pairs(save_handles) do
			forms.setproperty(k, "Enabled", false)
		end
		for k,v in pairs(load_handles) do
			forms.setproperty(k, "Enabled", false)
		end
	else
		forms.setproperty(txbIP, "Enabled", false)
		forms.setproperty(txbPort, "Enabled", false)
		forms.setproperty(txbModifyInputs, "Enabled", false)
		forms.setproperty(chkPlayer1, "Enabled", false)
		forms.setproperty(chkPlayer2, "Enabled", false)
		forms.setproperty(btnHost, "Enabled", false)
		forms.setproperty(btnClient, "Enabled", false)
		forms.setproperty(btnFrame0, "Enabled", false)
		forms.setproperty(btnPause, "Enabled", true)
		forms.settext(btnQuit, "End Sync")	

		for k,v in pairs(save_handles) do
			forms.setproperty(k, "Enabled", true)
		end
		for k,v in pairs(load_handles) do
			forms.setproperty(k, "Enabled", true)
		end	
	end
end

function cleanConnection()
	syncStatus = "Idle"
	client_socket = nil

	updateGUI()
end

local text1
outputtext = ""
function flushOutput() 
	forms.settext(text1, outputtext)
end

function frame0()
	client.reboot_core()
	savestate.saveslot(0)
	forms.destroy(form1)
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
	if config.input_display ~= "inputdisplay_none" then
		config.input_display_temp = config.input_display
		config.input_display = "inputdisplay_none"
	elseif config.input_display_temp ~= nil then
		config.input_display = config.input_display_temp
		config.input_display_temp = nil
	end
end

function prepareConnection()
	config.hostname = forms.gettext(txbIP)
	config.port = forms.gettext(txbPort)
	config.input_modifier = forms.gettext(txbModifyInputs)
	forms.setproperty(txbIP, "Enabled", false)
	forms.setproperty(txbPort, "Enabled", false)
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

local keymapfunc = require("setkeymap")
local hostfunc = require("host")
local clientfunc = require("client")


form1 = forms.newform(580, 390, "2p1c")
forms.setproperty(form1, "ControlBox", false)

text1 = forms.textbox(form1, "", 260, 325, nil, 290, 10, true, false)
forms.setproperty(text1, "ReadOnly", true)

btnFrame0 = forms.button(form1, "Initialize", frame0, 10, 50, 80, 30)
btnKeymap = forms.button(form1, "Set Controls", function() guiClick["setkeymap"] = keymapfunc end, 10, 10, 80, 30)
btnQuit = forms.button(form1, "Quit 2P1C", quit2P1C, 190, 10, 80, 30)
btnHost = forms.button(form1, "Host", function() prepareConnection(); guiClick["host"] = hostfunc end, 100, 50, 80, 30)
btnClient = forms.button(form1, "Client", function() prepareConnection(); guiClick["client"] = clientfunc end, 190, 50, 80, 30)
btnPause = forms.button(form1, "Pause", togglePause, 100, 10, 80, 30)
forms.setproperty(btnPause, "Enabled", false)

txbIP = forms.textbox(form1, "", 170, 20, nil, 10, 110, false, false)
lblIP = forms.label(form1, "Host IP (Client only):", 15, 95, 130, 20)
txbPort = forms.textbox(form1, "", 80, 20, "UNSIGNED", 190, 110, false, false)
lblPort = forms.label(form1, "Port:", 195, 95, 130, 20)
txbModifyInputs = forms.textbox(form1, "", 260, 20, nil, 10, 155, false, false)
lblModifyInputs = forms.label(form1, "Input Modifier:", 15, 140, 130, 20)
chkInputDisplay = forms.checkbox(form1, "Input Display", 190, 190)
chkPlayer2 = forms.checkbox(form1, "Player 2", 80, 190)
chkPlayer1 = forms.checkbox(form1, "Player 1", 10, 190)

forms.addclick(chkPlayer1, changePlayer1)
forms.addclick(chkPlayer2, changePlayer2)
forms.addclick(chkInputDisplay, toggleInputDisplay)

--create buttons to load a savestate slot
save_handles = {}
local lblSaveSlot = forms.label(form1, "Save to savestate slot:", 5, 230, 130, 20)
for i = 1,9 do
    save_handles[forms.button(form1, "" .. i, function() sendMessage["Save"] = i end, 30 * i - 20, 250, 20, 25)] = true
end

--create buttons to save to a savestate slot
load_handles = {}
local lblLoadSlot = forms.label(form1, "Load from savestate slot:", 5, 290, 130, 20)
for i = 1,9 do
    load_handles[forms.button(form1, "" .. i, function() sendMessage["Load"] = i end, 30 * i - 20, 310, 20, 25)] = true
end

sendMessage = {}
syncStatus = "Idle"
local prev_syncStatus = "Idle"
wclient_socket = nil

updateGUI()

while 1 do
	if forms.gettext(form1) == "" then
		return
	end

	if (prev_syncStatus ~= syncStatus) then
		prev_syncStatus = syncStatus
		updateGUI()
	end

	for k,v in pairs(guiClick) do
		local err = v()

		if (err ~= nil) then
			printOutput("Error during " .. k .. ": " .. err)
		end
	end
	guiClick = {}

	if syncStatus == "Play" then
		sync.syncallinput(client_socket)
	end

	if syncStatus == "Pause" then
		sync.syncpause(client_socket)
		emu.yield()
	else
		emu.frameadvance()		
	end

	flushOutput()

	--clear all input so that actual inputs do not interfere
  	joypad.set(controller.unset)
end