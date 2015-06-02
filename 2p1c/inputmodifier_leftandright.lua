--input modifier that only allows player 1 to press buttons on the right side
--of the controller, and player 2 to press buttons on the left side.
--author: TheOnlyOne
return function(myInput, theirInput, playernum)

  if playernum == 2 then
    myInput, theirInput = theirInput, myInput
  end

  theirInput["A"] = nil
  theirInput["B"] = nil
  theirInput["X"] = nil
  theirInput["Y"] = nil
  theirInput["R"] = nil
  theirInput["Start"] = nil

  myInput["Up"] = nil
  myInput["Down"] = nil
  myInput["Left"] = nil
  myInput["Right"] = nil
  myInput["L"] = nil
  myInput["Select"] = nil

  if playernum == 2 then
    myInput, theirInput = theirInput, myInput
  end

  return myInput, theirInput
end