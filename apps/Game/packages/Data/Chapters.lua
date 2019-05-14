
local BaseList = cc.import(".BaseList")
local Chapters = cc.class("Chapters", BaseList)
local Chapter = cc.import(".Chapter")
local dbConfig = cc.import("#dbConfig")

local ngx_now = ngx.now

function Chapters:createItem()
    return Chapter:new()
end

function Chapters:Initialize(db, rid, lastTime, loginTime)
    if not db or not lastTime or not loginTime or not rid then
        return nil, "NoParam"
    end
    
    local loginDate = os.date("*t", loginTime)
    local lastDate = os.date("*t", lastTime)
    
    if loginDate.year ~= lastDate.year or loginDate.yday ~= lastDate.yday then
        local template = self:getTemplate()
        template:updateQuery(db, {rid = rid}, {count = 0, extCount = 0})
    end
    return self:load(db, {
        rid = rid,
    })
end

function Chapters:Finish(db, rid, chapter_id, role_level, _star)
    local chapter_cfg = dbConfig.get("cfg_chapter", chapter_id)
    if chapter_cfg == nil then
        return nil, "NoParam"
    end
    
    local clevel_cfgs = dbConfig.getAll("cfg_chapter_level", {
        level = role_level,
        type = chapter_cfg.type,
    })
    if clevel_cfgs == nil or #clevel_cfgs == 0 then
        return nil, "NoParam"
    end
    
    local item = self:getByCID(chapter_cfg.type)
    if item == nil then
        local template = self:getTemplate()
        local result = template:insertQuery(db, {rid = rid, type = chapter_cfg.type, count = 1, totalCount = 1, enterTime = ngx_now(), extCount = 0})
        if result and result.insert_id then
            return self:load(db, {id = result.insert_id}), nil, clevel_cfgs[1]
        end
    else
        item:add("count", 1)
        item:add("totalCount", 1)
        item:set("enterTime", ngx_now())
        return {item:get()}, nil, clevel_cfgs[1]
    end
    return nil, "NoParam"
end

return Chapters
