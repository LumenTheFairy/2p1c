local config = {}

--This determines which player you are. This is mainly used in input modifiers
--and input displays. Valid player numbers are 1 and 2. Make sure this is the
--other number from the person you are playing with.
config.player = 1
--This is the amount of time, in seconds, that the host will wait for the
--client to connect. If this timeout is reached, the host script will end.
--This value is only inportant for the host.
config.accept_timeout = 10
--This is the amount of time, in seconds, that the input syncer will wait
--for the other player's input. If this timeout is reached, the connection
--will end, so a low timeout may ruin syncing if one player pauses emulation,
--has a slowdown in emulation, or has a slowdown in connection speed.
config.input_timeout = 120
--This is the port the connection will happen over. Make sure this is the same
--for both players before trying to sync.
config.port = 54321
--This is the ip address or hostname of the player running host.lua (ip
--addresses should should still be in quotes.) This value is only inportant
--for the client.
config.hostname = "localhost"
--This is the number of frames the network has to send the inputs back and
--forth. It is also the number of frames that all input will be delayed. If
--this is too low, the gameplay will be very slow and choppy due to the fact
--that the players must wait to recieve the other's input. If this is too high,
--there will be noticable input delay.
config.latency = 4
--This is the file name (without the .lua extension) of the lua script that
--contains the input modifier you wish to use. If you do not wish to run any
--input modification, set this to "inputmodifier_none".
config.input_modifier = "inputmodifier_none"
--This is the file name (without the .lua extension) of the lua script that
--contains the input display code wish to use. If you do not wish to display
--input, set this to "inputdisplay_none".
config.input_display = "inputdisplay_snes"

return config