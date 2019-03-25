magiceffects = {}

function newmagiceffect(x,y,id,duration)
	table.insert(magiceffects, {x=x, y=y, animation=magiceff[id].animation, sprite=magiceff[id].sprite, lasttime=os.clock(), duration=duration})
end

function updatemagiceffects()
	for k,v in pairs(magiceffects) do
		if ts*v.lasttime+v.duration <= ts*os.clock() then
			magiceffects[k] = nil
		end
	end
end

--[[function getmagiceffect(x,y)
	if not magiceffects[x] then 
		return nil 
	end
	return magiceffects[x][y]
end]]