
local Base = cc.import(".Base")
local AD = cc.class("AD", Base)
local Table = cc.import("#Table", ...)
local dbConfig = cc.import("#dbConfig")

function AD:ctor()
    AD.super.ctor(self, Table.AD)
end

function AD:getConfig()
    if not self._Config or not self:equalCID(self._Config.id) then
        self._Config = dbConfig.get("cfg_ad", self:get("cid"))
    end
    return self._Config
end

return AD
