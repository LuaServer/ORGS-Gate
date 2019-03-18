
local Base = cc.import(".Base")
local Signin = cc.class("Signin", Base)

local Table = cc.import("#Table", ...)

local json = cc.import("#json")
--local json_encode = json.encode
local json_decode = json.decode

function Signin:ctor()
    Signin.super.ctor(self, Table.Signin)
end

function Signin:Initialize(db, lastTime, loginTime, roleid)
    if not lastTime or not loginTime or not roleid then
        return false, "NoParam"
    end
    
    local loginDate = os.date("*t", loginTime)
    local lastDate = os.date("*t", lastTime)
    
    if loginDate.year ~= lastDate.year or loginDate.month ~= lastDate.month then
        --月份不同或者年份不同，则重制签到
        self:insertWithUpdateQuery(db, {
            rid = roleid,
            times = 1,
            record = "",
        }, {times = 1, record = ""}, {})
    elseif loginDate.year ~= lastDate.year or loginDate.yday ~= lastDate.yday then
        --新的一天
        self:insertWithUpdateQuery(db, {
            rid = roleid,
            times = 1,
            record = "",
        }, {}, {times = 1})
    end
    
    self:load(db, {rid = roleid})
    return self:GetProto()
end

function Signin:GetProto()
    local data = self:get()
    local pb = {
        times = data.times,
        record = json_decode(data.record) or {},
    }
    return pb
end

return Signin
