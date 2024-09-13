--==========================================================================================================================--
minetest.register_chatcommand("shop", {
    description = "Open shop menu",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if player then
            atl_item_exchange_plus.open_shop_menu(player)
        end
    end,
})
