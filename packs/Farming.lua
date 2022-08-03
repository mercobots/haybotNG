-------------------------------------------------------------------------------
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
local M = {}

-------------------------------------------------------------------------------
local anchor_offset = { 270, 80 }
local slide_check = false

-------------------------------------------------------------------------------
function M:set()
    self.crop = GV.PRODUCTS[1]
    self.crop_growing = OTimer:new(self.crop.produce_time)
    self.MoveFields = Move:new(8, 10, GV.FIELD_SIZE, 25)

end

-------------------------------------------------------------------------------
function M:start()

    if self.crop_growing:isRunning() then
        Console:show(self.crop.title .. ' - ' .. self.crop_growing:timeLeft())
        return true
    end

    local field, tool, tool_type = self:getField()

    if field then

        self.MoveFields:start({ tool.obj, field.obj }, 'up_left', 'up_right')

        if self:siloFull() then
            return true
        end
    end
end

-------------------------------------------------------------------------------
--[[
function M:getAnchor()
    if Image:R(GV.REG.align):bulkSearch(holder_list, 0, 0.75, anchor_offset) then
        local anchor = Image:getData('target')
        local screen = Region(0, 0, GV.SETTINGS.WIDTH, GV.SETTINGS.HEIGHT)
        if luall.location_in_region(anchor.obj, screen) then
            return anchor
        end
    end
    return false
end
]]

-------------------------------------------------------------------------------
function M:getField()
    --
    local anchor = botl.getAnchor(0, anchor_offset)

    if not anchor then
        scriptExit("Anchor not found")
    end
    --
    local field = botl.getAnchorClickLocation(anchor, 1, 1)
    if not field then
        scriptExit("field not found")
    end

    local tool, tool_type = self:getFieldStatus(field)

    if tool then
        return field, tool, tool_type
    end

    return false
end


-------------------------------------------------------------------------------
function M:getFieldStatus(field)

    -- set small region across field location
    --
    click(field.obj)

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
        -- save data target to avoid to mix whit switchSlides images
        local btn_switch = Image:getData('target')
        --
        if not slide_check then
            slide_check = true
            botl.switchSlides(self.crop.slide)
        end

        self.crop_growing:reset()
        return btn_switch, 1
    end
    --
    if Image:R(r):exists(Pattern('farming/scythe.png'):mask():similar(0.8), 0) then
        return Image:getData('center'), 2
    end

    return false, 0
end

-------------------------------------------------------------------------------
function M:siloFull()
    if not botl.isHomeScreen(0) and Color:exists(GV.OBJ.farming_silo_full, 3) then
        Console:show('Silo is full')
        luall.btn_back()

        -- replant crop to not get 0 while selling
        local field, tool, tool_type = self:getField()

        if field then
            if tool_type == 1 then
                -- plant
                self.MoveFields:start({ tool.obj, field.obj }, 'up_left', 'up_right')
            else
                self.crop_growing:stop()
            end
            return true
        end
    end
    return false
end




-------------------------------------------------------------------------------
--[[
function M:getFieldLocation(anchor)
    Console:show('Get Field')
    local pos_x = math.abs(self.config.start_left - self.config.start_bottom) * _field_size
    local pos_y = -math.abs((self.config.start_left + self.config.start_bottom) - 1) * (_field_size / 2)
    --  change direction to left or rigth
    pos_x = self.config.start_left > self.config.start_bottom and -pos_x or pos_x

    -- set new targetOffset
    holder.match:setTargetOffset(_holder_offset.x + pos_x, _holder_offset.y + pos_y)

    -- update holder data
    Image:updateData(holder)

    return Image:getData('target')
end
]]

return M


