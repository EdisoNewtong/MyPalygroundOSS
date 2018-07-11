include("asset://globalVar.lua")

local canClick_flag = false

local resFile_List = {
	pic = "asset://get_cup.png.imag",
	backToBegin = "asset://start.lua",

	-- bgm
	win_effect = "asset://win"
}

function setup()
	local designResoW,designResoH = 1136,640
	GL_SetResolution(designResoW,designResoH)

	snd_win = SND_Open(resFile_List.win_effect)


	pScreenCtrl = UI_Control(
							"onClick",
							"onDrag"
						)
	-- globalVar.winnerTeam
	
	pRaiseTask = TASK_Generic("raiseUpPic", "killraiseUpPic", "raiseTask");

	get_cup_pic = UI_SimpleItem(nil,7000,0,designResoH, resFile_List.pic)
	local w1,h1 = ASSET_getImageSize(resFile_List.pic);
	local designW1,designH1 = designResoW,designResoH
	local get_cup_pic_prop = TASK_getProperty(get_cup_pic)
	get_cup_pic_prop.scaleX = designW1 / w1
	get_cup_pic_prop.scaleY = designH1 / h1
	TASK_setProperty(get_cup_pic, get_cup_pic_prop)
	
	local flag_name = globalVar.Team32[globalVar.winnerTeam].flag
	local flag_nation_name = globalVar.Team32[globalVar.winnerTeam].name

	nation_flag = UI_SimpleItem(get_cup_pic,7001, designW1/2 + 700, designH1/2 - 30 ,flag_name)
	local flag_prop =  TASK_getProperty(nation_flag)
	flag_prop.scaleX = 3.0
	flag_prop.scaleY = 3.0
	TASK_setProperty(nation_flag,flag_prop)

	nation_name = UI_SimpleItem(get_cup_pic,7001, designW1/2 + 700, designH1/2 - 15 ,flag_nation_name)
	local name_prop = TASK_getProperty(nation_name)
	name_prop.scaleX = 3.0
	name_prop.scaleY = 3.0
	TASK_setProperty(nation_name,name_prop)

end

function execute(deltaT)

end

function leave()
	get_cup_pic = TASK_kill(get_cup_pic)
	nation_flag = TASK_kill(nation_flag)
	nation_name = TASK_kill(nation_name)
	pScreenCtrl = TASK_kill(pScreenCtrl)

	--pRaiseTask = nil
end


function raiseUpPic(pTask, deltaT, key)
	--get_cup_pic 
	local get_cup_pic_prop = TASK_getProperty(get_cup_pic)
	get_cup_pic_prop.y = get_cup_pic_prop.y - 20
	TASK_setProperty(get_cup_pic, get_cup_pic_prop)

	if get_cup_pic_prop.y>=(640/2 - 15) then
		SND_Play(snd_win);
	end

	if get_cup_pic_prop.y<=0 then
		--TASK_setProperty(get_cup_pic, get_cup_pic_prop)

		--get_cup_pic = TASK_kill(get_cup_pic)
		--nation_flag = TASK_kill(nation_flag)
		--nation_name = TASK_kill(nation_name)

		--syslog("Now Kill pTask")
		TASK_kill(pTask)
		--return
	end

end


function killraiseUpPic()
	--syslog("In killraiseUpPic");
	canClick_flag = true
	pRaiseTask = nil
end


function onClick(x,y)
	if not canClick_flag then
		return
	end

	--syslog("Do start.lua")
	sysLoad(resFile_List.backToBegin)
end
