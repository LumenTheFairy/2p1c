--author: TheOnlyOne
local socket = require("socket")
local sync = require("sync")
local config = require("config")

local client_socket = assert(socket.connect(config.hostname, config.port))

--display the server's information
local peername, peerport = client_socket:getpeername()
console.log("Connected to " .. peername .. " on port " .. peerport)
emu.frameadvance()
emu.frameadvance()

--make sure we don't block waiting for a response
client_socket:settimeout(config.input_timeout)

--when the script finishes, make sure to close the connection
local function close_connection()
  client_socket:close()
  console.log("Connection closed.")
end

event.onexit(close_connection)

--furthermore, override error with a function that closes the connection
--before the error is actually thrown
local old_error = error

error = function(message, level)
  close_connection()
  old_error(message, 0)
end

--sync the gameplay
sync.syncconfig(client_socket, 2)
sync.synctoframe1(client_socket)
sync.syncallinput(client_socket)