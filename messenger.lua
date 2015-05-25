--Abstracts message passing between two clients
local messenger = {}

controller = require("controller")

--list of message types
messenger.INPUT = 0

--the first character of the message tells what kind of message was sent
local message_type_to_char = {
  [messenger.INPUT] = "i"
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
  [messenger.INPUT] = function(message)
    local split_message = bizstring.split(message, ",")
    --get buttons from the message
    local input_message = split_message[0]
    their_input = {}
    for i, b in pairs(controller.buttons) do
      if (input_message:sub(i,i) == "1") then
        their_input[b] = true
      end
    end
    --get frame count from message
    local frame_message = split_message[1]
    their_frame = tonumber(frame_message)
    return {their_input, their_frame}
  end
}

--recieves a message from the other client, returning the message type
--along with a table containing the message type-specific information
--this will block as long as the socket will, and will throw an error on timeout
function messenger.receive(client_socket)
  --get the next message
  message = client_socket:receive()
  if(message == nil) then
    error("Timed out waiting for a message from the other player.")
  end
  --determine message type
  local message_type = char_to_message_type[message:sub(1,1)]
  if (message_type == nil) then
    error("Recieved an unidentifiable message.")
  end
  message = message:sub(2)
  --decode the message
  local decoder = decode_message[message_type]
  local data = decoder(message)
  --return info
  return message_type, data
end


return messenger