
if globalVar==nil then
	--syslog("In if, globalVar.AAABBB = 123 ")
	globalVar = {
		Team32 = {
			-- Group A
			Russia = {}, SaudiArabia = {}, Egypt = {}, Uruguay = {},
			-- Group B
			Portugal = {}, Spain = {}, Morocco = {}, Iran = {},
			-- Group C
			France = {}, Australia = {}, Peru = {}, DenMark = {},
			-- Group D
			Argentina = {}, IsLand = {}, Croatia = {}, Nigeria = {},
			-- Group E
			Brizilia = {}, Swiss = {}, Costarica = {}, Serbia = {},
			-- Group F
			Germany = {}, Mexico = {}, Sweden = {}, Korea = {},
			-- Group G
			Belgium = {}, Panama = {}, Tunisia = {}, England = {},
			-- Group H
			Poland = {}, Senegal = {}, Columbia = {}, Japan = {}
		},
		groupInfo = { 
			groupA = { "Russia", "SaudiArabia", "Egypt",  "Uruguay" },
			groupB = { "Portugal", "Spain", "Morocco", "Iran" },
			groupC = { "France",  "Australia",  "Peru",  "DenMark" },
			groupD = { "Argentina", "IsLand", "Croatia", "Nigeria" }, 
			groupE = { "Brizilia", "Swiss", "Costarica", "Serbia"  },
			groupF = { "Germany", "Mexico", "Sweden", "Korea" },
			groupG = { "Belgium",  "Panama", "Tunisia", "England" },
			groupH = { "Poland", "Senegal", "Columbia", "Japan"  }
		},
		picked_cnt = 6,
		picked6 = { nil,nil,nil,  nil,nil,nil },
		winnerTeam = nil,
		-- 1. France 98 , 2. WaKaKa
		last_Bgm = nil,
	}

	
	-- Set Flags And Name Resource
	for k,v in pairs(globalVar.Team32) do
		local national_name = k
		v["flag"] = "asset://" .. national_name .. ".png.imag"
		v["name"] = "asset://" .. national_name .. "_Name" .. ".png.imag"
	end
else
	--syslog("In else, globalVar != nil")
end

function clearAllPicked()
	if globalVar~=nil then
		for i=1,globalVar.picked_cnt,1 do
			globalVar.picked6[i] = nil
		end
	end
end

function setPicked(idx,nationName)
	if idx>=1 and idx<=globalVar.picked_cnt then
		globalVar.picked6[idx] = nationName
	end
end

function isAllPicked()
	local all_picked,whichNotPicked = true,-1
	for i=1,globalVar.picked_cnt,1 do
		if not globalVar.picked6[i] then
			all_picked = false
			whichNotPicked = i
			break
		end
	end

	return all_picked, whichNotPicked
end

function hasNationalPicked(nationName)
	local isPicked = false
	for i=1,globalVar.picked_cnt,1 do
		local element = globalVar.picked6[i]
		if element~=nil and element==nationName then
			isPicked = true
			break
		end
	end
	return isPicked
end

function inWhichGroup(nationName)
	local retGroupId = nil
	for k,v in pairs(globalVar.groupInfo) do
		local groupId = k
		for i,name in ipairs(v) do
			if name==nationName then
				retGroupId = groupId
				break
			end
		end

		if retGroupId~=nil then
			break
		end
	end

	return retGroupId
end

function copyTable(tb)
	local cloneTb = {}
	if type(tb)~="table" then
		return nil
	end

	for k,v in pairs(tb) do
		local vType = type(v)
		if vType == "table" then
			cloneTb[k] = copyTable(v)
		else
			cloneTb[k] = v
		end
	end

	return cloneTb
end

function copyTableKey(tb)
	local cloneTb = {}
	if type(tb)~="table" then
		return nil
	end

	for k,v in pairs(tb) do
		cloneTb[#cloneTb + 1] = k
	end

	return cloneTb
end
