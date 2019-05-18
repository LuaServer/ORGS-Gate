
local gbc = cc.import("#gbc")
local WebSocketInstance = cc.class("WebSocketInstance", gbc.WebSocketInstanceBase)
local Constants = gbc.Constants
local sdSIG = ngx.shared.sdSIG
local http = cc.import("#http")

local pb = cc.import("#protos")
local CmdToPB = pb.CmdToPB
local PBToCmd = pb.PBToCmd

local netpack = cc.import("#netpack")
local net_encode = netpack.encode
local net_decode = netpack.decode

local Mysql = cc.import("#mysql")

local UserCenter = cc.import("#UserCenter", ...)

function WebSocketInstance:ctor(config)
    WebSocketInstance.super.ctor(self, config)
end

function WebSocketInstance:onClose()
    if self._mysql then
        self._mysql:set_keepalive()
        self._mysql = nil
    end
    return WebSocketInstance.super.onClose(self)
end

function WebSocketInstance:getMysql()
    local mysql = self._mysql
    if not mysql then
        local config = self.config.app.mysql
        if not config then
            cc.printerror("WebSocketInstance:mysql() - mysql is not set config")
            return nil
        end
        mysql = Mysql:new(config)
        self._mysql = mysql
    end
    local ok, err = mysql:connect()
    if not ok then
        cc.printerror(err)
        self._mysql:close()
        self._mysql = nil
        return nil
    end
    return mysql
end

function WebSocketInstance:sendError(pid, errtype, msgid)
    self:sendPack(pid, PBToCmd.Error, {
        code = errtype,
    }, msgid)
end

--tp
--默认为发送到连接，1发送到control
function WebSocketInstance:sendToGate(pid, msg, tp)
    local data, err = net_encode({
        connectid = pid,
        message = msg,
        tp = tp,
    })
    if err then
        cc.printf("sendToGate err:"..err)
    else
        self:sendMessage(data)
    end
end

function WebSocketInstance:sendPack(pid, cmd, msg, msgid)
    msgid = msgid or 0
    local ok, result = self:safeFunction(function()
        local protoname = cmd
        if type(protoname) == "number" then
            protoname = CmdToPB[cmd]
        else
            protoname = cmd
            cmd = PBToCmd[cmd]
        end
        local data
        if protoname then
            if msg then
                data = pb.encode("pb."..protoname, msg)
            end
        else
            cmd = 0
            data = tostring(msg)
        end
        --cc.printf("sendToGate:"..protoname)
        return pb.encode("pb.Pack", {
            ["type"] = cmd,
            content = data,
            msgid = msgid,
        })
    end)
    
    if ok then
        self:sendToGate(pid, result)
    end
end

function WebSocketInstance:authConnect()
    if not sdSIG:get(Constants.SIGINIT) then
        cc.printf("SIGINIT is not set")
        return nil, nil, "SIGINIT is not set"
    end
    
    local gateuri = self:getProtocol(Constants.WEBSOCKET_SUBPROTOCOL_PATTERN_MESSAGE)
    
    --网关地址
    self.gateuri = gateuri
    
    local authorization = WebSocketInstance.super.authConnect(self)
    if not self:hasAuthority(authorization) then
        cc.printf("authorization is error")
        return nil, nil, "authorization is error"
    end
    
    return authorization
end

function WebSocketInstance:postMaster(action)
    local cfg = self:GetConfig()
    local args = {
        name = cfg.servername,
        uri = self.gateuri,
        authorization = self:GetAuthority(),
    }
    local master = self:GetConfig("Master")
    if master then
        http.Post(master.host, master.port, master.name.."/?action="..action, args)
    end
end

function WebSocketInstance:onConnected()
    local connectid = self:getConnectId()
    cc.printf("onConnected gate:"..connectid)
    self:postMaster("service.add")
    local this = self
    self:safeFunction(function()
        this.userCenter = UserCenter:new(this, connectid)
    end)
end

function WebSocketInstance:onDisconnected(closeReason)
    local this = self
    local connectid = self:getConnectId()
    cc.printf("onDisconnected gate:"..connectid)
    self:postMaster("service.remove")
    if self.userCenter then
        self:safeFunction(function()
            local mysql = this:getMysql()
            this.userCenter:SaveAll(mysql)
            this.userCenter:RemoveAll()
        end)
    end
    if closeReason ~= Constants.CLOSE_CONNECT then
        --服务器主动关闭
    end
end

function WebSocketInstance:onProcess(rawmessage)
    local data = net_decode(rawmessage)
    if data.format == "pbc" then
        local message = pb.decode("pb.Pack", data.message)
        if "table" == type(message) then
            if message.type then
                local protoname = CmdToPB[message.type]
                if protoname then
                    local content = pb.decode("pb."..protoname, message.content)
                    if content and self.userCenter then
                        self.userCenter:Process(data.connectid, content, self:getMysql(), protoname, message.msgid)
                    else
                        cc.printf("content is nil by parse:"..protoname)
                    end
                else
                    cc.printf("protoname is nil by type:"..message.type)
                end
            else
                cc.printf("message type is nil")
            end
        else
            cc.printf("message is not table")
        end
    else
        if data and self.userCenter then
            self.userCenter:Process(data.connectid, data.message, self:getMysql())
        end
    end
end

--protobuf数据
function WebSocketInstance:onProtobuf(message)
    local this = self
    self:safeFunction(function()
        this:onProcess(message)
    end)
    
    return true
end

--json数据
function WebSocketInstance:onData(message)
    local this = self
    self:safeFunction(function()
        this:onProcess(message)
    end)
    return true
end

function WebSocketInstance:onControlMessage(_msg, _subRedis)
    
end

function WebSocketInstance:heartbeat()
    
end

return WebSocketInstance
