nlist = {}
local storage=minetest.get_mod_storage()
local sl="default"
local mode=1 --1:add, 2:remove
local nled_hud
local edmode_wason=false
nlist.selected=sl

local function is_dflist(list)
	for k,v in pairs(minetest.registered_chatcommands) do
		if v.list_setting == list and v.params == "del <item> | add <item> | list" then
			return true
		end
	end
	return false
end

function nlist.add(list,node)
	if node == "" then mode=1 return end
	local tb=nlist.get(list)
	if table.indexof(tb,node) ~= -1 then return end
	table.insert(tb,node)
	nlist.set(list,tb)
	ws.dcm(node..' added to '..list)
end

function nlist.remove(list,node)
	if node == "" then mode=2 return end
	local tb=nlist.get(list)
	local ix = table.indexof(tb,node)
	if ix == -1 then return end
	table.remove(tb,ix)
	nlist.set(list,tb)
	ws.dcm(node..' removed from '..list)
end

function nlist.set(list,tb)
	local str=table.concat(tb,",")
	if is_dflist(list) then
		minetest.settings:set(list,str)
	else
		storage:set_string(list,str)
	end
end

function nlist.get(list)
	local str
	if is_dflist(list) then
		str=minetest.settings:get(list)
	else
		str=storage:get_string(list)
	end
	return str and str:split(',') or {}
end

function nlist.clear(list)
	if is_dflist(list) then
		minetest.settings:set(list,"")
	else
		storage:set_string(list,"")
	end
end

function nlist.get_lists()
	local ret={}
	for name, _ in pairs(storage:to_table().fields) do
		table.insert(ret, name)
	end
	table.sort(ret)
	return ret
end

function nlist.rename(oldname, newname)
	oldname, newname = tostring(oldname), tostring(newname)
	local list = nlist.get(oldname)
	if not list or not nlist.set(newname,list) then return end
	if oldname ~= newname then
		 nlist.clear(oldname)
	end
	return true
end

function nlist.random(list)
	local str=storage:get(list)
	local tb=str:split(',')
	local kk = {}
	for k in pairs(tb) do
		table.insert(kk, k)
	end
	return tb[kk[math.random(#kk)]]
end

function nlist.show_list(list,hlp)
	if not list then return end
	local act="add"
	if mode == 2 then act="remove" end
	local txt=list .. "\n --\n" .. table.concat(nlist.get(list),"\n")
	local htxt="Nodelist edit mode\n .nla/.nlr to switch\n punch node to ".. act .. "\n.nlc to clear\n"
	if hlp then txt=htxt .. txt end
	set_nled_hud(txt)
end

function nlist.hide()
	if nled_hud then minetest.localplayer:hud_remove(nled_hud) nled_hud=nil end
end

function set_nled_hud(ttext)
	if not minetest.localplayer then return end
	if type(ttext) ~= "string" then return end

	local dtext ="List: ".. ttext

	if nled_hud then
		minetest.localplayer:hud_change(nled_hud,'text',dtext)
	else
		nled_hud = minetest.localplayer:hud_add({
			hud_elem_type = 'text',
			name		  = "Nodelist",
			text		  = dtext,
			number		= 0x00ff00,
			direction   = 0,
			position = {x=0.8,y=0.40},
			alignment ={x=1,y=1},
			offset = {x=0, y=0}
		})
	end
	return true
end


minetest.register_on_punchnode(function(p, n)
	if not minetest.settings:get_bool('nlist_edmode') then return end
	if mode == 1 then
		nlist.add(nlist.selected,n.name)
	elseif mode ==2 then
		nlist.remove(nlist.selected,n.name)
	end
end)

ws.rg('NlEdMode','nList','nlist_edmode', function()nlist.show_list(sl,true) end,function() end,function()nlist.hide() end)

minetest.register_chatcommand('nls',{func=function(list) sl=list nlist.selected=list end})
minetest.register_chatcommand('nlshow',{func=function() nlist.show_list(sl) end})
minetest.register_chatcommand('nlhide',{func=function() nlist.hide() end})
minetest.register_chatcommand('nla',{func=function(el) nlist.add(sl,el)  end})
minetest.register_chatcommand('nlr',{func=function(el) nlist.remove(sl,el) end})
minetest.register_chatcommand('nlc',{func=function(el) nlist.clear(sl) end})

minetest.register_chatcommand('nlawi',{func=function() nlist.add(sl,minetest.localplayer:get_wielded_item():get_name())  end})
minetest.register_chatcommand('nlrwi',{func=function() nlist.remove(sl,minetest.localplayer:get_wielded_item():get_name())  end})

minetest.register_chatcommand('nlapn',{func=function()
	local ptd = minetest.get_pointed_thing()
	if ptd then
		local nd=minetest.get_node_or_nil(ptd.under)
		if nd then nlist.add(sl,nd.name) end
	end
end})
minetest.register_chatcommand('nlrpn',{func=function()
	local ptd = minetest.get_pointed_thing()
	if ptd then
		local nd=minetest.get_node_or_nil(ptd.under)
		if nd then nlist.remove(sl,nd.name) end
	end
end})

minetest.register_chatcommand('nltodf',{func=function(p) todflist(tostring(p)) end})
