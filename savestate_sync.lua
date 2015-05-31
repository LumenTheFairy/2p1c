--Makes sure that save state loads are synced properly,
--and can rewind to a synced backup save in case of desync
--author: TheOnlyOne
local savestate_sync = {}

local messenger = require("messenger")
local sha1 = require("sha1")

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
  local filename = config.path_to_root .. systemname .. "/State/" .. romname .. ".QuickSave" .. slot .. ".State"

  --check if it exists
  if (file_exists(filename)) then
    --construct a value that represents the save state
    local save_text = ""

    local f = assert(io.open(filename, "r"))
    save_text = f:read("*all")
    f:close()

    local save_hash = sha1.sha1(save_text)
    savestate_hashes[slot] = save_hash
      print(slot .. ": " .. save_hash)
  else
    savestate_hashes[slot] = nil
      print(slot .. ': nil')
  end
end

for i = 0,9 do
   savestate_sync.update_hash(i)
end
event.onsavestate(savestate_sync.update_hash)

--Checks if it is safe to load a save state, making sure the state exists for
--both players, and that both players' saves are the same.
--returns true if the slot can be loaded
--returns false and a reason for failure if not
function savestate_sync.is_safe_to_loadslot(client_socket, slot)
  if (savestate_hashes[slot] == nil) then
    local reason = "Savestate file for slot " .. slot .. " does not exist."
    messenger.send(client_socket, messenger.LOAD_FAIL, reason)
    messenger.receive(client_socket)
    return false, reason
  end

  messenger.send(client_socket, messenger.SAVE_HASH, slot, savestate_hashes[slot])

  --If we can load, see what the deal is with the other player
  local received_message_type, received_data = messenger.receive(client_socket)
  if (received_message_type == messenger.SAVE_HASH) then
    local their_save_hash = received_data[2]
    --check that the save states match
    if (slot == received_data[1]) and (savestate_hashes[slot] == their_save_hash) then
      return true
    else
      return false, "Your saves at slot " .. slot .. " do not match!"
    end
  elseif  (received_message_type == messenger.LOAD_FAIL) then
    local their_reason = received_data[1]
    return false, "Other player would have an error loading:\n" .. their_reason
  else
    error("Unexpected message type received.")
  end
end

return savestate_sync