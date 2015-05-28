--Abstracts message passing between two clients
--author: TheOnlyOne
local messenger = {}

controller = require("controller")

--list of message types
messenger.INPUT = 0
messenger.CONFIG = 1
messenger.PAUSE = 2
messenger.UNPAUSE = 3
messenger.QUIT = 4
messenger.MODIFIER = 5
messenger.SAVE_HASH = 6
messenger.LOAD_FAIL = 7
messenger.LOAD = 8
messenger.SAVE = 9

--the first character of the message tells what kind of message was sent
local message_type_to_char = {
  [messenger.INPUT] = "i",
  [messenger.CONFIG] = "c",
  [messenger.PAUSE] = "p",
  [messenger.UNPAUSE] = "u",
  [messenger.QUIT] = "q",
  [messenger.MODIFIER] = "m",
  [messenger.SAVE_HASH] = "h",
  [messenger.LOAD_FAIL] = "f",
  [messenger.LOAD] = "l",
  [messenger.SAVE] = "s"
}
--inverse of the previous table
local char_to_message_type = {}
for t, c in pairs(message_type_to_char) do
  char_to_message_type[c] = t
end



--describes how to encode a message for each message type
local encode_message = {

  --an input message expects 2 arguments:
  --a table containing the inputs pressed,
  --and the frame this input should be pressed on
  [messenger.INPUT] = function(data)
    local my_input = data[1]
    local frame = data[2]
    --convert pressed buttons to a binary string
    message = ""
    for i, b in pairs(controller.buttons) do
      if (my_input[b] == true) then
        message = message .. "1"
      else
        message = message .. "0"
      end
    end
    message = message .. "," .. frame
    return message
  end,

  --a config message expects 4 arguments:
  --the player number,
  --the latency frames,
  --the hash of the input modifier file,
  --and the hash of the code used in gameplay sync
  [messenger.CONFIG] = function(data)
    local player_num = data[1]
    local latency = data[2]
    local modifier_hash = data[3]
    local sync_hash = data[4]
    local message = player_num .. "," .. latency .. "," ..
                    modifier_hash .. "," .. sync_hash
    return message
  end,

  --a pause message expects 1 argument:
  --"request" or "accept" depending on who pressed pause
  [messenger.PAUSE] = function(data)
    return data[1]
  end,

  --an unpause message expects no arguments
  [messenger.UNPAUSE] = function(data)
    return ""
  end,

  --a quit message expects no arguments
  [messenger.QUIT] = function(data)
    return ""
  end,

  --a modifier message expects exactly 2 arguments:
  --a boolean saying whether to turn the input modifier on or off,
  --and the frame this modifier should change on
  [messenger.MODIFIER] = function(data)
    local modifier_state = data[1]
    local frame = data[2]
    local message = ""
    if (modifier_state) then
      message = "1"
    else
      message = "0"
    end
    return message .. "," .. frame
  end,

  --a save hash message expects 1 argument:
  --the save hash number
  [messenger.SAVE_HASH] = function(data)
    local save_hash = data[1]
    return save_hash
  end,

  --a load fail message expects 1 argument:
  --the reason for failure
  [messenger.LOAD_FAIL] = function(data)
    local reason = data[1]
    return reason
  end,

  --a load message expects 1 argument:
  --the slot that should be loaded
  [messenger.LOAD] = function(data)
    local slot = data[1]
    return "" .. slot
  end,

  --a load message expects 2 arguments:
  --the slot that should be saved to,
  --and the frame on which the save should occur
  [messenger.SAVE] = function(data)
    local slot = data[1]
    local frame = data[2]
    return slot .. "," .. frame
  end
}

--sends a message to the other clients
--client_socket is the socket the message is being sent over
--message_type is one of the types listed above
--the remaining arguments are specific to the type of message being sent
function messenger.send(client_socket, message_type, ...)
  --pack message type-specific arguments into a table
  local data = {...}
  --get the function that should encode the message
  local encoder = encode_message[message_type]
  if (encoder == nil) then
    error("Attempted to send an unknown message type")
  end
  --encode the message
  local message = message_type_to_char[message_type] .. encoder(data)
  --send the message
  client_socket:send(message .. "\n")
end



--describes how to decode a message for each message type
local decode_message = {

  [messenger.INPUT] = function(split_message)
    --get buttons from the message
    local input_message = split_message[0]
    local their_input = {}
    for i, b in pairs(controller.buttons) do
      if (input_message:sub(i,i) == "1") then
        their_input[b] = true
      end
    end
    --get frame count from message
    local frame_message = split_message[1]
    local their_frame = tonumber(frame_message)
    return {their_input, their_frame}
  end,

  [messenger.CONFIG] = function(split_message)
    --get playernum from message
    local player_message = split_message[0]
    local their_playernum = tonumber(player_message)
    --get latency from message
    local latency_message = split_message[1]
    local their_latency = tonumber(latency_message)
    --get modifier hash from message
    local their_modifier_hash = split_message[2]
    --get sync hash from message
    local their_sync_hash = split_message[3]
    return {their_playernum, their_latency, their_modifier_hash, their_sync_hash}
  end,

  [messenger.PAUSE] = function(split_message)
    --get pause state from the message
    local their_pause_state = tonumber(split_message[0])
    return {their_pause_state}
  end,

  [messenger.UNPAUSE] = function(split_message)
    return {}
  end,

  [messenger.QUIT] = function(split_message)
    return {}
  end,

  [messenger.MODIFIER] = function(split_message)
    --get modifier state from message
    local modifier_state_message = split_message[0]
    local their_modifier_state = false
    if (modifier_state_message == "1") then
      their_modifier_state = true
    end
    --get frame count from message
    local frame_message = split_message[1]
    local their_frame = tonumber(frame_message)
    return {their_modifier_state, their_frame}
  end,

  [messenger.SAVE_HASH] = function(split_message)
    --get save hash from message
    local their_save_hash = split_message[0]
    return {their_save_hash}
  end,

  [messenger.LOAD_FAIL] = function(split_message)
    --get reason for failure from message
    local their_reason = split_message[0]
    return {their_reason}
  end,

  [messenger.LOAD] = function(split_message)
    --get slot from message
    local slot_message = split_message[0]
    local their_slot = tonumber(slot_message)
    return {their_slot}
  end,

  [messenger.SAVE] = function(split_message)
    --get slot from message
    local slot_message = split_message[0]
    local their_slot = tonumber(slot_message)
    --get frame from message
    local frame_message = split_message[1]
    local their_frame = tonumber(frame_message)
    return {their_slot, their_frame}
  end
}

--recieves a message from the other client, returning the message type
--along with a table containing the message type-specific information
--this will block as long as the socket will, and will throw an error on timeout
function messenger.receive(client_socket, nonblocking)
  if nonblocking then
    client_socket:settimeout(0)
  end

  --get the next message
  message = client_socket:receive()

  if nonblocking then
    client_socket:settimeout(config.input_timeout)
  end

  if(message == nil) then
    if nonblocking then 
      return nil
    else
      error("Timed out waiting for a message from the other player (the other player may have disconnected.)")
    end
  end
  --determine message type
  local message_type = char_to_message_type[message:sub(1,1)]
  if (message_type == nil) then
    error("Recieved an unidentifiable message.")
  end
  message = message:sub(2)
  --decode the message
  local decoder = decode_message[message_type]
  local split_message = bizstring.split(message, ",")
  local data = decoder(split_message)
  --return info
  return message_type, data
end


return messenger