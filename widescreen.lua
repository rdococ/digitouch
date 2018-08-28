local data = {}

for k, v in pairs(minetest.registered_nodes["digistuff:touchscreen"]) do
	data[k] = v
end

data.description = "Digitouch Widescreen"

data.selection_box = {
	type = "fixed",
	fixed = {-0.5, -0.5, 0.4, 1.5, 0.5, 0.5}
}
data.tiles = {
	"digitouch_widescreen_back.png",
	"digitouch_widescreen_back.png",
	"digitouch_widescreen_back.png",
	"digitouch_widescreen_back.png",
	"digitouch_widescreen_back.png",
	"digitouch_widescreen_front_left.png"
}

data.after_place_node = function (pos, placer)
	local node = minetest.get_node(pos)
	local facedir = node.param2
	
	local dir = minetest.facedir_to_dir(facedir)
	dir = {x = dir.z, y = dir.y, z = -dir.x}
	
	local right_pos = vector.add(pos, dir)
	local right_node = minetest.get_node(right_pos)
	
	local right_def = minetest.registered_nodes[right_node.name] or {}
	
	if right_node.name ~= "air" and not right_def.buildable_to or minetest.is_protected(right_pos, placer and placer:get_player_name() or "") then
		minetest.dig_node(pos)
		return
	end
	
	minetest.set_node(right_pos, {name = "digitouch:widescreen_right", param2 = facedir})
end
data.after_dig_node = function (pos, node)
	local facedir = node.param2
	
	local dir = minetest.facedir_to_dir(facedir)
	dir = {x = dir.z, y = dir.y, z = -dir.x}
	
	local right_pos = vector.add(pos, dir)
	
	if minetest.get_node(right_pos).name ~= "digitouch:widescreen_right" or minetest.get_node(right_pos).param2 ~= facedir then
		return
	end
	
	minetest.set_node(vector.add(pos, dir), {name = "air"})
end

data.on_rotate = function (pos, node, user, mode, new_param2)
	data.after_dig_node(pos, node)
	
	node.param2 = new_param2 % 4
	
	local facedir = node.param2
	
	local dir = minetest.facedir_to_dir(facedir)
	dir = {x = dir.z, y = dir.y, z = -dir.x}
	
	local right_pos = vector.add(pos, dir)
	local right_node = minetest.get_node(right_pos)
	
	local right_def = minetest.registered_nodes[right_node.name] or {}
	
	if right_node.name ~= "air" and not right_def.buildable_to or minetest.is_protected(right_pos, placer and placer:get_player_name() or "") then
		minetest.dig_node(pos)
		return false
	end
	
	minetest.set_node(pos, node)
	data.after_place_node(pos, user)
	
	return true
end

data.inventory_image = "digitouch_widescreen_inv.png"
data.wield_image = "digitouch_widescreen_front.png"

minetest.register_node("digitouch:widescreen", data)

minetest.register_node("digitouch:widescreen_right", {
	drawtype = data.drawtype,
	node_box = data.node_box,
	
	paramtype = data.paramtype,
	paramtype2 = data.paramtype2,
	
	tiles = {
		"digitouch_widescreen_back.png",
		"digitouch_widescreen_back.png",
		"digitouch_widescreen_back.png",
		"digitouch_widescreen_back.png",
		"digitouch_widescreen_back.png",
		"digitouch_widescreen_front_right.png"
	},
	selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, -0.5, -0.5, -0.5}
	},
	groups = {not_in_creative_inventory = 1}
})

local oldf = digistuff.update_ts_formspec

digistuff.update_ts_formspec = function (pos)
	local res = oldf(pos)
	local meta = minetest.get_meta(pos)
	local name = minetest.get_node(pos).name
	
	if name ~= "digitouch:widescreen" then return res end
	
	local formspec = meta:get_string("formspec")
	meta:set_string("formspec", "size[16, 9]" .. formspec:sub(11, -1))
	return res
end

minetest.register_craft({
	output = "digitouch:widescreen",
	recipe = {
		{"digistuff:touchscreen", "digistuff:touchscreen"}
	}
})