

dirs = {[0]={x=0,y=-1},[1]={x=1,y=0},[2]={x=0,y=1},[3]={x=-1,y=0}}

--pathfinding

function umoumenosum() return math.random(0,1) == 1 and 1 or -1 end

function randomwalk(v)
	local x = math.random(0,1)
	local p = umoumenosum()
	if x==1 then
		trymovecreature(v.id,v.x+p,v.y)
	else
		trymovecreature(v.id,v.x,v.y+p)
	end
end

function getdirbydeltapos(dx,dy)
	local dir
	if math.abs(dx)>math.abs(dy) then
		if dx > 0 then
			dir = 1
		else
			dir=3
		end
	else
		if dy > 0 then
			dir=2
		else
			dir=0
		end
	end
	return dir
end

function movetopos(id,tox,toy,force)
	local c = creatures[id]
	local ax,ay = c.x,c.y
	local dx,dy = tox-ax,toy-ay
		if math.abs(dx)<=1 and math.abs(dy)<=1 and not force then return end
	local dir = getdirbydeltapos(dx,dy)
	local success = trymovecreature(id,ax+dirs[dir].x,ay+dirs[dir].y)
	if not success then 
		local d = umoumenosum()
		dir = (dir + d)%4
		success = trymovecreature(id,ax+dirs[dir].x,ay+dirs[dir].y)
	end
end

function movetopos2(id,tox,toy)		--with pathfinding
	local c = creatures[id]
	if c.path then
	local last = c.path[#c.path]
	if math.abs(last.x-tox)<=1 and math.abs(last.y-toy)<=1 then
		if not c.pathstep then
			c.pathstep=2
		end
		local pos = c.path[c.pathstep]
		if not pos then c.path = nil return end
		movetopos(c.id,pos.x,pos.y,true)
		c.pathstep=c.pathstep+1
	else
		c.path=getpath(c.x,c.y,tox,toy)
		c.pathstep=2
		if not c.path then return false end
		return movetopos2(id,tox,toy)
	end
	else
		c.path=getpath(c.x,c.y,tox,toy)
		c.pathstep=2
		if not c.path then return false end
		return movetopos2(id,tox,toy)
	end
end

--combat

function attack(c1,c2)
	if c2.life > 0 then
		c2.life = c2.life - items[c1.itemid].attack
		if c2.life <= 0 then
			--if c2 == player then
			--	gameover = true
			--else
				destroycreature(c2)
			--end
		end
	end
end


--misc

function searchforpreys(c, preys)
	if not preys then preys = c.preys end
	local list = {}
	for x=c.x-15,c.x+15 do
		for y=c.y-10,c.y+10 do
			local tile = gettile(x,y)
			if tile then
				local item = gettopitem(tile)
				local itype = getitype(item)
				local prey = preys[itype.itemid]
				if prey then	--might debug if c.preys is nil
					if not list[prey.priority] then 
						list[prey.priority] = {priority=prey.priority} 
					end
					if item.creature then
						table.insert(list[prey.priority],tile.creature)	--tile.creature has x and y
					else
						table.insert(list[prey.priority], {x=x,y=y})
					end
				end
			end
		end
	end
	if #list > 0 then
		local t
		local p = 0
		for k,v in pairs(list) do
			if v.priority>p then
				p=v.priority
				t=v
			end
		end
		table.sort(t, function(a,b) return (a.x-c.x)^2+(a.y-c.y)^2 < (b.x-c.x)^2+(b.y-c.y)^2 end)
		return t[1]
	end
end

function update1(v)
	if player.dead or player.invisible or math.abs(v.x-player.x)>seedist or math.abs(v.y-player.y)>seedist then
		randomwalk(v)
	elseif math.abs(v.x-player.x)<=1 and math.abs(v.y-player.y)<=1 then
		attack(v,player)
		--creatureaddlife(player,-items[v.itemid].attack)
	else
		movetopos2(v.id,player.x,player.y)
	end
end

FRONTEIRADAFOME = 300

function update2(v)
    --behavior
   if v.coward and v.lasthitcreature and math.abs(v.x-v.lasthitcreature.x)<=17 and math.abs(v.y-v.lasthitcreature.y)<=12 then
	local revx,revy = -2*(v.lasthitcreature.x-v.x)+v.x,-2*(v.lasthitcreature.y-v.y)+v.y		--just so deers run from wolves
	movetopos(v.id,revx,revy)
    else
	if not v.targettile then
		randomwalk(v)
		v.targettile = searchforpreys(v)
		if v.targettile then
			v.path = nil
		end
	else
		if math.abs(v.x-v.targettile.x)>15 or math.abs(v.y-v.targettile.y)>10 then	--creature lost
			v.targettile = nil
			v.path = nil
		elseif math.abs(v.x-v.targettile.x)>1 or math.abs(v.y-v.targettile.y)>1 then
			if v.targettile.life then
				movetopos(v.id,v.targettile.x,v.targettile.y)
			else
				local r = movetopos2(v.id,v.targettile.x,v.targettile.y)
				if not r then v.targettile = nil end
			end
		else
			v.path = nil
		end
	end

    end
end

function creatureaddlife(c,dlife)	--,armorable)
	if dlife < 0 then 
		dlife = math.min(0,dlife+c.armor) 
	end
	c.life = math.min(c.maxlife,c.life+dlife)
	if c.life <= 0 then
		destroycreature(c)
	end
end

function updateplayer(p)
	
end