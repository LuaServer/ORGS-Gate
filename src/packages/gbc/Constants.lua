
local _M = {}

-- request type
_M.HTTP_REQUEST_TYPE = "http"
_M.WEBSOCKET_REQUEST_TYPE = "websocket"
_M.CLI_REQUEST_TYPE = "cli"
_M.WORKER_REQUEST_TYPE = "worker"

-- message type
_M.MESSAGE_FORMAT_JSON = "json"
_M.MESSAGE_FORMAT_TEXT = "text"
_M.DEFAULT_MESSAGE_FORMAT = _M.MESSAGE_FORMAT_JSON

-- redis keys
_M.NEXT_CONNECT_ID_KEY = "_NEXT_CONNECT_ID"
_M.CONNECT_CHANNEL_PREFIX = "_CN_"
_M.CONTROL_CHANNEL_PREFIX = "_CT_"
_M.BROADCAST_ALL_CHANNEL = "_CN_ALL"
_M.SOCKET_CONNECT_CHANNLE = "_SCCN_" --连接互通的通道

-- beanstalkd
_M.BEANSTALKD_JOB_TUBE_PATTERN = "job-%s" -- job-<appindex>

-- websocket
_M.WEBSOCKET_TEXT_MESSAGE_TYPE = "text"
_M.WEBSOCKET_BINARY_MESSAGE_TYPE = "binary"
_M.WEBSOCKET_SUBPROTOCOL_PATTERN = "gbc%-auth%-([%w%d%-]+)" -- token
_M.WEBSOCKET_SUBPROTOCOL_PATTERN_MESSAGE = "gbc%-msg%-([%p%w%d%-]+)" -- message
_M.WEBSOCKET_DEFAULT_TIME_OUT = 10 * 1000 -- 10s
_M.WEBSOCKET_DEFAULT_MAX_PAYLOAD_LEN = 16 * 1024 -- 16KB

-- misc
_M.STRIP_LUA_PATH_PATTERN = "[/%.%a%-]+/([%a%-]+%.lua:%d+: )"

--关闭连接消息
_M.CLOSE_CONNECT = "SEND_CLOSE"

--初始化信号
_M.SIGINIT = "_SIGINIT"
--退出信号
_M.SIGQUIT = "_SIGQUIT"

--网络信号
_M.SIGNET = "_SIGNET"

--登录列表
_M.USERLIST = "_USERLIST"
--玩家信息
_M.USER = "_USER:"

return table.readonly(_M)
