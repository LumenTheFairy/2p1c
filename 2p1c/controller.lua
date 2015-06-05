--author: TheOnlyOne
local controller = {}

--get the set of buttons based on the current console
controller.buttons = {}
if (emu.getsystemid() == "GBA") then
  controller.buttons = {"Up", "Down", "Left", "Right", "A", "B", "L", "R", "Start", "Select"}
elseif (emu.getsystemid() == "SNES") then
  controller.buttons = {"P1 Up", "P1 Down", "P1 Left", "P1 Right", "P1 A", "P1 B", "P1 X", "P1 Y", "P1 L", "P1 R", "P1 Start", "P1 Select"}
elseif (emu.getsystemid() == "NES") then
  controller.buttons = {"P1 Up", "P1 Down", "P1 Left", "P1 Right", "P1 A", "P1 B", "P1 Start", "P1 Select"}
elseif (emu.getsystemid() == "GBC") then
  controller.buttons = {"Up", "Down", "Left", "Right", "A", "B", "Start", "Select"}
elseif (emu.getsystemid() == "GB") then
  controller.buttons = {"Up", "Down", "Left", "Right", "A", "B", "Start", "Select"}
else
  error("This system does not yet have the controller buttons set.\nThey must be added to controller.lua for the appropriate system id.")
end
--count the number of buttons on the controller
--and create a map that will unset all buttons when passed to joypad.set
controller.numbuttons = 0
controller.unset = {}
for j, b in pairs(controller.buttons) do
  controller.numbuttons = controller.numbuttons + 1
  controller.unset[b] = false
end
--what the name of the keymap file should be based on the current system
controller.keymapfilename = "2p1c\\Keymap\\" .. emu.getsystemid() .. ".km"



--returns a table of the buttons currently being pressed, based on the keymap
function controller.get(keymap)
  --gets the actual keyboard presses
  local keys_pressed = input.get()
  local current_input = {}
  --convert to controller buttons via keymap
  for k, b in pairs(keys_pressed) do
    if (keymap[k] ~= nil) then
      current_input[keymap[k]] = true
    end
  end

  return current_input
end

return controller