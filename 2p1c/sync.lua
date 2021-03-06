--This file implements the logic that syncs two player's inputs
--author: TheOnlyOne and TestRunner
local sync = {}

local require_status, modify_inputs
display_inputs = nil

function sync.load_input_display()
  --attempt to load the desired input display. If it does not exist, load the
  --default display
  require_status, display_inputs = pcall(function()
    return dofile("2p1c\\InputDisplay\\" .. config.input_display .. ".id")
  end)
  if not require_status then
    printOutput("The input diplay specified in config.lua could not be found.")
    printOutput("Loading the default input diplay instead.")
    config.input_display = "none"
    display_inputs = dofile("2p1c\\InputDisplay\\none.id")
  end
end

--Load required files before attempting to sync
function sync.initialize() 
  --attempt to load the desired input modifier. If it does not exist, load the
  --default modifier
  require_status, modify_inputs = pcall(function()
    return dofile("2p1c\\InputModifier\\" .. config.input_modifier .. ".im")
  end)
  if not require_status then
    printOutput("The input modifier specified in config.lua could not be found.")
    printOutput("Loading the default input modifier instead.")
    config.input_modifier = "none"
    modify_inputs = dofile("2p1c\\InputModifier\\none.im")
  end
end

local messenger = require("2p1c\\messenger")
local savestate_sync = require("2p1c\\savestate_sync")

--makes sure that configurations are consistent between the two players
function sync.syncconfig(client_socket, default_player)
  printOutput("Checking that configurations are consistent (this may take a few seconds...)")
  coroutine.yield()
  coroutine.yield()


  --construct a value representing the input modifier that is in use
  local sha1 = require("2p1c\\sha1")
  local modifier_text = ""
  for line in io.lines("2p1c\\InputModifier\\" .. config.input_modifier .. ".im") do modifier_text = modifier_text .. line .. "\n" end
  local modifier_hash = sha1.sha1(modifier_text)

  --construct a value representing the sync code that is in use
  local sync_code = ""
  for line in io.lines("2p1c\\sync.lua") do sync_code = sync_code .. line .. "\n" end
  for line in io.lines("2p1c\\controller.lua") do sync_code = sync_code .. line .. "\n" end
  for line in io.lines("2p1c\\messenger.lua") do sync_code = sync_code .. line .. "\n" end
  local sync_hash = sha1.sha1(sync_code)

  --send the configuration
  messenger.send(client_socket, messenger.CONFIG,
                 config.player, config.latency, modifier_hash, sync_hash)

  --receive their configuration
  local received_message_type, received_data = messenger.receive(client_socket)
  if (received_message_type ~= messenger.CONFIG) then
    error("Unexpected message type received.")
  end
  local their_player = received_data[1]
  local their_latency = received_data[2]
  local their_modifier_hash = received_data[3]
  local their_sync_hash = received_data[4]

  --check consistency of configurations

  --check players
  if (config.player == their_player) then
    printOutput("Both players have choosen the same player number.")
    printOutput("Setting you to player " .. default_player .. ".")
    config.player = default_player
  elseif (config.player < 1 or config.player > 2) then
    printOutput("Your player number is not 1 or 2.")
    printOutput("Setting you to player " .. default_player .. ".")
    config.player = default_player
  elseif (their_player < 1 or their_player > 2) then
    printOutput("Their player number is not 1 or 2.")
    printOutput("Setting you to player " .. default_player .. ".")
    config.player = default_player
  end

  --check latency
  if (config.latency ~= their_latency) then
    printOutput("Your latencies do not match!")
    config.latency = math.max(config.latency, their_latency)
    printOutput("Setting latency to " .. config.latency .. ".")
  end

  --check input modifiers
  if (modifier_hash ~= their_modifier_hash) then
    printOutput("You are not both using the same input modifier.")
    printOutput("Make sure your input modifiers are the same and try again.")
    error("Configuration consistency check failed.")
  end

  --check sync code
  if (sync_hash ~= their_sync_hash) then
    printOutput("You are not both using the same sync code (perhaps one of you is using an older version?)")
    printOutput("Make sure your sync code is the same and try again.")
    error("Configuration consistency check failed.")
  end
end



--loads slot 0, this should be a savestate at frame 0
--such a savestate should be generated on script load
function sync.synctoframe1(client_socket)
  local status, err = savestate_sync.are_save0_same(client_socket)
  if (not status) then
    error("Failed to sync.\n" .. err)
  end

  savestate.loadslot(0)

  printOutput("Synced! Let the games begin!")
  coroutine.yield()
end

local my_input_queue = {}
local their_input_queue = {}
local modifier_state_queue = {}
local save_queue = {}
local load_queue = {}
local pause_queue = {}
local current_input, received_input
local received_message_type, received_data
local received_frame
my_input = {}
their_input = {}
local final_input
local current_frame, future_frame, timeout_frames

local controller = require("2p1c\\controller")

--attempt to load the keymap. If it does not exist, it will create a default stub
require_status, keymap = pcall(function()
  return dofile(controller.keymapfilename)
end)
if not require_status then
  keymap = {}

  local output = ""
  output = output
  .. "--This file contains the controller key mappings.\n"
  .. "--This file can be set appropriately by running setkeymap.lua,\n"
  .. "--or it can be manually edited - the names of keys can be found at\n"
  .. "-- http://www.codeproject.com/Tips/73227/Keys-Enumeration-Win\n"
  .. "local keymap = {}\n\nreturn keymap"

  f = assert(io.open(controller.keymapfilename, "w"))
  f:write(output)
  f:close()
end

--Clears all the queues before syncing inputs
function sync.resetsync()
    current_frame = emu.framecount()
    future_frame = current_frame + config.latency

    --create input queues
    my_input_queue = {}
    their_input_queue = {}
    modifier_state_queue = {}
    save_queue = {}
    load_queue = {}
    pause_queue = {}

    --set the first latency frames to no input
    for i = current_frame, (future_frame - 1) do
      my_input_queue[i] = {}
      their_input_queue[i] = {}
    end
end

--Attempts to unpause the game is the game is paused
function sync.unpause(whoUnpaused)
  if (syncStatus == "Pause") then
    if (whoPaused ~= nil) then
      printOutput(whoUnpaused .. " unpaused the game.")
    else
      printOutput("The game is unpaused.")
    end      

    syncStatus = "Play"
    client.unpause()   
    return true
  end

  return false
end

--shares the input between two players, making sure that the same input is
--pressed for both players on every frame. Sends and receives instructions
--that must be performed simultaneously; such as pausing and saving
function sync.syncallinput(client_socket)
  current_frame = emu.framecount()
  future_frame = current_frame + config.latency

  --get the player input
  current_input = controller.get(keymap)

  --Send pause request
  if sendMessage["Pause"] == true then
    sendMessage["Pause"] = nil
    messenger.send(client_socket, messenger.PAUSE, future_frame)
    pause_queue[future_frame] = "request"
  end

  --Send unpause request
  if sendMessage["Unpause"] == true then
    sendMessage["Unpause"] = nil
    messenger.send(client_socket, messenger.UNPAUSE)

    if sync.unpause("You") then
      return
    end
  end

  --Send Quit request
  if sendMessage["Quit"] == true then 
    sendMessage["Quit"] = nil

    syncStatus = "Idle"
    client.unpause()
    error("You closed the connection.")
    return
  end

  --Send change ModifyInputs request
  if sendMessage["ModifyInputs"] ~= nil then 
    local i = sendMessage["ModifyInputs"]
    sendMessage["ModifyInputs"] = nil

    modifier_state_queue[future_frame] = i
    messenger.send(client_socket, messenger.MODIFIER, i, future_frame)
    
    if (i) then
      printOutput("You turned input modifier ON.")
    else
      printOutput("You turned input modifier OFF.")
    end

    if sync.unpause("You") then
      return
    end
  end

  --Send Save request
  if sendMessage["Save"] ~= nil then 
    local i = sendMessage["Save"]
    sendMessage["Save"] = nil

    messenger.send(client_socket, messenger.SAVE, i, future_frame)
    save_queue[future_frame] = i

    if sync.unpause("You") then
      return
    end
  end

  --Send Load request
  if sendMessage["Load"] ~= nil then 
    local i = sendMessage["Load"]
    sendMessage["Load"] = nil

    if (savestate_hashes[i] == nil) then
      printOutput("Savestate slot " .. i .. " does not exist.")
    else
      load_queue[future_frame] = i
      messenger.send(client_socket, messenger.LOAD, i, future_frame)

      if sync.unpause("You") then
        return
      end
    end
  end

  --Send inputs if not paused
  if (syncStatus == "Play") then
    --add input to the queue
    my_input_queue[future_frame] = current_input

    --send the input to the other player
    messenger.send(client_socket, messenger.INPUT, current_input, future_frame)
  end

  --receive this frame's input from the other player and other messages
  timeout_frames = 0
  repeat
    received_message_type, received_data = messenger.receive(client_socket, true)

    if (received_message_type == messenger.INPUT) then
      --we received input
      received_input = received_data[1]
      received_frame = received_data[2]

      --add the input to the queue
      their_input_queue[received_frame] = received_input
    elseif (received_message_type == messenger.PAUSE) then
      --add the pause to the queue
      pause_queue[received_data[1]] = "accept"
    elseif (received_message_type == messenger.UNPAUSE) then
      --unpause immediately
      if sync.unpause() then
        return
      end
    elseif (received_message_type == messenger.MODIFIER) then
      --add the modify input change to the queue
      modifier_state_queue[received_data[2]] = received_data[1]
      if (received_data[1]) then
        printOutput("The other player turned input modifier ON.")
      else
        printOutput("The other player turned input modifier OFF.")
      end

      if sync.unpause("The other player") then
        return
      end
    elseif (received_message_type == messenger.LOAD) then
      --add the load request to the queue if it exists
      local slot = received_data[1]

      --send a loadfail message if the save does not exist
      if (savestate_hashes[slot] == nil) then
        local reason = "The other player attempted to load savestate slot " .. slot .. ", but it does not exist for you."
        printOutput(reason)
        messenger.send(client_socket, messenger.LOAD_FAIL, reason)
      else
        load_queue[received_data[2]] = slot

        if sync.unpause("The other player") then
          return
        end
      end
    elseif (received_message_type == messenger.SAVE_HASH) then
      --Attempts to load from save if the received savehash matches
      local slot = received_data[1]
      local their_save_hash = received_data[2]
      --check that the save states match
      if (savestate_hashes[slot] == their_save_hash) then
        savestate.loadslot(slot)
        printOutput("Savestate slot " .. slot .. " loaded.")
        sync.resetsync()

        sync.unpause()

        --Skips the next advance frame
        sync.syncallinput(client_socket)
        return
      else
        printOutput("Your saves at slot " .. slot .. " do not match!")
      end
    elseif  (received_message_type == messenger.LOAD_FAIL) then
      --Do nothing if a loadfail is received
      local their_reason = received_data[1]
      printOutput("Other player would have an error loading:\n" .. their_reason)
    elseif (received_message_type == messenger.SAVE) then
      --Add the save to the queue
      save_queue[received_data[2]] = received_data[1]

      if sync.unpause("The other player") then
        return
      end
    elseif (received_message_type == nil) then
      --If no message if received, then yield and try again
      timeout_frames = timeout_frames + 1

      --Timeout the connection if no message in 300 frames
      if (timeout_frames > 300) then
        error("Connection Timeout")
      end

      if (syncStatus == "Play") then
        client.pause()
        coroutine.yield()
        client.unpause()
      else
        return
      end
    else
      error("Unexpected message type received.")
    end
  until (their_input_queue[current_frame] ~= nil)

  if (syncStatus == "Pause") then
    return
  end

  --construct the input for the next frame
  final_input = {}
  my_input = my_input_queue[current_frame]
  their_input = their_input_queue[current_frame]

  --switch effect of modifier if necessary
  if (modifier_state_queue[current_frame] ~= nil) then
    config.modify_inputs_enabled = modifier_state_queue[current_frame]
  end

  --Modify inputs if enabled
  if (config.modify_inputs_enabled) then
    my_input, their_input = modify_inputs(my_input, their_input, config.player)
  end

  --Merge both plays inputs
  for i, b in pairs(controller.buttons) do
    if (my_input[b] == true or their_input[b] == true) then
      final_input[b] = true
    else
      final_input[b] = false
    end
  end

  --set the input
  joypad.set(final_input)

  --Excute queued pause
  if (pause_queue[current_frame] ~= nil) then
    if pause_queue[current_frame] == "accept" then
      printOutput("The other player has paused.")
    else
      printOutput("You have paused.")
    end

    syncStatus = "Pause"
    client.pause()

    pause_queue[current_frame] = nil
  end

  --clear these entries to keep the queue size from growing
  my_input_queue[current_frame] = nil
  their_input_queue[current_frame] = nil

  --Execute queued save state
  if (save_queue[current_frame] ~= nil) then
    savestate.saveslot(save_queue[current_frame])
    printOutput("Saved state to slot " .. save_queue[current_frame] .. ".")
    save_queue[current_frame] = nil
  end

  --Send save hash for the queued load request. The savestate will load when a
  --matching save hash is received.
  if (load_queue[current_frame] ~= nil) then
    local slot = load_queue[current_frame]
    if (savestate_hashes[slot] == nil) then
      local reason = "Savestate file for slot " .. slot .. " does not exist."
      printOutput(reason)
      messenger.send(client_socket, messenger.LOAD_FAIL, reason)
    else
      messenger.send(client_socket, messenger.SAVE_HASH, slot, savestate_hashes[slot])
    end
    load_queue[current_frame] = nil
  end
end

return sync