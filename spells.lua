function dodamagearea(c, centerpos, area, magiceffect, damage)
	local areacenterx, areacentery
	for x=1,#area do
		for y=1,#(area[1]) do
			if area[x][y] == 2 or area[x][y] == 3 then
				areacenterx = x
				areacentery = y
			end
		end
	end
	if not areacenterx then
		return
	end
	for x=1,#area do
		for y=1,#(area[1]) do
			local posx = x - areacenterx + centerpos.x
			local posy = y - areacentery + centerpos.y
			if area[x][y] == 1 or area[x][y] == 3 then
				newmagiceffect(posx, posy, magiceffect, 0.2)
				local tile = gettile(posx, posy)
				if tile.creature then
					tile.creature.life = tile.creature.life - damage
					tile.creature.lasthitcreature = c
					if tile.creature.life <= 0 then
						destroycreature(tile.creature)
					end
				end
			end
		end
	end
end

function plotline(frompos, topos, plotfunc)
	local deltax = math.abs(topos.x - frompos.x)
	local deltay = math.abs(topos.y - frompos.y)
	local deltaerr = 2*deltay - deltax
	local x0,y0,x1,y1 = frompos.x, frompos.y, topos.x, topos.y

	local y = y0
	
	local swap = false
	if math.abs(deltay) > math.abs(deltax) then
		swap = true
		y = x0
		x0,x1,y0,y1 = y0,y1,x0,x1
		deltax,deltay = deltay,deltax
	end

	local dxsign = sign(x1 - x0)
	local dysign = sign(y1 - y0)
	for x=x0, x1, dxsign do
		if not swap then
			plotfunc(x, y)
		else
			plotfunc(y, x)
		end
		if deltaerr > 0 then
			y = y + dysign
			deltaerr = deltaerr - 2*deltax
		else
			deltaerr = deltaerr + 2*deltay
		end
	end
end

function checkpathblocking(c, frompos, topos)
	local list = {}
	local f = function (x, y) 
		if #list > 0 then
			return
		end
		local tile = gettile(x, y)
		local top = gettopitem(tile)
		if top.pathblocking or (top.creature and tile.creature ~= c) then
			table.insert(list, {x=x, y=y})
		end
	end
	plotline(frompos, topos, f)
	if #list == 0 then
		return topos
	else
		return list[1]
	end
end

--fireball

FBArea = {{0,1,1,1,0},
	  {1,1,1,1,1},
	  {1,1,3,1,1},
	  {1,1,1,1,1},
	  {0,1,1,1,0}}


function castfireball(c, topos)
	newdistanceeffect(c.x, c.y, topos.x, topos.y, 1, 0.1)
	dodamagearea(c, topos, FBArea, 1, 15)
end

function castlifepotion(c)
	--heal = 50
	creatureaddlife(c, 50)
	newmagiceffect(c.x, c.y, 2, 0.2)
end

function castinvisibility(c)
	c.invisible = true
	newmagiceffect(c.x, c.y, 2, 0.2)
	local tile = gettile(c.x, c.y)
	tile[#tile] = items[59]
	inserttoevent(function () c.invisible = false; newmagiceffect(c.x, c.y, 2, 0.2); local tile = gettile(c.x, c.y); tile[#tile] = items[c.itemid] end, 30)
end

function casthaste(c)
	c.walk_delay_temp = c.dt
	c.dt = c.dt/10
	newmagiceffect(c.x, c.y, 2, 0.2)
	inserttoevent(function () c.dt = c.walk_delay_temp; newmagiceffect(c.x, c.y, 2, 0.2); end, 30)
end