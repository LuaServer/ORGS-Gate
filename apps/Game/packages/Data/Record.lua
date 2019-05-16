
local Base = cc.import(".Base")
local Record = cc.class("Record", Base)

local Table = cc.import("#Table", ...)

function Record:ctor()
    Record.super.ctor(self, Table.Record)
end

function Record:Initialize(db, rid)
    if not db or not rid then
        return nil, "NoParam"
    end
    
    local ret = self:load(db, {rid = rid})
    if ret == nil then
        local data = self:get()
        data.rid = rid
        data.home = ""
        data.player = ""
        data.missions = ""
        data.used = ""
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
    
    return ret
end

return Record
