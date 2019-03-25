--[[
				local top = gettopitem(tile)
				if weapontype.name == "pickaxe" and top.name == "cave" and #tile == 1 and near then
					setmodified(fromx,fromy)	--modified the chunk, now it will save when unloaded
					swordtime = 0.5
					--newmagiceffect(fromx,fromy,8,0.5)	--pickaxe=8
					tile[1] = items[2] --grass
					--if math.random(1,10) <= 3 then
						--additemtypetoinventory(inventory,items[22]) --flint
					--else
						additemtypetoinventory(inventory,items[23],math.random(1,5)) --small stone
					--end
				elseif weapontype.name == "pickaxe" and top.construcao and near then
					setmodified(fromx,fromy)
					swordtime = 0.5
					--newmagiceffect(fromx,fromy,8,0.5)	--pickaxe=8
					tile[#tile] = nil
					additemtypetoinventory(inventory,items[top.construcao],1)
				elseif weapontype.name == "axe" and top.name == "tree" and near then
					print("using axe")
					setmodified(fromx,fromy)
					swordtime = 0.5
					--newmagiceffect(fromx,fromy,9,0.5)	--axe=9
					tile[#tile]=nil
					if #tile == 0 then
						tile[1] = items[2] --grass
					end
					--additemtypetoinventory(inventory,items[10],3)	--log
					--additemtypetoinventory(inventory,items[27],math.random(1,3))	--seed
				elseif weapontype.name == "fishing rod" and top.name == "water" then	--near not required
					swordtime = 0.5
					--newmagiceffect(fromx,fromy,11,0.5)	--fishingrod=11
					if math.random(1,10) == 10 then
						additemtypetoinventory(inventory,items[12]) --fish
					end
				elseif weapontype.name == "wooden wall carryable" and top.name == "grass" and near then
					setmodified(fromx,fromy)
					table.insert(tile,items[34])	--wooden wall
					removecount(weapon)
				elseif weapontype.name == "stone wall carryable" and top.name == "grass" and near then
					setmodified(fromx,fromy)
					table.insert(tile,items[19])	--stone wall
					removecount(weapon)
				elseif weapontype.name == "door carryable" and top.name == "grass" and near then
					setmodified(fromx,fromy)
					table.insert(tile,items[24])	--door
					removecount(weapon)
				elseif weapontype.name == "stone door carryable" and top.name == "grass" and near then
					setmodified(fromx,fromy)
					table.insert(tile,items[38])	--stone door
					removecount(weapon)
				elseif weapontype.name == "seed carryable" and top.name == "grass" and near then
					print("seedcarryable1")
					setmodified(fromx,fromy)
					table.insert(tile,items[28])	--seedling
					inserttodecay(tile,28,5,100)
					removecount(weapon)
				elseif weapontype.name == "seed carryable" then
					print("seedcarryable2",top.name,near)
				elseif weapontype.name == "fence carryable" and top.name == "grass" and near then
					setmodified(fromx,fromy)
					table.insert(tile,items[32])	--fence
					removecount(weapon)
				elseif weapontype.name == "binoculars" then
					binocularing = true
					if math.abs(fromx-player.x) <= binocdist and math.abs(fromy-player.y) <= binocdist then
						cx,cy = fromx,fromy
					end
				elseif top.name == "fruity tree" and near then
					additemtypetoinventory(inventory,items[21],5)	--apple
					tile[#tile]=nil
					table.insert(tile,items[5]) --normal tree
					local decay = items[5].decay
					inserttodecay(tile,5,decay.toid,decay.duration)	--normal decays to fruity
				elseif top.name == "door" and near then
					tile[#tile]=nil
					table.insert(tile,items[26]) --open door
				elseif top.name == "open door" and near then
					tile[#tile]=nil
					table.insert(tile,items[24]) --closed door
				end
]]

--pickaxe, axe --> nah
--fishing rod okay but nah
--fruity tree and doors!

function fruitytreeonuse(c, pos)
	local tile = gettile(pos.x, pos.y)
	if rangepos(newpos(c.x, c.y), pos) <= 1 then
		additemtypetoinventory(c.inventory,items[21],5)	--apple
		tile[#tile]=nil
		table.insert(tile,items[5]) --normal tree
		local decay = items[5].decay
		inserttodecay(tile,5,decay.toid,decay.duration)	--normal decays to fruity
	end
end

function closeddooronuse(c, pos)
	local tile = gettile(pos.x, pos.y)
	tile[#tile]=nil
	table.insert(tile,items[26]) --open door
end

function opendooronuse(c, pos)
	local tile = gettile(pos.x, pos.y)
	tile[#tile]=nil
	table.insert(tile,items[24]) --closed door
end

function pickaxeonuse(c, topos)
	local tile = gettile(topos.x, topos.y)
	local top = gettopitem(tile)
	if top.name == "cave" and #tile == 1 and rangepos(newpos(c.x, c.y), topos) <= 1 then
		--setmodified(fromx,fromy)	--modified the chunk, now it will save when unloaded
		swordtime = 0.5
		--newmagiceffect(fromx,fromy,8,0.5)	--pickaxe=8
		newdistanceeffect(c.x, c.y, topos.x, topos.y, 5, 0.2) 
		tile[1] = items[2] --grass
		--if math.random(1,10) <= 3 then
			--additemtypetoinventory(c.inventory,items[22]) --flint
		--else
			additemtypetoinventory(c.inventory,items[23],math.random(1,5)) --small stone
		--end
	end
end