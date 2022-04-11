return [[

	GitHub: SuperAwesomeLTD/pj-portal-roblox-connect-module

To install the PopJam Portal Roblox Connect module, ensure that the folder containing
this ModuleScript is a descendant of ServerScriptService, so that the Main script runs.
That's it! You should now test that the module works.

	Testing

This test process assumes you have installed the module as-is.

1. Test → Start (F7); note that Test → Play (F5) may have some issues (see "Chat Module" below)
2. Type "/pj setup" in chat. The interface should open.
3. Type an arbitrary 6-character setup code and click submit.
4. The setup code should be rejected for not matching any event - if this is the case, things are working!
5. Publish the place and enter it from a live Roblox Server. Repeat from 2.

Read on for more details on the module and ensuring it works in your game.

	Entry Point & Single-Script Architecture

The entry point of this module is the Main script. If you use single-script architecture,
disable or remove it and call PopJamConnect:main() yourself.

	Chat Module

By default, opening the interface added by this module is done by typing "/pj setup"
into Roblox's default chat. The module enables this by injecting its own chat module
which is used by the Lua Chat System at runtime. If using chat is not an option, you
should create another way for ANY ARBITRARY PLAYER to ask the server to call
PopJamConnect:setupCodePrompt(player)

Sometimes in Studio the player loads faster than the module injects the chat module,
which prevents the chat command from working. You can avoid this by copying
PopJamConnectChatModule to a Folder named ChatModules in the Chat game service at edit
time. If you do this, make sure to also add a true BoolValue named InsertDefaultModules
in the ChatModules folder as well. For more details about the Lua Chat System, read:

https://developer.roblox.com/en-us/articles/Lua-Chat-System

]]