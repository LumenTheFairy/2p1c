--input modifier that only allows player 1 to press buttons on the right side
--of the controller, and player 2 to press buttons on the left side.
--author: TheOnlyOne
return function(myInput, theirInput, playernum)

  if playernum == 2 then
    myInput, theirInput = theirInput, myInput
  end

  myInput["A"] = nil
  myInput["B"] = nil
  myInput["X"] = nil
  myInput["Y"] = nil
  myInput["R"] = nil
  myInput["Start"] = nil

  theirInput["Up"] = nil
  theirInput["Down"] = nil
  theirInput["Left"] = nil
  theirInput["Right"] = nil
  theirInput["L"] = nil
  theirInput["Select"] = nil

  if playernum == 2 then
    myInput, theirInput = theirInput, myInput
  end

  return myInput, theirInput
end