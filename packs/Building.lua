-------------------------------------------------------------------------------
---@class Building
--- **Singleton**
-------------------------------------------------------------------------------
local M = {}
M.__index = M

-- Dependencies
local Image = require('ImageHelper')
local Color = require('ColorHelper')
local luall = require('LuaLib')
local botl = require('BotLib')
local GV = require('GlobalVars')
local Console = require('Console')
local Queue = require("Queue")
local OTimer = require('OTimer')

-------------------------------------------------------------------------------
---[Public]
---
--- init class
---@param id string @building id
---@param title string @building name
---@param left number @building left location
---@param bottom number @building bottom location
---@return self @new class metatable
-------------------------------------------------------------------------------
function M:new(id, title, left, bottom)
    local _self = {}
    _self.id = id or "_no_building_"
    _self.title = title or "Building"
    _self.left = left or 1
    _self.bottom = bottom or 1
    _self.product_timeout = OTimer:new()
    setmetatable(_self, M)
    return _self
end

-------------------------------------------------------------------------------
function M:start()

    local product = Queue:getNextProduct(self.id)
    if not product then
        return false
    end

    while true do
        local building = self:getBuilding()
        if not building then
            return false
        end

        click(building.obj)
        while true do
            local anchor = self:collect()
            if anchor then

                if self:produce(anchor, product) then
                    return true
                end

                Queue:removeProduct(product.id)
                product = Queue:getNextProduct(self.id)
                if not product then
                    --break
                end
            end
        end
    end

end

-------------------------------------------------------------------------------
--- Select building by given location
---
---@return boolean|table @
-------------------------------------------------------------------------------
function M:getBuilding()
    Console:show(table.concat({ "Open", self.title }))
    local anchor = botl.getHolder(0,  { 355, 93 })

    if not anchor then
        scriptExit("Anchor not found")
    end
    --
    local building = botl.getAnchorClickLocation(anchor, self.left, self.bottom)
    if not building then
        scriptExit("field not found")
    end

    return building
end

-------------------------------------------------------------------------------
function M:collect()
    if Color:exists(GV.OBJ.collect_product, 0) and
            not Image:R(GV.REG.safe_area):exists("building/anchor.png", 0) then
        return false

    end

    if Image:R(GV.REG.safe_area):exists("building/anchor.png", 0) then
        return Image:getData('target')
    end

    return false
end

-------------------------------------------------------------------------------
function M:produce(anchor, product)
    local r_slots = Region(anchor.x - 228, anchor.y + 70, 730, 360)

    Image:R(r_slots):findAll("building/empty.png", 0)
    local slots = Image:getData()
    if #slots < 1 then
        return false
    end

    local product_location = Location(anchor.x + product.offset_x, anchor.y + product.offset_y)
    local slot_location = slots[1].target.obj

    for i = 1, #slots do
        swipe(product_location, slot_location)

        -- no more resources
        if not botl.isHomeScreen(1) and botl.btn_close("exists") then
            self:enqueueResources(product.resources)
            botl.btn_close("click", 0)
            return false
        end

        --
    end
    return true
end

-------------------------------------------------------------------------------
function M:enqueueResources(resources)
    if not resources then
        return false
    end

    for i = 1, #resources do
        if Image:R(GV.REG.product_resources):exists("products/" .. resources[i] .. ".png", 0) then
            Queue:addProduct(resources[i])
        end
    end

end

return M