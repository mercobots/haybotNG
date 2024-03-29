-- Regions - Common
-- ----------------------------------
local M = {}
--
local GV = require('GlobalVars')
local luall = require('LuaLib')

--
function M:start()
    GV.REG = {
        align = Region(350, 492, 180, 308),
        safe_area = Region(93, 91, 1066, 564),
        btn_close = Region(760, 0, 520, 358),
        rss_btn_close = Region(874, 94, 175, 121),
        rss_holder = Region(399, 209, 504, 75),
        rss_form = Region(251, 258, 785, 387),
        rss_sold_1 = Region(253, 414, 789, 37),
        rss_sold_2 = Region(261, 574, 771, 53),
        rss_sell = Region(321, 207, 361, 443),
        rss_edit_AD = Region(492, 198, 291, 433),
        product_resources = Region(355, 275, 576, 312),
    }
    --
    GV.LOC = {
        safe_click = Location(1188, 30),
    }
    --
    GV.OBJ = {
        --home_screen = { center = Location(55, 48), color = { 249, 228, 46 }, diff = { 7, 7, 7 }, },
        btn_home = { center = Location(109, 743), color = { 20, 176, 20 }, diff = { 7, 7, 7 }, }, -- btn down left (house)
        btn_home_dark = { center = Location(109, 743), color = { 5, 41, 5 }, diff = { 7, 7, 7 }, }, -- btn down left (house)
        btn_register = { center = Location(110, 730), color = { 231, 149, 0 }, diff = { 7, 7, 7 }, }, -- btn down left (register)
        btn_settings = { center = Location(31, 117), color = { 248, 225, 72 }, diff = { 7, 7, 7 }, },
        btn_vouchers = { center = Location(1254, 143), color = { 232, 151, 0 }, diff = { 7, 7, 7 }, },
        btn_boosters = { center = Location(1159, 766), color = { 251, 154, 0 }, diff = { 7, 7, 7 }, },
        btn_letter = { center = Location(38, 35), color = { 255, 240, 129 }, diff = { 7, 7, 7 }, },
        --
        slides = { center = Location(0, 0), color = { 255, 255, 213 }, diff = { 10, 10, 10 }, },
        farming_silo_full = { center = Location(443, 342), color = { 56, 55, 56 }, diff = { 7, 7, 7 }, },
        rss_tab = {
            silo = { center = Location(250, 225), color = { 71, 54, 46 }, diff = { 7, 7, 7 }, },
            barn = { center = Location(247, 363), color = { 64, 60, 56 }, diff = { 7, 7, 7 }, },
        },
        rss_sell_max = { center = Location(887, 426), color = { 236, 158, 0 }, diff = { 7, 7, 7 }, },
        rss_sell_min = { center = Location(802, 426), color = { 236, 160, 0 }, diff = { 7, 7, 7 }, },

        rss_btn_sell = { center = Location(949, 628), color = { 240, 161, 0 }, diff = { 7, 7, 7 }, },
        rss_ad_sell = { center = Location(752, 599), color = { 255, 251, 215 }, diff = { 7, 7, 7 }, targetOffset = { 10, -70 } },
        rss_ad_sell_edit = { center = Location(710, 449), color = { 255, 251, 215 }, diff = { 7, 7, 7 }, targetOffset = { 10, -50 } },
        rss_advertised = { center = Location(658, 420), color = { 80, 203, 0 }, diff = { 7, 7, 7 }, },
        rss_btn_create_ad_edit = { center = Location(747, 506), color = { 246, 161, 0 }, diff = { 7, 7, 7 }, },
        --
        collect_product = { center = Location(840, 113), color = { 56, 52, 54 }, diff = { 7, 7, 7 }, },
        --
        product_arrow = { center = Location(0, 0), color = { 235, 155, 2 }, diff = { 7, 7, 7 }, }
    }
    --
    GV.FIELD_SIZE = 42
    --
    local grid5 = { { -250, -300 }, { -370, -230 }, { -227, -200 }, { -430, -125 }, { -310, -125 }, }

    GV.PRODUCTS = {
        { id = "wheat", title = "Wheat", type = 'crop', tab = 'silo', cat = 'field', offset_x = -98, offset_y = -87, slide = 1, produce_time = 60 * 2 },
        { id = "corn", title = "Corn", type = 'crop', tab = 'silo', cat = 'field', offset_x = -168, offset_y = -27, slide = 1, produce_time = 60 * 5 },
        { id = "carrot", title = "Carrot", type = 'crop', tab = 'silo', cat = 'field', offset_x = -313, offset_y = -14, slide = 1, produce_time = 60 * 10 },
        { id = "soybean", title = "Soybean", type = 'crop', tab = 'silo', cat = 'field', offset_x = -117, offset_y = -195, slide = 1, produce_time = 60 * 20 },
        { id = "sugarcane", title = "Sugarcane", type = 'crop', tab = 'silo', cat = 'field', offset_x = -228, offset_y = -128, slide = 1, produce_time = 60 * 30 },
        --
        { id = "bread", title = "Bread", type = 'product', tab = 'barn', cat = 'bakery', resources = { { 'wheat', 3 } }, offset_x = grid5[3][1], offset_y = grid5[3][2], slide = 1, produce_time = 60 * 5 },
        { id = "corn_bread", title = "Corn Bread", type = 'product', tab = 'barn', cat = 'bakery', resources = { { 'corn', 2 }, { 'egg', 2 } }, offset_x = grid5[5][1], offset_y = grid5[5][2], slide = 1, produce_time = 60 * 30 },
        --
        { id = "chili_popcorn", title = "Chili Popcorn", type = 'product', tab = 'barn', cat = 'popcorn_pot', resources = { { 'corn', 2 }, { 'chili_pepper', 2 } }, offset_x = grid5[1][1], offset_y = grid5[1][2], slide = 1, produce_time = 60 * 60 * 2 },
        { id = "honey_popcorn", title = "Honey Popcorn", type = 'product', tab = 'barn', cat = 'popcorn_pot', resources = { { 'corn', 2 }, { 'honey', 2 } }, offset_x = grid5[2][1], offset_y = grid5[2][2], slide = 1, produce_time = 60 * 30 * 3 },
        { id = "popcorn", title = "Popcorn", type = 'product', tab = 'barn', cat = 'popcorn_pot', resources = { { 'corn', 2 } }, offset_x = grid5[3][1], offset_y = grid5[3][2], slide = 1, produce_time = 60 * 30 },
        --
        { id = "pig_feed", title = "Pig Feed", type = 'product', tab = 'barn', cat = 'feed_mill', resources = { { 'carrot', 2 }, { 'soybean', 1 } }, offset_x = grid5[1][1], offset_y = grid5[1][2], slide = 1, produce_time = 60 * 20 },
        { id = "sheep_feed", title = "Sheep Feed", type = 'product', tab = 'barn', cat = 'feed_mill', resources = { { 'wheat', 3 }, { 'soybean', 1 } }, offset_x = grid5[2][1], offset_y = grid5[2][2], slide = 1, produce_time = 60 * 30 },
        { id = "chicken_feed", title = "Chicken Feed", type = 'product', tab = 'barn', cat = 'feed_mill', resources = { { 'wheat', 2 }, { 'corn', 1 } }, offset_x = grid5[3][1], offset_y = grid5[3][2], slide = 1, produce_time = 60 * 5 },
        --
        { id = "milk", title = "Milk", type = 'product', tab = 'barn', cat = 'cow', resources = { 'cow_feed' }, offset_x = grid5[5][1], offset_y = grid5[5][2], slide = 1, produce_time = 60 * 10 },

    }

    -- add variable value
    for i = 1, #GV.PRODUCTS do
        GV.PRODUCTS[i].timer = false
        GV.PRODUCTS[i].stock = 0
        GV.PRODUCTS[i].require = 0
        GV.PRODUCTS[i].keep = 0
        GV.PRODUCTS[i].price = 0
    end

    -- only for crops
    local crops = luall.table_by_group(GV.PRODUCTS, "type", "crop")
    for i = 1, #crops do
        crops[i].lanes = {}
    end

    local function multiplesMachines(machine_id, machines_num)
        local product_data = luall.table_by_group(GV.PRODUCTS, "cat", machine_id)
        local machines = {}
        for i = 1, machines_num do
            if i == 1 then
                machines[i] = product_data
            else
                machines[i] = luall.clone_table(product_data)
            end
        end

        for m_i, machine in ipairs(machines) do
            for i = 1, #product_data do
                machine[i].id = table.concat({ machine[i].id, "_", m_i })
                machine[i].cat = table.concat({ machine[i].cat, "_", m_i })
                if m_i > 1 then
                    GV.PRODUCTS[#GV.PRODUCTS + 1] = luall.clone_table(machine[i])
                end
            end

        end
        machines = {}
    end

    multiplesMachines("feed_mill", 2)
end

return M
