--head,torso,legs,boots
local list = {"head","torso","legs","boots"}

function calculatearmor(inventory)
	local armor = 0
	for k,s in ipairs(list) do
		local i = inventory[s][1]
		if i then
			local itype = getitype(i)
			if itype.armor then
				armor = armor+itype.armor
			end
		end
	end
	return armor
end