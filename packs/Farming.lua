-------------------------------------------------------------------------------
---@class Farming
-------------------------------------------------------------------------------
local M = {}

-- Dependencies
local Console = require('Console')
local Image = require('ImageHelper')
local Color = require('ColorHelper')
local botl = require('BotLib')
local luall = require('LuaLib')
local GV = require("GlobalVars")
local OTimer = require('OTimer')
local Move = require('Move')
local Queue = require("Queue")
local Sentinel = require("Sentinel")
-------------------------------------------------------------------------------
--- Assign defaults values to class variables
---
---@return void
-------------------------------------------------------------------------------
function M:set()
    self.crops = luall.table_by_group(GV.PRODUCTS, "type", "crop")-- only crops table from products
    self.crop = false
    self.max_lanes = GV.CFG.layout.FIELD_TOTAL_B
    self.current_slide = 1
    self.allowed_lanes = {}
    self.first_lane = 0
    self.last_lane = 0
    self.field = nil
    self.tool = {}
    --self.MoveFields = Move:new(8, 10, GV.FIELD_SIZE, 25)
    self.Move = Move:new(
            GV.CFG.layout.FIELD_TOTAL_B,
            GV.CFG.layout.FIELD_TOTAL_L,
            GV.FIELD_SIZE - 2,
            GV.CFG.general.FARM_FIELD_SPEED
    )
end

-------------------------------------------------------------------------------
--- Start farming script
---
---@return void
-------------------------------------------------------------------------------
function M:start()
    local timer = Timer()
    while not Sentinel:lostConnection(0) do
        --
        if not self:getNextCrop() or not self:getFreeLanes() then
            return false
        end

        for _ = 1, 2 do

            -- get field location
            if not self:getField() then
                return false
            end

            -- get field status
            if not self:getFieldStatus() then
                return false
            end

            --
            if self.tool.plant then
                -- register occupied lanes
                self.crop.lanes = luall.clone_table(self.allowed_lanes)

                -- start timer crop
                self.crop.timer = OTimer:new(self.crop.produce_time)
                self.crop.timer:start()

                -- change move range
                self.Move.rows = (self.last_lane - self.first_lane) + 1
                --print(self.Move.rows, "Plant rows")

                -- move across the field
                self.Move:start({ self.tool.obj, self.field.obj }, 'up_left', 'up_right')
                Queue:removeProduct(self.crop.id)
                self:quickClearScreen()

                break
            end

            -- harvest
            if self.tool.harvest then

                -- change move range
                self.Move.rows = (self.last_lane - self.first_lane) + 1
                --print(self.Move.rows, "Harvest rows")

                -- move across the field
                self.Move:start({ self.tool.obj, self.field.obj }, 'up_left', 'up_right')

                -- reset harvest crops by timer/timeout
                self:resetCrops()

                -- check silo capacity
                if self:siloFull() then
                    break
                end

            end

        end

        -- avoid infinite loop
        if luall.is_timeout(timer:check(), 60) then
            Console:show("Farming DEBUG")
            return false
        end
    end
end

-------------------------------------------------------------------------------
function M:getNextCrop()
    local crop_id = Queue:getNextProduct("field")
    if not crop_id then
        Console:show("No crops to plant")
        return false
    end
    self.crop = botl.getGVProductBy(crop_id, "id")
    return true
end

-------------------------------------------------------------------------------
function M:quickClearScreen()
    -- get boat holder and click in the water
    local boat_holder = botl.getHolder(false, {
        offset = { -200, 20 },
        reg = GV.SCREEN.top,
        similar = 0.8,
        list = 3
    })

    if boat_holder then
        click(boat_holder.target.obj)
    else
        -- if can't find the boat then open a random form to clear the screen
        botl.openRandomForm()
    end
end

-------------------------------------------------------------------------------
--- search for holder image and calculates his offset to match field location
---
---@return table,table,number @returns field __{x,y,obj}__, tool __{x,y,obj}__ and tool type (1 = crop, 2 = scythe), returns false if no field found
-------------------------------------------------------------------------------
function M:getField()
    self.field = nil
    local offset = { 360, 107 }
    local holder_timeout = 0
    --local offset = { 365, 103 }

    -- 2x cuz sometimes the screens move and the target is not correct
    for try = 1, 2 do

        -- search for holder "cone image"
        local holder = botl.getHolder(true, { timeout = holder_timeout, offset = offset })
        if not holder then
            Console:show("Holder not found")
            return false
        end

        -- get offset starting location
        local field = botl.getAnchorClickLocation(holder, GV.CFG.layout.FIELD_START_L, self.first_lane + (GV.CFG.layout.FIELD_START_B - 1))
        if not field then
            Console:show("Field not found")
            return false
        end

        -- click field
        click(field.obj)
        wait(0.5)

        -- if holder is hidden
        local holder_confirmation = botl.getHolder(false)
        if not holder_confirmation then
            --
            self:quickClearScreen()

            -- screen is clear , then update holder position
            holder_confirmation = botl.getHolder(false)
        end

        if luall.location_equal(holder.center.obj, holder_confirmation.center.obj, 5) then
            self.field = field
            return true
        end

        -- fatal error
        if try == 2 then
            Console:show("Can't calibrate click field")
            break
        end

        wait(1.5)
    end
    return false
end

-------------------------------------------------------------------------------
--- Check if crops are growing, if is empty or crops are ready to harvest
---
---@return table,table,number @returns field __{x,y,obj}__, tool __{x,y,obj}__ and tool type (1 = crop, 2 = scythe), returns false if no field found
-------------------------------------------------------------------------------
function M:getFieldStatus()

    Console:show("Click Field")

    -- create small region to for ongoing img
    local x, y, w, h = self.field.x, self.field.y - 100, 300, 300
    local r = Region(x, y, w, h)

    if Image:R(r):exists(Pattern('ongoing.png'):similar(0.8), 1) then
        Console:show(self.crop.title .. ' growing')
        return false
    end

    -- create small region to for crop and scythe
    w, h = 400, 300
    x = self.field.x - w
    y = self.field.y - h
    r = Region(x, y, w + 100, h + 100)
    --
    if Image:R(r):exists(Pattern('farming/holder.png'), 1) then
        Console:show("Field is empty")

        -- set slide page for crop
        if self.current_slide ~= self.crop.slide then

            botl.switchSlides(self.crop.slide)
            self.current_slide = self.crop.slide
        end
        local result = {
            x = self.field.x + self.crop.offset_x,
            y = self.field.y + self.crop.offset_y,
            obj = Location(self.field.x + self.crop.offset_x, self.field.y + self.crop.offset_y),
        }
        debug_r(result.obj)

        self.tool = { plant = result, obj = result.obj }
        return true
    end


    -- Ready to harvest
    if Image:R(r):exists(Pattern('farming/scythe.png'):mask():similar(0.8), 0) then
        Console:show("Crop ready")
        local result = Image:getData('center')
        self.tool = { harvest = result, obj = result.obj }
        return true
    end

    return false
end

-------------------------------------------------------------------------------
--- Check if silo is full or not
---
---@return boolean
-------------------------------------------------------------------------------
function M:siloFull()
    if not botl.isHomeScreen(0) and Color:exists(GV.OBJ.farming_silo_full, 3) then
        Console:show('Silo is full')
        botl.btn_close("click", 0)

        --[[-- replant crop to not get 0 while selling
        local field, tool, tool_type = self:getField()

        if field then
            if tool_type == 1 then
                -- plant
                self.Move:start({ tool.obj, field.obj }, 'up_left', 'up_right')
            else
                self.crop.timer:stop()
            end
            return true
        end]]
        return true
    end
    return false
end

---##############################################################################
--- Data Lanes Related
---##############################################################################
-------------------------------------------------------------------------------
function M:getFreeLanes()
    -- check for free lanes
    self:getAllowedLanes()
    --
    if #self.allowed_lanes < 1 then
        Console:show("No lanes available")
        return false
    end
    return true
end

-------------------------------------------------------------------------------
--- Check if crops are ready to harvest and if yes, then remove they lanes.
---
---@return void
-------------------------------------------------------------------------------
function M:resetCrops()
    for i = 1, #self.crops do
        -- if there are registered lanes , that means timer is assigned! so if timeout
        -- theses crops are ready to harvest and the field will be free
        if self.crops[i].timer and self.crops[i].timer:isTimeout() then
            local stock = (#self.crops[i].lanes * GV.CFG.layout.FIELD_TOTAL_L) * 2
            self.crops[i].timer = false
            self.crops[i].lanes = {}
            self.crops[i].stock = stock
        end
    end
end

-------------------------------------------------------------------------------
--- Check if crops are ready to harvest and if yes, then remove they lanes.
---
---@return table,table,table @lanes free/occupied {boolean}, free lanes{numbers}, occupied_lanes{numbers}
-------------------------------------------------------------------------------
function M:getLanesStatus()
    --Console:show("Get lane status")
    local lanes = {}
    local occupied_lanes = {}
    local free_lanes = {}

    -- since enqueued crops are deleted only after harvest, they remain as data
    -- so for each enqueued crop get the lanes they are occupying , if any
    for i = 1, #self.crops do

        -- if there are registered lanes , that means timer is assigned!
        if self.crops[i].lanes and #self.crops[i].lanes > 0 and self.crops[i].timer:isRunning() then
            occupied_lanes = luall.table_merge(occupied_lanes, self.crops[i].lanes)
        end
    end

    -- creates range list of on/off lanes
    for i = 1, self.max_lanes do
        if luall.in_table(occupied_lanes, i) < 1 then
            free_lanes[#free_lanes + 1] = i
        end
        lanes[i] = luall.in_table(occupied_lanes, i) < 1
    end
    return lanes, free_lanes, occupied_lanes
end

-------------------------------------------------------------------------------
--- Calculates allowed lanes to use for current crop, free lanes against crops in queue
---
---@return table,number,number @lanes allowed_lanes {numbers}, first lane, last lane
-------------------------------------------------------------------------------
function M:getAllowedLanes()
    local lanes, free_lanes, occupied_lanes = self:getLanesStatus()
    -- print({lanes, free_lanes, occupied_lanes})
    if #free_lanes < 0 then
        return false
    end

    local max_lanes = math.ceil(#free_lanes / #Queue:getData("field"))
    local allowed_lanes = {}

    -- get the last lane available from free lanes, in case required lanes is greater than free lanes
    for i = 1, max_lanes do
        if not free_lanes[i] then
            break
        end
        allowed_lanes[#allowed_lanes + 1] = free_lanes[i]
    end
    -- print({allowed_lanes, allowed_lanes[1], allowed_lanes[#allowed_lanes]})
    self.allowed_lanes = allowed_lanes
    self.first_lane = allowed_lanes[1]
    self.last_lane = allowed_lanes[#allowed_lanes]
    return true
end

return M


