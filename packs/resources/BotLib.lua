local M = {}

local GV = require('GlobalVars')
local Image = require('ImageHelper')
local Color = require('ColorHelper')
local luall = require('LuaLib')
local Console = require('Console')
-- ----------------------------------
local Pattern = Pattern
local math_abs = math.abs
-- ----------------------------------
local holder_list = {
    Image:generateBulkList('holder/1/', 2),
    Image:generateBulkList('holder/2/', 1),
}

local btn_close_list = Image:generateBulkList('btn/close/', 2)

local function _zoom(pt1StartX, pt1StartY, pt1EndX, pt1EndY, pt2StartX, pt2StartY, pt2EndX, pt2EndY, delay, debug)
    if debug then
        local p_1_start = Region(pt1StartX - 7, pt1StartY - 7, 14, 14)
        local p_1_end = Region(pt1EndX - 7, pt1EndY - 7, 14, 14)
        local p_2_start = Region(pt2StartX - 7, pt2StartY - 7, 14, 14)
        local p_2_end = Region(pt2EndX - 7, pt2EndY - 7, 14, 14)
        wait(0.1)

        setHighlightTextStyle(0xFF000000, 0xFFFFFFFF, 10) -- blue
        wait(0.1)
        p_1_start:highlight('1')
        p_1_end:highlight('1')
        p_2_start:highlight('2')
        p_2_end:highlight('2')
        wait(debug)
        p_1_start:highlightOff()
        p_1_end:highlightOff()
        p_2_start:highlightOff()
        p_2_end:highlightOff()
    end
    zoom(pt1StartX, pt1StartY, pt1EndX, pt1EndY, pt2StartX, pt2StartY, pt2EndX, pt2EndY, delay)

end
-- ----------------------------------
-- isHomeScreen
-- ----------------------------------
function M.isHomeScreen(t)
    t = t or 0
    return Color:exists(GV.OBJ.btn_register, 0)
end

-- ----------------------------------
-- Btn Close
-- ----------------------------------
function M.btn_close(action, t, r)
    action = action or "click"
    t = t or 0
    r = r or GV.REG.btn_close
    if Image:R(r):bulkSearch(btn_close_list, t, 0.8) then
        if action == "click" then
            click(Image:getData('target', 'obj'))
        end
        return Image:getData()
    end

    return false
end
-- ----------------------------------
-- getHotSpot
-- ----------------------------------
--function M.getHotSpot(t, to)
--    t = t or 1
--    to = to or { 0, 0 }
--
--    if Image:R(GV.REG.align):bulkSearch(holder_list, t, 0.75, to) then
--        return Image:getData()
--    end
--end

-------------------------------------------------------------------------------
function M.getAnchor(t, to, list, r)
    t = t or 1
    to = to or { 0, 0 }
    list = list or 1
    r = r or GV.REG.align
    if Image:R(r):bulkSearch(holder_list[list], t, 0.75, to) then
        local anchor = Image:getData('target')
        local screen = Region(0, 0, GV.SETTINGS.WIDTH, GV.SETTINGS.HEIGHT)
        if luall.location_in_region(anchor.obj, screen) then
            return anchor
        end
    end
    return false
end

-------------------------------------------------------------------------------
function M.getAnchorClickLocation(anchor, line_1, line_2, corner)
    line_1 = line_1 or 0
    line_2 = line_2 or 0
    line_1 = line_1 > 0 and line_1 - 1 or line_1
    line_2 = line_2 > 0 and line_2 - 1 or line_2
    corner = corner or "B" --> T- top , L-left , R-right , B - bottom
    --
    local corner_y = { "T", "B" }
    local corner_x = { "L", "R" }
    local x, y = 0, 0
    --
    if luall.in_table(corner_y, corner) > 0 then
        x = math_abs(line_1 - line_2) * GV.FIELD_SIZE
        y = math_abs(line_1 + line_2) * (GV.FIELD_SIZE / 2)
        x = line_1 > line_2 and -x or x
        y = corner == "T" and y or -y
    elseif luall.in_table(corner_x, corner) > 0 then
        x = math_abs(line_1 + line_2) * GV.FIELD_SIZE
        y = math_abs(line_1 - line_2) * (GV.FIELD_SIZE / 2)

        x = corner == "L" and x or -x
        y = line_1 > line_2 and -y or y
    end

    local field = {
        x = anchor.x + x,
        y = anchor.y + y,
        obj = Location(anchor.x + x, anchor.y + y)
    }

    local screen = Region(0, 0, GV.SETTINGS.WIDTH, GV.SETTINGS.HEIGHT)

    if luall.location_in_region(field.obj)
    then
        return field
    end
    return false
end

--[[
function M.getAnchorClickLocation(anchor, start_left, start_bottom, corner)
    start_left = start_left or 0
    start_bottom = start_bottom or 0
    start_left = start_left - 1
    start_bottom = start_bottom - 1
    corner = corner or "bottom"
    --local x = math_abs(start_left - start_bottom) * GV.FIELD_SIZE
    --local y = math_abs((start_left + start_bottom) - 1)
    --y = -((y <= 1 and 0 or y) * (GV.FIELD_SIZE / 2))
    local x = math_abs(start_left - start_bottom) * GV.FIELD_SIZE
    local y = -(math_abs(start_left + start_bottom) * (GV.FIELD_SIZE / 2))

    --  change direction to left(-) or right(+)
    x = start_left > start_bottom and -x or x
    local field = {
        x = anchor.x + x,
        y = anchor.y + y,
        obj = Location(anchor.x + x, anchor.y + y)
    }

    local screen = Region(0, 0, GV.SETTINGS.WIDTH, GV.SETTINGS.HEIGHT)

    if luall.location_in_region(field.obj)
    then
        return field
    end
    return false
end]]

-- ----------------------------------
-- clearScreen
-- ----------------------------------
function M.clearScreen(t)
    local timer = Timer()
    local result = false
    t = t or 0

    luall.btn_back()
    while true do
        Console:show('check Screen')
        snapshotColor()
        if M.isHomeScreen(0) then
            result = true
            break
        elseif Color:existsClick(GV.OBJ.btn_home, 0) or Color:existsClick(GV.OBJ.btn_home_dark, 0) then
            t = t + 5
            Console:show('Return to farm Screen')
        elseif luall.is_timeout(timer:check(), t) then
            break
        else
            luall.btn_back()
            t = t + 1
        end
    end

    usePreviousSnap(false)
    return result
end

-- switchSlides
-- ----------------------------------
function M.switchSlides(slide, timeout)
    timeout = timeout or 0
    slide = slide or 1
    -- 24 pixel between each slide point
    local slide_offset = 24 * (slide - 1)

    if Image:exists(Pattern('btn/switch.png'):targetOffset(60, -5), timeout) then
        local img = Image:getData()
        GV.OBJ.slides.center = Location(img.target.x + slide_offset, img.target.y)
        while not Color:exists(GV.OBJ.slides, 0) do
            click(img.center.obj)
            wait(0.3)
        end
        return img
    end
    return false
end

-- Zoom Out
-- ----------------------------------
function M.zoomOut()
    Console:show('zoom out')
    -- LOG
    local pt1StartX = GV.SCREEN.w * 0.85
    local pt1StartY = GV.SCREEN.h * 0.65
    --
    local pt1EndX = GV.SCREEN.w * 0.75
    local pt1EndY = GV.SCREEN.h * 0.75
    --
    local pt2StartX = GV.SCREEN.w * 0.60
    local pt2StartY = GV.SCREEN.h * 0.90
    --
    local pt2EndX = GV.SCREEN.w * 0.70
    local pt2EndY = GV.SCREEN.h * 0.80
    --

    _zoom(pt1StartX, pt1StartY, pt1EndX, pt1EndY, pt2StartX, pt2StartY, pt2EndX, pt2EndY, 500, false)
end

function M.align(timeout)
    timeout = timeout or 60
    local timer = Timer()
    --
    Console:show('Align')
    --
    while not M.getHotSpot() do
        local s_l_1 = Location(171, 144)
        local s_l_2 = Location(9999, 9999)
        local SS = Region(1050, 504, 151, 215)
        local v = luall.get_values(SS)
        local SS_R = Region(v.x - 100, v.y - 100, v.w + 200, v.h + 200)
        --debug_r(SS_R)
        setImagePath(GV.SETTINGS.DIR_TEMP)
        --
        while true do
            swipe(s_l_1, s_l_2)
            SS:save('_align.png')
            --click(GV._LOC.safe_click)
            M.zoomOut()
            --click(GV._LOC.safe_click)
            -- M.zoomOut()
            click(GV.LOC.safe_click)
            swipe(s_l_1, s_l_2)
            click(GV.LOC.safe_click)
            if not M.isHomeScreen() then
                M.clearScreen()
            end
            if Image:R(SS_R):exists(Pattern('_align.png'):similar(0.8), 0) then
                break
            end
        end
        setImagePath(GV.SETTINGS.DIR_IMAGES)
        --
        dragDrop(Location(210, 490), Location(210, 190))
        --
        if luall.is_timeout(timer:check(), timeout) then
            return false
        end
    end

    --
end

return M