local Image = require('ImageHelper')
local Color = require('ColorHelper')
local luall = require('LuaLib')
local botl = require('BotLib')
local GV = require('GlobalVars')
local Console = require('Console')
local Queue = require("Queue")
local OTimer = require('OTimer')
local Move = require('Move')

local M = {}

-------------------------------------------------------------------------------
function M:networkReset(timeout, align_spot)
    timeout = timeout or 0
    if  Image:R(GV.REG.safe_area):exists("network/reset.png", timeout) then
        botl.align(false, align_spot)
        return true
    end
    return false
end

-------------------------------------------------------------------------------
function M:screenIsClean(timeout)
    timeout = timeout or 0
    if botl.isHomeScreen(timeout) then
        return true
    end
    botl.clearScreen(timeout)
    botl.align(timeout)
    return false
end

-------------------------------------------------------------------------------
function M:checkAll()
    self:networkReset()
    self:screenIsClean()
    botl.align()
end

return M