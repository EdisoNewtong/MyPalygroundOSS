include("asset://globalVar.lua")

local enterNationalIdx = nil
local timer_cnt = nil
local isStart = false		--true
local cd321_Start = nil

local isBGM_played = false

local resFile_List = {
	-- png
	green_field = "asset://green_field.png.imag",
	world_cup = "asset://world_cup.png.imag",
	foot_ball = "asset://football.png.imag",
	national_flag = "asset://National_Flag.png.imag",
	cup_frame = "asset://world_cupAll.png.imag",
	exp_cry = "asset://exp_cry.png.imag",
	exp_happy = "asset://exp_happy.png.imag",
	heart_icon = "asset://heart_icon.png.imag",

	-- count down
	cd1 = "asset://cd_1.png.imag",
	cd2 = "asset://cd_2.png.imag",
	cd3 = "asset://cd_3.png.imag",
	startGame = "asset://lg_start.png.imag",

	-- cfg json
	cfgFile = "asset://worldCupCfg.json",
	-- UI form
	mainUI = "asset://MainUI.json",

	-- sound
	snd_error = "asset://error",
	snd_failed = "asset://failed",
	snd_env = "asset://field_env",
	snd_kick = "asset://kick",

	-- Bgm
	bgm1 = "asset://The_Cup_Of_Life",
	bgm2 = "asset://WaKa",
}

-- football target destination Array
local targetPtAry = {
	"topLeft",
	"topMiddle",
	"topRight",
	"bottomRight",
	"bottomMiddle", 
	"bottomLeft"
}

local ball_Statu = { stopped = 0, running = 1, }

local ball_Info = {
	status = ball_Statu.stopped,

	-- if status == stopped , set current
	current = "topLeft",
	-- if stopped = running , set from && to
	from = nil,
	to = nil,	-- topMiddle
}


local getPositionNameByIdx = function(idx)
	local posName = nil
	if idx==1 then
		posName = "topLeft"
	elseif idx==2 then
		posName = "topMiddle"
	elseif idx==3 then
		posName = "topRight"
	elseif idx==4 then
		posName = "bottomLeft"
	elseif idx==5 then
		posName = "bottomMiddle"
	elseif idx==6 then
		posName = "bottomRight"
	end
	return posName
end

local getIdxByPositionName = function(name)
	local posIdx = nil
	if name=="topLeft" then
		posIdx = 1
	elseif name=="topMiddle" then
		posIdx = 2
	elseif name=="topRight" then
		posIdx = 3
	elseif name=="bottomLeft" then
		posIdx = 4
	elseif name== "bottomMiddle" then
		posIdx = 5
	elseif name=="bottomRight" then
		posIdx = 6
	end
	return posIdx
end

function setup()
	globalVar.winnerTeam = nil
	national_ui_ary = { }
	national_happy_ary = { }
	
	local designResoW,designResoH = 1136,640
	GL_SetResolution(designResoW,designResoH)

	if snd_bgm then
		snd_bgm = SND_Close(snd_bgm)
		snd_bgm = SND_Open(globalVar.last_Bgm==1 and resFile_List.bgm2 or resFile_List.bgm1, true)
	end
	--
	-- load and open sound
	--
	snd_error = SND_Open(resFile_List.snd_error)
	snd_failed = SND_Open(resFile_List.snd_failed)
	snd_env = SND_Open(resFile_List.snd_env, true)
	snd_kick = SND_Open(resFile_List.snd_kick)

	syslog("Edison WorldCup Log : In WorldCup_Main.lua");

	myBtnForm = UI_Form(nil,	-- arg[1]:	親となるUIタスクのポインタ
		7003,		-- arg[2]:	基準表示プライオリティ
		0, 0,		-- arg[3,4]:	表示位置
		resFile_List.mainUI,	-- arg[5]:	composit jsonのパス
		true		-- arg[6]:	排他フラグ
	)


	G_cfg = CONV_JsonFile2Lua(resFile_List.cfgFile);
	--if G_cfg then
	--	syslog("G_cfg~=nil , G_cfg = " .. type(G_cfg) )
	--	local _www = G_cfg.greenField_w
	--	syslog("_www" .. type(_www))
	--else
	--	syslog("G_cfg=nil");
	--	return
	--end

	local x1,y1 = G_cfg.greenField_x , G_cfg.greenField_y
	local w1,h1 = G_cfg.greenField_w , G_cfg.greenField_h
	x1 = (designResoW - w1) / 2
	--syslog("G_cfg.football_speed = " .. G_cfg.football_speed);
	syslog("G_cfg.cup_step = " .. G_cfg.cup_step)
	G_6ptAry = {
		count = 6,
		topLeft = { x = x1 , y = y1 },					-- 1. left top
		topMiddle = { x = x1 + w1/2, y = y1 },			-- 2. middle top
		topRight = { x = x1 + w1, y = y1 },				-- 3. right top
		bottomRight = { x = x1 + w1, y = y1 + h1 },		-- 4. right bottom 
		bottomMiddle = { x = x1 + w1/2, y = y1 + h1 },	-- 5. middle bottom
		bottomLeft = { x = x1, y = y1 + h1  },			-- 6. left bottom
	}

	national_corner_delta = 30
	nation_offset_flagAry = {
		{ x=-1, y=-1 },
		{ x=0,   y=-1 },
		{ x=1,   y=-1 },
		{ x=-1,   y=1 },
		{ x=0,    y=1 },
		{ x=1,    y=1 },
	}
	---[[
	for i=1,globalVar.picked_cnt,1 do
		local national_name = globalVar.picked6[i]
		local posName = getPositionNameByIdx(i);
		if posName then
			local nation_flag = UI_SimpleItem(nil,7001,G_6ptAry[posName].x + nation_offset_flagAry[i].x * national_corner_delta, G_6ptAry[posName].y + nation_offset_flagAry[i].y * national_corner_delta, globalVar.Team32[national_name].flag);
			local nation_prop = TASK_getProperty(nation_flag)
			nation_prop.scaleX = 1.5
			nation_prop.scaleY = 1.5
			TASK_setProperty(nation_flag, nation_prop)
			national_ui_ary[i] = nation_flag

			local happy_exp = UI_SimpleItem(nil,7002,G_6ptAry[posName].x ,G_6ptAry[posName].y + (i>3 and -55 or 0) , resFile_List.exp_happy);
			local exp_prop = TASK_getProperty(happy_exp)
			exp_prop.visible = false
			exp_prop.scaleX = 0.5
			exp_prop.scaleY = 0.5
			TASK_setProperty(happy_exp, exp_prop)
			national_happy_ary[i] = happy_exp
		end
	end
	--]]

	green_field = UI_SimpleItem(	nil,							-- arg[1]:		親となるUIタスクポインタ
									7000,							-- arg[2]:		表示プライオリティ
									G_6ptAry.topLeft.x, G_6ptAry.topLeft.y,						-- arg[3,4]:	表示位置
									resFile_List.green_field				-- arg[5]:		表示assetのパス
								)
	

	w1,h1 = ASSET_getImageSize(resFile_List.green_field);
	--syslog(string.format("w,h = (%d,%d)",w,h));
	local designW1,designH1 = G_cfg.greenField_w, G_cfg.greenField_h
	local green_prop = TASK_getProperty(green_field)
	green_prop.scaleX = designW1 / w1
	green_prop.scaleY = designH1 / h1
	TASK_setProperty(green_field, green_prop)



	world_cup = UI_SimpleItem( nil,
									 7001,
									 G_6ptAry.topMiddle.x, G_6ptAry.topMiddle.y + G_cfg.greenField_h/ 2,
									 resFile_List.cup_frame
									)
	local w2,h2 = ASSET_getImageSize(resFile_List.cup_frame)
	local designW2,designH2 = G_cfg.worldcup_radius*2 , G_cfg.worldcup_radius*2
	local worldcupframe_prop = TASK_getProperty(world_cup)
	worldcupframe_prop.scaleX = designW2 / w2
	worldcupframe_prop.scaleY = designH2 / h2
	TASK_setProperty(world_cup, worldcupframe_prop);

	exp_cry_icon = UI_SimpleItem(world_cup,
								 7002,
								 designW2 / 2, -designH2 / 2 - 15,
								 resFile_List.exp_cry
								 )
	local exp_prop = TASK_getProperty(exp_cry_icon)
	exp_prop.visible = false
	exp_prop.scaleX = 0.48
	exp_prop.scaleY = 0.48
	TASK_setProperty(exp_cry_icon, exp_prop)



	foot_ball = UI_SimpleItem(nil,
							  7002,
							  G_6ptAry.topLeft.x, G_6ptAry.topLeft.y,
							  --150 - designW3/2,70 - designH3/2,
							  resFile_List.foot_ball
							 );
	local designW3,designH3 = G_cfg.football_radius * 2 , G_cfg.football_radius * 2
	local w3,h3 = ASSET_getImageSize(resFile_List.foot_ball);
	local football_prop = TASK_getProperty(foot_ball);
	football_prop.x = G_6ptAry.topMiddle.x
	football_prop.y = (G_6ptAry.topMiddle.y + G_6ptAry.bottomMiddle.y) / 2
	football_prop.scaleX = designW3 / w3; 
	football_prop.scaleY = designH3 / h3;
	football_prop.visible = false
	TASK_setProperty(foot_ball, football_prop);

	
	cd_ui = { }
	cd_ui[1] = UI_SimpleItem(nil,7004, G_6ptAry.topMiddle.x, (G_6ptAry.topMiddle.y + G_6ptAry.bottomMiddle.y) / 2, resFile_List.cd1)
	cd_ui[2] = UI_SimpleItem(nil,7004, G_6ptAry.topMiddle.x, (G_6ptAry.topMiddle.y + G_6ptAry.bottomMiddle.y) / 2, resFile_List.cd2)
	cd_ui[3] = UI_SimpleItem(nil,7004, G_6ptAry.topMiddle.x, (G_6ptAry.topMiddle.y + G_6ptAry.bottomMiddle.y) / 2, resFile_List.cd3)
	cd_ui.start = UI_SimpleItem(nil,7004, G_6ptAry.topMiddle.x, (G_6ptAry.topMiddle.y + G_6ptAry.bottomMiddle.y) / 2, resFile_List.startGame)
	for k,v in pairs(cd_ui) do
		local item_prop = TASK_getProperty(v);
		item_prop.visible = false
		item_prop.scaleX = 3.0
		item_prop.scaleY = 3.0
		TASK_setProperty(v, item_prop)
	end


	--sysCommand(foot_ball ,UI_GENERIC_SET_NAME, "FFTTBB");
	heart_icon = UI_SimpleItem(nil,
							   7002,
							   0,0,
							   resFile_List.heart_icon
							   )
	showHideHeartIcon(false)

	pHitTask = TASK_Generic("ballCupHitListener", "killHitListener", "HitListenTask");

	--
	-- Play Sound Env
	--
	
	SND_Play(snd_env)
	-- 1. Play National Enter GreenField Animation and footBall Animation
	enterGreenFieldTimer = UTIL_IntervalTimer(2,"enterGreenField",200,true)
	enterNationalIdx = 1

	-- 2.   3->2->1  Ready Go
	-- countDownTimer = UTIL_IntervalTimer(3,"countDownAndStart",200,true)
	--
	-- 3. When ball is hited
	-- delayTimer = UTIL_IntervalTimer(4,"countDownAndStart",3000,false)

	count = 0;
end


function execute(deltaT)
	if not isStart then
		return
	end

	local w,h = GL_GetScreenSize();
	--syslog("Edison Log , w = " .. w);
	--syslog("Edison Log , h = " .. h);


	-- 传入的deltaT 是以毫秒为单位的，所以如果在转化成秒要 除以 1000
	local dt = deltaT / 1000.0
	
	--local breturn = true
	--if breturn then
	--	return
	--end

	
	--count = count + 1

	if ball_Info.status == ball_Statu.stopped  then
		-- Football Animation Timer
		if not decide_Timer then
			-- Create a Decide Timer and Run the Timer
			local idx = getIdxByPositionName(ball_Info.current)

			if idx>=1 and idx<=globalVar.picked_cnt then
				local national_name = globalVar.picked6[idx]

				local decide_time = G_cfg[national_name].response
				if not decide_time then
					syslog("Not Find <" .. national_name .. "> , Use Default response ")
					decide_time = G_cfg.decide_time
				end
				decide_Timer = UTIL_IntervalTimer(
												0, 			--<timerID>
												"football_decide",--"<callback>" 
												decide_time,		--<interval>
												false		--[ , <repeat> ]
											)
			end
		end
	else 
		-- Football is Running
		-- Direction  : from --> to
		local football_prop = TASK_getProperty(foot_ball);

		if ball_Info.from~=nil and ball_Info.to~=nil then

			local current_pos = { x = football_prop.x, y = football_prop.y };
			local from_vec = { x = G_6ptAry[ball_Info.from].x, y = G_6ptAry[ball_Info.from].y };
			local to_vec = { x = G_6ptAry[ball_Info.to].x, y = G_6ptAry[ball_Info.to].y };

			local moveVec = makeVector( current_pos, to_vec);
			local targetVec = makeVector( from_vec, to_vec);

			
			---[[
			if moveVec.len < 1e-5 then
				-- ********** Core Code : Set Ball Statu **********
				-- 正正好好 到达终点
				syslog("<Directly Wanderful Match>")
				ball_Info.status = ball_Statu.stopped
				showHideHeartIcon(false)
				-- Next frame will Creat a timer to decide ball's next destination
				ball_Info.current = ball_Info.to
				ball_Info.from = nil
				ball_Info.to = nil
			else
				-- 求 当前运行方向 与 目标方向 2个向量的夹角
				local cos_Angle = (moveVec.x * targetVec.x + moveVec.y * targetVec.y) / (moveVec.len * targetVec.len);

				-- 夹角为钝角时，运行方向已经超出了 终点
				if cos_Angle <=0 then
					-- ********** Core Code : Set Ball Statu **********
					--syslog("Edison Log : Now : <Stopping> , cos_Angle <=0");
					ball_Info.status = ball_Statu.stopped
					showHideHeartIcon(false)
					-- Next frame will Creat a timer to decide ball's next destination
					ball_Info.current = ball_Info.to
					ball_Info.from = nil
					ball_Info.to = nil
				else

					-- Set Rotation  &&   football_speed
					local ball_speed = 250;
					local idx = getIdxByPositionName(ball_Info.from)
					if not idx then
						return
					end

					local speed_name = ball_Info.from .. "_speed"
					local national_name = globalVar.picked6[idx]
					local cfg_speed = G_cfg[national_name].speed
					if not cfg_speed then
						syslog("Not Find <" .. national_name .. "> , Use Default football Speed")
						ball_speed = G_cfg[speed_name]~=0 and G_cfg[speed_name] or ball_speed
					else
						ball_speed = cfg_speed
					end
					--syslog("speed_name = " .. speed_name)
					--ball_speed = G_cfg[speed_name]~=0 and G_cfg[speed_name] or ball_speed
					--syslog(string.format("@%s , speed_name = %d" , ball_Info.from , ball_speed) )
					local d_theta = 180 * dt * ball_speed / (math.pi * G_cfg.football_radius / 2);
					football_prop.rot = football_prop.rot * 180.0 / math.pi + d_theta;

					local delta_len =  ball_speed * dt
					if moveVec.len > delta_len then
						-- Normal Move
						football_prop.x = football_prop.x + moveVec.cos * ball_speed * dt
						football_prop.y = football_prop.y + moveVec.sin * ball_speed * dt
						TASK_setProperty(foot_ball, football_prop);
					else
						football_prop.x = to_vec.x
						football_prop.y = to_vec.y
						TASK_setProperty(foot_ball, football_prop);

						--syslog("Edison Log :  Now : <Stopping> , Reach Destination");
						ball_Info.status = ball_Statu.stopped

						showHideHeartIcon(false)
						-- Next frame will Creat a timer to decide ball's next destination
						ball_Info.current = ball_Info.to
						ball_Info.from = nil
						ball_Info.to = nil
					end
				end
			end
			--]]
		end
		
	end
end


function leave()
end

-- pt1 : from point
-- pt2 : to   point
function makeVector(pt1,pt2)
	local ret_vec = { x = 0, y = 0, len = 0, sin = 0, cos = 0 };
	ret_vec.x = pt2.x - pt1.x;
	ret_vec.y = pt2.y - pt1.y;
	ret_vec.len = math.sqrt( math.pow(ret_vec.x,2) + math.pow(ret_vec.y ,2) );
	ret_vec.sin = ret_vec.y / ret_vec.len;
	ret_vec.cos = ret_vec.x / ret_vec.len;
	
	return ret_vec;
end

function football_decide(timer_id)
	if not isStart then
		return
	end

	--count = count + 1
	local dest_count = 0
	if G_cfg.same_direction_pass then
		dest_count = G_6ptAry.count - 1
	else
		dest_count = G_6ptAry.count / 2
	end

	local removeCurrentPtAry = {}

	if G_cfg.same_direction_pass then
		for i=1,#targetPtAry,1 do
			local name = targetPtAry[i];
			if name~=ball_Info.current then
				removeCurrentPtAry[#removeCurrentPtAry+1] = name;
			end
		end
	else
		local isTop = string.find(ball_Info.current,"top")~=nil
		if isTop then
			removeCurrentPtAry[#removeCurrentPtAry+1] = "bottomRight"
			removeCurrentPtAry[#removeCurrentPtAry+1] = "bottomMiddle"
			removeCurrentPtAry[#removeCurrentPtAry+1] = "bottomLeft"
		else
			-- @ Bottom
			removeCurrentPtAry[#removeCurrentPtAry+1] = "topLeft"
			removeCurrentPtAry[#removeCurrentPtAry+1] = "topMiddle"
			removeCurrentPtAry[#removeCurrentPtAry+1] = "topRight"
		end
	end



	local removeAry_len = #removeCurrentPtAry;
	if dest_count~=removeAry_len then
		--syslog("==================================================");
		--syslog("Edison Log :  Logic Error dest_count~=removeAry_len , removeAry_len = " .. removeAry_len);
		--syslog("==================================================");
		return
	end
	
	
	-- ********** Core Code : Set Ball Statu **********
	local len = #removeCurrentPtAry
	local random_idx = 0
	while true do
		random_idx = math.random(len);	-- return an index range  [ 1, len ] , include 1 , include len
		if random_idx>=1 and random_idx<=len then
			break
		end
	end
	ball_Info.from = ball_Info.current;
	ball_Info.to = removeCurrentPtAry[random_idx]

	local heart_icon_prop = TASK_getProperty(heart_icon)
	heart_icon_prop.visible = true
	heart_icon_prop.x =  G_6ptAry[ball_Info.to].x
	heart_icon_prop.y =  G_6ptAry[ball_Info.to].y
	TASK_setProperty(heart_icon, heart_icon_prop)

	if not heart_animationTimer then
		heart_animationTimer = UTIL_IntervalTimer(
											1, 			--<timerID>
											"Hide_Heart_func",--"<callback>" 
											G_cfg.show_target_animation,		--<interval>
											false		--[ , <repeat> ]
										)
	end
	
	-- Show Heart Icon

	--if ball_Info.from=="topLeft" then
	--	ball_Info.to = "bottomMiddle"
	--elseif ball_Info.from=="bottomMiddle" then
	--	if test_flag==0 then
	--		ball_Info.to = "topRight"
	--		test_flag = 1
	--	else
	--		test_flag = 0
	--		ball_Info.to = "topLeft"
	--	end
	--elseif ball_Info.from=="topRight" then
	--	ball_Info.to = "bottomMiddle"
	--end

	
	--syslog("Edison Log :  Now : <Running> ");
	--syslog("Edison Log :  Now : Show HeartIcon");
	--ball_Info.status = ball_Statu.running
	--decide_Timer = nil
end



function onLeftBtnClick(arg1,arg2,arg3)
	-- arg2 : 1:Push ,   2:Release   3.Click		10. LongTap
	--syslog("arg2 = " .. arg2)
	--syslog("on LeftBtn Click")
	if not isStart then
		SND_Play(snd_error)
		return
	end

	---[[
	if arg2==1 or arg2==2 or arg2==3 or arg2==10 then
		local worldcupframe_prop = TASK_getProperty(world_cup)
		local will_move_toX = worldcupframe_prop.x - G_cfg.cup_step;
		if will_move_toX <= (G_6ptAry.topLeft.x) then
			return
		end
		worldcupframe_prop.x = will_move_toX
		--syslog("Move Left --->");
		TASK_setProperty(world_cup, worldcupframe_prop);
	end
	--]]
end


function onRightBtnClick(arg1,arg2)
	if not isStart then
		SND_Play(snd_error)
		return
	end

	if arg2==1 or arg2==2 or arg2==3 or arg2==10 then
		local worldcupframe_prop = TASK_getProperty(world_cup)
		local will_move_toX = worldcupframe_prop.x + G_cfg.cup_step;
		--G_cfg.worldcup_radius*2
		if will_move_toX >= (G_6ptAry.topRight.x) then
			return
		end
		worldcupframe_prop.x = will_move_toX
		--syslog("Move Right <---");
		TASK_setProperty(world_cup, worldcupframe_prop);
	end
end


-- function execute_char2(pTask, deltaT, key)
function ballCupHitListener(pTask, deltaT, key)
	if not isStart then
		return
	end


	local football_prop = TASK_getProperty(foot_ball)
	-- 因为球的中心点被设置在了 图片(球)的中心，而!!!不是!!! 左上角的点
	local football_centerPt = { x = football_prop.x, y = football_prop.y }
	local r_ball = G_cfg.football_radius

	local worldcupframe_prop = TASK_getProperty(world_cup)
	local frame_centerPt = { x = worldcupframe_prop.x  , y = worldcupframe_prop.y  };
	local r_cup = G_cfg.worldcup_radius;

	local vec = makeVector(football_centerPt,frame_centerPt);
	local is_InterSection = false
	if vec.len < 1e-5 or vec.len <= (r_ball+r_cup) then
		-- 2 circle is hit
		is_InterSection = true
	else
		is_InterSection = false
	end

	if is_InterSection then
		SND_Play( snd_failed )

		--gameover
		--
		-- Game Over
		--
		isStart = false

		--
		-- ball_Info.from   Win  the World-Cup
		--
		local idx = getIdxByPositionName(ball_Info.from)
		if idx then
			local national_name = globalVar.picked6[idx]
			globalVar.winnerTeam = national_name

			local exp_Happy = national_happy_ary[idx];
			if exp_Happy then
				local exp_prop = TASK_getProperty(exp_Happy)
				exp_prop.visible = true
				TASK_setProperty(exp_Happy, exp_prop)
			end
			

			local exp_prop = TASK_getProperty(exp_cry_icon)
			exp_prop.visible = true
			TASK_setProperty(exp_cry_icon, exp_prop)

			delayTimer = UTIL_IntervalTimer(4,"delayShow",3000,false)
			--
			-- Do Clear Work
			--
			--clearWork()
			
			return
		end

	end

end



function Hide_Heart_func()
	-- Ball Start to Run
	ball_Info.status = ball_Statu.running

	-- Play Ball Kick Sound
	SND_Play(snd_kick)
	-- Set Timer Varible  as nil
	decide_Timer = nil
	heart_animationTimer = nil
end

function showHideHeartIcon(bFlag)
	local heart_icon_prop = TASK_getProperty(heart_icon)
	heart_icon_prop.visible = bFlag
	TASK_setProperty(heart_icon, heart_icon_prop)
end

function enterGreenField(timerId)
	local step = 4.5
	local football_step = 15
	if not enterNationalIdx then
		return
	end

	local nation_flag = national_ui_ary[enterNationalIdx]
	if nation_flag then
		local nation_prop = TASK_getProperty(nation_flag)
		nation_prop.x = nation_prop.x + nation_offset_flagAry[enterNationalIdx].x * (-1) * step
		nation_prop.y = nation_prop.y + nation_offset_flagAry[enterNationalIdx].y * (-1) * step
		if enterNationalIdx==1 then
			if nation_prop.x>=G_6ptAry.topLeft.x then
				nation_prop.x = G_6ptAry.topLeft.x 
			end
			if nation_prop.y>=G_6ptAry.topLeft.y then
				nation_prop.y = G_6ptAry.topLeft.y
			end

			if nation_prop.x==G_6ptAry.topLeft.x and nation_prop.y==G_6ptAry.topLeft.y then
				-- Do Next Enter
				enterNationalIdx = 2
			end
		elseif enterNationalIdx==2 then
			if nation_prop.y>=G_6ptAry.topMiddle.y then
				nation_prop.y = G_6ptAry.topMiddle.y
			end

			if nation_prop.y==G_6ptAry.topMiddle.y then
				-- Do Next Enter
				enterNationalIdx = 3
			end
		elseif enterNationalIdx==3 then
			if nation_prop.x<=G_6ptAry.topRight.x then
				nation_prop.x = G_6ptAry.topRight.x 
			end
			if nation_prop.y>=G_6ptAry.topRight.y then
				nation_prop.y = G_6ptAry.topRight.y
			end

			if nation_prop.x==G_6ptAry.topRight.x and nation_prop.y==G_6ptAry.topRight.y then
				-- Do Next Enter
				enterNationalIdx = 4
			end
		elseif enterNationalIdx==4 then
			if nation_prop.x>=G_6ptAry.bottomLeft.x then
				nation_prop.x = G_6ptAry.bottomLeft.x 
			end
			if nation_prop.y<=G_6ptAry.bottomLeft.y then
				nation_prop.y = G_6ptAry.bottomLeft.y
			end

			if nation_prop.x==G_6ptAry.bottomLeft.x and nation_prop.y==G_6ptAry.bottomLeft.y then
				-- Do Next Enter
				enterNationalIdx = 5
			end
		elseif enterNationalIdx==5 then
			if nation_prop.y<=G_6ptAry.bottomMiddle.y then
				nation_prop.y = G_6ptAry.bottomMiddle.y 
			end

			if nation_prop.y==G_6ptAry.bottomMiddle.y then
				-- Do Next Enter
				enterNationalIdx = 6
			end
		elseif enterNationalIdx==6 then
			if nation_prop.x<=G_6ptAry.bottomRight.x then
				nation_prop.x = G_6ptAry.bottomRight.x 
			end

			if nation_prop.y<=G_6ptAry.bottomRight.y then
				nation_prop.y = G_6ptAry.bottomRight.y
			end

			if nation_prop.x==G_6ptAry.bottomRight.x and nation_prop.y==G_6ptAry.bottomRight.y then
				-- Do Next Enter
				enterNationalIdx = 7
			end
		end
		TASK_setProperty(nation_flag, nation_prop)
	end

	if enterNationalIdx==7 then
		if not isBGM_played then
			SND_Play(snd_bgm)
			isBGM_played = true
		end
		-- Show Football and Start the Game
		local centerPt = { x = G_6ptAry.topMiddle.x, y = (G_6ptAry.topMiddle.y + G_6ptAry.bottomMiddle.y) / 2 }
		local moveVec = makeVector(centerPt, G_6ptAry.topLeft );
		
		local football_prop = TASK_getProperty(foot_ball);
		football_prop.visible = true
		football_prop.x = football_prop.x + moveVec.cos * football_step
		football_prop.y = football_prop.y + moveVec.sin * football_step

		if football_prop.x<=G_6ptAry.topLeft.x then
			football_prop.x = G_6ptAry.topLeft.x 
		end

		if football_prop.y<=G_6ptAry.topLeft.y then
			football_prop.y = G_6ptAry.topLeft.y 
		end

		if football_prop.x==G_6ptAry.topLeft.x and football_prop.y==G_6ptAry.topLeft.y then
			TASK_setProperty(foot_ball, football_prop);

			-- Start 3-2-1 CountDown
			countDownTimer = UTIL_IntervalTimer(3,"countDownAndStart",200,true)
			cd321_Start = 3
			timer_cnt = 0

			local cd_ui_item = cd_ui[cd321_Start]
			local item_prop = TASK_getProperty(cd_ui_item);
			item_prop.visible = true
			TASK_setProperty(cd_ui_item, item_prop)

			-- Kill Self Timer
			enterNationalIdx = nil
			local timer_prop = TASK_getProperty(enterGreenFieldTimer)
			timer_prop.is_repeating = false
			TASK_setProperty(enterGreenFieldTimer, timer_prop)
			enterGreenFieldTimer = nil
			return

			--TASK_setProperty(foot_ball, football_prop);
			---- Kill Timer

			--isStart = true
		end
		TASK_setProperty(foot_ball, football_prop);
	end
end

function countDownAndStart(timerId)
	if not cd321_Start then
		return
	end

	timer_cnt = timer_cnt + 200
	if timer_cnt==1000 then
		local cd_ui_item = cd_ui[cd321_Start]
		if cd_ui_item then
			local item_prop = TASK_getProperty(cd_ui_item);
			item_prop.visible = false
			TASK_setProperty(cd_ui_item, item_prop)
		end

		cd321_Start = cd321_Start - 1
		if cd321_Start==0 then
			local cd_ui_item = cd_ui.start
			if cd_ui_item then
				local item_prop = TASK_getProperty(cd_ui_item);
				item_prop.visible = true
				TASK_setProperty(cd_ui_item, item_prop)
			end
		end

		if cd321_Start==-1 then
			-- Really Start the Game
			local item_prop = TASK_getProperty(cd_ui[1]);
			item_prop.visible = false
			TASK_setProperty(cd_ui[1], item_prop)
			item_prop = TASK_getProperty(cd_ui[2]);
			item_prop.visible = false
			TASK_setProperty(cd_ui[2], item_prop)
			item_prop = TASK_getProperty(cd_ui[3]);
			item_prop.visible = false
			TASK_setProperty(cd_ui[3], item_prop)
			item_prop = TASK_getProperty(cd_ui.start);
			item_prop.visible = false
			TASK_setProperty(cd_ui.start, item_prop)

			isStart = true

			cd321_Start = 3

			local timer_prop = TASK_getProperty(countDownTimer)
			timer_prop.is_repeating = false
			TASK_setProperty(countDownTimer,  timer_prop)
			timer_cnt = 0
			return
		end

		timer_cnt = 0
	end

	if cd321_Start>0 then
		-- Scale Changed     3.0 --> 1.0
		local cd_ui_item = cd_ui[cd321_Start]
		if cd_ui_item then
			local item_prop = TASK_getProperty(cd_ui_item);
			item_prop.visible = true
			item_prop.scaleX = item_prop.scaleX - (3.0-1.0)/ (1000/200)
			item_prop.scaleY = item_prop.scaleX - (3.0-1.0)/ (1000/200)
			TASK_setProperty(cd_ui_item, item_prop)
		end
	else
		-- cd321_Start <=0
		--
		local cd_ui_item = cd_ui.start
		if cd_ui_item then
			local item_prop = TASK_getProperty(cd_ui_item);
			item_prop.visible = true
			item_prop.scaleX = item_prop.scaleX - (3.0-1.0)/ (1000/200)
			item_prop.scaleY = item_prop.scaleX - (3.0-1.0)/ (1000/200)
			TASK_setProperty(cd_ui_item, item_prop)
		end
	end
end

function killHitListener(pTask,key)
	pHitTask = nil
end


function clearWork()
	syslog("In clearWork()")
	-- Clear Timer
	if enterGreenFieldTimer then
		syslog("clear Timer enterGreenFieldTimer")
		local timer_prop = TASK_getProperty(enterGreenFieldTimer)
		timer_prop.is_repeating = false
		TASK_setProperty(enterGreenFieldTimer, timer_prop)
		
		enterGreenFieldTimer = nil
	end
	if  decide_Timer then
		syslog("clear Timer decide_Timer")
		local timer_prop = TASK_getProperty(decide_Timer)
		timer_prop.is_repeating = false
		TASK_setProperty(decide_Timer, timer_prop)

		decide_Timer = nil
	end

	if heart_animationTimer then
		syslog("clear Timer heart_animationTimer")
		local timer_prop = TASK_getProperty(heart_animationTimer)
		timer_prop.is_repeating = false
		TASK_setProperty(heart_animationTimer, timer_prop)
		heart_animationTimer = nil
	end

	--Clear TASK_Generic
	if pHitTask then
		syslog("clear pHitTask")
		TASK_kill(pHitTask)
		--pHitTask = nil
	end

	syslog("Now Clear UI")
	-- Clear UI
	-- bg = TASK_kill(bg)
	-- Go_Button = TASK_kill(Go_Button)
	-- pScreenCtrl = TASK_kill(pScreenCtrl)
	for i=1,globalVar.picked_cnt,1 do
		if national_ui_ary[i] then
			national_ui_ary[i] = TASK_kill(national_ui_ary[i])
			national_happy_ary[i] = TASK_kill(national_happy_ary[i])
		end
	end

	green_field = TASK_kill(green_field)
	exp_cry_icon = TASK_kill(exp_cry_icon)
	world_cup = TASK_kill(world_cup)
	foot_ball = TASK_kill(foot_ball)

	cd_ui[1] = TASK_kill(cd_ui[1])
	cd_ui[2] = TASK_kill(cd_ui[2])
	cd_ui[3] = TASK_kill(cd_ui[3])
	cd_ui.start = TASK_kill(cd_ui.start)
	heart_icon = TASK_kill(heart_icon)

	snd_error = SND_Close(snd_error)
	snd_failed = SND_Close(snd_failed)
	snd_env = SND_Close(snd_env)
	snd_kick = SND_Close(snd_kick)

	myBtnForm = TASK_kill(myBtnForm)

	-- clear UI 2 UI button
	TASK_StageClear()
	--myBtnForm
	sysLoad("asset://winnerTeamShow.lua")
end

function delayShow(timerId)
	clearWork()
end
