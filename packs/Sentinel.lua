local Image = require('ImageHelper')
local Color = require('ColorHelper')
local luall = require('LuaLib')
local botl = require('BotLib')
local GV = require('GlobalVars')
local Console = require('Console')
local Queue = require("Queue")
local OTimer = require('OTimer')
local Move = require('Move')

local M = {
    network_attempts = 0
}

-------------------------------------------------------------------------------
function M:networkReset(timeout, align_spot)
    timeout = timeout or 0
    if Image:R(GV.REG.safe_area):exists("network/reset.png", timeout) then
        botl.align(false, align_spot)
        return true
    end
    return false
end

-------------------------------------------------------------------------------
function M:networkDown(timeout, align_spot)
    if not GV.CFG.general.NETWORK_DOWN then
        return false
    end
    --
    timeout = timeout or 0
    --
    while true do
        if self.network_attempts >= GV.CFG.general.NETWORK_DOWN_ATTEMPTS then
            return false
        end
        --
        if not Image:R(GV.REG.safe_area):exists("network/down.png", timeout) then
            return false
        end
        --
        Console:show("Connection Down")
        if not Image:R(GV.REG.safe_area):existsClick("btn/try_again.png") then
            return false
        end
        --
        self.network_attempts = self.network_attempts + 1

        -- anchor
        if botl.isHomeScreen(60) then
            botl.align(false, align_spot)
            self.network_attempts = 0
            return true
        end
        local clock = luall.get_clock(GV.CFG.general.NETWORK_DOWN_ATTEMPTS_DELAY)
        Console:show(table.concat({  self.network_attempts + 1,"º Attempt in ", clock }))
        wait(GV.CFG.general.NETWORK_DOWN_ATTEMPTS_DELAY)
    end
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
    self:networkDown()
    self:networkReset()
    self:screenIsClean()
    botl.align()
end

return M