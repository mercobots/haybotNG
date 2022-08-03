local Image = require('ImageHelper')
local Color = require('ColorHelper')
local luall = require('LuaLib')
local botl = require('BotLib')
local GV = require('GlobalVars')
local Console = require('Console')
local OTimer = require('OTimer')
-------------------------------------------------------------------------------
local M = {
    data = {}
}

-------------------------------------------------------------------------------
function M:getGVProductBy(field, value)
    local i = luall.in_table(GV.PRODUCTS, value, field)
    if i < 0 then
        return false
    end
    return GV.PRODUCTS[i]
end

-------------------------------------------------------------------------------
function M:addProduct(product_id, cat)
    local product = self:getGVProductBy('id', product_id)
    if not product then
        return false
    end
    --
    cat = cat or product.cat
    --
    if not self.data[cat] then
        self.data[cat] = {}
    end

    if luall.in_table(self.data[cat], product.id, "id") > 0 then
        scriptExit("[" .. product.id .. "] already registered")
    end

    local i = #self.data[cat] + 1
    self.data[cat][i] = product

end

-------------------------------------------------------------------------------
function M:removeProduct(product_id, cat)
    local product = self:getGVProductBy('id', product_id)
    --
    if not product then
        return false
    end
    --
    cat = cat or product.cat

    if not self.data[cat] then
        return false
    end
    --
    local data_i = luall.in_table(self.data[cat], product_id, "id")

    if data_i < 1 then
        return false
    end

    table.remove(self.data[cat], data_i)
    return true
end

-------------------------------------------------------------------------------
function M:totalProducts(cat)
    if self.data[cat] then
        return #self.data[cat]
    end
    return -1
end

-------------------------------------------------------------------------------
function M:getNextProduct(cat)
    if self:totalProducts(cat) < 1 then
        return false
    end
    return self.data[cat][1]
end

return M