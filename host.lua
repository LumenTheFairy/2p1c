--author: TheOnlyOne
local socket = require("socket")
local sync = require("sync")
local config = require("config")

local server = assert(socket.bind("*", config.port, 1))
local ip, setport = server:getsockname()
console.log("Created server at " .. ip .. " on port " .. setport)

-- make sure we don't block waiting for a client_socket to accept
server:settimeout(config.accept_timeout)
-- wait for the connection from the client
console.log("Awaiting connection.")
emu.frameadvance()
local client_socket, err = server:accept()

--end execution if a client does not connect in time
if (client_socket == nil) then
  console.log("Timed out waiting for client_socket to connect.")
  server:close()
  return
end

local peername, peerport = client_socket:getpeername()

console.log("Connected to " .. peername .. " on port " .. peerport)
emu.frameadvance()

-- make sure we don't block forever waiting for input
client_socket:settimeout(config.input_timeout)

--
event.onexit(function()
  client_socket:close()
  server:close()
end)

sync.synctoframe1()
sync.syncallinput(client_socket, 1)