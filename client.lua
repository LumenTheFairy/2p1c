--author: TheOnlyOne
local socket = require("socket")
local sync = require("sync")
local config = require("config")

local client_socket = assert(socket.connect(config.hostname, config.port))

--display the server's information
local peername, peerport = client_socket:getpeername()
console.log("Connected to " .. peername .. " on port " .. peerport)
emu.frameadvance()

--make sure we don't block waiting for a response
client_socket:settimeout(config.input_timeout)

--when the script finishes, make sure to close the connection
event.onexit(function()
  client_socket:close()
  console.log("Connection closed.")
end)

--sync the gameplay
sync.synctoframe1()
sync.syncallinput(client_socket)