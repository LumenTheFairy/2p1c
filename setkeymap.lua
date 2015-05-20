--author: TestRunner
local keymap = {}
local keylist = {"Up", "Down", "Left", "Right", "A", "B", "L", "R", "Start", "Select"}

function getKey(t)
	local key = nil
	for k, v in pairs(t) do
		if k ~= "WMouse L" then
			if key == nil then
				key = k
			else
				return nil
			end
		end
	end

	return key
end

function getInput(val)
	local timeout = 300
	local keyPress
	local key

    repeat
    	gui.text(client.bufferheight() / 2, (client.bufferwidth() / 2),"Enter a key for " ..val)
    	keyPress = input.get()
    	key = getKey(keyPress)

    	timeout = timeout - 1
    	if timeout == 0 then
    		return
    	end
    	emu.frameadvance()
    until (key ~= nil)

    repeat
    	gui.text(client.bufferheight() / 2, (client.bufferwidth() / 2),"Enter a key for " ..val)
    	keyPress = input.get()
    	
    	emu.frameadvance()
    until (keyPress[key] == nil)    

	keymap[key] = val
end

for k, v in ipairs(keylist) do
	getInput(v)
end

f = assert(io.open("keymap.lua", "w"))
f:write("local keymap = {\n")
local first = true
for k, v in pairs(keymap) do
	if first then
		first = false
	else
		f:write(",")
	end
	f:write("  ", k ," = \"", v, "\"\n")
end
f:write("}\n\nreturn keymap")

f:close()