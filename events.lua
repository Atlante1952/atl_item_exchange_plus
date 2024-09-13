
--==========================================================================================================================--
minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local player_name = player:get_player_name()
        local message = atl_item_exchange_plus.check_messages_for_player(player_name)
        if message ~= "" then
            minetest.chat_send_player(player_name, minetest.colorize("#aac729", "[Shop] -!- A player has purchased one of your offers, you have received payment in your inventory or on the ground."))
            local items_added = atl_item_exchange_plus.add_purchased_items_to_inventory(player_name, message)
            if not items_added then
                minetest.chat_send_player(player_name, minetest.colorize("#aac729", "[Shop] -!- Error adding purchased items to your inventory."))
            end
            atl_item_exchange_plus.remove_purchase_line(player_name)
        end
    end
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
    for field, _ in pairs(fields) do
        if field:sub(1, 4) == "buy_" then
            local article_name = field:sub(5)
            local items_for_sale = atl_item_exchange_plus.read_items_for_sale()
            for _, item in ipairs(items_for_sale) do
                if item.articles[1].article == article_name then
                    atl_item_exchange_plus.set_selected_item(player, item)
                    return
                end
            end
        end
    end

    if fields.buyitem_ then
        local selected_item = atl_item_exchange_plus.get_selected_item(player)
        if selected_item then
            local enough_prices = true
            for _, price in ipairs(selected_item.prices) do
                local required_stack = ItemStack(price.price .. " " .. price.count)
                local total_available_count = 0
                local inv = player:get_inventory()
                local all_stacks = inv:get_list("main")
                for _, stack in ipairs(all_stacks) do
                    if stack:get_name() == required_stack:get_name() then
                        total_available_count = total_available_count + stack:get_count()
                    end
                end
                if total_available_count < required_stack:get_count() then
                    enough_prices = false
                    break
                end
            end

            if enough_prices then
                local leftover_items = {}
                for _, price in ipairs(selected_item.prices) do
                    local required_stack = ItemStack(price.price .. " " .. price.count)
                    local leftover = player:get_inventory():remove_item("main", required_stack)
                    if not leftover:is_empty() then
                        table.insert(leftover_items, leftover)
                    end
                end
                for _, article in ipairs(selected_item.articles) do
                    local added = player:get_inventory():add_item("main", ItemStack(article.article .. " " .. article.count))
                    if not added:is_empty() then
                        table.insert(leftover_items, added)
                    end
                end
                if #leftover_items > 0 then
                    local player_pos = player:get_pos()
                    for _, leftover in ipairs(leftover_items) do
                        minetest.add_item(player_pos, leftover)
                    end
                end
                minetest.chat_send_player(player:get_player_name(), minetest.colorize("#aac729", "[Shop] -!- Purchase successful!"))
                atl_item_exchange_plus.write_successful_purchase(player:get_player_name(), selected_item)
                atl_item_exchange_plus.remove_purchase_line(player:get_player_name())
                atl_item_exchange_plus.set_selected_item(player, nil)
                atl_item_exchange_plus.open_shop_menu(player)
            else
                minetest.chat_send_player(player:get_player_name(), minetest.colorize("#aac729", "[Shop] -!- You don't have enough prices to buy this item."))
            end
        end
    end
end)


--==========================================================================================================================--
minetest.register_on_player_receive_fields(function(player, formname, fields)
    local player_name = player:get_player_name()
    local inv = player:get_inventory()

    if fields.sell then
        local has_items = false
        for i = 1, 3 do
            if not inv:get_stack("sell_slot", i):is_empty() then
                has_items = true
                break
            end
        end

        if has_items then
            local has_prices = false
            for i = 1, 3 do
                if not inv:get_stack("sell_price_slot", i):is_empty() then
                    has_prices = true
                    break
                end
            end

            if has_prices then
                local sell_items = {}
                for i = 1, 3 do
                    local stack = inv:get_stack("sell_slot", i)
                    if not stack:is_empty() then
                        table.insert(sell_items, stack)
                        inv:set_stack("sell_slot", i, ItemStack(nil))
                    end
                end

                local prices = {}
                for i = 1, 3 do
                    local stack = inv:get_stack("sell_price_slot", i)
                    if not stack:is_empty() then
                        table.insert(prices, stack)
                        inv:set_stack("sell_price_slot", i, ItemStack(nil))
                    end
                end

                local file = io.open(atl_item_exchange_plus.filename, "a")
                if file then
                    file:write(player_name .. " is selling:")
                    for _, item in ipairs(sell_items) do
                        file:write(" " .. item:get_name() .. " x" .. item:get_count())
                    end
                    file:write(" for:")
                    for _, price in ipairs(prices) do
                        file:write(" " .. price:get_name() .. " x" .. price:get_count())
                    end
                    file:write("\n")
                    file:close()
                    atl_item_exchange_plus.open_shop_menu(player)
                end
            else
                minetest.chat_send_player(player_name, minetest.colorize("#aac729", "[Shop] -!- You must have at least one item in each sell price slot."))
                atl_item_exchange_plus.open_shop_menu(player)
            end
        else
            minetest.chat_send_player(player_name, minetest.colorize("#aac729", "[Shop] -!- You must have at least one item in each sell slot."))
            atl_item_exchange_plus.open_shop_menu(player)
        end
    end
end)



--==========================================================================================================================--
minetest.register_on_player_receive_fields(function(player, formname, fields)
    local meta = player:get_meta()
    local current_page = meta:get_int("shop_current_page")
    if fields and (fields.next or fields.prev) then
        local total_items = #atl_item_exchange_plus.read_items_for_sale()
        local max_items = 32
        local total_pages = math.ceil(total_items / max_items)
        if fields.next then
            if current_page < total_pages then
                current_page = current_page + 1
            end
        elseif fields.prev then
            current_page = math.max(current_page - 1, 1)
        end
        meta:set_int("shop_current_page", current_page)
        atl_item_exchange_plus.open_shop_menu(player)
    else
        for field, _ in pairs(fields) do
            if field:sub(1, 4) == "buy_" then
                local article_name = field:sub(5)
                local items_for_sale = atl_item_exchange_plus.read_items_for_sale()
                for _, item in ipairs(items_for_sale) do
                    if item.articles[1].article == article_name then
                        atl_item_exchange_plus.openshop_menu_item_selected(player, item)
                        break
                    end
                end
            end
        end
    end
end)

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if fields.remove then
        local player_name = player:get_player_name()
        local selected_item = atl_item_exchange_plus.get_selected_item(player)
        if selected_item then
            if selected_item.player == player_name then
                local file = io.open(atl_item_exchange_plus.filename, "r")
                if file then
                    local lines = {}
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
                        file:close()
                        local player_inv = player:get_inventory()
                        for _, price in ipairs(selected_item.prices) do
                            player_inv:add_item("main", ItemStack(price.price .. " " .. price.count))
                        end
                        for _, article in ipairs(selected_item.articles) do
                            player_inv:add_item("main", ItemStack(article.article .. " " .. article.count))
                        end
                        minetest.chat_send_player(player_name, minetest.colorize("#aac729", "[Shop] -!- Item(s) successfully removed."))
                        atl_item_exchange_plus.set_selected_item(player, nil)
                        atl_item_exchange_plus.open_shop_menu(player)
                    else
                        minetest.log("[Server] -!- Error opening atl_item_exchange_plus.txt for writing")
                    end
                else
                    minetest.log("[Server] -!- Error opening atl_item_exchange_plus.txt for reading")
                end
            else
                minetest.chat_send_player(player_name, minetest.colorize("#aac729", "[Shop] -!- You can only remove items you have put up for sale."))
            end
        else
            minetest.chat_send_player(player_name, minetest.colorize("#aac729", "[Shop] -!- No item selected."))
        end
    end
end)