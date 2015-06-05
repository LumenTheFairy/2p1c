--author: TheOnlyOne

local socket = require("socket")
local sync = require("2p1c\\sync")

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
	coroutine.yield()
	coroutine.yield()


	--make sure we don't block waiting for a response
	client_socket:settimeout(config.input_timeout)

	--sync the gameplay
	sync.initialize()
	sync.syncconfig(client_socket, 2)
	sync.synctoframe1(client_socket)
	sync.resetsync()
	
	updateGUI()
	syncStatus = "Play"
	return
end