local data = {}

for k, v in pairs(minetest.registered_nodes["digistuff:touchscreen"]) do
	data[k] = v
end

data.description = "Widescreen Touchscreen"

data.selection_box = {
	type = "fixed",
	fixed = {-0.5, -0.5, 0.4, 1.5, 0.5, 0.5}
}
data.tiles = {
	"widescreents_ts_back.png",
	"widescreents_ts_back.png",
	"widescreents_ts_back.png",
	"widescreents_ts_back.png",
	"widescreents_ts_back.png",
	"widescreents_ts_front_left.png"
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
	
	minetest.set_node(right_pos, {name = "widescreents:touchscreen_right", param2 = facedir})
end
data.after_dig_node = function (pos, node)
	local facedir = node.param2
	
	local dir = minetest.facedir_to_dir(facedir)
	dir = {x = dir.z, y = dir.y, z = -dir.x}
	
	local right_pos = vector.add(pos, dir)
	
	if minetest.get_node(right_pos).name ~= "widescreents:touchscreen_right" or minetest.get_node(right_pos).param2 ~= facedir then
		return
	end
	
	minetest.set_node(vector.add(pos, dir), {name = "air"})
end

data.inventory_image = "widescreents_ts_inv.png"
data.wield_image = "widescreents_ts_front.png"

minetest.register_node("widescreents:touchscreen", data)

minetest.register_node("widescreents:touchscreen_right", {
	drawtype = data.drawtype,
	node_box = data.node_box,
	
	paramtype = data.paramtype,
	paramtype2 = data.paramtype2,
	
	tiles = {
		"widescreents_ts_back.png",
		"widescreents_ts_back.png",
		"widescreents_ts_back.png",
		"widescreents_ts_back.png",
		"widescreents_ts_back.png",
		"widescreents_ts_front_right.png"
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
	
	if name ~= "widescreents:touchscreen" then return res end
	
	local formspec = meta:get_string("formspec")
	meta:set_string("formspec", "size[16, 9]" .. formspec:sub(11, -1))
	return res
end

minetest.register_craft({
	output = "widescreents:touchscreen",
	recipe = {
		{"digistuff:touchscreen", "digistuff:touchscreen"}
	}
})