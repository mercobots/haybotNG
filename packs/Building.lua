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
    _self.production_timeout = OTimer:new()
    setmetatable(_self, M)
    return _self
end

-------------------------------------------------------------------------------
function M:start()
    --
    if #Queue:getData(self.id) < 1 then
        return false
    end

    -- still in production
    if self.production_timeout:isRunning() then
        Console:show(table.concat({ self.title, " in ", self.production_timeout:timeLeft()[1] }))
        return false
    end

    -- get next enqueue product
    local product = Queue:getNextProduct(self.id)
    if not product then
        return false
    end

    Console:show(table.concat({ self.title, " - ", product.title }))

    -- get building location by user layout config
    local building = self:getBuilding()
    if not building then
        return false
    end

    -- collect products and return anchor production
    local anchor = self:collect(building)
    if not anchor then
        botl.openRandomForm()
        return false
    end

    -- start product production
    self:produce(anchor, product)

    Queue:removeProduct(product.id)
    botl.openRandomForm()

end
-----
-----------------------------------------------------------------------------
function M:collect(building)
    while true do
        click(building.obj)

        -- collecting , still has products to collect
        --if Color:exists(GV.OBJ.collect_product, 0) and
        --        not Image:R(GV.REG.safe_area):exists("building/anchor.png", 0) then
        --    return false
        --end
        --
        -- building available
        --if not Image:R(GV.REG.safe_area):exists("building/anchor.png", 0) then
        --    return Image:getData('target')
        --end

        if Image:R(GV.REG.safe_area):exists("building/anchor.png", 0) then
            Console:show(table.concat({ "Open ", self.title }))
            return Image:getData('target')
        end
        Console:show("Collect Products")
    end

    return false
end

-------------------------------------------------------------------------------
--- Select building by given location
---
---@return boolean|table @
-------------------------------------------------------------------------------
function M:getBuilding()
    local anchor = botl.getHolder(0, { 360, 107 })

    if not anchor then
        Console:show("Anchor not found")
        return false
    end
    --
    local building = botl.getAnchorClickLocation(anchor, self.left, self.bottom)
    if not building then
        Console:show("Building not found")
        return false
    end

    return building
end

-------------------------------------------------------------------------------
function M:produce(anchor, product)
    Console:show("Start production")
    -- Set Slots region

    -- calculate product location
    local product_location = Location(anchor.x + product.offset_x, anchor.y + product.offset_y)
    local slot = Location(anchor.x - 128, anchor.y + 152)
    local full_R = Region(anchor.x - 435, anchor.y, 635, 300)
    local timer = Timer()

    self:resetRequiredResources(product.resources)

    while true do
        if luall.is_timeout(timer:check(), 30) then
            Console:show("Production timeout")
            return false
        end

        --
        swipe(product_location, slot)

        if Image:R(full_R):exists("building/full.png", 1) then
            Console:show("No more slots")
            -- TODO temp
            if self.production_timeout:isStopped() then
                self.production_timeout.timeout = product.produce_time
                self.production_timeout:start()
            end
            -- TODO temp
            break
        end

        -- no more resources
        if not botl.isHomeScreen(0) and botl.btn_close("exists") then
            -- enqueue missing resources
            self:enqueueResources(product.resources)
            -- TODO temp
            if self.production_timeout:isStopped() then
                self.production_timeout.timeout = product.produce_time
                self.production_timeout:start()
            end
            -- TODO temp
            botl.btn_close("click", 0)
            return false
        end

        if self.production_timeout:isStopped() then
            self.production_timeout:start()
        end

        -- everything is fine
        self.production_timeout:increaseTimeout(product.produce_time)

    end

    return true
end

-------------------------------------------------------------------------------
function M:resetRequiredResources(resources)
    Console:show("reset resources")

    if not resources then
        return false
    end

    for i = 1, #resources do
        local resource = botl.getGVProductBy(resources[i][1], "id")
        resource.require = 0
    end

end

-------------------------------------------------------------------------------
function M:enqueueResources(resources)
    Console:show("No more resources")

    if not resources then
        return false
    end

    for i = 1, #resources do
        local product_id = resources[i][1]
        local require = resources[i][2]
        Console:show(table.concat({ "Enqueue ", require, " - ", product_id }))

        --
        if Image:R(GV.REG.product_resources):exists("products/" .. product_id .. ".png", 0) then
            Queue:addProduct(product_id, false, require)
        end
    end

end

return M