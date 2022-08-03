local Image = require('ImageHelper')
local Color = require('ColorHelper')
local luall = require('LuaLib')
local botl = require('BotLib')
local GV = require('GlobalVars')
local Console = require('Console')
local Queue = require("Queue")
local OTimer = require('OTimer')
local Move = require('Move')

-------------------------------------------------------------------------------
local M = {}
M.__index = M

-------------------------------------------------------------------------------
local anchor_offset = { 25, -5 }

-------------------------------------------------------------------------------
function M:new(id, title, left, bottom, direction, switch_direction, layout)
    local _self = {}
    _self.id = id or "_no_animal_"
    _self.title = title or "Animal"
    _self.left = left or 1
    _self.bottom = bottom or 1
    _self.direction = direction or "up_right"
    _self.switch_direction = switch_direction or "down_right"
    layout = layout or "up_right"
    -- chicken and goat fence is smaller
    local grid = (id == "chicken" or id == "goat") and 3 or 4
    --
    local rows = grid
    local cols = grid * 3

    _self.Move = Move:new(rows * 2, cols * 2, GV.FIELD_SIZE / 2, 30)
    setmetatable(_self, M)

    return _self
end

-------------------------------------------------------------------------------
function M:start()
    local building = self:getBuilding()
    if building then
        for i = 1, 2 do
            local target, status = self:getStatus(building)
            if not target then
                return false
            end

            -- building spot adjust to cover the fences
            self.Move:start({ target, Location(building.x - 10, building.y - 10) }, self.direction, self.switch_direction)
            -- animals are fed
            if status == 1 then
                return true
            end
        end
    end
    return false
end

-------------------------------------------------------------------------------
function M:getBuilding()
    Console:show(table.concat({ "Open", self.title }))
    local anchor = botl.getAnchor(0, { 30, -5 }, 2, GV.SCREEN.left)

    if not anchor then
        scriptExit("Anchor not found")
    end
    --
    local building = botl.getAnchorClickLocation(anchor, self.left, self.bottom, "L")
    if not building then
        scriptExit("field not found")
    end

    return building
end

-------------------------------------------------------------------------------
function M:getStatus(building)

    -- set small region across field location
    --
    click(building.obj)
    wait(0.2)
    -- create small region to catch holder
    local x, y, w, h = building.x - 250, building.y - 320, 400, 320
    local r = Region(x, y, w, h)

    -- click is good ?
    if not Image:R(r):exists(Pattern("animal/holder.png"):similar(0.8), 1) then
        Console:show(self.title .. "can't find animal anchor")
        return false, -1
    end

    --
    local anchor = Image:getData("target")
    -- Ready to collect ?
    local product_arrow = GV.OBJ.product_arrow
    -- 2 tries cuz  orange arrow for some animals is more down
    for try = 1, 2 do
        product_arrow.center = try == 1 and Location(anchor.x + 82, anchor.y - 70) or Location(anchor.x + 82, anchor.y - 63)
        if Color:exists(product_arrow) then
            return product_arrow.center, 2
        end
    end

    -- Has feed ?
    x, y, w, h = anchor.x + 45, anchor.y - 220, 75, 55
    r = Region(x, y, w, h)

    if not Image:R(r):exists(Pattern("animal/no_feed.png"):similar(0.8), 0) then
        return Location(anchor.x + 125, anchor.y - 170), 1
    end

    -- TODO: insert in queue

    return false, 0
end
return M