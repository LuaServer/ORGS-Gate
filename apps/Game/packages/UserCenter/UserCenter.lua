
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

--更新在线时间
function UserCenter:updateSessionTime(connectid)
    local user = self.users[connectid]
    if user then
        user:UpdateSessionTime()
    else
        cc.printf("user is offline:"..connectid)
    end
end

--检测掉线玩家
function UserCenter:checkOnlineUser(db)
    local list = {}
    for connectid, _ in pairs(self.users) do
        table.insert(list, connectid)
    end
    for connectid, _ in ipairs(list) do
        local user = self.users[connectid]
        if user and user:IsOffline() then
            self:userLogout(connectid, db)
        end
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
    elseif MessageType.CHECKCONNECTED == message then
        self:checkOnlineUser(db)
    elseif MessageType.UPDATE_SESSION == message then
        self:updateSessionTime(connectid)
    else
        local user = self.users[connectid]
        if user then
            user:Process(db, message, self.instance, msgtype, msgid)
        else
            --用户已经离线，需要重新登陆
            cc.printf("user is offline:"..connectid)
        end
    end
end

function UserCenter:Save(connectid, db)
    local user = self.users[connectid]
    if user then
        user:Save(db)
    end
end

--保存所有数据
function UserCenter:SaveAll(db)
    for _, user in pairs(self.users) do
        user:Save(db)
    end
end

--移除所有用户
function UserCenter:RemoveAll()
    for id, _ in pairs(self.users) do
        sdLogin:incr("PID:"..id, -1, 0)
    end
    self.users = {}
end

return UserCenter
