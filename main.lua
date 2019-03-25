require "perlin"
require "monsterAI"
require "savechunk"
require "magiceffects"
require "distanceeffects"
require "armor"
require "pathfinding"
require "spells"
require "util"
require "tools"

map = {}
chunks = {}	--each chunk will be 32x32
CHUNKSIZE = 32
creatures = {}
ccount = 0
decaylist = {}
eventlist = {}

function inserttodecay(tile,itemid,toid,duration)	--only on tiles for now
	table.insert(decaylist,{tile=tile,itemid=itemid,toid=toid,lasttime=os.clock(),duration=duration})
end

function inserttoevent(f, timeout)
	table.insert(eventlist, {f=f, lasttime=os.clock(), timeout=timeout})
end

WATER = 1
GRASS = 2
CAVE = 3
TREE = 5
FRUITYTREE = 17

function newcreature(x,y,life,itemid,npc)
	local c = {x=x,y=y,life=life,food=life,maxlife=life,itemid=itemid,npc=npc}
	local ix,iy = getindex(x,y)
	local chunk = chunks[ix][iy]
	ccount=ccount+1
	creatures[ccount]=c
	c.id = ccount
	c.loot = items[c.itemid].loot
	c.construct = items[c.itemid].construct
	c.coward = items[c.itemid].coward
	c.preys = items[c.itemid].preys
	c.migrate=items[c.itemid].migrate
	c.dt = items[c.itemid].dt
	c.lasttime = os.clock()
	c.armor = items[c.itemid].armor or 0
	chunk.creatures[c.id] = c
	local tile = gettile(x,y)
	table.insert(tile, items[itemid])
	tile.creature = c
	return c
end

nullitem = {itype={}}	--dont draw it, dont put it anywhere

terrain = {	{max=-0.6,id=WATER},
		{max=-0.3,id=GRASS},
		{max=-0.295,id=FRUITYTREE},
		{max=0,id=GRASS},
		{max=0.01,id=FRUITYTREE},
		{max=0.15,id=GRASS},
		{max=0.16,id=FRUITYTREE},
		{max=0.3,id=GRASS},
		{max=0.31,id=FRUITYTREE},
		{max=0.375,id=GRASS},
		elsethen=CAVE
	}
	

function getpointid(x,y)
	local noise = PerlinNoise_2D(x,y)	-- between 0 and 1? more like between 0.4 and 1
	--print(noise,x,y)
	noise = (noise-0.4)/0.3-1
	--print(noise)
	local id
	for x=1,#terrain do
		local t = terrain[x]
		if noise <=t.max then
			id =t.id
			break
		end
	end
	if not id then
		id = terrain.elsethen
	end
return id
end

function getorcreatechunk(ix,iy)
	if not chunks[ix] then 
		chunks[ix] = {} 
	end
	if not chunks[ix][iy] then 
		chunks[ix][iy] = {} 
	end
	return chunks[ix][iy]
end

function getchunk(ix,iy)
	--print("getchunk:",ix,iy)
	if not chunks[ix] then 
		return nil
	end
	return chunks[ix][iy]
end

function loadchunk(ix,iy)
	if love.filesystem.isFile("chunk"..ix.."-"..iy..".lua") then 
		loadchunkfromfile(ix,iy) 
		return 
	end
	local basex, basey = ix*CHUNKSIZE,iy*CHUNKSIZE
	local chunk = getorcreatechunk(ix,iy)
	chunk.creatures = {}
	--print("getorcreate:",ix,iy)
	for x=0,CHUNKSIZE-1 do
		chunk[x]={}
		for y=0,CHUNKSIZE-1 do
			chunk[x][y] = {}
			local id = getpointid(basex+x,basey+y)
			table.insert(chunk[x][y],items[id])
			if id == TREE then
				inserttodecay(chunk[x][y],TREE,FRUITYTREE,10)
			end
		end
	end
	local ta = {37}
	for t=1,#ta do
		local x = math.random(0,CHUNKSIZE-1)
		local y = math.random(0,CHUNKSIZE-1)
		if not gettopitem(chunk[x][y]).blocking then
			--table.insert(chunk[x][y],items[6])
			newcreature(basex+x,basey+y,100,ta[t],true)
		end
	end
end

function destroycreature(v)
	local ix,iy = getindex(v.x,v.y)
	local cx,cy = v.x-ix*CHUNKSIZE,v.y-iy*CHUNKSIZE
	local chunk = chunks[ix][iy]
	local tile = chunk[cx][cy]
	if tile then
		if tile.creature == v then	--only destroy it once

			creatures[v.id] = nil
			chunk.creatures[v.id] = nil		
			tile.creature = nil
			tile[#tile] = nil
			v.dead = true

			if v.loot then
				for k,i in ipairs(v.loot) do
					additemtotile(newitem(items[i],1), tile)
					inserttodecay(tile,i,0,100)
				end
			end


			--[[local count = math.ceil(v.food/20)		--each meat is 60 food
			local t = count
			while count > 0 do
				if count > 10 then
					additemtotile(newitem(items[31],10), tile)
				else
					additemtotile(newitem(items[31],count), tile)
				end
				count=count-10
			end]]
		end
	end
end

function unloadchunk(ix,iy)
	for k,v in pairs(chunks[ix][iy].creatures) do	--unload the creatures
		creatures[k] = nil
	end
	if chunks[ix][iy].modified then
		savechunk(ix,iy)
	end
	chunks[ix][iy] = nil
end

function setmodified(x,y)
	local ix,iy = getindex(x,y)
	local chunk = getchunk(ix,iy)
	if chunk then
		chunk.modified=true
	end
end

function getindex(x,y)	
	return math.floor(x/CHUNKSIZE),math.floor(y/CHUNKSIZE) 
end


--function gettile(x,y) if not map[x] then return nil elseif not map[x][y] then return nil else return map[x][y] end end

function gettile(x,y)
	local ix,iy = getindex(x,y)
	--print(x,y,ix,iy,x%CHUNKSIZE,y%CHUNKSIZE)
	local chunk = getchunk(ix,iy)
	if not chunk then 
		return nil 
	end
	return chunk[x%CHUNKSIZE][y%CHUNKSIZE]
end

function gettopitem(tile) 
	return tile[#tile] 
end


function loadTransparent(imagePath, transR, transG, transB)
	local imageData = love.image.newImageData( imagePath )
	local function mapFfunction(x,y, r,g,b,a)
		if (r == 1 and g == 0 and b == 1) then a = 0 end
		return r,g,b,a
	end
	imageData:mapPixel( mapFfunction )
	return love.graphics.newImage( imageData )
end


function newitem(itemtype,count)
	local item = {itype = itemtype}
	if itemtype.stackable then
		item.count = count and count or 1
	end
	return item
end

function additemtotile(item,tile)
	if item.itype then	--it means its a true item, not just an itype
		item.pos=tile
	end
	table.insert(tile,item)
end

function additemtoinventory(inventory,item)
	local bbreak = false
	for y=1,14 do
		for x=1,10 do
			local itemtile = inventory.items[x][y]
			if #itemtile == 0 then
				table.insert(itemtile, item)
				item.pos = itemtile
				bbreak = true
				break
			else
				local item2 = itemtile[1]
				if item2.itype.stackable and item2.itype.itemid == item.itype.itemid then
					item2.count,item.count = math.min(#counts,item2.count+item.count),math.max(0,item.count+item2.count-#counts)
					if item.count == 0 then
						bbreak=true
						break
					end
			    	end
			end
		end
		if bbreak then 
			break 
		end
	end
end

function additemtypetoinventory(inventory,itemtype,count)
	if not count then 
		count = 1 
	end
	local item = newitem(itemtype)
	if itemtype.stackable then 
		item.count = count 
	end
	additemtoinventory(inventory,item)
end

function newinventory()
	local inventory = {head={},torso={},lefthand={},righthand={},legs={},boots={},ammo={},items={}}
	for x=1,10 do
		local c = {}
		table.insert(inventory.items,c)
		for y=1,14 do
			table.insert(c,{})
		end
	end
	--[[for x=1,3 do
		local c={}
		table.insert(inventory.crafting,c)
		for y=1,3 do
			table.insert(c,{})
		end
	end]]
	return inventory
end

function love.load()
	
	items = {}
	items[1] = {itemid=1,name="water",sprite=love.graphics.newImage("sprites/1.png"),blocking=true}
	items[2] = {itemid=2,name="grass",sprite=love.graphics.newImage("sprites/2.png"),unmovable=true}
	items[3] = {itemid=3,name="cave",sprite=love.graphics.newImage("sprites/3.png"),blocking=true, pathblocking=true}
	items[4] = {itemid=4,name="player",dt=0.2,creature=true,inventory=true,sprite=loadTransparent("sprites/4.png"),blocking=true}	--inventory=true so it wont be saved
	items[5] = {itemid=5,name="tree",sprite=love.graphics.newImage("sprites/5.png"),blocking=true,decay={toid=17,duration=30}, pathblocking=true}
	items[6] = {itemid=6,name="creature",creature=true,sprite=loadTransparent("sprites/6.png",255,0,255),blocking=true,attack=5}	--
	items[7] = {itemid=7,name="sword",inventory=true,sprite=loadTransparent("sprites/7.png",255,0,255),blocking=false,righthand=true,lefthand=true,attack=24,near=true, distanceid=2}	--
	items[8] = {itemid=8,name="pickaxe",inventory=true,sprite=loadTransparent("sprites/8.png",255,0,255),blocking=false,righthand=true,lefthand=true,attack=3,tool=true, onuse=pickaxeonuse}
	items[9] = {itemid=9,name="axe",inventory=true,sprite=loadTransparent("sprites/9.png",255,0,255),blocking=false,righthand=true,lefthand=true,attack=3,tool=true}
	--items[10] = {itemid=10,name="wood",inventory=true,sprite=loadTransparent("sprites/10.png",255,0,255),blocking=false,stackable=true}
	--items[11] = {itemid=11,name="fishing rod",inventory=true,sprite=loadTransparent("sprites/11.png"),blocking=false,lefthand=true,righthand=true,tool=true}
	--items[12] = {itemid=12,name="fish",inventory=true,sprite=loadTransparent("sprites/12.png"),blocking=false,stackable=true,heal=6}
	items[13] = {itemid=13,name="bow",inventory=true,sprite=loadTransparent("sprites/13.png"),blocking=false,righthand=true,lefthand=true,attack=18,ammoid=14,near=false, distanceid=3}
	items[14] = {itemid=14,name="arrow",inventory=true,sprite=loadTransparent("sprites/14.png"),blocking=false,ammo=true,stackable=true}
	items[15] = {itemid=15,name="binoculars",inventory=true,sprite=loadTransparent("sprites/15.png"),blocking=false,righthand=true,lefthand=true,tool=true}
	--items[16] = {itemid=16,name="stick",inventory=true,sprite=loadTransparent("sprites/16.png"),blocking=false,stackable=true}
	items[17] = {itemid=17,name="fruity tree",sprite=loadTransparent("sprites/17.png"),blocking=true, onuse=fruitytreeonuse, pathblocking=true}
	items[18] = {itemid=18,name="wall",sprite=loadTransparent("sprites/18.png"),blocking=true}
	items[19] = {itemid=19,name="stone wall",construcao=20,sprite=loadTransparent("sprites/19.png"),blocking=true, pathblocking=true}
	--items[20] = {itemid=20,name="stone wall carryable",inventory=true,sprite=loadTransparent("sprites/20.png"),stackable=true,blocking=false,righthand=true,lefthand=true,tool=true}
	items[21] = {itemid=21,name="apple",inventory=true,sprite=loadTransparent("sprites/21.png"),stackable=true,blocking=false,heal=3}
	--items[22] = {itemid=22,name="flint",inventory=true,sprite=loadTransparent("sprites/22.png"),stackable=true,blocking=false}
	items[23] = {itemid=23,name="small stone",inventory=true,sprite=loadTransparent("sprites/23.png"),stackable=true,attack=50,blocking=false, righthand=true, lefthand=true, distanceid=4, removeonuse=true}
	items[24] = {itemid=24,name="door",construcao=25,sprite=loadTransparent("sprites/24.png"),blocking=true, onuse=closeddooronuse}
	--items[25] = {itemid=25,name="door carryable",inventory=true,sprite=loadTransparent("sprites/25.png"),stackable=true,blocking=false,righthand=true,lefthand=true,tool=true}
	items[26] = {itemid=26,name="open door",construcao=25,sprite=loadTransparent("sprites/26.png"),blocking=false, onuse=opendooronuse}
	--items[27] = {itemid=27,name="seed carryable",inventory=true,sprite=loadTransparent("sprites/27.png"),blocking=false,stackable=true,righthand=true,lefthand=true,tool=true}
	--items[28] = {itemid=28,name="seedling",sprite=loadTransparent("sprites/28.png"),blocking=false,unmovable=true,decay={toid=5,duration=100}}
	--items[29] = {itemid=29,name="deer",dt=0.5,creature=true,coward=true,sprite=loadTransparent("sprites/29.png"),blocking=true,attack=5,preys={[17]={food=150,toid=5,heal=15,priority=1},[21]={removecount=true,priority=2}},loot={}}	--
	--items[30] = {itemid=30,name="wolf",dt=0.5,creature=true,sprite=loadTransparent("sprites/30.png"),migrate=true,blocking=true,attack=10,preys={[4]={creature=true,priority=1},[29]={creature=true,priority=1},[41]={creature=true,priority=1},[31]={removecount=true,priority=2}}}	--
	items[31] = {itemid=31,name="meat",inventory=true,sprite=loadTransparent("sprites/31.png"),blocking=false,stackable=true,heal=6}
	items[32] = {itemid=32,name="fence",construcao=33,sprite=loadTransparent("sprites/32.png"),blocking=true}
	--items[33] = {itemid=33,name="fence carryable",inventory=true,sprite=loadTransparent("sprites/33.png"),blocking=false,stackable=true,righthand=true,lefthand=true,tool=true}
	items[34] = {itemid=34,name="wooden wall",construcao=35,sprite=loadTransparent("sprites/34.png"),blocking=true}
	--items[35] = {itemid=35,name="wooden wall carryable",inventory=true,sprite=loadTransparent("sprites/35.png"),blocking=false,stackable=true,righthand=true,lefthand=true,tool=true}
	items[36] = {itemid=36,name="human npc",dt=0.5,humannpc=true,creature=true,sprite=loadTransparent("sprites/36.png"),blocking=true}
	items[37] = {itemid=37,name="giant",dt=0.2,creature=true,construct=true,sprite=loadTransparent("sprites/37.png"),migrate=true,blocking=true,attack=20,preys={[4]={creature=true,priority=1},[31]={removecount=true,priority=2}}}
	items[38] = {itemid=38,name="stone door",construcao=39,sprite=loadTransparent("sprites/38.png"),blocking=true}
	--items[39] = {itemid=39,name="stone door carryable",inventory=true,sprite=loadTransparent("sprites/39.png"),stackable=true,blocking=false,righthand=true,lefthand=true,tool=true}
	items[40] = {itemid=40,name="open stone door",construcao=39,sprite=loadTransparent("sprites/40.png"),blocking=false}
	--items[41] = {itemid=41,name="sheep",dt=0.5,creature=true,sprite=loadTransparent("sprites/41.png"),blocking=true,attack=5,preys={[17]={food=150,toid=5,heal=15,priority=1},[21]={removecount=true,priority=2}},loot={}}
	--items[42] = {itemid=42,name="wool",inventory=true,sprite=loadTransparent("sprites/42.png"),stackable=true,blocking=false}
	--items[43] = {itemid=43,name="string",inventory=true,sprite=loadTransparent("sprites/43.png"),stackable=true,blocking=false}
	--items[44] = {itemid=44,name="wooden sword",inventory=true,sprite=loadTransparent("sprites/44.png"),blocking=false,righthand=true,lefthand=true,attack=10,near=true}	--
	--items[45] = {itemid=45,name="stone sword",inventory=true,sprite=loadTransparent("sprites/45.png"),blocking=false,righthand=true,lefthand=true,attack=16,near=true}	--
	items[46] = {itemid=46,name="leather armor",inventory=true,sprite=loadTransparent("sprites/46.png"),blocking=false,torso=true,armor=4}
	items[47] = {itemid=47,name="leather legs",inventory=true,sprite=loadTransparent("sprites/47.png"),blocking=false,legs=true,armor=1}
	items[48] = {itemid=48,name="leather helmet",inventory=true,sprite=loadTransparent("sprites/48.png"),blocking=false,head=true,armor=1}
	items[49] = {itemid=49,name="leather boots",inventory=true,sprite=loadTransparent("sprites/49.png"),blocking=false,boots=true,armor=1}
	--items[50] = {itemid=50,name="leather",inventory=true,sprite=loadTransparent("sprites/50.png"),blocking=false,stackable=true}
	items[51] = {itemid=51,name="fireball rune", inventory=true, sprite=loadTransparent("sprites/fireballrune.png"), blocking=false, stackable=true, righthand=true, lefthand=true, cast=castfireball, removeonuse=true}
	items[52] = {itemid=52,name="dragon",dt=0.5,creature=true,sprite=loadTransparent("sprites/dragon.png"),blocking=true}
	items[53] = {itemid=53, name="haste potion", inventory=true, sprite=loadTransparent("sprites/hastepotion.png"), blocking=false, stackable=true, removeonuse=true, castself=casthaste} --cast=...
	items[54] = {itemid=54, name="invisible potion", inventory=true, sprite=loadTransparent("sprites/invisiblepotion.png"), blocking=false, stackable=true, removeonuse=true, castself=castinvisibility} --cast=...
	items[55] = {itemid=55, name="life potion", inventory=true, sprite=loadTransparent("sprites/lifepotion.png"), blocking=false, stackable=true, removeonuse=true, castself=castlifepotion} --cast=...
	items[56] = {itemid=56, name="healing rune", inventory=true, sprite=loadTransparent("sprites/healingrune.png"), blocking=false, stackable=true, removeonuse=true}
	items[57] = {itemid=57, name="magic wall rune", inventory=true, sprite=loadTransparent("sprites/magicwallrune.png"), blocking=false, stackable=true, removeonuse=true}
	items[58] = {itemid=58, name="magic wall", inventory=false, sprite=loadTransparent("sprites/magicwall1.png"), animation=true, animationdelay=0.5, blocking=true}	--{loadTransparent("sprites/magicwall1.png"),loadTransparent("sprites/magicwall2.png"),loadTransparent("sprites/magicwall3.png"),loadTransparent("sprites/magicwall4.png")},
	items[59] = {itemid=59, name="invisible creature", dt=1, creature=true, sprite={loadTransparent("sprites/1509.bmp"), loadTransparent("sprites/1510.bmp"), loadTransparent("sprites/1511.bmp"), loadTransparent("sprites/1512.bmp"), loadTransparent("sprites/1513.bmp")}, animation=true, animationdelay=0.5, blocking=true}
	--items[60] = {itemid=60, name="convince creature rune", 

	inventoryimg = love.graphics.newImage("sprites/inventory.png")
	--inventory = {head={},torso={},lefthand={},righthand={},legs={},boots={},ammo={},items={}}
	inveqx,inveqy = 16,29
	--invcraftx,invcrafty = 148,29
	--invresultx,invresulty = 280,61

	magiceff = {}
	magiceff[1] = { sprite=loadTransparent("sprites/fire.png") }
	magiceff[2] = { animation=true, sprite={loadTransparent("sprites/1509.bmp"), loadTransparent("sprites/1510.bmp"), loadTransparent("sprites/1511.bmp"), loadTransparent("sprites/1512.bmp"), loadTransparent("sprites/1513.bmp")} }
	
	distanceeff = {}
	distanceeff[1] = { sprite=loadTransparent("sprites/fireball.png") }
	distanceeff[2] = { sprite=loadTransparent("sprites/7.png") }
	distanceeff[3] = { sprite=loadTransparent("sprites/14.png") } 
	distanceeff[4] = { sprite=loadTransparent("sprites/23.png") } 
	distanceeff[5] = { sprite=loadTransparent("sprites/8.png") } 


counts = {
	loadTransparent("sprites/n1.png",255,0,255),
	loadTransparent("sprites/n2.png",255,0,255),
	loadTransparent("sprites/n3.png",255,0,255),
	loadTransparent("sprites/n4.png",255,0,255),
	loadTransparent("sprites/n5.png",255,0,255),
	loadTransparent("sprites/n6.png",255,0,255),
	loadTransparent("sprites/n7.png",255,0,255),
	loadTransparent("sprites/n8.png",255,0,255),
	loadTransparent("sprites/n9.png",255,0,255),
	loadTransparent("sprites/n10.png",255,0,255)
		}

	inveqs={[1]={[2]="lefthand"},[2]={[1]="head",[2]="torso",[3]="legs",[4]="boots"},[3]={[2]="righthand",[3]="ammo"}}


	--local inventory = loadplayerinventory()
	local inventory

	if not inventory then

		inventory = newinventory()

		inventory.items[3][4][1] = newitem(items[8])
		additemtypetoinventory(inventory,items[7])
		additemtypetoinventory(inventory,items[9])
		--additemtypetoinventory(inventory,items[11])
		additemtypetoinventory(inventory,items[13])
		additemtypetoinventory(inventory, items[14], 10)
		additemtypetoinventory(inventory, items[14], 10)
		additemtypetoinventory(inventory,items[15])
		--additemtypetoinventory(inventory,items[16])
		--additemtypetoinventory(inventory, items[20], 10)
		additemtypetoinventory(inventory, items[21], 10)
		additemtypetoinventory(inventory,items[46])
		additemtypetoinventory(inventory,items[47])
		additemtypetoinventory(inventory,items[48])
		additemtypetoinventory(inventory,items[49])
		additemtypetoinventory(inventory,items[51], 10)
		additemtypetoinventory(inventory,items[51], 10)
		additemtypetoinventory(inventory,items[23], 10)
		additemtypetoinventory(inventory,items[23], 10)
		additemtypetoinventory(inventory,items[53], 10)
		additemtypetoinventory(inventory,items[54], 10)
		additemtypetoinventory(inventory,items[55], 10)
		additemtypetoinventory(inventory,items[56], 10)
		additemtypetoinventory(inventory,items[57], 10)

	end
	
	
	hpx,hpy = 148,143
	local initx,inity = 10,10
	local playertable = loadplayertable()
	if playertable then 
		initx,inity = playertable[1],playertable[2] 
	end
	--[[
	local y = 1
		for line in love.filesystem.lines("map.txt") do
			for x=1,#line do
				table.insert(map[x][y],items[tonumber(line:sub(x,x))])
			end
			y=y+1
		end
		--table.insert(map[px][py],items[4])
		print(#map[px][py])
	]]

	print("loading...")
	local ix,iy = getindex(initx,inity)

	for iix=ix-1,ix+1 do
		for iiy=iy-1,iy+1 do
			--print("loading",iix,iiy)
			loadchunk(iix,iiy)
		end
	end
	--loadchunk(ix,iy)
	--loadchunk(ix+1,iy)
	--print(chunks[0][0],chunks[1][0])
	print("loaded.")
	love.graphics.setBackgroundColor(104, 136, 248) --set the background color to a nice blue
	width=960
	height=640
	love.window.setMode(width+320, height, { fullscreen = false, vsync = true, msaa = 0})

	--newcreature(initx+1,inity,100,36,true)
	if not playertable then
		player = newcreature(initx,inity,100,4,false)
	else
		local x,y,hp,id,npc = unpack(playertable)
		player = newcreature(x,y,100,id,npc)
		player.life = hp
	end
	player.inventory = inventory
	player.armor = calculatearmor(inventory)
	--table.insert(gettile(player.x,player.y),items[4])
	--table.insert(gettile(player.x+1,player.y),items[19])
	

	--print(inventorytostring(player.inventory))
end


function trymovecreature(id, tox, toy)
	local c = creatures[id]
	if not c then 
		return 
	end
	local ax,ay = c.x,c.y
	if tox==ax and toy==ay then --it might be true
			return 
	end		
	local aix,aiy = getindex(ax,ay)
	local before = gettile(ax,ay)
	if before then
		local me = gettopitem(before)
		local after = gettile(tox,toy)
		if after then
			local topafter = gettopitem(after)
			if topafter then
				if not topafter.blocking then	--it is free, lets occupy it
					before.creature = nil
					before[#before] = nil
					table.insert(after, me)
					after.creature = c
					c.x, c.y = tox, toy
					local toix, toiy = getindex(tox,toy)
					if toix~=aix or toiy~=aiy then	--changed chunks
						local oldchunk = chunks[aix][aiy]
						local newchunk = chunks[toix][toiy]
						oldchunk.creatures[c.id] = nil
						newchunk.creatures[c.id] = c
					end
					return true	--succesfully moved
				end
			end
		end
	end
	return false
end
	

mydt = 1
dtcount = 0
seedist = 15
ts = 1	--time scale
function love.update(dt)
	if swordtime > 0 then 
		swordtime = swordtime - dt 
	end
	if os.clock() - last_walk >= player.dt then	--WALK_DELAY
		checkplayermove()
	end
	updatemagiceffects()
	updatedistanceeffects()
	dtcount = dtcount+dt
	for k,v in pairs(creatures) do
		local time = os.clock() 
		if v.lasttime + v.dt <= time then
			v.lasttime = time
			if v.npc then	
				update1(v)
			else
				updateplayer(v)
			end
		end
	end
	--if dtcount >= mydt then
		--dtcount = dtcount-mydt
		for k,v in pairs(decaylist) do
			if v.lasttime + v.duration <= os.clock() then
				for t = #v.tile,1,-1 do
					local itype = getitype(v.tile[t])
					if itype.itemid == v.itemid then
						local to = items[v.toid]
						if to then
							v.tile[t] = to
							local decay = to.decay
							if decay then
								inserttodecay(v.tile,v.toid,decay.toid,decay.duration)
							end
						else
							--v.tile[t] = items[15]
							table.remove(v.tile,t)
						end
						break
					end
				end
				decaylist[k] = nil
			end
		end
	--end
	for k,v in pairs(eventlist) do
		if v.lasttime + v.timeout <= os.clock() then
			v.f()
			eventlist[k] = nil
		end
	end
end		


function checkplayermove()
	local ax,ay = player.x,player.y
	local aix,aiy = getindex(ax,ay)
	local tox,toy = ax,ay
	local before = gettile(ax,ay)
	local moved = true
	if keyboard["right"] or keyboard["d"] then
		tox = tox+1
	elseif keyboard["down"] or keyboard["s"] then
		toy = toy+1
	elseif keyboard["left"] or keyboard["a"] then
		tox = tox-1
	elseif keyboard["up"] or keyboard["w"] then
		toy = toy-1
	else
		moved = false
	end

	if moved then
		last_walk = os.clock()
		local success = trymovecreature(player.id,tox,toy)
		if success then
			local pix,piy = getindex(tox,toy)
			if pix~=aix or piy~=aiy then
				if pix>aix then	--to the right
					for y=piy-1,piy+1 do
						unloadchunk(aix-1,y)
						loadchunk(pix+1,y)
					end
				elseif pix<aix then --to the left
					for y=piy-1,piy+1 do
						unloadchunk(aix+1,y)
						loadchunk(pix-1,y)
					end
				elseif piy>aiy then	--down
					for x=pix-1,pix+1 do
						unloadchunk(x,aiy-1)
						loadchunk(x,piy+1)
					end
				elseif piy<aiy then	--up
					for x=pix-1,pix+1 do
						unloadchunk(x,aiy+1)
						loadchunk(x,piy-1)
					end
				end
					
			end
		end
	end
		
end

keyboard = {}
function love.keypressed(key)
	keyboard[key] = true
end

function love.keyreleased(key)
	keyboard[key] = false
end

dragfromx=0
dragfromy=0
dragtox=0
dragtoy=0

swordtime = 0
WALK_DELAY = 0.1
last_walk = 0
function love.mousepressed(x,y,button)
	--print("mouse event pressed", x, y)
	if button == 1 then
		dragfromx=x
		dragfromy=y
	end
end

function removecount(item)
	local itype = getitype(item)
	if itype.stackable then
		item.count=item.count-1
		if item.count <= 0 then
			item.pos[#item.pos] = nil	--would work for tiles (since remove count is always used on top item) if pos was tile
		end
	else
		item.pos[#item.pos] = nil
	end
end

function gettilefromscreen(dragx,dragy)
	local x,y
	local inv
	local eq
	local centerx,centery = player.x,player.y
	if binocularing then 
		centerx,centery = cx,cy 
	end
		if dragx <= 960 then	--it means its not from the inventory
			x = centerx-width/64+math.ceil(dragx/32)
			y = centery-height/64+math.ceil(dragy/32)
			inv = false
		elseif dragy > 188 then
			x = math.ceil((dragx-960)/32)
			y = math.ceil((dragy-188)/32)
			inv = true
		elseif dragx > 960+inveqx and dragx <= 960+inveqx+3*32 and dragy > inveqy then	--from the equipped items
			x = math.ceil((dragx-(960+inveqx))/32)
			y = math.ceil((dragy-inveqy)/32)
			if inveqs[x] then
				eq = inveqs[x][y]
			end
			if not eq then eq = "false" end
		else
			eq="false"
		end
	--print(x,y,inv,eq)
	return x,y,inv,eq
end
	


function love.mousereleased(x,y,button)
	--print ("mouse event released", x, y)
	local inventory = player.inventory
	local fromx,fromy
	local frominv
	local fromeq		--head,torso,legs,boots,lefthand,righthand
	local tox,toy
	local toinv
	local toeq
	if button == 1 then
		dragtox = x
		dragtoy = y
		fromx,fromy,frominv,fromeq = gettilefromscreen(dragfromx,dragfromy)
		tox,toy,toinv,toeq = gettilefromscreen(dragtox,dragtoy)
		if fromeq==toeq and frominv==toinv and fromx==tox and fromy==toy then
			onclick(player,fromx,fromy,frominv,fromeq)
			return
		end
		local fromtile,totile
		local me
		local metype
		if not frominv and not fromeq then
			fromtile = gettile(fromx,fromy)
			me = gettopitem(fromtile)
			metype = getitype(me)
			if metype.blocking or metype.unmovable then 
				return 
			end
			if not (math.abs(player.x-fromx) <= 1 and math.abs(player.y-fromy) <=1) then 
				return 
			end
		elseif fromeq then
			if fromeq == "false" then return end
			me = inventory[fromeq][1]
		elseif frominv then
			me = inventory.items[fromx][fromy][1]
		end
		if not me then return end
		if not metype then metype = getitype(me) end
		local check
		local stack = false
		local amount
		if not toinv and not toeq then
			totile = gettile(tox,toy)
			check = gettopitem(totile)
			local checktype = getitype(check)
			if checktype.blocking then 
				return 
			end
		elseif toeq then
			if toeq == "false" then 
				return 
			end
			check = inventory[toeq][1]
			if not metype[toeq] then 
				return 
			end
		elseif toinv then
			check = inventory.items[tox][toy][1]
			--if check then return end
		end
		if check then
			local checktype = getitype(check)
			if toeq and metype[toeq] and metype.itemid ~= checktype.itemid then
				--swap
				inventory[toeq][1] = me
				me.pos = inventory[toeq]
				additemtypetoinventory(inventory, checktype, check.count)
			elseif not checktype.stackable or not (checktype.itemid == metype.itemid) then
				if (toinv or toeq) then
			 		return
				end
			else
				stack = true
			end
		elseif metype.stackable then 
			stack = true
		end
		if stack then
			if love.keyboard.isDown("1") then
				amount = 1
			elseif love.keyboard.isDown("2") then
				amount = 2
			elseif love.keyboard.isDown("3") then
				amount = 3
			elseif love.keyboard.isDown("4") then
				amount = 4
			elseif love.keyboard.isDown("5") then
				amount = 5
			elseif love.keyboard.isDown("6") then
				amount = 6
			elseif love.keyboard.isDown("7") then
				amount = 7
			elseif love.keyboard.isDown("8") then
				amount = 8
			elseif love.keyboard.isDown("9") then
				amount = 9
			else
				amount = me.count
			end
			amount = math.min(amount,me.count)
		end
		local all = false
		local remove = true
		if stack then
			if check then
				local d = 0
				if amount + check.count > #counts then
					all = true
					d = amount+check.count-#counts
				end
				me.count = me.count-amount+d
			else
				me.count = me.count-amount
			end
			if me.count > 0 then		--you cant remove partially from result
				remove=false
			end
		end
		if remove then
			if not frominv and not fromeq then		--if fromtile then
				fromtile[#fromtile] = nil
			elseif fromeq then
				inventory[fromeq][1] = nil
			elseif frominv then
				inventory.items[fromx][fromy][1] = nil
			end
		end
		if stack then
			if check then
				if all then 
					check.count = #counts
				else
					check.count = check.count+amount
				end
				return
			else
				me = newitem(metype)
				me.count = amount
			end
		end

		if not toinv and not toeq then
			table.insert(totile,me)
			me.pos=totile
		elseif toeq then
			inventory[toeq][1] = me
			me.pos = inventory[toeq]
		elseif toinv then
			inventory.items[tox][toy][1] = me
			me.pos=inventory.items[tox][toy]
		end

		if fromeq or toeq then
			player.armor = calculatearmor(inventory)
		end
	end
end

binocdist = 30

function onclick(v,fromx,fromy,frominv,fromeq)
	if v.dead then
		return
	end
	local inventory = v.inventory
	if v==player then
		binocularing = false 
	end
	if not frominv and not fromeq then
		if v==player and swordtime > 0 then
			return
		end
		local weapon1 = inventory.righthand[1]
		local weapon2 = inventory.lefthand[1]
		local ammo = inventory.ammo[1] or nullitem
		local weapon
		local other
		if weapon1 and (weapon1.itype.attack or weapon1.itype.tool or weapon1.itype.cast) then
			weapon,other=weapon1,weapon2 or nullitem
		elseif weapon2 and (weapon2.itype.attack or weapon2.itype.tool or weapon2.itype.cast) then
			weapon,other=weapon2,weapon1 or nullitem
		end
		local weapontype,othertype
		if weapon then
			weapontype = getitype(weapon)
			othertype = getitype(other)
		else
			weapontype = nullitem.itype
			othertype = nullitem.itype
		end
		if weapontype.cast or weapontype.attack or weapontype.tool then
			local mytopos = checkpathblocking(v, newpos(v.x, v.y), newpos(fromx, fromy))
			fromx,fromy = mytopos.x,mytopos.y
		end
		local tile = gettile(fromx,fromy)
		if tile then
			local near = math.abs(v.x-fromx)<=1 and math.abs(v.y-fromy)<=1
			local top = gettopitem(tile)
			if top.onuse and near then
				top.onuse(v, {x=fromx, y=fromy})
			elseif weapontype.tool then
				if weapontype.onuse then
					weapontype.onuse(v, {x=fromx, y=fromy})
				end
			elseif weapontype.attack then
				if (weapontype.near and near) or not weapontype.near then
					if weapontype.ammoid then
						if not (weapontype.ammoid == ammo.itype.itemid) then 
							return
						else
							removecount(ammo)
						end
						--newmagiceffect(fromx, fromy, weapontype.ammoid, 0.5)
						if weapontype.distanceid then
							newdistanceeffect(player.x, player.y, fromx, fromy, weapontype.distanceid, 0.1)
						end
					else
						--newmagiceffect(fromx, fromy, weapontype.itemid, 0.5)
						if weapontype.distanceid then
							newdistanceeffect(player.x, player.y, fromx, fromy, weapontype.distanceid, 0.1)
						end
					end
					swordtime = 0.5
					if tile.creature then
						tile.creature.life = tile.creature.life - weapontype.attack
						tile.creature.lasthitcreature = v
						if tile.creature.life <= 0 then
							destroycreature(tile.creature)
						end
					end
					if weapontype.removeonuse then
						removecount(weapon)
					end
				end
			elseif weapontype.cast then
				weapontype.cast(v, {x=fromx, y=fromy})
				if weapontype.removeonuse then
					removecount(weapon)
				end
			else
				
			end
		end
	else
		local me
		if fromeq then
			if fromeq == "false" then 
				return 
			end
			me = inventory[fromeq][1]
		else
			me = inventory.items[fromx][fromy][1]
		end
		if not me then 
			return 
		end
		local metype = getitype(me)
		if metype.heal then
			if v.life == v.maxlife then 
				return 
			end
			creatureaddlife(v, metype.heal)
			removecount(me)
		elseif metype.castself then
			metype.castself(v)
			if metype.removeonuse then
				removecount(me)
			end
		end
	end
end

function getitype(i)
	return i.itype or i
end

function worldpostoscreenpos(tx, ty)
	local x,y = tx-player.x+15, ty-player.y+10
	return (x-1)*32, (y-1)*32 
end

function love.draw()
	local inventory = player.inventory
	local centerx,centery = player.x,player.y
	if binocularing then 
		centerx,centery = cx,cy 
	end

	for x=1,width/32 do
		for y=1,height/32 do
		--for x=0,2*CHUNKSIZE-1 do
		--for y=0,CHUNKSIZE-1 do
			local tx,ty = centerx-width/64+x,centery-height/64+y
			local tile = gettile(tx,ty)
			if tile then 
				for z=1,#tile do
					local item = tile[z]
					if item then
						if item.animation then
							local spr = getitype(item).sprite
							local p = (os.clock()%item.animationdelay)/item.animationdelay
							if p < 1 then
								love.graphics.draw(spr[math.ceil(p*#spr)], (x-1)*32, (y-1)*32)
							end
						else
							local spr = getitype(item).sprite
							love.graphics.draw(spr, (x-1)*32, (y-1)*32)
						end
					end
				end
			else
				print("no tile at:",x,y)
			end
			--[[local me = getmagiceffect(tx,ty)
			if me then
				local spr = me.sprite
				love.graphics.draw(spr, (x-1)*32, (y-1)*32)
			end]]
				
		end
	end
	

	for x=1,#magiceffects do
		local me = magiceffects[x]
		if me then
			local sx,sy = worldpostoscreenpos(me.x, me.y)
			if sx >= 0 and sx < 960 and sy >= 0 and sy < 640 then
				if me.animation then
					local time = os.clock()
					local p = (time - me.lasttime)/me.duration
					if p < 1 then
						love.graphics.draw(me.sprite[math.ceil(p*(#me.sprite))], sx, sy)
					end
				else	
					love.graphics.draw(me.sprite, sx, sy)
				end
			end
		end
	end

	for x=1,#distanceeffects do
		local de = distanceeffects[x]
		if de then
			local mytime = os.clock()
			local p = (mytime-de.lasttime)/de.duration
			local tx = (de.tox - de.fromx)*p + de.fromx
			local ty = (de.toy - de.fromy)*p + de.fromy
			local sx,sy = worldpostoscreenpos(tx, ty)
			if sx >= 0 and sx < 960 and sy >= 0 and sy < 640 then
				love.graphics.draw(de.sprite, sx, sy)
			end
		end
	end

	love.graphics.draw(inventoryimg,960,0)
	local invwidth = 10 --items
	local invy = 188
		for x=1,10 do
			for y=1,14 do
				local item = inventory.items[x][y][1]
				if item then
					local itype = getitype(item)
					love.graphics.draw(itype.sprite,960+(x-1)*32, invy+(y-1)*32)
					if itype.stackable then
						love.graphics.draw(counts[item.count],960+(x-1)*32, invy+(y-1)*32)
					end
				end
			end
		end


	for x=1,#inveqs do
		local t = inveqs[x]
		for y,v in pairs(t) do
		local item = inventory[v][1]
		if item then
			local itype = getitype(item)
			love.graphics.draw(itype.sprite,960+inveqx+(x-1)*32,inveqy+(y-1)*32)
			if itype.stackable then
				love.graphics.draw(counts[item.count],960+inveqx+(x-1)*32,inveqy+(y-1)*32)
			end
		end
		end
	end

	
	love.graphics.setColor(0.78,0,0)
	love.graphics.rectangle("fill",960+hpx,hpy,player.maxlife,10)
	love.graphics.setColor(1,0,0)
	love.graphics.rectangle("fill",960+hpx,hpy,player.life,10)
	love.graphics.setColor(1,1,1)
	love.graphics.print("x:"..player.x.." y:"..player.y,0,0)
end

function love.quit()
	for k,v in pairs(chunks) do	--so changes are saved
	for k2,v2 in pairs(v) do
		unloadchunk(k,k2)	
	end
	end
	saveplayer()
	saveplayerinventory()
end