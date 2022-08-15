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

-- Private
local slide_check = false

-------------------------------------------------------------------------------
--- Assign defaults values to class variables
---
---@return void
-------------------------------------------------------------------------------
function M:set()
    self.crops = luall.table_by_group(GV.PRODUCTS, "type", "crop")-- only crops table from products
    self.crop = Queue:getNextProduct("field")
    self.max_lanes = GV.CFG.layout.FIELD_TOTAL_L
    --self.MoveFields = Move:new(8, 10, GV.FIELD_SIZE, 25)
    self.Move = Move:new(
            GV.CFG.layout.FIELD_TOTAL_L,
            GV.CFG.layout.FIELD_TOTAL_B,
            GV.FIELD_SIZE,
            GV.CFG.general.FARM_FIELD_SPEED
    )
end

-------------------------------------------------------------------------------
--- Start farming script
---
---@return void
-------------------------------------------------------------------------------
function M:start()

    -- crop timeout
    if self:cropIsGrowing() then
        return false
    end

    -- get field location and field status
    local field, tool, tool_type = self:getField()

    -- move across the field
    if field then
        self.Move:start({ tool.obj, field.obj }, 'up_left', 'up_right')

        -- check silo capacity
        if self:siloFull() then
            return true
        end
    end
end

-------------------------------------------------------------------------------
function M:getFreeLanes(holder)
    local enqueued_crops = Queue:getData("field")
    local lane_occupied = 0

    -- get occupied lanes
    for i = 1, #enqueued_crops do
        lane_occupied = lane_occupied + Queue.data[i].space
    end

    local lane_size = self.max_lanes - lane_occupied

    if lane_size > 0 then

    end

    -- update available rows for next crop
    botl.getAnchorClickLocation(holder, 1, self.crop)
end

-------------------------------------------------------------------------------
--- check crop timeout
---
---@return boolean
-------------------------------------------------------------------------------
function M:cropIsGrowing()
    local crop = false
    local last_crop_check = 9999
    -- select crop whit less timeout
    for i = 1, #self.crops do
        if self.crops[i].timer then
            -- one crop is ready to harvest
            if self.crops[i].timer:isTimeout() then
                Console:show(self.crops[i].title .. ' - Ready ')
                -- crop ready to harvest, remove from queue
                Queue:removeProduct(self.crops[i].id)
                return true
            end

            -- get next crop ready (Not required)
            local crop_timer = self.crops[i].timer:getData()
            if crop_timer.time_left < last_crop_check then
                crop = self.crops[i]
            end

        end
    end

    --(Not required)
    if crop then
        Console:show(crop.title .. ' - ' .. crop.timer:timeLeft())
    end

    return crop
end

-------------------------------------------------------------------------------
--- search for holder image and calculates his offset to match field location
---
---@return table,table,number @returns field __{x,y,obj}__, tool __{x,y,obj}__ and tool type (1 = crop, 2 = scythe), returns false if no field found
-------------------------------------------------------------------------------
function M:getField()
    Console:show("Search Field")
    --
    --local holder = botl.getHolder(0, { 360, 98 })
    local holder = botl.getHolder(0, { 365, 103 })
    if not holder then
        Console:show("Holder not found")
        return false
    end
    -- get offset starting location
    local field = botl.getAnchorClickLocation(holder, 1, 1)
    if not field then
        Console:show("Field not found")
        return false
    end

    local tool, tool_type = self:getFieldStatus(field)

    if tool then
        return field, tool, tool_type
    end

    Console:show("Field status undefined")
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
    click(field.obj)
    wait(0.2)

    -- create small region to catch ongoing img
    local x, y, w, h = field.x + 70, field.y + 50, 230, 90
    local r = Region(x, y, w, h)
    if Image:R(r):exists(Pattern('ongoing.png'):similar(0.8), 1) then
        Console:show(self.crop.title .. ' growing')
        return false, 0
    end

    -- create small region to catch if field is to harvest or plant
    w, h = 400, 300
    x = field.x - w
    y = field.y - h
    r = Region(x, y, w + 100, h + 100)
    --
    if Image:R(r):exists(Pattern('btn/switch.png'):targetOffset(self.crop.offset_x, self.crop.offset_y), 1) then
        Console:show("Field is empty")
        -- save data target to avoid mix whit switchSlides images
        local btn_switch = Image:getData('target')

        -- set slide page for crop
        if not slide_check then
            slide_check = true
            botl.switchSlides(self.crop.slide)
        end

        self.crop.timer = OTimer:new(self.crop.produce_time)
        self.crop.timer:start()
        return btn_switch, 1
    end

    -- Ready to harvest
    if Image:R(r):exists(Pattern('farming/scythe.png'):mask():similar(0.8), 0) then
        Console:show("Crop ready")
        return Image:getData('center'), 2
    end

    return false, 0
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

        -- replant crop to not get 0 while selling
        local field, tool, tool_type = self:getField()

        if field then
            if tool_type == 1 then
                -- plant
                self.Move:start({ tool.obj, field.obj }, 'up_left', 'up_right')
            else
                self.crop.timer:stop()
            end
            return true
        end
    end
    return false
end

return M


