
local _M = {}

_M.ONCONNECTED = 1
_M.ONDISCONNECTED = 2
_M.DB_SAVE = 3
_M.CHECKCONNECTED = 4
_M.UPDATE_SESSION = 5

return table.readonly(_M)
