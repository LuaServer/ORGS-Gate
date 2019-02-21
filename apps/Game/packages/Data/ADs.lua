
local BaseList = cc.import(".BaseList")
local ADs = cc.class("ADs", BaseList)
local AD = cc.import(".AD")
local dbConfig = cc.import("#dbConfig")

function ADs:createItem()
    return AD:new()
end

function ADs:Initialize(db, rid, lastTime, loginTime)
    if not db or not lastTime or not loginTime or not rid then
        return nil, "NoParam"
    end
    
    local loginDate = os.date("*t", loginTime)
    local lastDate = os.date("*t", lastTime)
    
    if loginDate.year ~= lastDate.year or loginDate.yday ~= lastDate.yday then
        local template = self:getTemplate()
        --删除所有旧的数据
        template:deleteQuery(db, {rid = rid})
        local cfgs = dbConfig.getAll("cfg_ad")
        local template = self:getTemplate()
        --插入所有需要插入的成就
        for _, cfg in ipairs(cfgs) do
            template:insertQuery(db, {rid = rid, cid = cfg.id, time = 0, count = cfg.times})
        end
    end
    return self:load(db, {
        rid = rid,
    })
end

function ADs:Finish(id)
    local ad = self:getByCID(id)
    
    if not ad then
        return nil, "NoneID"
    end
    
    local ad_data = ad:get()
    if ad_data.count <= 0 or ad_data.time > ngx.now() then
        return nil, "OperationNotPermit"
    end
    local cfg = ad:getConfig()
    ad:set("count", ad_data.count - 1)
    ad:set("time", cfg.delay + ngx.now())
    
    return ad:get(), nil, cfg
end

return ADs
