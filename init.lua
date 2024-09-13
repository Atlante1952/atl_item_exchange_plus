atl_item_exchange_plus = {}
atl_item_exchange_plus.filename = minetest.get_worldpath() .. "/atl_item_exchange_plus.txt"


dofile(minetest.get_modpath("atl_item_exchange_plus").."/api.lua")
dofile(minetest.get_modpath("atl_item_exchange_plus").."/commands.lua")
dofile(minetest.get_modpath("atl_item_exchange_plus").."/events.lua")