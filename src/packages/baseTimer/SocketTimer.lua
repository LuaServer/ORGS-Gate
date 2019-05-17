
local gbc = cc.import("#gbc")
local SocketTimer = cc.class("SocketTimer", gbc.NgxTimerBase)
local client = require "resty.websocket_client"
local ngx_sleep = ngx.sleep
local string_sub = string.sub
local table_concat = table.concat

local netpack = cc.import("#netpack")
local net_decode = netpack.decode

--param
--[[
    uri -- 服务器地址
    authorization --授权码
    channel --共享通道
    msg --附带消息
]]--

function SocketTimer:ctor(config, param, ...)
    SocketTimer.super.ctor(self, config, param, ...)
end

function SocketTimer:OnClosed(_redis)
    -- body
end

function SocketTimer:OnConnected()
    -- body
end

function SocketTimer:connect()
    if self._socket == nil then
        local socket = client:new()
        local ok, err = socket:connect(self.param.uri, {
            protocols = {
                "gbc-auth-"..self.param.authorization,
                "gbc-msg-"..self.param.msg,
            },
        })
        if not ok then
            cc.printerror("wb connect:"..err)
            return false
        end
        cc.printf(string.format("%s is connect success", self.param.uri))
        self._socket = socket
        self:OnConnected()
        return true
    end
    return true
end

function SocketTimer:closeSocket(redis)
    if self._socket ~= nil then
        local socket = self._socket
        self._socket = nil
        socket:set_keepalive()
        self:OnClosed(redis)
    end
end

--处理来着Game服务器的消息
function SocketTimer:ProcessMessage(frame, ftype)
    self:safeFunction(function ()
        if frame then
            local data, err = net_decode(frame)
            if err then
                cc.printerror(string.format("can not decode frame err:%s [%d]", err, #frame))
                return
            end
            if type(data) == "table" and data.connectid then
                --cc.printf(string.format("decode success length[%d]", #frame))
                if data.tp == 1 then
                    self:sendControlMessage(data.connectid, data.message)
                else
                    self:sendMessageToConnectID(data.connectid, data.message)
                end
            else
                cc.printf(string.format("net_decode data is not table length:[%d] ftype:[%s]", #frame, ftype))
            end
        end
    end)
end

--服务器循环
function SocketTimer:runEventLoop()
    local sub, _err = self:getRedis():makeSubscribeLoop(self.param.channel)
    if not sub then
        cc.printerror("makeSubscribeLoop failure")
        return false
    end
    local this = self
    --接收到channel消息就发送到Game服务器
    sub:start(function(subRedis, _channel, msg)
        if this._socket ~= nil then
            local _, err = this._socket:send_binary(msg)
            if err then
                cc.printf("sub close socket:"..err)
                this:closeSocket(subRedis)
            end
        else
            cc.printf("send_binary failed:"..msg)
        end
    end, self.param.channel)
    cc.printf("subscribe channel:"..self.param.channel)
    local frames = {}
    while true do
        if self._socket then
            while self._socket do
                local frame, ftype, err = self._socket:recv_frame()
                if err then
                    if err == "again" then
                        table.insert(frames, frame)
                        break -- recv next message
                    end
                    if string_sub(err, -7) == "timeout" then
                        break -- recv next message
                    end
                    cc.printf("close socket:"..err)
                    self:closeSocket(self:getRedis())
                end
                
                if #frames > 0 then
                    -- merging fragmented frames
                    table.insert(frames, frame)
                    frame = table_concat(frames)
                    frames = {}
                end
                
                if ftype == "close" then
                    self:closeSocket(self:getRedis())
                    break
                elseif ftype == "ping" then
                    if self._socket then
                        self._socket:send_pong()
                    end
                elseif ftype == "pong" then
                    -- client ponged
                elseif ftype == "text" or ftype == "binary" then
                    self:ProcessMessage(frame, ftype)
                else
                    cc.printwarn("[SocketTimer:%s] unknown frame type \"%s\"", self.param.channel, tostring(ftype))
                end
            end
        else
            --重新连接服务器
            self:connect()
            ngx_sleep(5)
        end
    end
end

return SocketTimer

