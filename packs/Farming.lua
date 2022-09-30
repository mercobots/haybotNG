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
    while true do

        local crop_id = Queue:getNextProduct("field")
        if not crop_id then
            Console:show("No crops to plant")
            return false
        end

        -- get next crops in queue
        self.crop = botl.getGVProductBy(crop_id, "id")

        botl.align()

        -- check for free lanes
        local allowed_lanes, start_lane, end_lane = self:getAllowedLanes()
        if #allowed_lanes < 1 then
            Console:show("No lanes available")
            return false
        end

        for _ = 1, 2 do

            -- get field location
            local field = self:getField(start_lane)
            if not field then
                return false
            end

            -- get field status
            -- tool type -1  = error, 0 = growing, 1 = crop, 2 = scythe
            local tool, tool_type = self:getFieldStatus(field)
            if not tool then
                return false
            end


            -- Plant
            if tool_type == 1 then
                -- register occupied lanes
                self.crop.lanes = allowed_lanes

                -- start timer crop
                self.crop.timer = OTimer:new(self.crop.produce_time)
                self.crop.timer:start()

                -- change move range
                self.Move.rows = (end_lane - start_lane) + 1
                --print(self.Move.rows, "Plant rows")

                -- move across the field
                self.Move:start({ tool.obj, field.obj }, 'up_left', 'up_right')
                Queue:removeProduct(self.crop.id)
                break
            end

            -- harvest
            if tool_type == 2 then
                -- change move range
                self.Move.rows = (self.max_lanes - start_lane) + 1
                --print(self.Move.rows, "Harvest rows")

                -- move across the field
                self.Move:start({ tool.obj, field.obj }, 'up_left', 'up_right')

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
    Console:show("Get lane status")
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
    return allowed_lanes, allowed_lanes[1], allowed_lanes[#allowed_lanes]
end

-------------------------------------------------------------------------------
--- search for holder image and calculates his offset to match field location
---
---@return table,table,number @returns field __{x,y,obj}__, tool __{x,y,obj}__ and tool type (1 = crop, 2 = scythe), returns false if no field found
-------------------------------------------------------------------------------
function M:getField(start_lane)
    Console:show("Search Field")
    local offset = { 360, 107 }
    local holder_timeout = 0
    --local offset = { 365, 103 }

    -- 2x cuz sometimes the screens move and the target is not correct
    for try = 1, 2 do

        -- search for holder "cone image"
        local holder = botl.getHolder(holder_timeout, offset)
        if not holder then
            Console:show("Holder not found")
            return false
        end

        -- get offset starting location
        local field = botl.getAnchorClickLocation(holder, GV.CFG.layout.FIELD_START_L, start_lane + (GV.CFG.layout.FIELD_START_B - 1))
        if not field then
            Console:show("Field not found")
            return false
        end

        -- click filed
        click(field.obj)
        wait(0.5)

        local click_confirm = botl.getHolder(0, offset)

        -- in case crop list is above holder image
        if not click_confirm then

            -- clean screen
            botl.openRandomForm()
            wait(0.5)

            -- 2º try
            click_confirm = botl.getHolder(0, offset)
            if not click_confirm then
                Console:show("Holder confirm not found")
                return false
            end

            -- click filed
            click(field.obj)
            wait(0.5)
        end

        -- creates a region from 1º holder match 10x10 and check if new click is in the region
        if luall.location_equal(holder.center.obj, click_confirm.center.obj, 5) then
            return field
        end

        if try == 2 then
            Console:show("Can't calibrate click field")
            return false
        end

        botl.openRandomForm()


        --holder_timeout = 1


    end
    return false
end

-------------------------------------------------------------------------------
--- Check if crops are growing, if is empty or crops are ready to harvest
---
---@param field table @{x,y,obj}
---@return table,table,number @returns field __{x,y,obj}__, tool __{x,y,obj}__ and tool type (1 = crop, 2 = scythe), returns false if no field found
-------------------------------------------------------------------------------
function M:getFieldStatus(field)

    Console:show("Click Field")
    --

    -- create small region to for ongoing img
    local x, y, w, h = field.x + 70, field.y + 50, 230, 90
    local r = Region(x, y, w, h)
    if Image:R(r):exists(Pattern('ongoing.png'):similar(0.8), 1) then
        Console:show(self.crop.title .. ' growing')
        return false, 0
    end

    -- create small region to for crop and scythe
    w, h = 400, 300
    x = field.x - w
    y = field.y - h
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
            x = field.x + self.crop.offset_x,
            y = field.y + self.crop.offset_y,
            obj = Location(field.x + self.crop.offset_x, field.y + self.crop.offset_y),
        }
        debug_r(result.obj)

        return result, 1
    end


    -- Ready to harvest
    if Image:R(r):exists(Pattern('farming/scythe.png'):mask():similar(0.8), 0) then
        Console:show("Crop ready")
        return Image:getData('center'), 2
    end

    return false, -1
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

return M


