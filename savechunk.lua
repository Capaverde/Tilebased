function savechunk(ix,iy)
	local file = love.filesystem.newFile("chunk"..ix.."-"..iy..".lua")
	file:open("w")
	file:write("return "..chunktostring(ix,iy))
	file:close()
end

function loadchunkfromfile(ix,iy)
	getorcreatechunk(ix,iy)
	local chunk = love.filesystem.load("chunk"..ix.."-"..iy..".lua")	--assumindo que existe
	chunks[ix][iy] = chunk()
	for x=0,CHUNKSIZE-1 do
	for y=0,CHUNKSIZE-1 do
		local tile = chunks[ix][iy][x][y]
		local item = gettopitem(tile)
		if item.decay then
			inserttodecay(tile,item.itemid,item.decay.toid,item.decay.duration)
		elseif item.creature then
			tile[#tile] = nil
			newcreature(ix*CHUNKSIZE+x,iy*CHUNKSIZE+y,100,item.itemid,true)
		end
	end
	end
end

function chunktostring(ix,iy)
	local chunk = getchunk(ix,iy)
	if not chunk then print("sem chunk no savechunk") return end
	local str = "{"
	for x=0,CHUNKSIZE-1 do
	str=str.."["..x.."]={"
	for y=0,CHUNKSIZE-1 do
	str=str.."["..y.."]="
	local tile = chunk[x][y]
	str=str..tiletostring(tile)..","
	end
	str=str:sub(1,#str-1).."},"
	end
	str=str.."creatures={}}"
	--str=str:sub(1,#str-1).."}"
	return str
end
	
function tiletostring(tile)
	local str="{"
	for x=1,#tile do
		if not getitype(tile[x]).inventory then
			str=str..itemtostring(tile[x])..","
		end
	end
	str=str:sub(1,#str-1).."}"
	return str
end


function itemtostring(i,pos)	--pos is a string
	if i.itemid then
		return "items["..i.itemid.."]"
	else
		str = "{"
		for k,v in pairs(i) do
			if k ~= "pos" then	--pos is only for inventory, not for tiles
			str=str..k.."="	--assuming k is a string, not a number or a table
			if type(v) == "number" or type(v) == "string" then
				str=str..tostring(v)
			elseif k=="itype" then
				str=str..itemtostring(v)
			end
			str=str..","
			elseif pos then
			str=str.."pos="..pos..","
			end
		end
		str=str:sub(1,#str-1).."}"
		return str
	end
end

function saveplayer()
	if player.life <= 0 then return end
	local file = love.filesystem.newFile("playerdata.lua")
	file:open("w")
	file:write("return "..creaturetostring(player))
	file:close()
end

function loadplayertable()
	if not love.filesystem.isFile("playerdata.lua") then return end
	local f = love.filesystem.load("playerdata.lua")	--assumindo que existe
	if f then
		return f()
	end
end

function loadplayerinventory()
	if not love.filesystem.isFile("playerinventory.lua") then return end
	local f = love.filesystem.load("playerinventory.lua")	--assumindo que existe
	if f then
		return f()
	end
end	

function saveplayerinventory()
	local file = love.filesystem.newFile("playerinventory.lua")
	file:open("w")
	local invstr,poslist = inventorytostring(player.inventory)
	file:write("local inventory = "..invstr.." \n")
	for k,pos in ipairs(poslist) do
		if pos:find("items") or pos:find("crafting") then
			file:write(pos..".pos="..pos.." \n")
		else
			file:write(pos.."[1].pos="..pos.." \n")
		end
	end
	file:write(" return inventory")
	file:close()
end

function creaturetostring(v)
	return "{"..v.x..","..v.y..","..v.life..","..v.itemid..","..tostring(v.npc).."}"
end

function inventorytostring(inv)
	local poslist = {}
	local str = "{"
	for k,v in pairs(inv) do
		  str = str..k.."={"
		if k=="items" or k == "crafting" then
		  for k1,v1 in pairs(v) do
		  if k1~="result" then
			  str = str.."["..k1.."]={"
			  for k2,v2 in pairs(v1) do
				str = str.."["..k2.."]={"
				if #v2 > 0 then
					table.insert(poslist,"inventory."..k.."["..k1.."]["..k2.."]")
					str=str..itemtostring(v2[1])
				end
				str = str.."},"
			  end
		  else
			  str = str..k1.."={,"
		  end
		  str = str:sub(1,#str-1).."},"
		  end
		  str=str:sub(1,#str-1)
		else
			if #v > 0 then
				table.insert(poslist,"inventory."..k)
				str=str..itemtostring(v[1],pos)
			end
		end
		str = str.."},"
	end
	str=str:sub(1,#str-1).."}"
	return str,poslist
end