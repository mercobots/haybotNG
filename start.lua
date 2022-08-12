local GV = require("GlobalVars")
local Data = require("DataBot")
local Queue = require("Queue")
local Menu = require("Menu")
local Sentinel = require("Sentinel")
--
local Farming = require("Farming")
--
Data:start()
Menu:start()
-- get actives crops
do
    for i = 1, #GV.PRODUCTS do
        local product = GV.PRODUCTS[i].id
        local active = string.upper(table.concat({ "PRO_", product, "_ACTIVE" }))
        if GV.CFG.products[active] then
            Queue:addProduct(product)

        end
    end
end
--
Farming:set()

--
Farming:start()
Sentinel:networkReset()