local GV = require("GlobalVars")
local Data = require("DataBot")
local Queue = require("Queue")
local Menu = require("Menu")
local Sentinel = require("Sentinel")
--
local Farming = require("Farming")
local Building = require("Building")

-- load default data
Data:start()

-- Start UI Menu
Menu:start()

-- Set Active products
local function setDefaultProducts()
    for i = 1, #GV.PRODUCTS do
        local product = GV.PRODUCTS[i].id
        local active = string.upper(table.concat({ "PRO_", product, "_ACTIVE" }))
        local rss_price = string.upper(table.concat({ "PRO_", product, "_PRICE" }))
        local rss_keep = string.upper(table.concat({ "PRO_", product, "_KEEP" }))
        if GV.CFG.products[active] then
            Queue:addProduct(product)
            GV.CFG.products.keep = rss_keep
            if GV.CFG.products[rss_price] > 1 then
                Queue:addProduct(product, "rss")
                GV.CFG.products.price = rss_price
            end
        end

    end
end
setDefaultProducts()

-- Set Machines
local Bakery = Building:new(GV.CFG.products.PRO_BREAD_ACTIVE, "bakery", "Bakery", GV.CFG.layout.BAKERY_START_L, GV.CFG.layout.BAKERY_START_B)

-- Init Defaults values for Static Classes
Farming:set()


---------------------------------------------------- BOT START ----------------------------------------------------

while true do
    Sentinel:checkAll()
    Bakery:start()
    Farming:start()
    wait(0.1)
    setDefaultProducts()
end