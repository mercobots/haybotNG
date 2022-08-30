local luall = require('LuaLib')
local GV = require('GlobalVars')
local botl = require('BotLib')

-------------------------------------------------------------------------------
local M = {
    data = {}
}

-------------------------------------------------------------------------------
function M:addProduct(product_id, cat, require)
    require = require or 0
    --
    local product = botl.getGVProductBy(product_id, 'id')
    if not product then
        return false
    end
    --
    cat = cat or product.cat
    --
    if not self.data[cat] then
        self.data[cat] = {}
    end

    product.require = product.require + require

    -- if product exists in queue update quantities
    if luall.in_table(self.data[cat], product.id, "id") > 0 then
        return false
    end

    local i = #self.data[cat] + 1
    self.data[cat][i] = product

end

-------------------------------------------------------------------------------
function M:removeProduct(product_id, cat)
    local product = botl.getGVProductBy(product_id, 'id')
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

    product.require = 0
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

-------------------------------------------------------------------------------
function M:getData(cat)

    if cat and self.data[cat] then
        return self.data[cat]
    end

    return self.data
end

return M