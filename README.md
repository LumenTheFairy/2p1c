# 2 Players, 1 Controller

2p1c is a Lua script for BizHawk that allows two people to play the same game at the same time over the network.

## Setup

### You will need the following:

* (1) [BizHawk 1.9.4](http://sourceforge.net/projects/bizhawk/files/BizHawk/BizHawk-1.9.4.zip/download)
* (2) [BizHawk prerequisite installer](http://sourceforge.net/projects/bizhawk/files/Prerequisites/bizhawk_prereqs_v1.1.zip/download) (run this)
* (3) [luasocket](http://files.luaforge.net/releases/luasocket/luasocket/luasocket-2.0.2/luasocket-2.0.2-lua-5.1.2-Win32-vc8.zip)
* (4) [2p1c](https://github.com/LumenTheFairy/2p1c/releases)

### Directory structure

The locations of files is very important! Make sure to put them in the right place. After unzipping BizHawk (1), you should be able to find the executable `EmuHawk.exe`, we will call the folder containing it `BizHawkRoot/`.

First, in luasocket (3), you should find three folders, a file, and an executable: `lua/`, `mime/`, `socket/`, `lua5.1.dll`, and `lua5.1.exe`.
Place `mime/` and `socket/` in `BizHawkRoot/`, and place the *contents* of `lua/` in `BizHawkRoot/Lua/`. Place `lua5.1.dll` in `BizHawkRoot/dll/`. You do not need `lua5.1.exe`.

Next, the 2p1c distribution includes two important things: the main lua script `2p1c.lua` and a folder `2p1c/`. Place both of these in `BizHawkRoot/`.

Finally, make sure that BizHawk is saving savestates and battery to the proper locations. For each console, savestates should be going into `BizHawkRoot/<system name>/State/`, and save battery should be going into `BizHawkRoot/<system name>/SaveRAM/` (these are the defaults.) To change this, load up BizHawk, and go to `Config -> Paths...`

Once this is done, your directory structure should look like this:

```
(1) BizHawkRoot/ 
(4)   2p1c/
(1)   dll/
(3)     lua5.1.dll
        ...
(3)   mime/
        ...
(3)   socket/
        ...
(1)   Lua/
(3)     socket/
(3)     ltn12.lua
(3)     mime.lua
(3)     socket.lua
        ...
(1)   <system name>/
(1)     SaveRam/
(1)     State/
        ...
(4)   2p1c.lua
(1)   EmuHawk.exe
      ...
```

### BizHawk Configuration

There are a few configurations in BizHawk that must be properly set in order to avoid de-syncing. Open up EmuHawk and run the game you're interested in playing (in order to get the relevant config menus to be available.)

* `Config -> Controllers...` While running 2p1c, the normal controllers are ignored, and input is read directly (you will set up the key mapping later.) For this reason, it does not matter what you have mapped on the Normal Controllers. On the other hand, accidentally pressing an autofire button is very likely to cause a de-sync while playing, and thus **it is extremely important that you unmap all Autofire Controls.** You can do this by clicking on on the Autofire Controls at the top, then selecting `Misc... -> Clear` at the bottom-right.

* `Config -> Hotkeys...` It is recommended that you unmap any hotkeys you are likely to accidentally press. Reseting, loading a savestate, opening a different game, and the like through BizHawk menus or hotkeys while synced is almost certain to ruin the connection.

* `Config -> Paths...` As mentioned above, make sure that BizHawk is saving savestates and battery to the proper locations for the console you are interested in playing.

* `Config -> Rewind & States...` When syncing and loading savestates, 2p1c does a sanity check to make sure both players' saves are the same. For this reason, it is important that both players' emulators are generating savestates the same way. Make sure the options under Savestate Options match for both players.

### 2p1c Configuration

Once you have everything else properly set up, you can run the 2p1c script to do some final setup before syncing and playing a game. To run the script in BizHawk, go to `Tools -> Lua Console`, and the Lua Console should open up. At this point, I suggest checking `Settings -> Disable Script on Load` and `Settings -> Autoload`. The former will allow you to choose when to start the script after opening it instead of it running automatically, and the latter will open the Lua Console automatically when you load EmuHawk.

Next, go to `Script -> Open Script...` and open `2p1c.lua` (it should be in `BizHawkRoot/`.) Make sure you are running a game, and then double click 2p1c (or click it and then press the green check mark) to run the script. The game may hang for a few seconds while the script is loading. Once it has finished loading, the game should reboot, savestate 0 should be created (or overridden,) and a new window will appear. The window has the following important configurations:

* Set Controls: You will have to do this for each different console, and if you want to change your key mapping. Click Set Controls, and text will appear over the game prompting you to press which buttons you want to use (note this text is white, so pick a game with a dark title screen to do this.) If for some reason the keys are not mapping properly, you can try manually setting them by opening `BizHawkRoot/2p1c/Keymap/<system	name>.km` in a text editor.

* Host IP and Port: The client should set the IP to the host's IP address, and both players must choose the same port number. The host will have to have port forwarding enabled on this port, and will have to make sure their firewall is not blocking BizHawk. Google is your friend.

* Latency: This is the delay, in frames, between when you press input, and when the input is registered by the game. This is also the amount of time, in frames, that it takes to send inputs between the players. Thus if the latency is too low, the game will run slowly while waiting for inputs from the other player, and if the latency is too high, there will be noticeable input delay. Finding the right medium is mostly trial and error, and will likely be different for different sets of players, but for a rough estimate, if the client pings the host and has max ping time `p` in ms, the latency should be around `(p / 1000) * fps * 1.5` rounded up to the next integer. Make sure this is set the same for both players.

* Input Modifier: These must be the same for both players. More on what the input modifiers and input displays do is below.

* Select Player: Make sure these are different for the two players. These affect the input modifiers and displays; see below for details.

Make sure to click Save Settings, and you should be ready to play!


## Syncing with 2p1c

Once you have completed setup and chosen a game to play, you can run the 2p1c script from the Lua Console. Make sure before running the script that both players have the same save battery. The easiest way to do this is to just delete the saves, or one player can send a save to the other. If you synced and played before, and have not played independently since, the saves should still be the same in this case as well.

After both players have the 2p1c window up, the host clicks Host to host, and the client clicks Join to join. 2p1c will run some consistency checks on your configurations to make sure, for example, that your saves match, and that your latencies are the same. If these all pass, the games will reset on both sides, and the two players will be synced. As you play, there are a few more options available to you:

* Pause: If you wish to pause for any reason, either player can click Pause, and both players will be paused in sync. Use this instead of BizHawk's pause - if you use BizHawk's, the connection will break after 10 seconds. Either player can click Unpause to resume synced gameplay.

* Input Modifiers: While playing, you can enable and disable them. This will happen for both players at the same time.

* Save and Load savestates: If you want to make a savestate while synced, or load to a synced savestate, use these. Again, do not use BizHawk's savestates from menus or hotkeys - saves would only happen on one side, and loads would run the connection. Do not worry about accidentally loading an unsynced savestate from the 2p1c window; 2p1c checks that the saves are the same before loading them.

* Close Connection: Click this to cleanly close down the connection. Closing the Lua Console or BizHawk directly can result in issues reconnecting for some time, and may cause the other player to hang.

### Input Modifiers

Input modifiers are functions that change the input that the players pressed before it is sent to the game. This allows, for example, for some inputs to be disabled for each player, as would be the case in an in-person 2 players, 1 controller experience. The input modifiers that currently come with 2p1c are as follows:

* none: Both players can press any buttons at any time, and they will take effect.

* leftandright: Player 1 can only press buttons on the right side of the controller, and player 2 can only press buttons on the left side of the controller.

* superstarsaga: This is a game specific input modifier for Mario & Luigi Superstar Saga for the GBA that gives player 1 control of Mario, and player 2 control of Luigi, so that, for example, if Mario is in the lead, player one has control of movement buttons while player 2 does not, and if Luigi is in the lead, the opposite is the case.

If an input modifier is getting in the way of how you want to play, or is acting wonky at some point, you can disable it at any time. This will act as if the "none" modifier is in effect.

You can create your own input modifiers as well, or edit the existing ones. If you wish to do so, look into `BizHawkRoot/2p1c/InputModifier/` and use the files there as a template (they are simply Lua scripts that return a function, despite their extensions.) Just make sure that both players have identical input modifiers, or else the games will not sync.

### Input Displays

If you want an input display other that BizHawk's default display, you can use one of these. 2p1c input displays give more information that the default display because they can tell which player pressed which buttons. The input displays that currently come with 2p1c are as follows:

* none: 2p1c will not display any input information.

* snes: A snes controller is drawn on the screen (stretch BizHawk to get this off to the side.) If player 1 presses a button (after input modification) it will light up red, for player 2, green, and if both at the same time, the button becomes white. This can be used for NES, GB, and GBA as well since their buttons are subsets of the snes's.

Again, you can create your own input displays by looking into `BizHawkRoot/2p1c/InputDisplay/` and using the files there as a template. Each player can use whatever input display they like, and they can be enabled and disabled independently. 

## Misc

### Supported Systems

2p1c currently supports NES, SNES, GB, GBC, and GBA.

2p1c will only run on a Windows os (BizHawk does not have recent versions for other operating systems anyway.)

### Credits

Created by TheOnlyOne and TestRunner.

Credit to BizHawk, Lua, Luasocket, and kikito's sha1 script. Lua, luasocket, and sha1.lua all fall under the MIT license.

### Issues

If you have any problems with the script (and restarting BizHawk does not fix them,) contact me ([@Modest_Ralts](https://twitter.com/Modest_ralts)) or TestRunner ([@Test_Runner](https://twitter.com/Test_Runner)) on Twitter. You can also submit an issue here on the GitHub, but we are much less likely to see it in a timely manner.