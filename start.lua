local GV = require("GlobalVars")
local Data = require("DataBot")
local Queue = require("Queue")
local Menu = require("Menu")
local Sentinel = require("Sentinel")
--
local Farming = require("Farming")
local Building = require("Building")
local RSS = require("RSS")

--
setButtonPosition(0, GV.SCREEN.h / 2)

-- load default data
Data:start()

-- Start UI Menu
Menu:start()

-- Set Active products
local function setDefaultProducts()
    --print(GV.CFG.products)
    for i = 1, #GV.PRODUCTS do
        local product = GV.PRODUCTS[i]
        local cfg_active = string.upper(table.concat({ "PRO_", product.id, "_ACTIVE" }))
        local cfg_price = string.upper(table.concat({ "PRO_", product.id, "_PRICE" }))
        local cfg_keep = string.upper(table.concat({ "PRO_", product.id, "_KEEP" }))

        -- == nil (Not Defined at Menu)
        if GV.CFG.products[cfg_active] ~= nil then
            product.keep = GV.CFG.products[cfg_keep]
            product.price = GV.CFG.products[cfg_price]

            -- sell is enabled
            if product.price > 1 then
                Queue:addProduct(product.id, "rss")
            end

            -- active for production
            if GV.CFG.products[cfg_active] then
                Queue:addProduct(product.id)
            end
        end
    end
end
setDefaultProducts()

-- Set Machines
local Bakery = Building:new("bakery", "Bakery", GV.CFG.layout.BAKERY_START_L, GV.CFG.layout.BAKERY_START_B)
local PopcornPot = Building:new("popcorn_pot", "Popcorn Pot", GV.CFG.layout.POPCORN_POT_START_L, GV.CFG.layout.POPCORN_POT_START_B)

-- Init Defaults values for Static Classes
Farming:set()
RSS:set()

---------------------------------------------------- BOT START ----------------------------------------------------

while true do
    Sentinel:checkAll()
    Bakery:start()
    PopcornPot:start()
    Farming:start()
    RSS:start()
    wait(0.1)
    setDefaultProducts()
end