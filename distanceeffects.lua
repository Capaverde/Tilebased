distanceeffects = {}

function newdistanceeffect(fromx, fromy, tox, toy, id, duration)
	table.insert(distanceeffects, {fromx=fromx, fromy=fromy, tox=tox, toy=toy, sprite=distanceeff[id].sprite, lasttime=os.clock(), duration=duration})
end

function updatedistanceeffects()
	for k,v in pairs(distanceeffects) do
		if v.lasttime + v.duration <= os.clock() then
			distanceeffects[k] = nil
		end
	end
end