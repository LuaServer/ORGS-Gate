local ngx = ngx
-- local ngx_log = ngx.log
-- local ngx_md5 = ngx.md5
-- local ngx_thread_spawn = ngx.thread.spawn
-- local req_get_headers = ngx.req.get_headers
local req_read_body = ngx.req.read_body
-- local string_format = string.format
local string_sub = string.sub
local table_concat = table.concat
-- local table_insert = table.insert
-- local ngx_say = ngx.say
local tostring = tostring
local type = type

-- local ngx_thread_kill = ngx.thread.kill
-- local ngx_thread_spawn = ngx.thread.spawn

local Constants = cc.import(".Constants")

local json = cc.import("#json")
local json_encode = json.encode
local json_decode = json.decode

local netpack = cc.import("#netpack")
local net_encode = netpack.encode

local InstanceBase = cc.import(".InstanceBase")
local WebSocketInstanceBase = cc.class("WebSocketInstanceBase", InstanceBase)

local sdLogin = ngx.shared.sdLogin

function WebSocketInstanceBase:ctor(config)
    WebSocketInstanceBase.super.ctor(self, config, Constants.WEBSOCKET_REQUEST_TYPE)
    
    local appConfig = self.config.app
    if config.app.websocketMessageFormat then
        appConfig.messageFormat = config.app.websocketMessageFormat
    end
    appConfig.websocketsTimeout = appConfig.websocketsTimeout or Constants.WEBSOCKET_DEFAULT_TIME_OUT
    appConfig.websocketsMaxPayloadLen = appConfig.websocketsMaxPayloadLen or Constants.WEBSOCKET_DEFAULT_MAX_PAYLOAD_LEN
end

function WebSocketInstanceBase:run()
    local _ok
    local this = self
    _ok, _ = xpcall(function()
        this:runEventLoop()
        this:onClose()
        ngx.exit(ngx.OK)
    end, function(err)
        err = tostring(err)
        cc.printerror(err .. debug.traceback("", 1))
        this:onClose()
        ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
        ngx.exit(ngx.ERROR)
    end)
end

function WebSocketInstanceBase:readProtocols()
    if ngx.headers_sent then
        return nil, "response header already sent"
    end
    
    req_read_body()
    local headers = ngx.req.get_headers()
    local protocols = headers["sec-websocket-protocol"]
    if type(protocols) ~= "table" then
        protocols = {protocols}
    end
    if #protocols == 0 then
        return nil, "not set header: Sec-WebSocket-Protocol"
    end
    self.protocols = protocols
    return true
end

function WebSocketInstanceBase:getProtocol(pattern)
    for _, protocol in ipairs(self.protocols) do
        local item = string.match(protocol, pattern)
        if item then
            return item
        end
    end
    return nil
end

function WebSocketInstanceBase:authConnect()
    local pattern = Constants.WEBSOCKET_SUBPROTOCOL_PATTERN
    local token = self:getProtocol(pattern)
    if token then
        return token, nil
    end
    return nil, nil, "not found token in header: Sec-WebSocket-Protocol"
end

function WebSocketInstanceBase:afterAuth()
    local connectId = self:getConnectId()
    if connectId then
        local lgcnt = sdLogin:incr(connectId, 1, 0)
        if lgcnt > 1 then
            sdLogin:incr(connectId, -1, 0)
            self:sendMessage({
                err = "already logged",
            })
            return false
        end
        self._locked = true
    end
    return true
end

function WebSocketInstanceBase:onClose()
    if self._locked then
        local connectId = self:getConnectId()
        sdLogin:incr(connectId, -1, 0)
    end
    if self._socket then
        self._socket:send_close()
        self._socket = nil
    end
    return WebSocketInstanceBase.super.onClose(self)
end

function WebSocketInstanceBase:send_text(msg)
    if self._socket then
        self._socket:send_text(tostring(msg))
    end
end

--回复消息
function WebSocketInstanceBase:sendMessage(msg)
    if self._socket then
        if type(msg) == "table" then
            self._socket:send_text(json_encode(msg))
        else
            self._socket:send_binary(msg)
        end
    end
end

--服务器本身通信使用msgpack
function WebSocketInstanceBase:sendToChannel(channel, msg)
    local redis = self:getRedis()
    if redis then
        if type(msg) == "table" then
            return redis:publish(channel, net_encode(msg))
        else
            return redis:publish(channel, tostring(msg))
        end
    end
    return false, "sendToChannel failed"
end

function WebSocketInstanceBase:onPing()
    -- body
end

function WebSocketInstanceBase:onPong()
    -- body
end

function WebSocketInstanceBase:runEventLoop()
    -- auth client
    local this = self
    local ok, err = self:readProtocols()
    if not ok then
        cc.printf("readProtocols:"..err)
        return ok, err
    end
    
    local token, connectId, err = self:authConnect()
    if not token then
        cc.printinfo(err)
        self:sendMessage({
            err = err,
        })
        return false
    end
    
    self._connectToken = token
    
    -- generate connect id and channel
    local redis = self:getRedis()
    --当没有取得链接ID时，使用自动生成的ID
    if not connectId then
        connectId = tostring(redis:incr(Constants.NEXT_CONNECT_ID_KEY))
    end
    
    --添加程序名称，使得id唯一
    connectId = self.config.app.appName .. "-" .. connectId
    
    self._connectId = connectId
    
    if not self:afterAuth() then
        cc.printinfo("user is already connected:"..connectId)
        return false
    end
    
    local connectChannel = Constants.CONNECT_CHANNEL_PREFIX .. tostring(connectId)
    self._connectChannel = connectChannel
    local controlChannel = Constants.CONTROL_CHANNEL_PREFIX .. tostring(connectId)
    self._controlChannel = controlChannel
    
    -- create websocket server
    local server = require("resty.websocket.server")
    local socket, err = server:new({
        timeout = self.config.app.websocketsTimeout,
        max_payload_len = self.config.app.websocketsMaxPayloadLen,
    })
    if err then
        return false, string.format("[websocket:%s] create websocket server failed, %s", connectId, err)
    end
    self._socket = socket
    
    -- tracking socket close reason
    local closeReason = ""
    
    -- create subscribe loop
    local sub, _err = self:getRedis():makeSubscribeLoop(connectId)
    if not sub then
        return false, err
    end
    
    sub:start(function(subRedis, channel, msg)
        if msg == Constants.CLOSE_CONNECT then
            closeReason = Constants.CLOSE_CONNECT
            socket:send_close()
        else
            if channel == controlChannel then
                this:onControlMessage(msg, subRedis)
            else
                socket:send_binary(msg)
            end
        end
    end, controlChannel, connectChannel, Constants.BROADCAST_ALL_CHANNEL)
    self._subloop = sub
    
    -- connected
    cc.printinfo("[websocket:%s] connected", connectId)
    
    self:safeFunction(function()
        this:onConnected()
    end)
    
    -- event loop
    local frames = {}
    local running = true
    while running do
        self:heartbeat()
        while true do
            local frame, ftype, err = socket:recv_frame()
            if err then
                if err == "again" then
                    frames[#frames + 1] = frame
                    break -- recv next message
                end
                
                if string_sub(err, -7) == "timeout" then
                    break -- recv next message
                end
                
                cc.printwarn("[websocket:%s] failed to receive frame, type \"%s\", %s", connectId, ftype, err)
                closeReason = ftype
                running = false -- stop loop
                break
            end
            
            if #frames > 0 then
                -- merging fragmented frames
                frames[#frames + 1] = frame
                frame = table_concat(frames)
                frames = {}
            end
            
            if ftype == "close" then
                running = false -- stop loop
                break
            elseif ftype == "ping" then
                socket:send_pong()
                self:onPing()
            elseif ftype == "pong" then
                -- client ponged
                self:onPong()
            elseif ftype == "text" or ftype == "binary" then
                local _, err = self:processMessage(frame, ftype)
                if err then
                    cc.printerror("[websocket:%s] process %s message failed, %s", connectId, ftype, err)
                end
            else
                cc.printwarn("[websocket:%s] unknown frame type \"%s\"", connectId, tostring(ftype))
            end
        end -- rect next message
    end -- loop
    
    -- disconnected
    self:safeFunction(function()
        this:onDisconnected(closeReason)
    end)
    
    sub:stop()
    self._subloop = nil
    self._socket = nil
    cc.printinfo("[websocket:%s] disconnected", connectId)
end

function WebSocketInstanceBase:heartbeat()
    
end

function WebSocketInstanceBase:getConnectToken()
    return self._connectToken
end

function WebSocketInstanceBase:getConnectId()
    return self._connectId
end

function WebSocketInstanceBase:getConnectChannel()
    return self._connectChannel
end

function WebSocketInstanceBase:getControlChannel()
    return self._controlChannel
end

-- add methods

local _COMMANDS = {
    "subscribe", "unsubscribe",
    "psubscribe", "punsubscribe",
}

for _, cmd in ipairs(_COMMANDS) do
    WebSocketInstanceBase[cmd] = function(self, ...)
        local subloop = self._subloop
        local method = subloop[cmd]
        return method(subloop, ...)
    end
end

function WebSocketInstanceBase:onConnected()
    -- body
end

function WebSocketInstanceBase:onDisconnected(_closeReason)
    -- body
end

function WebSocketInstanceBase:onControlMessage(_msg, _subRedis)
    
end

function WebSocketInstanceBase:onProtobuf(_rawMessage)
    return nil, "not support protobuf"
end

--json数据处理
function WebSocketInstanceBase:onData(_message)
    
    return false, "not message action"
end

function WebSocketInstanceBase:onJson(rawMessage)
    local message = json_decode(rawMessage)
    if message.action then
        return self:runAction(message.action, message.args or message)
    else
        return self:onData(message)
    end
end

function WebSocketInstanceBase:onMessage(rawMessage, messageType, messageFormat)
    if messageType == Constants.WEBSOCKET_BINARY_MESSAGE_TYPE then
        if messageFormat == "pbc" then
            return self:onProtobuf(rawMessage)
        else
            return nil, string.format("not support message format \"%s\"", tostring(messageFormat))
        end
    end
    
    if messageType == Constants.WEBSOCKET_TEXT_MESSAGE_TYPE then
        if messageFormat == "json" then
            return self:onJson(rawMessage)
        else
            return nil, string.format("not support message format \"%s\"", tostring(messageFormat))
        end
    end
    
    return nil, string.format("not supported message type \"%s\"", messageType)
end

function WebSocketInstanceBase:processMessage(rawMessage, messageType)
    local this = self
    local ok, result, err
    local messageFormat = self.config.app.websocketMessageFormat
    ok, result, err = self:safeFunction(function()
        return this:onMessage(rawMessage, messageType, messageFormat)
    end)
    
    if not ok or err then
        return nil, err
    end
    
    if not self._socket then
        return nil, string.format("socket removed, action")
    end
    
    if type(result) == "table" then
        local message = json_encode(result)
        local _bytes, err = self._socket:send_text(message)
        if err then
            return nil, string.format("send message to client failed, %s", err)
        end
    end
    return true
end

function WebSocketInstanceBase:GetConfig(name)
    if not name then
        name = self:getAppName()
    end
    local configs = self.config.server.nginx
    if configs then
        for _, v in ipairs(configs) do
            if v.apps and v.apps[name] then
                return v
            end
        end
    end
end

function WebSocketInstanceBase:getAppName()
    return self.config.app.appName
end

return WebSocketInstanceBase
