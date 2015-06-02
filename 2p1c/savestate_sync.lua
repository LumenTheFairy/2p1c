--Makes sure that save state loads are synced properly,
--and can rewind to a synced backup save in case of desync
--author: TheOnlyOne
local savestate_sync = {}

local messenger = require("2p1c\\messenger")
local sha1 = require("2p1c\\sha1")

--checks if a file exists and can be read
--credit: http://stackoverflow.com/questions/4990990/lua-check-if-a-file-exists
function file_exists(name)
  local f = io.open(name,"r")
  if (f ~= nil) then
    io.close(f)
    return true
  else
    return false
  end
end

savestate_hashes = {}

function savestate_sync.update_hash(slot) 
  local save_hash = ""

  --construct the filename
  local romname = gameinfo.getromname()
  local systemname = emu.getsystemid()
  local filename = "./" .. systemname .. "/State/" .. romname .. ".QuickSave" .. slot .. ".State"

  --check if it exists
  if (file_exists(filename)) then
    --construct a value that represents the save state
    local save_text = ""

    local f = assert(io.open(filename, "r"))
    save_text = f:read("*all")
    f:close()

    local save_hash = sha1.sha1(save_text)
    savestate_hashes[slot] = save_hash
  else
    savestate_hashes[slot] = nil
  end
  print(savestate_hashes[slot])
end

for i = 0,9 do
   savestate_sync.update_hash(i)
end
event.onsavestate(savestate_sync.update_hash)

--Checks if it is safe to load a save state, making sure the state exists for
--both players, and that both players' saves are the same.
--First checks if they have the same save battery for proper feedback
--returns true if the slot can be loaded
--returns false and a reason for failure if not
function savestate_sync.are_batteries_same(client_socket)
  local save_hash = ""

  --construct the filename
  local romname = gameinfo.getromname()
  local systemname = emu.getsystemid()
  local filename = "./" .. systemname .. "/SaveRAM/" .. romname .. ".SaveRAM"

  --check if it exists
  if (file_exists(filename)) then
    --construct a value that represents the save state
    local save_text = ""

    local f = assert(io.open(filename, "r"))
    save_text = f:read("*all")
    f:close()

    local save_hash = sha1.sha1(save_text)

    messenger.send(client_socket, messenger.SAVE_HASH, 0, save_hash)

    --If we can load, see what the deal is with the other player
    local received_message_type, received_data = messenger.receive(client_socket)
    if (received_message_type == messenger.SAVE_HASH) then
      local their_save_hash = received_data[2]
      --check that the save states match
      if (save_hash == their_save_hash) then
        return savestate_sync.are_save0_same(client_socket)
      else
        return false, "Your save batteries do not match!"
      end
    elseif  (received_message_type == messenger.LOAD_FAIL) then
      local their_reason = received_data[1]
      return false, "Other player would have an error loading:\n" .. their_reason
    else
      error("Unexpected message type received.")
    end
  else
    local reason = "Could not find save battery."
    messenger.send(client_socket, messenger.LOAD_FAIL, reason)

    --If we can't load, see what the deal is with the other player
    local received_message_type, received_data = messenger.receive(client_socket)
    if (received_message_type == messenger.SAVE_HASH) then
      return false, reason
    elseif  (received_message_type == messenger.LOAD_FAIL) then
      local their_reason = received_data[1]
      if (their_reason == "Could not find save battery.") then
        return savestate_sync.are_save0_same(client_socket)
      else
        return false, "Other player would have an error loading:\n" .. their_reason
      end
    else
      error("Unexpected message type received.")  
    end
  end
end

--Checks if it is safe to load a save state, making sure the state exists for
--both players, and that both players' saves are the same.
--returns true if the slot can be loaded
--returns false and a reason for failure if not
function savestate_sync.are_save0_same(client_socket)
  --check if it exists
  if (savestate_hashes[0] ~= nil) then
 
    messenger.send(client_socket, messenger.SAVE_HASH, 0, savestate_hashes[0])

    --If we can load, see what the deal is with the other player
    local received_message_type, received_data = messenger.receive(client_socket)
    if (received_message_type == messenger.SAVE_HASH) then
      local their_save_hash = received_data[2]
      --check that the save states match
      if (savestate_hashes[0] == their_save_hash) then
        return true
      else
        return false, "Your init states do not match! Try restarting BizHawk."
      end
    elseif  (received_message_type == messenger.LOAD_FAIL) then
      local their_reason = received_data[1]
      return false, "Other player would have an error loading:\n" .. their_reason
    else
      error("Unexpected message type received.")
    end
  else
    local reason = "Could not find init state."
    messenger.send(client_socket, messenger.LOAD_FAIL, reason)
    messenger.receive(client_socket)

    return false, reason .. "\nTry restarting BizHawk."
  end
end

return savestate_sync