local luall = require('LuaLib')
local GV = require('GlobalVars')
local botl = require('BotLib')

-------------------------------------------------------------------------------
local M = {
    data = {}
}

-------------------------------------------------------------------------------
function M:getProductCat(product_id)
    local product = botl.getGVProductBy(product_id, 'id')
    if not product then
        return "no_product"
    end
    return product.cat and product.cat or "no_cat"
end



-------------------------------------------------------------------------------
function M:addProduct(product_id, cat)
    --
    cat = cat or self:getProductCat(product_id)
    --
    if not self.data[cat] then
        self.data[cat] = {}
    end

    -- if product exists in queue list
    if luall.in_table(self.data[cat], product_id) > 0 then
        return false
    end


    local i = #self.data[cat] + 1
    self.data[cat][i] = product_id

end

-------------------------------------------------------------------------------
function M:removeProduct(product_id, cat)
    --
    cat = cat or self:getProductCat(product_id)

    if not self.data[cat] then
        return false
    end
    --

    local data_i = luall.in_table(self.data[cat], product_id)
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

-------------------------------------------------------------------------------
function M:getData(cat)

    if cat and self.data[cat] then
        return self.data[cat]
    end

    return self.data
end

return M