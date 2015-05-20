--This creates a savestate on frame 0, which is used to sync the players
--Running this script will cause BizHawk to alert an error, but it still works
--correctly. If you do not want to see this error, move this file to out to the
--same directory as the EmuHawk executable
client.reboot_core()
savestate.saveslot(0)