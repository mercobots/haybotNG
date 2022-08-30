local Form = require("Form")
local GV = require("GlobalVars")
local Memory = require("Memory")
local LuaL = require("LuaLib")

local M = {}

local crop, move_direction, move_speed, price
--
do
    crop = { 'Wheat', 'Corn', 'Carrot', 'Soybean', 'Sugarcane', }
    move_direction = { 'Up Left', }
    price = { 'None', 'Max', 'Default', 'Min' }
    move_speed = {}
    for i = 1, 50 do
        move_speed[i] = table.concat({ "X ", i })
    end
    move_speed = LuaL.table_reverse(move_speed)
end
--
function M:start()
    --
    self:updateGVValues()
    --
    while true do
        local form = Form:new(table.concat({ GV.SETTINGS.BRAND, " - ", GV.SETTINGS.BOT_VERSION, " - ", GV.SETTINGS.BOT_NAME, }))
        form:addForm {
            ele = {
                { type = 'radio', id = 'OP_MENU', label = '', value = 1, options = {
                    "Start",
                    "Layout Settings",
                    "General Settings",
                    "Products Settings",
                    "Animals Settings"
                }, },

            }
        }
        form:show()
        local op = form:getDataId('OP_MENU')

        if op == 1 then
            break
        elseif op == 2 then
            self:layoutSettings()
        elseif op == 3 then
            self:generalSettings()
        elseif op == 4 then
            self:productsSettings()
        elseif op == 5 then

        end
    end
end
-------------------------------------------------------------------------------
function M:updateGVValues()
    GV.CFG ={
        general = Memory:load("config_general"),
        layout = Memory:load("config_layout"),
        products = Memory:load("config_products"),
    }
end

-------------------------------------------------------------------------------
function M:generalSettings()
    --
    local form = Form:new("General Settings")
    form:addForm {
        ele = {
            { type = 'text', label = '\n# System #' },
            { type = 'checkbox', id = 'DEBUG_MODE', label = '\tDebug', value = false },
            --
            { type = 'text', label = '\n# Farm #' },
            { type = 'input_number', id = 'RSS_SLOTS', label = '\tRSS Slots', value = 10 },
            { type = 'selectbox_index', id = 'FARM_FIELD_SPEED', label = '\tPlant/Harvest\tspeed', value = 25, options = move_speed, new_row = false },
            { type = 'selectbox_index', id = 'FARM_FIELD_DIRECTION', label = '\tDirection', value = 1, options = move_direction, new_row = false },
        }
    }
    local data = Memory:load("config_general")
    form:loadData(data, true)
    form:show()
    Memory:save("config_general", form:getMinifiedData())
    self:updateGVValues()
end
-------------------------------------------------------------------------------
function M:productsSettings()
    --
    Memory:load("config_products")
    local form = Form:new("Products Settings")
    form:addForm {
        ele = {
            { type = 'text', label = '\n# Crops #' },
            { type = 'checkbox', id = 'PRO_WHEAT_ACTIVE', label = '\tWheat', value = false, new_row = false },
            { type = 'selectbox_index', id = 'PRO_WHEAT_PRICE', label = '\tSell', value = 1, options = price, new_row = false },
            { type = 'input_number', id = 'PRO_WHEAT_KEEP', label = '\tKeep\t', value = 10 },
            --
            { type = 'checkbox', id = 'PRO_CORN_ACTIVE', label = '\tCorn', value = false, new_row = false },
            { type = 'selectbox_index', id = 'PRO_CORN_PRICE', label = '\tSell', value = 1, options = price, new_row = false },
            { type = 'input_number', id = 'PRO_CORN_KEEP', label = '\tKeep\t', value = 10 },
            --
            { type = 'checkbox', id = 'PRO_CARROT_ACTIVE', label = '\tCarrot', value = false, new_row = false },
            { type = 'selectbox_index', id = 'PRO_CARROT_PRICE', label = '\tSell', value = 1, options = price, new_row = false },
            { type = 'input_number', id = 'PRO_CARROT_KEEP', label = '\tKeep\t', value = 10 },
            --
            --{ type = 'checkbox', id = '#', label = '\tCorn', value = false, new_row = false },
            --{ type = 'selectbox_index', id = '#', label = '\tSell', value = 1, options = price, new_row = false },
            --{ type = 'input_number', id = '#', label = '\tKeep\t', value = 10 },
            ----
            --{ type = 'checkbox', id = '#', label = '\tCarrot', value = false, new_row = false },
            --{ type = 'selectbox_index', id = '#', label = '\tSell', value = 1, options = price, new_row = false },
            --{ type = 'input_number', id = '#', label = '\tKeep\t', value = 10 },
            ----
            --{ type = 'checkbox', id = '#', label = '\tSugarcane', value = false, new_row = false },
            --{ type = 'selectbox_index', id = '#', label = '\tSell', value = 1, options = price, new_row = false },
            --{ type = 'input_number', id = '#', label = '\tKeep\t', value = 10 },
            ----
            --{ type = 'checkbox', id = '#', label = '\tSoybean', value = false, new_row = false },
            --{ type = 'selectbox_index', id = '#', label = '\tSell', value = 1, options = price, new_row = false },
            --{ type = 'input_number', id = '#', label = '\tKeep\t', value = 10 },
            ----
            ----
            { type = 'text', label = '\n# BAKERY #' },
            { type = 'checkbox', id = 'PRO_BREAD_ACTIVE', label = '\tBread', value = false, new_row = false },
            { type = 'selectbox_index', id = 'PRO_BREAD_PRICE', label = '\tSell', value = 1, options = price, new_row = false },
            { type = 'input_number', id = 'PRO_BREAD_KEEP', label = '\tKeep\t', value = 10 },
            ----
            --{ type = 'checkbox', id = '#', label = '\tCorn Bread', value = false, new_row = false },
            --{ type = 'selectbox_index', id = '#', label = '\tSell', value = 1, options = price, new_row = false },
            --{ type = 'input_number', id = '#', label = '\tKeep\t', value = 10 },
            ----
            --{ type = 'checkbox', id = '#', label = '\tCookie', value = false, new_row = false },
            --{ type = 'selectbox_index', id = '#', label = '\tSell', value = 1, options = price, new_row = false },
            --{ type = 'input_number', id = '#', label = '\tKeep\t', value = 10 },
            ----
            ----
            --{ type = 'text', id = '#', label = '\n# Dairy #' },
            --{ type = 'checkbox', id = '#', label = '\tCream', value = false, new_row = false },
            --{ type = 'selectbox_index', id = '#', label = '\tSell', value = 1, options = price, new_row = false },
            --{ type = 'input_number', id = '#', label = '\tKeep\t', value = 10 },
            ----
            --{ type = 'checkbox', id = '#', label = '\tButter', value = false, new_row = false },
            --{ type = 'selectbox_index', id = '#', label = '\tSell', value = 1, options = price, new_row = false },
            --{ type = 'input_number', id = '#', label = '\tKeep\t', value = 10 },
            ----
            --{ type = 'checkbox', id = '#', label = '\tCheese', value = false, new_row = false },
            --{ type = 'selectbox_index', id = '#', label = '\tSell', value = 1, options = price, new_row = false },
            --{ type = 'input_number', id = '#', label = '\tKeep\t', value = 10 },
            ----
            --{ type = 'checkbox', id = '#', label = '\tGoat Cheese', value = false, new_row = false },
            --{ type = 'selectbox_index', id = '#', label = '\tSell', value = 1, options = price, new_row = false },
            --{ type = 'input_number', id = '#', label = '\tKeep\t', value = 10 },
            ----
            ----
            --{ type = 'text', id = '#', label = '\n# Sugar Mill #' },
            --{ type = 'checkbox', id = '#', label = '\tSugar', value = false, new_row = false },
            --{ type = 'selectbox_index', id = '#', label = '\tSell', value = 1, options = price, new_row = false },
            --{ type = 'input_number', id = '#', label = '\tKeep\t', value = 10 },
            ----
            --{ type = 'checkbox', id = '#', label = '\tBrown Sugar', value = false, new_row = false },
            --{ type = 'selectbox_index', id = '#', label = '\tSell', value = 1, options = price, new_row = false },
            --{ type = 'input_number', id = '#', label = '\tKeep\t', value = 10 },
            ----
            --{ type = 'checkbox', id = '#', label = '\tSyrup', value = false, new_row = false },
            --{ type = 'selectbox_index', id = '#', label = '\tSell', value = 1, options = price, new_row = false },
            --{ type = 'input_number', id = '#', label = '\tKeep\t', value = 10 },

        }
    }
    local data = Memory:load("config_products")
    form:loadData(data, true)
    form:show()
    Memory:save("config_products", form:getMinifiedData())
    self:updateGVValues()
end

-------------------------------------------------------------------------------
function M:layoutSettings()
    local form = Form:new("Layout Settings")
    form:addForm {
        ele = {
            { type = 'text', value = '\n# FIELDS #', },
            { type = 'input_number', id = 'FIELD_START_L', label = '\tStarting point\t[left]', value = 1, new_row = false },
            { type = 'input_number', id = 'FIELD_START_B', label = '\t[Bottom]', value = 1 },
            { type = 'input_number', id = 'FIELD_TOTAL_L', label = '\tTotal fields [Left]', value = 10, new_row = false },
            { type = 'input_number', id = 'FIELD_TOTAL_B', label = '\t[Bottom]', value = 10 },
            --
            --{ type = 'text', value = '\n# ANIMALS #', },
            --{ type = 'input_number', id = '#', label = '\tCow\t[left]', value = 1, new_row = false },
            --{ type = 'input_number', id = '#', label = '\t[Bottom]', value = 10 },
            --{ type = 'input_number', id = '#', label = '\tPig\t[left]', value = 1, new_row = false },
            --{ type = 'input_number', id = '#', label = '\t[Bottom]', value = 10 },
            --{ type = 'input_number', id = '#', label = '\tSheep\t[left]', value = 1, new_row = false },
            --{ type = 'input_number', id = '#', label = '\t[Bottom]', value = 10 },
            --{ type = 'input_number', id = '#', label = '\tChicken\t[left]', value = 1, new_row = false },
            --{ type = 'input_number', id = '#', label = '\t[Bottom]', value = 10 },
            --{ type = 'input_number', id = '#', label = '\tGoat\t[left]', value = 1, new_row = false },
            --{ type = 'input_number', id = '#', label = '\t[Bottom]', value = 10 },
            ----
            { type = 'text', value = '\n# MACHINES #', },
            --{ type = 'input_number', id = '#', label = '\tDairy\t[left]', value = 1, new_row = false },
            --{ type = 'input_number', id = '#', label = '\t[Bottom]', value = 10 },
            --{ type = 'input_number', id = '#', label = '\tSugar Mill\t[left]', value = 1, new_row = false },
            --{ type = 'input_number', id = '#', label = '\t[Bottom]', value = 10 },
            --{ type = 'input_number', id = '#', label = '\tHoney Extractor\t[left]', value = 1, new_row = false },
            --{ type = 'input_number', id = '#', label = '\t[Bottom]', value = 10 },
            --{ type = 'input_number', id = '#', label = '\tPopcorn Pot\t[left]', value = 1, new_row = false },
            --{ type = 'input_number', id = '#', label = '\t[Bottom]', value = 10 },
            { type = 'input_number', id = 'BAKERY_START_L', label = '\tBakery\t[left]', value = 15, new_row = false },
            { type = 'input_number', id = 'BAKERY_START_B', label = '\t[Bottom]', value = 6 },
            --{ type = 'input_number', id = '#', label = '\tFeed Mill (1)\t[left]', value = 1, new_row = false },
            --{ type = 'input_number', id = '#', label = '\t[Bottom]', value = 10 },
            --{ type = 'input_number', id = '#', label = '\tFeed Mill (2)\t[left]', value = 1, new_row = false },
            --{ type = 'input_number', id = '#', label = '\t[Bottom]', value = 10 },
            --{ type = 'input_number', id = '#', label = '\tBeehive Tree\t[left]', value = 1, new_row = false },
            --{ type = 'input_number', id = '#', label = '\t[Bottom]', value = 10 },
        }
    }
    local data = Memory:load("config_layout")
    form:loadData(data, true)
    form:show()
    Memory:save("config_layout", form:getMinifiedData())
    self:updateGVValues()
end

--function M:start()
--    local data = Memory:load("config")
--    local form = Form:new("", self:getForm())
--    form:loadData(data, true)
--    form:show()
--    Memory:save("config", form:getMinifiedData())
--    GV.CFG = form:getMinifiedData()
--end

return M