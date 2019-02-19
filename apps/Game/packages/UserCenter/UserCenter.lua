
local UserCenter = cc.class("UserCenter")

local gbc = cc.import("#gbc")
local User = cc.import(".User")
local MessageType = gbc.MessageType
local Constants = gbc.Constants
local sdLogin = ngx.shared.sdLogin

function UserCenter:ctor(instance, connect_channel)
    self.users = {}
    self.instance = instance
    self.connect_channel = connect_channel
end

function UserCenter:canLogin(connectid)
    local connectid_CN = "PID:"..connectid
    local lgcnt = sdLogin:incr(connectid_CN, 1, 0)
    
    if lgcnt > 1 then
        sdLogin:incr(connectid_CN, -1, 0)
        return false
    else
        --cc.printf(string.format("User:%d |--|%s----å|%d", connectid, self.connect_channel, lgcnt))
        return true
    end
end

function UserCenter:userLogin(connectid, db)
    if self:canLogin(connectid) then
        local user = self.users[connectid]
        if not user then
            user = User:new(connectid)
            self.users[connectid] = user
            user:Login(db, self.instance)
        end
    else
        if self.instance then
            self.instance:sendError(connectid, "UserLoggedIn")
            self.instance:sendToGate(connectid, Constants.CLOSE_CONNECT, 1)
        end
    end
end

function UserCenter:userLogout(connectid, db)
    local user = self.users[connectid]
    if user then
        user:Logout(db, self.instance)
        self.users[connectid] = nil
        sdLogin:incr("PID:"..connectid, -1, 0)
    end
    --cc.printf(string.format("User:%d |--|%s----å|%d", connectid, self.connect_channel, lgcnt))
end

function UserCenter:checkdb(db)
    local ok, err = db:query("select now()")
    if err then
        cc.printf("checkdb:"..err)
    end
    return ok
end

function UserCenter:Process(connectid, message, db, msgtype, msgid)
    if MessageType.ONCONNECTED == message then --用户登陆
        self:userLogin(connectid, db)
    elseif MessageType.ONDISCONNECTED == message then --断开链接
        self:userLogout(connectid, db)
    elseif MessageType.DB_SAVE == message then --存储到数据库
        if self:checkdb(db) then
            self:SaveAll(db)
        end
    else
        local user = self.users[connectid]
        if user then
            user:Process(db, message, self.instance, msgtype, msgid)
        end
    end
end

function UserCenter:SaveAll(db)
    --cc.printf("SaveAll")
    for _, user in pairs(self.users) do
        user:Save(db)
    end
end

function UserCenter:Save(connectid, db)
    local user = self.users[connectid]
    if user then
        user:Save(db)
    end
end

function UserCenter:RemoveAll()
    for id, _ in pairs(self.users) do
        sdLogin:incr("PID:"..id, -1, 0)
        --cc.printf(string.format("User:%d |--|%s----å|%d", id, self.connect_channel, lgcnt))
    end
    self.users = {}
end

return UserCenter
