
--[[
Copyright (c) 2015 gameboxcloud.com
Permission is hereby granted, free of chargse, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
 
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
 
]]

local gbc = cc.import("#gbc")
local EquipAction = cc.class("EquipAction", gbc.ActionBase)
local dbConfig = cc.import("#dbConfig")

EquipAction.ACCEPTED_REQUEST_TYPE = "websocket"

function EquipAction:checkProp(id)
    local instance = self:getInstance()
    if not id then
        instance:sendError("NoneProp")
        return nil
    end
    local player = instance:getPlayer()
    local props = player:getProps()
    local prop = props:get(id)
    if not prop or prop.count < 1 then
        instance:sendError("NoneProp")
        return nil
    end
    return prop
end

function EquipAction:checkEquipment(id)
    local instance = self:getInstance()
    local player = instance:getPlayer()
    local equipments = player:getEquipments()
    local equip = equipments:get(id)
    if not equip then
        instance:sendError("NoneEquipment")
        return nil
    end
    return equip
end

function EquipAction:onProp(args, _redis)
    cc.dump(args)
end

function EquipAction:onEquip(args, _redis)
    cc.dump(args)
end

--得到了新的装备
function EquipAction:onNewEquip(args, _redis)
    if args.err then
        return
    end
    local instance = self:getInstance()
    local player = instance:getPlayer()
    local equipments = player:getEquipments()
    local bupdate = equipments:updates(args)
    if bupdate then
        instance:sendPack("Equipments", {
            values = args,
        })
    end
end

--解锁新的装备成功
function EquipAction:onUnlock(args, _redis)
    if not args.err then
        return
    end
    local insert_id = args.insert_id
    if insert_id then
        local instance = self:getInstance()
        local player = instance:getPlayer()
        local equipments = player:getEquipments()
        local equip = equipments:get()
        local query = equip:selectQuery({id = insert_id})
        equip:pushQuery(query, instance:getConnectId(), "onNewEquip")
    end
end

function EquipAction:unlockEquipment(args, _redis)
    local instance = self:getInstance()
    local player = instance:getPlayer()
    local prop = self:checkProp(args.prop_id)
    if not prop then
        return
    end
    local role = player:getRole()
    
    local prop_data = prop:get()
    local cfg_prop = dbConfig.get("cfg_prop", prop_data.cid)
    if not cfg_prop then
        instance:sendError("ConfigError")
        return
    end
    local cfg_equip = dbConfig.get("cfg_equip", cfg_prop.eid)
    if not cfg_equip then
        instance:sendError("ConfigError")
        return
    end
    
    --类型不为武器书，错误
    if cfg_prop.type ~= 2 then
        instance:sendError("OperationNotPermit")
        return
    end
    
    local equipments = player:getEquipments()
    
    local equip = equipments:getOriginal(cfg_equip.originalId)
    --找到该装备，无法解锁该类型装备
    if equip then
        instance:sendError("OperationNotPermit")
    end
    
    --好了，现在允许操作了，减少道具数量, 更新星级与品质
    prop_data.count = prop_data.count - 1
    local query = prop:updateQuery({count = prop_data.count}, {id = prop_data.id})
    prop:pushQuery(query, instance:getConnectId(), "equip.onProp")
    instance:sendPack("Prop", prop_data)
    
    local equip = equipments:get()
    local dt = equip:get()
    dt.rid = role:getID()
    dt.cid = cfg_prop.eid
    dt.star = 1
    --cfg_prop.star
    dt.oid = cfg_equip.originalId
    query = equip:insertQuery(dt)
    equip:pushQuery(query, instance:getConnectId(), "equip.onUnlock")
end

function EquipAction:checkProps(ids)
    local countMap = {}
    for _, id in ipairs(ids) do
        if not countMap[id] then
            countMap[id] = 0
        end
        countMap[id] = countMap[id] + 1
    end
    local propMap = {}
    local instance = self:getInstance()
    local player = instance:getPlayer()
    local props = player:getProps()
    for id, count in pairs(countMap) do
        local prop = props:get(id)
        if not prop or prop.count < count then
            instance:sendError("NoneProp")
            return nil
        end
        propMap[prop] = count
    end
    return propMap
end

function EquipAction:upgradeStarAction(args, _redis)
    local instance = self:getInstance()
    local id = args.id
    local prop_ids = args.prop_ids
    if not prop_ids or not id then
        instance:sendError("NoneID")
        return
    end
    
    local propMap = self:checkProps(prop_ids)
    if not propMap then
        return
    end
    
    local equip = self:checkEquipment(id)
    if not equip then
        return
    end
    
    --检查武器是否存在
    local equip_data = equip:get()
    local cfg_equip = dbConfig.get("cfg_equip", equip_data.cid)
    if not cfg_equip then
        instance:sendError("ConfigError")
        return
    end
    
    --计算总的升星power
    local power = 0
    for prop, count in pairs(propMap) do
        local prop_data = prop:get()
        local cfg_prop = dbConfig.get("cfg_prop", prop_data.cid)
        
        if not cfg_prop or cfg_prop.type ~= 2 then
            instance:sendError("ConfigError")
            return
        end
        local cfg_equip_prop = dbConfig.get("cfg_equip", cfg_prop.eid)
        if cfg_equip_prop.originalId ~= cfg_equip.originalId then
            instance:sendError("ConfigError")
            return
        end
        power = power + count * cfg_prop.power
    end
    
    --检查是否可以更新武器品质
    
    --类型不为武器书，错误
    
    local cfg_star = dbConfig.get("cfg_star", equip_data.star)
    if not cfg_star then
        instance:sendError("ConfigError")
        return
    end
    
    local cfg_star_next = dbConfig.get("cfg_star", equip_data.star + 1)
    if not cfg_star_next then
        instance:sendError("OperationNotPermit")
        return
    end
    
    --等级是否已经满级
    if cfg_equip.level ~= cfg_star.maxLevel then
        instance:sendError("OperationNotPermit")
        return
    end
    
    --减掉需要减去的装备
    for prop, count in pairs(propMap) do
        local prop_data = prop:get()
        prop_data.count = prop_data.count - count
        local query = prop:updateQuery({count = prop_data.count}, {id = prop_data.id})
        prop:pushQuery(query, instance:getConnectId())
        instance:sendPack("Prop", prop_data)
    end
    
    --判断是否可以升级
    local bUpStar = false
    math.randomseed(ngx.now())
    if cfg_star_next.power >= 1 then
        local randnumber = math.random(cfg_star_next.power)
        if randnumber <= power then
            bUpStar = true
        end
    end
    
    if bUpStar then
        equip_data.star = equip_data.star + 1
        local query = equip:updateQuery({
            star = equip_data.star,
        }, {id = equip_data.id})
        equip:pushQuery(query, instance:getConnectId())
    end
    instance:sendPack("Equipment", equip_data)
end

function EquipAction:upgradeLevelAction(args, _redis)
    local instance = self:getInstance()
    local id = args.id
    local prop_id = args.prop_id
    --local player = instance:getPlayer()
    if not id or not prop_id then
        instance:sendError("NoneID")
        return
    end
    
    local prop = self:checkProp(prop_id)
    if not prop then
        return
    end
    
    local equip = self:checkEquipment(id)
    if not equip then
        return
    end
    
    local prop_data = prop:get()
    local equip_data = equip:get()
    
    --检查是否可以更新武器品质
    local cfg_prop = dbConfig.get("cfg_prop", prop_data.cid)
    local cfg_equip = dbConfig.get("cfg_equip", equip_data.cid)
    if not cfg_prop or not cfg_equip then
        instance:sendError("ConfigError")
        return
    end
    local cfg_star = dbConfig.get("cfg_star", equip_data.star)
    if not cfg_star then
        instance:sendError("ConfigError")
    end
    
    --类型不为经验书，错误
    if cfg_prop.type ~= 1 then
        instance:sendError("OperationNotPermit")
        return
    end
    
    --等级已经升满，不需要进行升级了
    if cfg_equip.level >= cfg_star.maxLevel then
        instance:sendError("OperationNotPermit")
        return
    end
    
    equip_data.exp = cfg_prop.exp + equip_data.exp
    if equip_data.exp >= cfg_equip.updradeExp then
        equip_data.exp = 0
        equip_data.cid = cfg_equip.upgradeID
    end
    
    prop_data.count = prop_data.count - 1
    
    local query = prop:updateQuery({count = prop_data.count}, {id = prop_data.id})
    prop:pushQuery(query, instance:getConnectId())
    instance:sendPack("Prop", prop_data)
    
    query = equip:updateQuery({
        exp = equip_data.exp,
        cid = equip_data.cid,
    }, {id = equip_data.id})
    equip:pushQuery(query, instance:getConnectId())
    instance:sendPack("Equipment", equip_data)
    
end

return EquipAction

