-- unsure if this is necessary
local formspec_positions, formspec_names = {}, {}

local function on_close_formspec(name)
	local pos_string = formspec_positions[name]
	local pos = minetest.string_to_pos(pos_string)
	
	formspec_positions[name] = nil
	formspec_names[pos_string][name] = nil
	
	if #formspec_names[pos_string] == 0 then
		minetest.forceload_free_block(pos, true)
	end
end

local function sync(itemstack, player, pointed)
	local player_name = player and player:get_player_name() or ""
	local item_meta = itemstack:get_meta()
	
	local pos_string = item_meta:get_string("position")
	
	local pos = minetest.string_to_pos(pos_string)
	
	if not pos then
		minetest.chat_send_player(player_name, "You haven't synced this remote yet.")
		return
	end
	
	minetest.forceload_block(pos, true)
	
	local node = minetest.get_node(pos)
	local def = minetest.registered_nodes[node.name]
	local meta = minetest.get_meta(pos)
	
	if minetest.is_protected(pos, player_name) then
		minetest.chat_send_player(player_name, "The synced touchscreen has been protected.")
		minetest.forceload_free_block(pos, true)
		return
	end
	
	if not def then return end
	
	-- if it's not a touchscreen (wide or not), return
	if node.name ~= "digistuff:touchscreen" and node.name ~= "digitouch:widescreen" then
		if node.name == "ignore" then
			minetest.chat_send_player(player_name, "The synced touchscreen is not loaded yet. Trying to forceload it - try again in a few seconds.")
			return
		end
		
		minetest.chat_send_player(player_name, "The synced touchscreen no longer exists.")
		formspec_names[pos_string] = nil
		minetest.forceload_free_block(pos, true)
		return
	end
	
	formspec_positions[player_name] = pos_string
	
	formspec_names[pos_string] = formspec_names[pos_string] or {}
	formspec_names[pos_string][player_name] = true
	
	minetest.show_formspec(player_name, "digitouch:" .. pos_string, meta:get_string("formspec"))
end

minetest.register_craftitem("digitouch:remote", {
	inventory_image = "digitouch_remote.png",
	description = "Digitouch Remote (shift+right-click to sync to a touchscreen)",
	
	on_use = function (itemstack, player, pointed)
		-- left-click to connect remote to a touchscreen if the area is not protected
		local player_name = player and player:get_player_name() or ""
		
		-- touchscreens are nodes
		if pointed.type ~= "node" then return end
		
		-- the node is 'under' the crosshair
		local pos = pointed.under
		local node = minetest.get_node(pos)
		local def = minetest.registered_nodes[node.name]
		
		if minetest.is_protected(pos, player_name) then
			minetest.register_protection_violation(pos, player_name)
			return
		end
		
		if not def then return end
		
		-- if it's not a touchscreen (wide or not), return
		if node.name ~= "digistuff:touchscreen" and node.name ~= "digitouch:widescreen" then
			minetest.chat_send_player(player_name, "You can only sync with touchscreens.")
			return
		end
		
		local item_meta = itemstack:get_meta()
		
		local pos_string = minetest.pos_to_string(pos)
		item_meta:set_string("position", pos_string)
		
		minetest.chat_send_player(player_name, "Remote has been synced to the touchscreen at " .. pos_string .. ".")
		item_meta:set_string("description", "Digitouch Remote " .. pos_string)
		
		return itemstack
	end,
	on_secondary_use = sync,
	on_place = sync
})

minetest.register_on_player_receive_fields(function (player, formname, fields)
	local name = player and player:get_player_name() or ""
	
	if type(formname) ~= "string" then return end
	if type(fields) ~= "table" then return end
	
	local pos_string = formname:sub(("digitouch:"):len() + 1, -1)
	local pos = minetest.string_to_pos(pos_string)
	
	if formspec_positions[name] ~= pos_string then return end
	
	local node = minetest.get_node(pos)
	local def = minetest.registered_nodes[node.name]
	local meta = minetest.get_meta(pos)
	
	if node.name ~= "digistuff:touchscreen" and node.name ~= "digitouch:widescreen" then
		minetest.chat_send_player(name, "The synced touchscreen was destroyed while you were using it.")
		on_close_formspec(name)
		
		return
	end
	
	if fields.quit then
		on_close_formspec(name)
	end
	
	digistuff.ts_on_receive_fields(pos, formname, fields, player)
end)

minetest.register_on_leaveplayer(function (player)
	local name = player and player:get_player_name() or ""
	on_close_formspec(name)
end)

minetest.register_on_dieplayer(function (player)
	local name = player and player:get_player_name() or ""
	on_close_formspec(name)
end)

local old_update_ts_formspec = digistuff.update_ts_formspec
digistuff.update_ts_formspec = function (pos, formname, fields, player)
	old_update_ts_formspec(pos, formname, fields, player)
	
	local pos_string = minetest.pos_to_string(pos)
	local meta = minetest.get_meta(pos)
	for name, _ in pairs(formspec_names[pos_string] or {}) do
		minetest.show_formspec(name, "digitouch:" .. pos_string, meta:get_string("formspec"))
	end
end