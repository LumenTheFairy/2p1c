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
--author: testrunner
return function(myInput, theirInput, playernum)
  local mario_input = myInput
  local luigi_input = theirInput

  if playernum == 2 then
    mario_input, luigi_input = luigi_input, mario_input
  end

  --surpress illegal buttons for mario and luigi
  luigi_input["A"] = nil;
  luigi_input["R"] = nil;
  mario_input["B"] = nil;
  mario_input["L"] = nil;

  memory.usememorydomain("EWRAM")

  if memory.readbyte(0x03F64E) == 0 then
    --Out of Combat
    if memory.readbyte(0x004F4C) == 0 then
      --Mario is the lead

      --surpress movement, swap, pause for luigi
      luigi_input["Up"] = nil;
      luigi_input["Down"] = nil;
      luigi_input["Left"] = nil;
      luigi_input["Right"] = nil;
      luigi_input["Start"] = nil;
      luigi_input["Select"] = nil;
    else
      --Luigi is the lead

      --surpress movement, swap, pause for mario
      mario_input["Up"] = nil;
      mario_input["Down"] = nil;
      mario_input["Left"] = nil;
      mario_input["Right"] = nil;
      mario_input["Start"] = nil;
      mario_input["Select"] = nil;

      --swap A to B for mario and luigi
      luigi_input["A"], luigi_input["B"] = luigi_input["B"], luigi_input["A"];
      mario_input["A"], mario_input["B"] = mario_input["B"], mario_input["A"];
      --map L to R for mario and luigi
      luigi_input["L"], luigi_input["R"] = luigi_input["R"], luigi_input["L"];
      mario_input["L"], mario_input["R"] = mario_input["R"], mario_input["L"];
    end
  elseif memory.readbyte(0x03F64E) == 1 or memory.readbyte(0x03F64E) == 255 then
    --In Combat

    if memory.readbyte(0x00A5F9) == 58 then
      --Mario's Turn

      --surpress movement for luigi
      luigi_input["Up"] = nil;
      luigi_input["Down"] = nil;
      luigi_input["Left"] = nil;
      luigi_input["Right"] = nil;
    elseif memory.readbyte(0x00A5F9) == 24 then
      --Luigi's Turn

      --surpress movement for mario
      mario_input["Up"] = nil;
      mario_input["Down"] = nil;
      mario_input["Left"] = nil;
      mario_input["Right"] = nil;
    end
  else
    --Pause Screen

    if memory.readbyte(0x004F4C) == 0 then
      --Mario is the lead

      --surpress all input for luigi
      luigi_input = {}

      --map Select to B for mario
      mario_input["B"] = mario_input["Select"];
    else
      --Luigi is the lead
      
      --surpress all input for mario
      mario_input = {}

      --map B to A for luigi
      luigi_input["A"] = luigi_input["B"];
      --map Select to B for luigi
      luigi_input["B"] = luigi_input["Select"];
    end 
  end

  if playernum == 2 then
    mario_input, luigi_input = luigi_input, mario_input
  end

  return mario_input, luigi_input
end
