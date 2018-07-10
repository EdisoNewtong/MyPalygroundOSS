include("asset://globalVar.lua")

--bgm = SND_Open("asset://bgm", true)
--seON = SND_Open("asset://se_on")
--seOFF = SND_Open("asset://se_off")
--seDRAG = SND_Open("asset://se_drag")
--tcount = 0
--SND_Play(bgm)
--seDRAG, seOFF, seON = SND_Close(seDRAG, seOFF, seON)


local currentSelect = nil
local resList = {
	mainUI = "asset://SelectTeams.json",
	-- sound mp3
	snd_click1 = "asset://click1",
	snd_click2 = "asset://click2",
	snd_error = "asset://error",
	snd_random = "asset://random",
	-- config file name
	cfgFile = "asset://worldCupCfg.json",
}



local isInRandom = false
local singleNational_random_time = 0.8
local random_time_var = 0
local random_national_idx = 0
local random_teamAry = nil
local label_hints_flag = false

function setControlResAndVisible(controlName,resName,visible)
	local find_node = sysCommand(UI, UI_FORM_UPDATE_NODE, controlName,FORM_NODE_TASK)

	if find_node then
		local prop = TASK_getProperty(find_node);
		prop.visible = visible
		TASK_setProperty(find_node, prop)

		if visible then
			sysCommand(find_node, UI_VARITEM_CHANGE_ASSET, resName)
		end
	end
end


function register32TeamClick()
	for k,v in pairs(globalVar.Team32) do
		local national_name = k
		local func_name = "onbutton_" .. national_name
		_G[func_name] = function(btnId, clickType)
			--syslog("Now You Click : " .. national_name);
			if clickType==3 then
				if isInRandom then
					SND_Play(snd_error)
					showHideHints(true,"Please Wait Random Finished ... ")
					--syslog("Please Wait Random Finished ... ")
					return
				end

				SND_Play(snd_click1)
				setControlResAndVisible("National_Name.flag",v.flag, true)
				setControlResAndVisible("National_Name.name",v.name, true)

				currentSelect = national_name

				local str_Response = tostring(G_Filecfg[currentSelect].response)
				local str_Speed = tostring(G_Filecfg[currentSelect].speed)
				-- Set Label Text OK
				sysCommand(UI, UI_FORM_UPDATE_NODE, "National_Property.label_Respons",FORM_LBL_SET_TEXT, str_Response);
				sysCommand(UI, UI_FORM_UPDATE_NODE, "National_Property.label_Speed",FORM_LBL_SET_TEXT, str_Speed);

			--elseif clickType==10 then
			--	syslog(national_name .. " | LongTap");
			--else
			--	syslog(national_name .. " | Other touch Type = " .. clickType);
			end
		end
	end
end

function setup()
	GL_SetResolution(1136,640)
	-- Load and Open Sound
	snd_click1 = SND_Open(resList.snd_click1)
	snd_click2 = SND_Open(resList.snd_click2)
	snd_error =  SND_Open(resList.snd_error)
	snd_random = SND_Open(resList.snd_random)


	G_Filecfg = CONV_JsonFile2Lua(resList.cfgFile );


	FONT_load("AlexBrush","asset://AlexBrush-Regular-OTF.otf")

	UI = UI_Form(nil,	-- arg[1]:	親となるUIタスクのポインタ
		7000,		-- arg[2]:	基準表示プライオリティ
		0, 0,		-- arg[3,4]:	表示位置
		resList.mainUI,	-- arg[5]:	composit jsonのパス
		true		-- arg[6]:	排他フラグ
	)

	sysCommand(UI, UI_FORM_UPDATE_NODE, "National_Property.label_Respons",FORM_LBL_SET_TEXT, "???");
	sysCommand(UI, UI_FORM_UPDATE_NODE, "National_Property.label_Speed",FORM_LBL_SET_TEXT, "???");
	register32TeamClick()
	clearAllPicked()

	local ScreenW,ScreenH = GL_GetScreenSize();

	pRandomTask = TASK_Generic("randomTeamsAnimation", "killRandomTeamTask", "randomTask");
	pHinsTask = TASK_Generic("hitsAnimation", "killHintsTask", "hintsTextTask");
	
	p_hints_Label = UI_Label(
							nil, 			-- <parent pointer>, 
							8000, 			-- <order>, 
							ScreenW/2 - 260,ScreenH - 60,		-- <x>, <y>,
                            0xFF, 0xFF0000,	-- <alpha>, <rgb>, 
							"AlexBrush",	-- "<font name>", 
							32,				-- <font size>, 
							"Hello World!"	-- "<text string>"
						)
	showHideHints(false)
	TASK_StageOnly(UI)
end

function onbutton_Pick(btnName,clickType,arg,flag)
	-- 1 : PRESS
	-- 2 : RELEASE
	-- 3 : CLICK
	--
	--CKLBUIForm.cpp
	--
	if clickType==3 then
		--syslog("onbutton_Pick")
		if isInRandom and flag~="randomFlag" then
			SND_Play(snd_error)
			syslog("Please Wait Random Finished ... ")
			showHideHints(true,"Please Wait Random Finished ... ")
			return
		end

		if not currentSelect then
			SND_Play(snd_error)
			syslog("Please Select at least 1 national")
			showHideHints(true,"Please Select at least 1 national");
			return
		end

		--local groupid = inWhichGroup(currentSelect)
		--if not groupid then
		--	syslog("Can't Find <" .. currentSelect .. "> in group [A-H]")
		--else
		--	local checkbox_name = groupid .. "." .. "Check_" .. currentSelect
		--	sysCommand(UI, UI_FORM_UPDATE_NODE, checkbox_name, FORM_NODE_VISIBLE, true)
		--end

		---[[
		local isallpicked,notpicked_idx = isAllPicked()
		if isallpicked then
			SND_Play(snd_error)
			showHideHints(true,"All 6 national Picked , Do Nothing");
			--syslog("All 6 national Picked , Do Nothing")
		else
			local isnation_picked = hasNationalPicked(currentSelect)
			if isnation_picked then
				SND_Play(snd_error)
				--syslog("National <" .. currentSelect .. ">  is Picked")
				showHideHints(true,"National <" .. currentSelect .. ">  is Picked")
			else
				local groupid = inWhichGroup(currentSelect)
				if not groupid then
					syslog("Can't Find <" .. currentSelect .. "> in group [A-H]")
				else
					SND_Play(snd_click2)
					-- Set UI
					-- 1. set flag
					setControlResAndVisible("national_" .. notpicked_idx, globalVar.Team32[currentSelect].flag ,true)
					-- 2. set checkbox
					local checkbox_name = groupid .. "." .. "Check_" .. currentSelect
					sysCommand(UI, UI_FORM_UPDATE_NODE, checkbox_name, FORM_NODE_VISIBLE, true)

					-- Set varible 
					setPicked(notpicked_idx,currentSelect)
				end
			end
		end
		--]]
	end
end

function onbutton_Random(btnName,clickType)
	if clickType==3 then
		--syslog("onbutton_Random")

		if isInRandom then
			SND_Play(snd_error)
			showHideHints(true,"Please Wait Random Finished ... ");
			return
		end

		SND_Play(snd_click2)
		-- Clear All 6
		onbutton_ReSelect("",3)

		-- Start Flag
		isInRandom = true
		random_national_idx = 1
		random_teamAry = copyTableKey(globalVar.Team32)

		--[[
		local teamAry = {}
		for k,v in pairs(globalVar.Team32) do
			teamAry[#teamAry + 1] = k
		end
		for i=1,globalVar.picked_cnt,1 do
			local idx = math.random(#teamAry)
			currentSelect = teamAry[idx]
			onbutton_Pick("",3,nil, false)
			table.remove(teamAry,idx)
		end

		currentSelect = nil
		--]]
	end
end

function onbutton_ReSelect(btnName,clickType)
	if clickType==3 then
		if isInRandom then
			--syslog("Please Wait Random Finished ... ")
			SND_Play(snd_error)
			showHideHints(true,"Please Wait Random Finished ... ");
			return
		end

		SND_Play(snd_click2)
		--syslog("onbutton_ReSelect")
		-- Clear UI
		-- Clear greenField Icon
		for i=1,globalVar.picked_cnt,1 do
			setControlResAndVisible("national_" .. i, "" ,false)
		end

		-- Clear National_Flag && Name
		setControlResAndVisible("National_Name.flag","", false)
		setControlResAndVisible("National_Name.name","", false)

		-- Clear All CheckBox
		for k,v in pairs(globalVar.Team32) do
			local national_name = k
			local groupid = inWhichGroup(national_name)
			if groupid then
				local checkbox_name = groupid .. "." .. "Check_" .. national_name
				sysCommand(UI, UI_FORM_UPDATE_NODE, checkbox_name, FORM_NODE_VISIBLE, false)
			end
		end

		sysCommand(UI, UI_FORM_UPDATE_NODE, "National_Property.label_Respons",FORM_LBL_SET_TEXT, "???");
		sysCommand(UI, UI_FORM_UPDATE_NODE, "National_Property.label_Speed",FORM_LBL_SET_TEXT, "???");

		-- Clear Varible
		currentSelect = nil
		clearAllPicked()
	end
end

function onbutton_Go(btnName,clickType)
	if clickType==3 then
		syslog("onbutton_Go")
		if isInRandom then
			--syslog("Please Wait Random Finished ... ")
			SND_Play(snd_error)
			showHideHints(true,"Please Wait Random Finished ... ");
			return
		end


		local isallpicked,notpicked_idx = isAllPicked()
		if not isallpicked then
			SND_Play(snd_error)
			local notpicked_cnt = globalVar.picked_cnt - notpicked_idx + 1
			--syslog("Please select all 6 Teams , your need  picked other " .. notpicked_cnt .. " Teams")
			showHideHints(true,"Please select all 6 Teams , your need  picked other " .. notpicked_cnt .. " Teams")
		else
			for i=1,globalVar.picked_cnt,1 do
				syslog(i .. ". " .. globalVar.picked6[i])
			end

			SND_Play(snd_click2)
			--syslog("Go to Next Scene")
			showHideHints(false)
			TASK_StageClear()
			sysLoad("asset://WorldCup_Main.lua")
		end
	end
end

function execute(deltaT)
	
end

function leave()
	syslog("Edison Lua Log : --->  In teamSelect.lua   leave()")

	snd_click1, snd_click2,snd_error,snd_random = SND_Close(snd_click1, snd_click2,snd_error,snd_random)
	--seDRAG, seOFF, seON = SND_Close(seDRAG, seOFF, seON)
	TASK_kill(pRandomTask)
	TASK_kill(pHinsTask)
end

function randomTeamsAnimation(pTask, deltaT, key)
	if not isInRandom then
		return
	end

	--syslog("deltaT = " .. deltaT)
	local dt = deltaT / 1000
	random_time_var = random_time_var + dt
	if random_time_var >= singleNational_random_time then

		-- timeout , set National
		local idx = math.random(#random_teamAry)
		currentSelect = random_teamAry[idx]
		onbutton_Pick("",3,nil, "randomFlag")
		table.remove(random_teamAry,idx)
		--setControlResAndVisible("national_" .. random_national_idx,  globalVar.Team32[currentSelect].flag ,true)
		random_time_var = 0
		random_national_idx = random_national_idx + 1

		if random_national_idx>globalVar.picked_cnt then

			SND_Stop(snd_random)
			-- Stop Random
			isInRandom = false
			-- Clear state
			random_time_var = 0
			random_national_idx = 0

			currentSelect = 0
		end
	else
		SND_Play(snd_random)

		-- random_teamAry
		local idx = math.random(#random_teamAry)
		local national_name = random_teamAry[idx]
		setControlResAndVisible("national_" .. random_national_idx,  globalVar.Team32[national_name].flag ,true)
	end
end

function hitsAnimation(pTask, deltaT, key)
	if not label_hints_flag then
		return
	end

	local ScreenW,ScreenH = GL_GetScreenSize();
	local prop = TASK_getProperty(p_hints_Label)
	--prop.visible = true
	prop.y = prop.y - 5
	if prop.y < ScreenH/2 - 20 then
		label_hints_flag = false
		prop.visible = false
	end
	TASK_setProperty(p_hints_Label, prop)	
end

function showHideHints(bVisible, txt)
	local prop = TASK_getProperty(p_hints_Label)
	prop.visible = bVisible
	if bVisible and txt then
		-- Set Hints Flag
		label_hints_flag = true

		local ScreenW,ScreenH = GL_GetScreenSize();
		prop.y = ScreenH - 60
		prop.text = txt
	end
	TASK_setProperty(p_hints_Label, prop)	
end

function killRandomTeamTask(pTask,key)
	pRandomTask = nil
end

function killHintsTask(pTask,key)
	pHinsTask = nil
end
