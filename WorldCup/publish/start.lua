include("asset://globalVar.lua")

local resFile_List = {
	-- png
	bg = "asset://guardCup.png.imag",
	startGame = "asset://startGame.png.imag",

	snd_click1 = "asset://click1",
	-- Bgm
	bgm1 = "asset://The_Cup_Of_Life",
	bgm2 = "asset://WaKa",
}

--local cnt = 0
blink_flag1 = -1
blink_flag2 = 1


function setup()
	syslog("In start.lua : setup()");
	GL_SetResolution(1136,640)
	
	if not globalVar.last_Bgm then
		globalVar.last_Bgm = math.random(2) -- range from [1,2]
	elseif globalVar.last_Bgm==1 then
		globalVar.last_Bgm = 2
	elseif globalVar.last_Bgm==2 then
		globalVar.last_Bgm = 1
	end

	if snd_bgm then
		snd_bgm	= SND_Close(snd_bgm)
	end

	snd_bgm = SND_Open(globalVar.last_Bgm==1 and resFile_List.bgm1 or resFile_List.bgm2,true) -- true means sound is  BGM

	snd_click1 = SND_Open(resFile_List.snd_click1)
	SND_Play(snd_bgm)
	
	local ScreenW,ScreenH = GL_GetScreenSize();

	local w,h = ASSET_getImageSize(resFile_List.bg);
	bg = UI_SimpleItem(	nil,							-- arg[1]:		親となるUIタスクポインタ
									7000,							-- arg[2]:		表示プライオリティ
									0,0,
									resFile_List.bg
								)
	
	local designW1,designH1 = 1136,640 --ScreenW, ScreenH
	local bg_prop = TASK_getProperty(bg)
	bg_prop.scaleX = designW1 / w
	bg_prop.scaleY = designH1 / h
	TASK_setProperty(bg, bg_prop)

	local wStart,hStart = ASSET_getImageSize(resFile_List.startGame);
	Go_Button = UI_SimpleItem(nil,
				  7001,
				  ScreenW/2 , 640 - hStart + 45,
				  resFile_List.startGame
				  )

	blink_Timer = UTIL_IntervalTimer(
									0, 			--<timerID>
									"StartButtonBlink",--"<callback>" 
									350,		--<interval>
									true		--[ , <repeat> ]
									)


	stopBlink_Timer = nil 
				  
	pScreenCtrl = UI_Control( "onClick", "onDrag")
end

function execute(deltaT)
	--sysLoad("asset://WorldCup_Main.lua")
end

function leave()
	snd_click1 = SND_Close(snd_click1)

	syslog("In start.lua leave, Kill Timer");
	--local timer_prop = TASK_getProperty(blink_Timer)
	--timer_prop.is_repeating = false
	--TASK_setProperty(blink_Timer, timer_prop )

	--blink_Timer = nil


	--TASK_kill(pTask)

	bg = TASK_kill(bg)
	Go_Button = TASK_kill(Go_Button)
	pScreenCtrl = TASK_kill(pScreenCtrl)

	bg = nil
	Go_Button = nil
	pScreenCtrl = nil
	stopBlink_Timer = nil
	--TASK_StageClear()
end

function StartButtonBlink(timer_id)
	if not Go_Button then
		return
	end

	local btn_prop = TASK_getProperty(Go_Button)
	-- Set Alpha
	local dt1 = 25
	btn_prop.alpha = btn_prop.alpha + blink_flag1 * dt1
	if btn_prop.alpha < 140 then
		blink_flag1 = 1
	elseif btn_prop.alpha>=255 then
		blink_flag1 = -1
		--btn_prop.alpha = 
	end

	-- Set Scale
	local dt2 = 0.2
	btn_prop.scaleX = btn_prop.scaleX + blink_flag2 * dt2
	btn_prop.scaleY = btn_prop.scaleY + blink_flag2 * dt2

	if btn_prop.scaleX >= 1.5 then
		blink_flag2 = -1
	elseif btn_prop.scaleX <=1.0 then
		blink_flag2 = 1
	end

	--syslog("alpha = " .. btn_prop.alpha);
	TASK_setProperty(Go_Button,btn_prop)
end


function onClick(x,y)
	--cnt = cnt + 1
	SND_Play(snd_click1)

	-- 如果 立即调用 sysLoad(...) , 将听不到点击屏幕的音效(立即调用了 leave 关闭了音效对象)，所以 用定时器进行延时播放
	--sysLoad("asset://teamSelect.lua")
	---[[
	stopBlink_Timer = UTIL_IntervalTimer(
									1, 			--<timerID>
									"stopBlink",--"<callback>" 
									500,		--<interval>
									false		--[ , <repeat> ]
									)
	--]]
end

function stopBlink(timer_id)
	if not Go_Button then
		return
	end

	local btn_prop = TASK_getProperty(Go_Button)
	btn_prop.alpha = 255
	btn_prop.scaleX = 1.0
	btn_prop.scaleY = 1.0
	TASK_getProperty(Go_Button,btn_prop)

	syslog("Enter Next Scene")
	sysLoad("asset://teamSelect.lua")
end

function onDrag(mode,x,y,mvX,mvY)
end

