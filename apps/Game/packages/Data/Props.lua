
local BaseList = cc.import(".BaseList")
local Props = cc.class("Props", BaseList)
local Prop = cc.import(".Prop", ...)

local parse = cc.import("#parse")
local ParseConfig = parse.ParseConfig
local dbConfig = cc.import("#dbConfig")

function Props:createItem()
    return Prop:new()
end

function Props:Initialize(db, rid)
    return self:load(db, {rid = rid})
end

--已经拥有当前道具，无法再进行购买
function Props:CanAddItems(items)
    local list = ParseConfig.ParseRewards(items)
    for _, item in ipairs(list) do
        if 3 == item.tp then
            local cfg = dbConfig.get("cfg_prop", item.id)
            --当前道具唯一
            if cfg.unique == 1 and self:HasItem(item.id, 1) then
                return false
            end
        end
    end
    return true
end

function Props:HasItems(items)
    for _, item in ipairs(items) do
        if not item then
            return false
        end
        if not self:HasItem(item.id, item.count) then
            return false
        end
    end
    return true
end

function Props:HasItem(cid, count)
    if not cid or not count then
        return false
    end
    local prop = self:getByCID(cid)
    if not prop then
        return false
    end
    local data = prop:get()
    if data.count < count then
        return false
    end
    return true
end

function Props:UseItem(cid, count)
    if not cid then
        return nil, "NoParam"
    end
    local prop = self:getByCID(cid)
    if not prop then
        return nil, "NoneProp"
    end
    local data = prop:get()
    if data.count < count then
        return nil, "LessProp"
    end
    prop:add("count", -count)
    return data
end

function Props:UseItems(items_str)
    local items = ParseConfig.ParseProps(items_str)
    local list = {}
    for _, item in ipairs(items) do
        local data = self:UseItem(item.id, item.count)
        if data then
            table.insert(list, data)
        end
    end
    return list
end

function Props:AddItem(db, item, rid)
    if 3 == item.tp then
        local cid = item.id
        local count = item.count
        local prop = self:getByCID(cid)
        if prop then
            prop:add("count", count)
            return prop:get()
        else
            local cfg = dbConfig.get("cfg_prop", cid)
            if cfg == nil then
                return nil, "NoneConfigID"
            end
            prop = self:get()
            local result, err = prop:insertQuery(db, {
                rid = rid,
                count = item.count,
                cid = cfg.id
            })
            
            if err then
                cc.printf(err)
                return nil, "DBError"
            end
            
            if result and result.insert_id then
                local datas = self:load(db, {id = result.insert_id})
                if #datas == 1 then
                    return datas[1]
                end
            end
        end
    end
    
    return nil, "OperationNotPermit"
end

function Props:AddRewards(db, items, rid)
    if not items or not rid or not db then
        return nil, "NoParam"
    end
    local itemlist = {}
    for _, item in ipairs(items) do
        local data, _err = self:AddItem(db, item, rid)
        if data then
            table.insert(itemlist, data)
        end
    end
    return itemlist, nil
end

return Props
