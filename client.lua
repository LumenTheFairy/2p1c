--author: TheOnlyOne

local socket = require("socket")
local sync = require("sync")

return function()

	client_socket, err = socket.connect(config.hostname, config.port)
	if (client_socket == nil) then
		printOutput("Connection failed: " .. err)
		cleanConnection()
		return
	end

	--display the server's information
	local peername, peerport = client_socket:getpeername()
	printOutput("Connected to " .. peername .. " on port " .. peerport)
	emu.frameadvance()
	emu.frameadvance()

	--make sure we don't block waiting for a response
	client_socket:settimeout(config.input_timeout)

	--when the script finishes, make sure to close the connection
	local function close_connection()
	  client_socket:close()
	  printOutput("Connection closed.")
	  cleanConnection()
	end

	event.onexit(function () close_connection(); forms.destroy(form1) end)

	--furthermore, override error with a function that closes the connection
	--before the error is actually thrown
	local old_error = error

	error = function(message, level)
	  close_connection()
	  printOutput(message)
	  --old_error(message, 0)
	end

	--sync the gameplay
	sync.initialize()
	sync.syncconfig(client_socket, 2)
	sync.synctoframe1(client_socket)
	sync.resetsync()
	
	syncStatus = "Play"
	return
end