local file = io.open(atl_item_exchange_plus.filename, "r")
if not file then
    file = io.open(atl_item_exchange_plus.filename, "w")
    if file then
        file:close()
        minetest.log("[Server] -!- Creating atl_item_exchange_plus.txt file")
    else
        minetest.log("[Server] -!- Error creating atl_item_exchange_plus.txt file")
    end
else
    file:close()
end

function atl_item_exchange_plus.read_items_for_sale()
    local items = {}
    local file = io.open(atl_item_exchange_plus.filename, "r")
    if file then
        for line in file:lines() do
            local player, action, articles, prices = line:match("(%S+) is (%S+):%s*(.-)%s*for:%s*(.+)")
            if player and action and articles and prices then
                if action == "selling" then
                    local article_list = {}
                    local price_list = {}
                    for article, count in articles:gmatch("(%S+)%s*x(%d+)") do
                        table.insert(article_list, {article = article, count = tonumber(count)})
                    end
                    for price, count in prices:gmatch("(%S+)%s*x(%d+)") do
                        table.insert(price_list, {price = price, count = tonumber(count)})
                    end
                    table.insert(items, {player = player, articles = article_list, prices = price_list})
                end
            end
        end
        file:close()
    end
    return items
end

function atl_item_exchange_plus.set_selected_item(player, item)
    local player_meta = player:get_meta()
    player_meta:set_string("selected_item", minetest.serialize(item))
end

function atl_item_exchange_plus.get_selected_item(player)
    local player_meta = player:get_meta()
    local item_str = player_meta:get_string("selected_item")
    return minetest.deserialize(item_str)
end

function atl_item_exchange_plus.open_shop_menu(player)
    local inv = player:get_inventory()
    local meta = player:get_meta()
    local current_page = meta:get_int("shop_current_page")
    if current_page == 0 then
        current_page = 1
        meta:set_int("shop_current_page", current_page)
    end
    inv:set_size("sell_slot", 3)
    inv:set_size("sell_price_slot", 3)
    local formspec = "size[13,9]"
    formspec = formspec .. "background[-0.25,-0.25;13.45,10;bc.png]"
    formspec = formspec .. "label[11.65,8.1;Price]"
    formspec = formspec .. "label[8.65,8.1;Item(s)]"
    formspec = formspec .. "tabheader[0,0;shop_tab;      Menu      ;1;true;false]"
    formspec = formspec .. "list[current_player;main;0,5.2;8,1;]"
    formspec = formspec .. "list[current_player;main;0,6.35;8,3;8]"
    formspec = formspec .. "listring[current_player;main]"
    formspec = formspec .. "image[10,6.25;1,1;gui_furnace_arrow_bg.png^[transformR270]"
    formspec = formspec .. "list[current_player;sell_slot;8.5,5.25;1,3;]" --==Slot Item==--
    formspec = formspec .. "listring[current_player;sell_slot]"
    formspec = formspec .. "list[current_player;sell_price_slot;11.5,5.25;1,3;]" --==Slot Price==--
    formspec = formspec .. "style[sell;bgcolor=green]"
    formspec = formspec .. "button[8.25,8.5;3,1;sell;Put up for sale]"
    formspec = formspec .. "button[5,4.25;1.5,1;prev;Prev page]"
    formspec = formspec .. "button[6.5,4.25;1.5,1;next;Next page]"
    local items_for_sale = atl_item_exchange_plus.read_items_for_sale()
    local y = 0.25
    local x = 0
    local max_items = 32
    local item_count = 0
    local start_index = (current_page - 1) * max_items + 1
    local end_index = math.min(start_index + max_items - 1, #items_for_sale)
    for i = start_index, end_index do
        local item = items_for_sale[i]
        if not item then break end
        local tooltip_text = minetest.colorize("orange", "The player: " .. item.player .. minetest.colorize("", " sells:\n"))
        local item_totals = {}
        for _, article in ipairs(item.articles) do
            item_totals[article.article] = (item_totals[article.article] or 0) + article.count
        end
        for article, total_count in pairs(item_totals) do
            tooltip_text = tooltip_text .. minetest.colorize("", "= " .. article .. " x" .. total_count .. "\n")
        end
        tooltip_text = tooltip_text .. minetest.colorize("orange", "For:\n")
        local price_counts = {}
        for _, price in ipairs(item.prices) do
            price_counts[price.price] = (price_counts[price.price] or 0) + price.count
        end
        for price, count in pairs(price_counts) do
            tooltip_text = tooltip_text .. "= " ..price .. " x" .. count .. "\n"
        end
        formspec = formspec .. "item_image_button[" .. x .. "," .. y .. ";1,1;" .. item.articles[1].article .. ";buy_" .. item.articles[1].article .. ";]"
        formspec = formspec .. "tooltip[buy_" .. item.articles[1].article .. ";" .. tooltip_text .. "]"
        x = x + 1
        item_count = item_count + 1
        if item_count % 8 == 0 then
            y = y + 1
            x = 0
        end
    end
    local total_pages = math.ceil(#items_for_sale / max_items)
    formspec = formspec .. "label[4,4.5;Page: " .. current_page .. "/" .. total_pages .. "]"
    minetest.show_formspec(player:get_player_name(), "shop_menu", formspec)
end

function atl_item_exchange_plus.openshop_menu_item_selected(player, article, current_page)
    local inv = player:get_inventory()
    local meta = player:get_meta()
    local current_page = meta:get_int("shop_current_page")
    inv:set_size("sell_slot", 3)
    inv:set_size("sell_price_slot", 3)
    local formspec = "size[13,9]"
    formspec = formspec .. "background[-0.25,-0.25;13.45,10;bc.png]"
    formspec = formspec .. "label[11.65,8.1;Price]"
    formspec = formspec .. "label[8.65,8.1;Item(s)]"
    formspec = formspec .. "label[11.65,3;Price]"
    formspec = formspec .. "label[8.65,3;Item(s)]"
    formspec = formspec .. "tabheader[0,0;shop_tab;      Menu      ;1;true;false]"
    formspec = formspec .. "list[current_player;main;0,5.2;8,1;]"
    formspec = formspec .. "list[current_player;main;0,6.35;8,3;8]"
    formspec = formspec .. "listring[current_player;main]"
    formspec = formspec .. "image[10,6.25;1,1;gui_furnace_arrow_bg.png^[transformR270]"
    formspec = formspec .. "image[10,1.25;1,1;gui_furnace_arrow_bg.png^[transformR270]"
    formspec = formspec .. "list[current_player;sell_slot;8.5,5.25;1,3;]" --==Slot Item==--
    formspec = formspec .. "listring[current_player;sell_slot]"
    formspec = formspec .. "list[current_player;sell_price_slot;11.5,5.25;1,3;]" --==Slot Price==--
    formspec = formspec .. "style[sell;bgcolor=green]"
    formspec = formspec .. "button[8.25,8.5;3,1;sell;Put up for sale]"
    formspec = formspec .. "style[buyitem_;bgcolor=red]"
    formspec = formspec .. "button[8.25,3.5;3,1;buyitem_;Buy the item(s)]"
    formspec = formspec .. "button[5,4.25;1.5,1;prev;Prev page]"
    formspec = formspec .. "button[6.5,4.25;1.5,1;next;Next page]"
    formspec = formspec .. "style[remove;bgcolor=black]"
    formspec = formspec .. "button[11.25,3.5;1.85,1;remove;Remove]"
    local seller_name = article.player
    formspec = formspec .. "label[9,-0.15;The player " .. seller_name .. " wishes to sell:]"
    local y = 0.25
    local x = 8.5
    local max_items = 6
    local item_count = 0
    for _, item in ipairs(article.articles) do
        if item_count < max_items then
            local item_name = item.article
            formspec = formspec .. "item_image_button[" .. x .. "," .. y .. ";1,1;" .. item_name .. ";buy_" .. item_name .. "; x" .. item.count .. "]"
            y = y + 1
            item_count = item_count + 1
            if item_count % 5 == 0 then
                y = y + 1
                x = 0
            end
        else
            break
        end
    end
    y = 0.25
    x = 11.5
    item_count = 0
    for _, price in ipairs(article.prices) do
        if item_count < max_items then
            local price_name = price.price
            formspec = formspec .. "item_image_button[" .. x .. "," .. y .. ";1,1;" .. price_name .. ";buy_" .. price_name .. "; x" .. price.count .. "]"
            y = y + 1
            item_count = item_count + 1
            if item_count % 5 == 0 then
                y = y + 1
                x = 11.75
            end
        else
            break
        end
    end
    local items_for_sale = atl_item_exchange_plus.read_items_for_sale()
    y = 0.25
    x = 0
    max_items = 32
    item_count = 0
    local start_index = (current_page - 1) * max_items + 1
    local end_index = math.min(start_index + max_items - 1, #items_for_sale)
    for i = start_index, end_index do
        local item = items_for_sale[i]
        if not item then break end
        local tooltip_text = minetest.colorize("orange", "The player: " .. item.player .. minetest.colorize("", " sells:\n"))
        local item_totals = {}
        for _, article in ipairs(item.articles) do
            if not item_totals[article.article] then
                item_totals[article.article] = article.count
            else
                item_totals[article.article] = item_totals[article.article] + article.count
            end
        end
        for article, total_count in pairs(item_totals) do
            tooltip_text = tooltip_text .. minetest.colorize("", "= " .. article .. " x" .. total_count .. "\n")
        end
        tooltip_text = tooltip_text .. minetest.colorize("orange", "For:\n")
        local price_counts = {}
        for _, price in ipairs(item.prices) do
            if not price_counts[price.price] then
                price_counts[price.price] = price.count
            else
                price_counts[price.price] = price_counts[price.price] + price.count
            end
        end
        for price, count in pairs(price_counts) do
            tooltip_text = tooltip_text .. "= " ..price .. " x" .. count .. "\n"
        end
        formspec = formspec .. "item_image_button[" .. x .. "," .. y .. ";1,1;" .. item.articles[1].article .. ";buy_" .. item.articles[1].article .. ";]"
        formspec = formspec .. "tooltip[buy_" .. item.articles[1].article .. ";" .. tooltip_text .. "]"
        x = x + 1
        item_count = item_count + 1
        if item_count % 8 == 0 then
            y = y + 1
            x = 0
        end
    end
    local total_pages = math.ceil(#items_for_sale / max_items)
    formspec = formspec .. "label[4,4.5;Page: " .. current_page .. "/" .. total_pages .. "]"
    minetest.show_formspec(player:get_player_name(), "openshop_item_menu", formspec)
end

function atl_item_exchange_plus.write_successful_purchase(player_name, selected_item)
    local file = io.open(atl_item_exchange_plus.filename, "r")
    if file then
        local lines = {}
        local purchase_info = player_name .. " has successfully purchased: "
        local item_removed = false
        for line in file:lines() do
            if not (line:find(selected_item.player .. " is selling:") and line:find(selected_item.articles[1].article) and not item_removed) then
                table.insert(lines, line)
            else
                item_removed = true
            end
        end
        file:close()
        file = io.open(atl_item_exchange_plus.filename, "w")
        if file then
            for _, line in ipairs(lines) do
                file:write(line .. "\n")
            end
            for _, article in ipairs(selected_item.articles) do
                purchase_info = purchase_info .. "- " .. article.article .. " x" .. article.count .. ", "
            end
            purchase_info = purchase_info .. "from " .. selected_item.player .. " for prices: "
            for _, price in ipairs(selected_item.prices) do
                purchase_info = purchase_info .. price.price .. " x" .. price.count .. ", "
            end
            purchase_info = purchase_info .. "Purchase completed.\n"
            file:write(purchase_info)
            file:close()
        else
            minetest.log("[Server] -!- Error opening atl_item_exchange_plus.txt for writing")
        end
    else
        minetest.log("[Server] -!- Error opening atl_item_exchange_plus.txt for reading")
    end
end

function atl_item_exchange_plus.check_messages_for_player(player_name)
    local file = io.open(atl_item_exchange_plus.filename, "r")
    if file then
        local message = ""
        local found = false
        for line in file:lines() do
            if line:find("from " .. player_name) then
                found = true
                message = message .. line .. "\n"
            elseif found and line:find("for prices:") then
                message = message .. line .. "\n"
                break
            end
        end
        file:close()
        return message
    else
        minetest.log("[Server] -!- Error opening atl_item_exchange_plus.txt for reading")
        return ""
    end
end

function atl_item_exchange_plus.add_purchased_items_to_inventory(player_name, message)
    local items_added = false
    local prices_str = message:match("for prices:%s*(.-)%s*Purchase completed")
    if prices_str then
        local items = {}
        for item_str in prices_str:gmatch("%s*([^,]-)%s*,") do
            local item_name, item_count = item_str:match("(%S+)%s+x(%d+)")
            if item_name and item_count then
                table.insert(items, {name = item_name, count = tonumber(item_count)})
            end
        end
        local player_inv = minetest.get_inventory({type = "player", name = player_name})
        if player_inv then
            local leftover_items = {}
            for _, item in ipairs(items) do
                local added = player_inv:add_item("main", ItemStack(item.name .. " " .. item.count))
                if not added:is_empty() then
                    table.insert(leftover_items, added)
                end
            end
            if #leftover_items > 0 then
                local player_pos = minetest.get_player_by_name(player_name):get_pos()
                for _, leftover in ipairs(leftover_items) do
                    minetest.add_item(player_pos, leftover)
                end
            end
            items_added = true
        end
    end
    return items_added
end

function atl_item_exchange_plus.remove_purchase_line(player_name)
    local file = io.open(atl_item_exchange_plus.filename, "r")
    if file then
        local lines = {}
        local found_purchase_line = false
        for line in file:lines() do
            if not found_purchase_line and line:find("from " .. player_name) then
                found_purchase_line = true
            elseif found_purchase_line and line:find("Purchase completed") then
                found_purchase_line = false
            elseif not found_purchase_line then
                table.insert(lines, line)
            end
        end
        file:close()
        file = io.open(atl_item_exchange_plus.filename, "w")
        if file then
            for _, line in ipairs(lines) do
                file:write(line .. "\n")
            end
            file:close()
        else
            minetest.log("[Server] -!- Error opening atl_item_exchange_plus.txt for writing")
        end
    else
        minetest.log("[Server] -!- Error opening atl_item_exchange_plus.txt for reading")
    end
end