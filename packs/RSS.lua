local Image = require('ImageHelper')
local Color = require('ColorHelper')
local luall = require('LuaLib')
local botl = require('BotLib')
local GV = require('GlobalVars')
local Console = require('Console')
local OTimer = require('OTimer')
local Queue = require("Queue")

-------------------------------------------------------------------------------
local M = {
    rss_tab = 'none',
    current_page = 1,
}

local anchor_offset = { 127, 40 }

-------------------------------------------------------------------------------


function M:set()
    --self.config = {
    --    total_pages = math.ceil(GV.config.RSS_BOXES / 10)
    --}
    self.current_page = 1
    self.AD = OTimer:new(60 * 5)
    --
    setContinueClickTiming(0.5, 0.1)
    --self.queue[1] = GV.PRODUCTS[1]
    --
    self.config = {
        total_pages = 3
    }
    --
end

-------------------------------------------------------------------------------
function M:start()
    self.current_page = 1

    if self:open() then
        for page = 1, self.config.total_pages do
            local empty, full, sold = self:getBoxes()
            self:collectSold(sold)
            if not self:sellController(empty) then
                break
            end
            self:movePage()
        end
    end

end

-------------------------------------------------------------------------------
function M:open()

    if Image:R(GV.REG.rss_holder):exists('rss/holder.png', 0) then
        Console:show('RSS open')
        return true
    else
        local target = botl.getAnchor(0, anchor_offset)

        if target then
            click(target.obj)
            Console:show('Awaiting for RSS')
            if Image:R(GV.REG.rss_holder):exists('rss/holder.png') then
                return true
            end
        end
    end

    Console:show('Fail opening RSS')
    return false
end

-------------------------------------------------------------------------------
function M:getBoxes()
    Console:show('Check Boxes')
    Image:R(GV.REG.rss_form):findAll(Pattern('rss/coin.png'):similar(0.8))
    local data = Image:getData()
    local sold = {}
    local sold_i = 0
    local empty = {}
    local empty_i = 0
    local full = {}
    local full_i = 0
    for i = 1, #data do
        local coin = data[i].center.obj
        -- box is empty (no coin img)
        -- is sold
        if (luall.location_in_region(coin, GV.REG.rss_sold_1) or luall.location_in_region(coin, GV.REG.rss_sold_2)) then
            sold_i = sold_i + 1
            sold[sold_i] = coin
        else
            full_i = full_i + 1
            full[full_i] = coin
        end
    end

    if #sold + #full < 10 then
        usePreviousSnap(true)

        Image:R(GV.REG.rss_form):findAll(Pattern('rss/empty.png'):similar(0.8))
        data = Image:getData()

        for i = 1, #data do
            empty_i = empty_i + 1
            empty[empty_i] = data[i].center.obj
        end
        usePreviousSnap(false)
    end
    empty = luall.table_merge(empty, sold)

    return empty, full, sold
end

-------------------------------------------------------------------------------
function M:collectSold(sold)
    if #sold > 0 then
        for i = 1, #sold do
            Console:show('Collect box - ' .. i)
            click(sold[i])
        end
    end
end

-------------------------------------------------------------------------------
function M:sellController(empty)

    for box = 1, #empty do
        --
        if Queue:totalProducts("rss") < 1 then
            return
        end
        --
        local product = Queue:getNextProduct("rss")
        --
        click(empty[box])

        if not self:selectTab(product) then
            return false
        end

        if not self:selectProduct(product) then
            return false
        end

        if self:productHasStock(product) then
            self:sell(product)

            -- update product stock after sell
            product.stock = product.stock >= 20 and product.stock - 10 or math.floor(product.stock * 0.5)
            Console:show(product.title .. ' - ' .. product.stock)
        else
            Queue:removeProduct(product.id, "rss")
            botl.btn_close("click", 0, GV.REG.rss_btn_close)
        end
    end
    return true
end

-------------------------------------------------------------------------------
function M:sell(product)

    --
    if product.price == 1 then
        Console:show('Sell Min')
        click(GV.OBJ.rss_sell_min.center)
    elseif product.price == 2 then
        Console:show('Sell Max')
        click(GV.OBJ.rss_sell_max.center)
    else
        Console:show('Sell Normal')
    end

    -- AD
    if not self.AD:isRunning() then
        Console:show('Create AD')
        if not Color:exists(GV.OBJ.rss_ad_sell) then
            click(Color:getTarget(GV.OBJ.rss_ad_sell))
        else
            Console:show('Ad is already running')
        end
        self.AD:reset()
    end

    --
    Console:show('Confirm sell')
    click(GV.OBJ.rss_btn_sell.center)
    return true
end

-------------------------------------------------------------------------------
function M:selectTab(product)
    if self.rss_tab == product.tab then
        return true
    else
        local tab = product.tab
        Console:show('Change Tab ' .. tab)
        if Color:existsClick(GV.OBJ.rss_tab[tab], 3) then
            self.rss_tab = product.tab
            return true
        end
    end
    Console:show('Can\'t select tab')
    return false
end

-------------------------------------------------------------------------------
function M:selectProduct(product)
    local img = 'rss/' .. product.id .. '.png'
    Console:show('Select ' .. product.title)
    if Image:R(GV.REG.rss_sell):existsClick(img) then
        return true
    end
    Console:show('Select ' .. product.title .. ' - FAIL')
    return false
end

-------------------------------------------------------------------------------
function M:productHasStock(product)
    product.stock = product.stock > 0 and product.stock or self:getProductQuantity()
    Console:show(product.title .. ' - ' .. product.stock)

    if product.stock > product.stock_keep then
        return true
    end

    Console:show('[Stock Keep] ' .. product.stock .. '/' .. product.stock_keep)
    return false
end

-------------------------------------------------------------------------------
function M:getProductQuantity()
    -- right after M:selectProduct()
    local center = Image:getData('center')
    local _R = Region(center.x - 20, center.y + 10, 90, 45)
    debug_r(_R)
    --
    local old_similar = Settings:get("MinSimilarity")
    Settings:set("MinSimilarity", 0.7)
    --
    local ocr, ocr_ok = numberOCRNoFindException(_R, 'set/1/_')
    -- print(ocr, 'ocr')
    Settings:set("MinSimilarity", old_similar)
    return ocr
end

-------------------------------------------------------------------------------
function M:movePage(direction)
    if self.current_page >= self.config.total_pages then
        self.current_page = 1
        return false
    end
    direction = direction or 'left'
    Console:show('Move boxes - ' .. direction)
    local l_left, l_right = Location(295, 435), Location(1000, 435)
    if direction == 'left' then
        self.current_page = self.current_page + 1
        dragDrop(l_right, l_left)
    else
        self.current_page = self.current_page - 1
        dragDrop(l_left, l_right)

    end
    return true
end

-------------------------------------------------------------------------------
function M:hasSell(action)
    local target = botl.getAnchor(0, anchor_offset)
    if target then
        local R = Region(target.x - 50, target.y - 50, 100, 100)
        --debug_r(R)
        if Image:R(R):exists('sold.png', 1) then
            Console:show('Has sold')
            if action == 'open' then
                click(target.obj)
            end
            return target
        end
    end
    return false
end


-- ========================================
function M:createAd()
    if self.AD:isRunning() then
        Console:show('RSS AD - ' .. self.AD:timeLeft())
        return true
    end

    if self:open() then
        repeat
            local empty, full, sold = self:getBoxes()
            for i = 1, #full do
                click(full[i])
                --

                if Color:exists(GV.OBJ.rss_advertised, 3) then
                    Console:show('Ad advertised')
                    luall.btn_back()
                elseif Color:exists(GV.OBJ.rss_ad_sell_edit, 0) then
                    self.AD:start()
                    luall.btn_back(2)
                    return true
                else
                    click(Color:getTarget(GV.OBJ.rss_ad_sell_edit))
                    if Color:existsClick(GV.OBJ.rss_btn_create_ad_edit) then
                        Console:show('Ad Created')
                        self.AD:reset()
                        return true
                    end
                end
            end
        until not self:movePage()
        Console:show('unable to create AD')
    end

    return false
end
return M