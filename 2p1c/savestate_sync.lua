--Makes sure that save state loads are synced properly,
--and can rewind to a synced backup save in case of desync
--author: TheOnlyOne and TestRunner
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
  if (systemname == "GB" or systemname == "GBC") then
    systemname = "Gameboy"
  end
  local filename = "./" .. systemname .. "/State/" .. romname .. ".QuickSave" .. slot .. ".State"

  --check if it exists
  if (file_exists(filename)) then
    --construct a value that represents the save state
    local save_text = ""
    for line in io.lines(filename) do save_text = save_text .. line .. "\n" end

    local save_hash = sha1.sha1(save_text)
    savestate_hashes[slot] = save_hash
  else
    savestate_hashes[slot] = nil
  end
end

--Create the hashes for all the savestate slots
for i = 0,9 do
  savestate_sync.update_hash(i)
end

--Create the onsavestate handle to update the hash
event.onsavestate(function (savefile)
  local savematch = string.match(savefile, "QuickSave(%d)")

  if (savematch ~= nil) then
    savestate_sync.update_hash(tonumber(savematch))
  end
end)

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
        return false, "Your init states do not match!\nTry restarting BizHawk with matching save batteries."
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