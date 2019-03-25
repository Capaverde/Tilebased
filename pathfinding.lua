direc = {[0]={0,-1},{1,0},{0,1},{-1,0}}


function istileblocked(x,y)
	local tile = gettile(x,y)
	if tile then
		local item = gettopitem(tile)
		if item.blocking then 
			return true
		else
			return false
		end
	else
		return true
	end
end

function heuristic(x,y,x1,y1)
	return math.abs(x-x1)+math.abs(y-y1)
end

function addtolookuptable(lut,x,y,t)
	if not lut[x] then 
		lut[x] = {} 
	end
	lut[x][y] = t
end

function lookup(lut,x,y)
	if not lut[x] then 
		return false 
	end
	return lut[x][y]
end

function openlistsort(a,b) 
	return a.f < b.f 
end

function getpath(x0,y0,x1,y1)
	local openlist = {}
	table.insert(openlist,{x=x0,y=y0,g=0,f=heuristic(x0,y0,x1,y1)})
	local closedlist = {}
	local lookupopen = {}
	local lookupclosed = {}
	local last

	for count=1,100 do	--only 100
		local t = openlist[1]
		if not t then --print("empty openlist",#closedlist) 
			local a = closedlist[#closedlist]
			--print(a.x,a.y,x0,y0,x1,y1)

			return
		end
		for dir=0,3 do			--only orthogonal
			local d = direc[dir]
			local x,y = t.x+d[1],t.y+d[2]
			if x==x1 and y==y1 then 
				--print("found path",x0,y0,x1,y1) 
				last=t break 
			end
			if not lookup(lookupclosed,x,y) then
				if not istileblocked(x,y) then
					if not lookup(lookupopen,x,y) then
						local t2 = {x=x,y=y,parent=t}
						table.insert(openlist,t2)
						addtolookuptable(lookupopen,x,y,t2)
						t2.g=t.g+1
						t2.f=t2.g+heuristic(t2.x,t2.y,x1,y1)
					else
						local t2 = lookup(lookupopen,x,y)
						local g = t.g+1
						if g < t2.g then
							t2.f = t2.f-t2.g+g
							t2.g = g
							t2.parent = t
						end
					end
				end
			end
		end

		if last then 
			break 
		end

		table.insert(closedlist,t)
		addtolookuptable(lookupclosed,t.x,t.y,t)
		table.remove(openlist,1)
		table.sort(openlist,openlistsort)
		--print("openlist.f:",openlist[1].f,openlist[#openlist].f)
	end

	if last then
		--print("lastTTTTT")
		local path = {}
		while true do
			table.insert(path,1,last)
			last = last.parent
			if not last then 
				return path 
			end
		end
	end

end