-- This module exists for backwards compatibility only!
-- You should update your require calls to use PopJamConnect.
-- This module may be removed at any point in the future.

warn("RukkazEventHost is now PopJamConnect\n" .. debug.traceback())

local PopJamConnect = require(script.Parent.PopJamConnect)

return PopJamConnect
