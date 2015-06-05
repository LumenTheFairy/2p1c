--author: TestRunner

controller = require("2p1c\\controller")

return function()
	local keymap = {}
	local keylist = controller.buttons

	--Returns key pressed in keys table
	function getKey(t)
		local key = nil
		for k, v in pairs(t) do
			if k ~= "WMouse L" and not string.find(k, "^J%d+ [^b]$") and k ~= "" then
				if key == nil then
					key = k
				else
					return nil
				end
			end
		end

		return key
	end

	--Prompt and wait for key press. Returns the key pressed
	function getInput(val)
		local timeout = 300
		local keyPress
		local key

		--Wait for key press
	    repeat
	    	gui.text(client.bufferheight() / 2, (client.bufferwidth() / 2),"Enter a key for " ..val)
	    	keyPress = input.get()
	    	key = getKey(keyPress)

	    	timeout = timeout - 1
	    	if timeout == 0 then
	    		return
	    	end
	    	coroutine.yield()
	    until (key ~= nil)

	    --Wait for key release
	    repeat
	    	gui.text(client.bufferheight() / 2, (client.bufferwidth() / 2),"Enter a key for " ..val)
	    	keyPress = input.get()
	    	
	    	coroutine.yield()
	    until (keyPress[key] == nil)    

		keymap[key] = val
	end

	--Prompt for all keys in the keylist
	for k, v in ipairs(keylist) do
		getInput(v)
	end

	--Create keymap file
	local output = ""
	output = output
	.. "--This file contains the controller key mappings.\n"
	.. "--This file is set by clicking 'Set Controls' when running 2p1c,\n"
	.. "--or it can be manually edited - the names of keys can be found at\n"
	.. "-- http://www.codeproject.com/Tips/73227/Keys-Enumeration-Win\n"
	.. "local keymap = {\n"
	for k, v in pairs(keymap) do
		output = output .. "  [\"" .. k .. "\"] = \"" .. v .. "\",\n"
	end
	--remove the final comma
	output = output:sub(1, -3) .. "\n"

	output = output .. "}\n\nreturn keymap"

	f = assert(io.open(controller.keymapfilename, "w"))
	f:write(output)
	f:close()

	return

end