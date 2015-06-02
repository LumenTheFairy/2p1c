return function(myController, theirController, player)
	local colors = {
		Left = 	"Black",
		Right = "Black",
		Up = 	"Black",
		Down = 	"Black",
		Start = "Black",
		Select ="Black",
		A = 	"Black",
		B = 	"Black",
		X = 	"Black",
		Y = 	"Black",
		L = 	"Black",
		R = 	"Black"
	}

	local color1 = "Red"
	local color2 = "Green"
	if player == 2 then
		color1, color2 = color2, color1
	end

	for k, v in pairs(colors) do
		if myController[k] == true and theirController[k] == true then
			colors[k] = "White"
		elseif myController[k] == true then
			colors[k] = color1
		elseif theirController[k] == true then
			colors[k] = color2
		end
	end

	--Left
	gui.text(20, 100, "/", nil, colors["Left"])
	gui.text(20, 108, "\\", nil, colors["Left"])

	--Right
	gui.text(60, 100, "\\", nil, colors["Right"])
	gui.text(60, 108, "/", nil, colors["Right"])

	--Up
	gui.text(35, 85, "/", nil, colors["Up"])
	gui.text(43, 85, "\\", nil, colors["Up"])

	--Down
	gui.text(35, 124, "\\", nil, colors["Down"])
	gui.text(43, 124, "/", nil, colors["Down"])

	--Start
	gui.text(94, 94, "Start", nil, colors["Start"])

	--Select
	gui.text(90, 114, "Select", nil, colors["Select"])

	--A
	gui.text(205, 104, "A", nil, colors["A"])

	--B
	gui.text(185, 124, "B", nil, colors["B"])

	--X
	gui.text(185, 85, "X", nil, colors["X"])

	--Y
	gui.text(165, 104, "Y", nil, colors["Y"])

	--L
	gui.text(04, 79, "|", nil, colors["L"])
	gui.text(08, 70, "/", nil, colors["L"])
	gui.text(16, 60, "_____", nil, colors["L"])

	--R
	gui.text(168, 60, "_____", nil, colors["R"])
	gui.text(216, 70, "\\", nil, colors["R"])
	gui.text(220, 79, "|", nil, colors["R"])
end