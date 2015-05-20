-- Memory Domain: EWRAM
--
-- In combat
-- 00A5F9   58 = Mario
--          24 = Luigi
--          0  = Niether
--
-- Out of combat
-- 004F4C   0  = Mario
--          1  = Luigi
--
-- Combat?
-- 03F64E   0   = Out of combat
--          1   = In combat
--          255 = Combat Explanation
--          102 = Paused
--
function modifyInputs(myInput, theirInput, playernum)
  local mario_input = myInput
  local luigi_input = theirInput

  if playernum == 1 then
    mario_input, luigi_input = luigi_input, mario_input
  end

  --surpress illegal buttons for mario and luigi
  luigi_input["A"] = nil;
  luigi_input["R"] = nil;
  mario_input["B"] = nil;
  mario_input["L"] = nil;

  memory.usememorydomain("EWRAM")

  if memory.readbyte(0x03F64E) == 0 then
    if memory.readbyte(0x004F4C) == 0 then
      --surpress movement, swap, pause for luigi
      luigi_input["Up"] = nil;
      luigi_input["Down"] = nil;
      luigi_input["Left"] = nil;
      luigi_input["Right"] = nil;
      luigi_input["Start"] = nil;
      luigi_input["Select"] = nil;
    else
      --surpress movement, swap, pause for mario
      mario_input["Up"] = nil;
      mario_input["Down"] = nil;
      mario_input["Left"] = nil;
      mario_input["Right"] = nil;
      mario_input["Start"] = nil;
      mario_input["Select"] = nil;

      --swap A to B for mario and luigi
      luigi_input["A"], luigi_input["B"] = luigi_input["B"], luigi_input["A"];
      --map L to R for mario and luigi
      luigi_input["L"], luigi_input["R"] = luigi_input["R"], luigi_input["L"];
    end
  elseif memory.readbyte(0x03F64E) == 1 or memory.readbyte(0x03F64E) == 255 then
    if memory.readbyte(0x00A5F9) == 58 then
      --surpress movement for mario
      luigi_input["Up"] = nil;
      luigi_input["Down"] = nil;
      luigi_input["Left"] = nil;
      luigi_input["Right"] = nil;
    elseif memory.readbyte(0x00A5F9) == 24
      --surpress movement for mario
      mario_input["Up"] = nil;
      mario_input["Down"] = nil;
      mario_input["Left"] = nil;
      mario_input["Right"] = nil;
    end
  else
    if memory.readbyte(0x004F4C) == 0 then
      --surpress all input for luigi
      luigi_input = {}

      --map Select to B for mario
      mario_input["B"] = mario_input["Select"];
    else
      --surpress all input for mario
      mario_input = {}

      --map B to A for luigi
      luigi_input["A"] = luigi_input["B"];
      --map Select to B for luigi
      luigi_input["B"] = luigi_input["Select"];
    end 
  end

  if playernum == 1 then
    mario_input, luigi_input = luigi_input, mario_input
  end

  return mario_input, luigi_input
end
