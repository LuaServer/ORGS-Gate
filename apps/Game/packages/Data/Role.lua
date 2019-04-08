local Base = cc.import(".Base")
local Role = cc.class("Role", Base)

local Table = cc.import("#Table", ...)

local dbConfig = cc.import("#dbConfig")

function Role:ctor()
    Role.super.ctor(self, Table.Role)
end

function Role:Initialize(db, pid)
    if not db or not pid then
        return nil, "NoParam"
    end
    return self:load(db, {pid = pid})
end

function Role:Create(db, pid, nickname, cid)
    if not db or not pid or not nickname or not cid then
        return nil, "NoParam"
    end
    
    if #nickname <= 6 then
        return nil, "NoSetNickname"
    end
    
    local data = self:get()
    data.pid = pid
    data.nickname = nickname
    data.loginTime = 0
    data.createTime = ngx.now()
    data.cid = cid
    
    local result, err = self:insertQuery(db, data)
    if err then
        cc.printf(err)
        return nil, "DBError"
    end
    if not result or not result.insert_id then
        return nil, "DBError"
    end
    return self:load(db, {id = result.insert_id})
end

function Role:AddExp(exp_add)
    local level = self:get("level")
    local exp = self:get("exp")
    local cfg = dbConfig.get("cfg_levelup", level)
    if cfg == nil then
        self:add("exp", exp_add)
    else
        local need = cfg.exp - exp
        if need > exp_add then
            self:add("exp", exp_add)
        else
            self:add("level", 1)
            self:set("exp", 0)
            self:AddExp(exp_add - need)
        end
    end
end

function Role:AddRewards(items)
    for _, item in ipairs(items) do
        if 1 == item.tp then
            self:add("diamond", item.count)
        elseif 2 == item.tp then
            self:add("techPoint", item.count)
        end
    end
end

return Role
