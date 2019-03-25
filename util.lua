function rangepos(pos1, pos2)
	return math.max(math.abs(pos1.x - pos2.x), math.abs(pos1.y - pos2.y))
end

function newpos(x, y)
	return {x=x, y=y}
end

function sign(x)
	if x == 0 then
		return 0
	end
	return x/math.abs(x)
end