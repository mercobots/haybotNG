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
local Sentinel = require("Sentinel")

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
    _self.production_timer = OTimer:new()
    _self.line_production = {}
    _self.current_slide = 1
    _self.product = false
    _self.building = false
    _self.building_anchor = false
    setmetatable(_self, M)
    return _self
end

-------------------------------------------------------------------------------
function M:start()
    if not self:getNextProduct() or
            not self:getBuilding() or
            not self:collect() or
            not  self:produce()  then
        return false
    end

    Queue:removeProduct(self.product.id)
    botl.openRandomForm()

end
-------------------------------------------------------------------------------
function M:getNextProduct()
    -- No products for this machine
    if #Queue:getData(self.id) < 1 then
        Console:show("No products for " .. self.title)
        return false
    end

    -- still in production
    if self.production_timer:isRunning() then
        Console:show(table.concat({ self.title, " in ", self.production_timer:timeLeft() }))
        return false
    end

    -- get next enqueue product
    local product_id = Queue:getNextProduct(self.id)
    self.product = botl.getGVProductBy(product_id, "id")
    Console:show(table.concat({ self.title, " - ", self.product.title }))
    --
    return true
end

-------------------------------------------------------------------------------
--- Select building by given location
---
---@return boolean|table @
-------------------------------------------------------------------------------
function M:getBuilding()
    local anchor = botl.getHolder(true, { offset = { 360, 107 } })

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

    self.building = building
    return true
end

-----------------------------------------------------------------------------
function M:collect()
    local timer = Timer()
    while not Sentinel:lostConnection(0) do
        click(self.building.obj)

        if Image:R(GV.REG.safe_area):exists("building/anchor.png", 1) then
            Console:show(table.concat({ "Open ", self.title }))
            -- save anchor location , avoid to look it again later
            self.building_anchor = Image:getData('target')
            return true
        end

        -- update last product produced stock
        if #self.line_production > 0 then
            local product = botl.getGVProductBy(self.line_production[1], "id")
            if product then
                product.stock = product.stock + 1
                self.line_production[1] = nil
            end
        end

        Console:show("Collect Products")

        if luall.is_timeout(timer:check(), 30) then
            Console:show("Timeout while collecting")
            break
        end
    end

    return false
end


-------------------------------------------------------------------------------
function M:produce()
    Console:show("Start production")

    if self.current_slide ~= self.product.slide then
        botl.switchSlides(self.product.slide)
        -- reset current slide
        self.current_slide = 1
    end

    -- Set Slots region
    -- calculate product location
    local product_location = Location(self.building_anchor.x + self.product.offset_x, self.building_anchor.y + self.product.offset_y)
    local slot = Location(self.building_anchor.x - 128, self.building_anchor.y + 152)
    local full_R = Region(self.building_anchor.x - 435, self.building_anchor.y, 635, 300)
    local timer = Timer()
    local first_production = true

    --self:productResources("reset", product.resources)

    while  not Sentinel:lostConnection(0) do
        -- avoid infinite loop
        if luall.is_timeout(timer:check(), 30) then
            Console:show("Production timeout")
            return false
        end

        -- move product to production
        swipe(product_location, slot)

        -- search "full" image
        if Image:R(full_R):exists("building/full.png", 1) then
            Console:show("No more slots")
            break
        end

        -- no more resources
        if not botl.isHomeScreen(0) and botl.btn_close("exists") then
            -- enqueue missing resources
            self:productResources("enqueue", self.product.resources)
            botl.btn_close("click", 0)
            break
        end

        -- check line production timeout is grater than product production timer
        -- update machine timeout
        if self.production_timer.timeout == 0 or
                (self.production_timer.timeout > 0 and self.product.produce_time < self.production_timer.timeout) then
            self.production_timer.timeout = self.product.produce_time
            self.production_timer:reset()
        end

        self:productResources("updateStock", self.product.resources)

        -- everything is fine
        -- update line production
        self.line_production[#self.line_production + 1] = self.product.id
        first_production = false
    end

    -- add some timeout if is the first production and no product is producing, this prevent
    -- the bot opening this machine repeatedly
    if first_production then
        self.production_timer.timeout = 60 * 3
        self.production_timer:reset()
    end

    return true
end

-------------------------------------------------------------------------------
function M:productResources(task, resources)
    if not resources then
        return false
    end
    task = task or "reset"

    for i = 1, #resources do
        local resource_id = resources[i][1]
        local require = resources[i][2]
        local resource = botl.getGVProductBy(resource_id, "id")
        --
        if task == "hasStock" then
            if resource.stock < require then
                return false
            elseif i == #resources then
                return true
            end
        elseif task == "updateStock" then
            resource.stock = resource.stock - require
            resource.stock = resource.stock > 0 and resource.stock or 0
            resource.reserved = resource.reserved - require
            resource.reserved = resource.reserved > 0 and resource.reserved or 0

        elseif task == "enqueue" then
            Console:show(table.concat({ "Enqueue ", require, " - ", resource.title }))

            --
            if Image:R(GV.REG.product_resources):exists("products/" .. resource_id .. ".png", 0) then
                resource.reserved = resource.reserved + require
                Queue:addProduct(resource_id)
            end
        end
    end

end

return M