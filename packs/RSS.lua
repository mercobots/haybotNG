local Image = require('ImageHelper')
local Color = require('ColorHelper')
local luall = require('LuaLib')
local botl = require('BotLib')
local GV = require('GlobalVars')
local Console = require('Console')
local OTimer = require('OTimer')
local Queue = require("Queue")
local Sentinel = require("Sentinel")

-------------------------------------------------------------------------------
local M = {}

local anchor_offset = { 210, 65 }
-- create only 1, memory saver
local btn_tab = {
    barn = "btn/barn.png",
    silo = "btn/silo.png",
}

-------------------------------------------------------------------------------
function M:set()
    self.rss_tab = 'none'
    self.current_page = 1
    self.first_run = true
    self.AD = OTimer:new(60 * 5)
    self.total_pages = math.ceil(GV.CFG.general.RSS_SLOTS / 10)
    --
end

-------------------------------------------------------------------------------
function M:start()
    -- reset rss page
    if not self:canSell() then
        return false
    end
    --
    if not self:open() then
        return false
    end
    --
    self.first_run = false
    self.current_page = 1

    --
    self:boxController()

    -- in case any product has put in sell and AD is not running so
    -- also used for GV.CFG.general.RSS_AD_INDEX == 2
    self:createAd()
end

-------------------------------------------------------------------------------
function M:canSell()
    if Queue:totalProducts("rss") < 1 then
        Console:show("No Products to sell")
        return false
    end
    --
    if self.first_run then
        return true
    end
    --
    if self:enqueuedProductHasStock() then
        return true
    end
    --
    if self.AD:isRunning() and not self:hasSell() then
        return true
    end

    return false
end

-------------------------------------------------------------------------------
function M:open(timeout)
    timeout = timeout or 0
    for try = 1, 2 do
        if Image:R(GV.REG.rss_holder):exists('rss/holder.png', timeout) then
            Console:show('RSS open')
            return true
        end
        if try == 1 then
            local holder = botl.getHolder(true, { offset = anchor_offset, timeout = 0 })
            click(holder.target.obj)
            Console:show('Awaiting for RSS')
            timeout = 3
        end
    end
    Console:show('Fail opening RSS')
    return false
end

-------------------------------------------------------------------------------
function M:boxController()
    local empty, full, sold
    --
    while not Sentinel:lostConnection(0) do
        repeat
            empty, full, sold = self:getBoxes()
            self:collectSold(sold)

            if not self:sellController(empty) then
                botl.btn_close("click", 0, GV.REG.rss_btn_close)
                return false
            end
        until #empty < 1
        --
        if not self:movePage() then
            break
        end
    end
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
        Console:show(table.concat({ "Collect - ", #sold }))
        for i = 1, #sold do
            click(sold[i])
        end
    end
end

-------------------------------------------------------------------------------
function M:sellController(empty)
    local rectify_stock = true
    local last_product_id = ""
    local product_id = false
    local result = true
    ---
    for box = 1, #empty do
        --
        -- get next enqueue product
        product_id = Queue:getNextProduct("rss")
        if not product_id then
            Console:show("RSS - No more products")
            result = false
            break
        end

        -- get product data
        local product = botl.getGVProductBy(product_id, "id")

        -- only show 1 time per new product
        if last_product_id ~= product_id then
            last_product_id = product_id
            rectify_stock = true
            Console:show(table.concat({ "sell", product.title }))
        end

        --
        click(empty[box])

        if not self:selectTab(product) then
            result = false
            break
        end

        -- check if product is still visible to select
        local product_match = self:selectProduct(product)
        if not product_match then
            result = false
            break
        end

        -- force ocr if rectify is active
        product_match = rectify_stock and product_match or rectify_stock

        -- so if product ha sno stock and there is only 1 product enqueue (self.product) then
        -- stop

        if self:productHasStock(product, product_match) then
            rectify_stock = false
            self:sell(product)
        else
            botl.btn_close("click", 0, GV.REG.rss_btn_close)
            Queue:removeProduct(product_id, "rss")
        end

    end
    --
    if not result and product_id then
        Queue:removeProduct(product_id, "rss")
    end
    --
    return result
end

-------------------------------------------------------------------------------
function M:sell(product)

    --
    if product.price == 2 then
        Console:show('Sell Max')
        click(GV.OBJ.rss_sell_max.center)
    elseif product.price == 3 then
        Console:show('Sell Normal')
    elseif product.price == 4 then
        Console:show('Sell Min')
        click(GV.OBJ.rss_sell_min.center)
    end

    -- Ad not running and and active at 1º sell
    if not self.AD:isRunning() and GV.CFG.general.RSS_AD_INDEX == 1 then
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

    -- update product stock after sell
    product.stock = product.stock >= 20 and product.stock - 10 or math.floor(product.stock * 0.5)
end

-------------------------------------------------------------------------------
function M:movePage(direction)
    direction = direction or "left"
    if direction == "left" and self.current_page >= self.total_pages then
        self.current_page = 1
        return false
    elseif direction == "right" and self.current_page <= 1 then
        return false
    end

    Console:show('Move page - ' .. direction)
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
function M:selectTab(product)
    if self.rss_tab == product.tab then
        return true
    else
        local tab = product.tab
        Console:show('Change Tab ' .. tab)
        if Image:R(GV.REG.safe_area):existsClick(btn_tab[tab]) then
            self.rss_tab = product.tab
            return true
        end
    end
    Console:show('Can\'t select tab')
    return false
end

-------------------------------------------------------------------------------
function M:selectProduct(product)
    -- for identical machines, since product.id == product_x.png
    local img = product.img and product.img or product.id
    local pattern = Pattern('rss/' .. img .. '.png'):similar(0.8)
    local timeout = 3
    --
    Console:show('Select ' .. product.title)
    for tries = 1, 3 do
        if Image:R(GV.REG.rss_sell):existsClick(pattern, timeout) then
            return Image:getData()
        end
        if tries < 3 then
            dragDrop(Location(495, 620), Location(485, 264))
        end
        timeout = 1
    end
    Console:show('Select ' .. product.title .. ' - FAIL')
    return false
end

-------------------------------------------------------------------------------
function M:productHasStock(product, product_match)
    --if product.stock < 1 and product_match then
    if product_match then
        product.stock = self:getProductQuantity(product_match)
    end
    --Console:show(product.title .. ' - ' .. product.stock)

    if product.stock > (product.keep + product.reserved) then
        return true
    end

    -- Console:show('[Stock Keep] ' .. product.stock .. '/' .. product.stock_keep)
    -- Console:show(table.concat({ "[Stock Keep]", product.stock, "/", product.keep, "(+", product.reserved, ")" }))
    return false
end

-------------------------------------------------------------------------------
function M:enqueuedProductHasStock()
    local data = Queue:getData("rss")
    for i = 1, #data do
        local product_id = data[i]
        local product = botl.getGVProductBy(product_id, "id")
        if self:productHasStock(product) then
            Console:show(product.title .. " has stock ")
            return true
        end
    end
    Console:show("No stock available")
    return false
end

-------------------------------------------------------------------------------
function M:getProductQuantity(product_match)
    local center = product_match.center
    local _R = Region(center.x - 20, center.y + 10, 90, 45)
    wait(0.3)
    --debug_r(_R)
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
function M:hasSell(action)
    local holder = botl.getHolder(true, { offset = { 215, 52 }, timeout = 0 })

    if holder then
        local R = Region(holder.target.x - 50, holder.target.y - 50, 100, 100)
        --debug_r(R)
        if Image:R(R):exists('rss/sold.png', 1) then
            Console:show('Has sold')
            if action == 'open' then
                click(holder.target.obj)
            end
            return holder
        end
    end
    return false
end


-- ========================================
function M:createAd()
    -- print("Create AD")
    if self.AD:isRunning() then
        --print(" AD running")
        Console:show('RSS AD - ' .. self.AD:timeLeft())
        return true
    end
    --print(" shop Open")
    if self:open(1) then

        repeat
            --print("Get Slots")
            local empty, full, sold = self:getBoxes()
            for i = 1, #full do
                click(full[i])
                --

                if Image:R(GV.REG.rss_edit_AD):exists("rss/ad/advertised.png", 3) then
                    Console:show('Ad advertised')
                    botl.btn_close("click")
                elseif Image:R(GV.REG.rss_edit_AD):exists("rss/ad/running.png", 0) then
                    self.AD:start() -- start timer in case is not running
                    botl.btn_close("click")
                    return true
                elseif Image:R(GV.REG.rss_edit_AD):exists(Pattern("rss/ad/paper.png"):targetOffset(0, 105), 0) then
                    local paper = Image:getData()
                    click(paper.center.obj)
                    wait(0.5)
                    click(paper.target.obj)
                    Console:show('Ad Created')
                    self.AD:reset()
                    return true
                end
            end
        until not self:movePage("right")
        Console:show('unable to create AD')
    end

    return false
end
return M