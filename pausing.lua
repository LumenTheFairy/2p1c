--author: TheOnlyOne
local pausing = {}

local config = require("config")
local messenger = require("messenger")

--the person who paused gets a menu with various options
function pausing.pausemenu(client_socket, future_frame)
  --send back information about how we unpaused
  local message_type = -1
  local data = {}
  --causes the other player to pause, and pause the emulator
  messenger.send(client_socket, messenger.PAUSE)
  client.pause()

  --create form for pause menu
  local form_handle = forms.newform(150, 150, "Paused")

  --create unpuase button
  local unpause_event = function()
    --tell the other player to unpause, unpause, and close the menu
    messenger.send(client_socket, messenger.UNPAUSE)
    client.unpause()
    forms.destroy(form_handle)
    message_type = messenger.UNPAUSE
  end
  local unpause_handle = forms.button(form_handle, "Unpause", unpause_event, 5, 10, 60, 25)

  --create quit button
  local quit_event = function()
    --tell the other player to quit, and close the menu
    messenger.send(client_socket, messenger.QUIT)
    client.unpause()
    forms.destroy(form_handle)
    message_type = messenger.QUIT
  end
  local quit_handle = forms.button(form_handle, "Quit", quit_event, 75, 10, 60, 25)

  --create buttons to toggle input modification
  local modifier_lable_handle = forms.label(form_handle, "Set use of input modifier:", 5, 40, 130, 20)

  local modifier_on_event = function()
    --tell the other player to quit, and close the menu
    messenger.send(client_socket, messenger.MODIFIER, true, future_frame)
    client.unpause()
    forms.destroy(form_handle)
    message_type = messenger.MODIFIER
    data = {true, future_frame}
  end
  local modifier_on_handle = forms.button(form_handle, "ON", modifier_on_event, 5, 65, 60, 25)

  local modifier_off_event = function()
    --tell the other player to quit, and close the menu
    messenger.send(client_socket, messenger.MODIFIER, false, future_frame)
    client.unpause()
    forms.destroy(form_handle)
    message_type = messenger.MODIFIER
    data = {false, future_frame}
  end
  local modifier_on_handle = forms.button(form_handle, "OFF", modifier_off_event, 75, 65, 60, 25)

  --unpause if the form is closed
  --(this was the only way I could figure out to test if the form is open
  --this also ensures that unpause is sent before the next input)
  while client.ispaused() do
    if ("" == forms.gettext(form_handle)) then
      unpause_event()
    else
      emu.yield()
    end
  end

  return message_type, data
end

--the other player simply blocks on receive until the player on the menu makes a choice
--returns the message the other player sent from the pause menu
function pausing.pausewait(client_socket)
  console.log("The other player has paused.")
  --block until a message is received, effectively pausing the game
  client_socket:settimeout(nil)
  local received_message_type, received_data = messenger.receive(client_socket)
  client_socket:settimeout(config.input_timeout)
  return received_message_type, received_data
end

return pausing