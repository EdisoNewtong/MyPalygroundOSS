#提交 <保卫世界杯> 游戏 (类似 躲避球 的游戏)，使用playgroundoss开发。
* **修改了引擎,添加了1个可以获取屏幕分辨率的接口 , GL_GetScreenSize() 返回 width,height   2个数值
* **修改了引擎,添加了一个触摸事件，长按的功能(可能有bug) , 多久时间在同一个点，点击不动算是长按，具体见  Engine/source/SystemTask/CKLBTouchPad.cpp   , 目前设置成 450ms 为长按
* ** RubberBand 有个Bug , 就是加载的图片资源是 旋转180度后的状态 ， 
	可以修改以下 CKLBUIRubberBand.cpp 的代码片段来 fix bug , 
	我能理解 = 0.0f 的意义，因为0.0表示与X正半轴的夹角为0  
	但是旋转矩形的设置有点问题, 所以 RubberBand  实例化后的图形是是倒转180度后的样子

	-- theta = 0.0f;	
	++ theta = M_PI

	// 傾きから回転の角度を得る
	float theta = 0.0f;
	float adx   = (dx > 0.0f) ? dx : -dx;
	float ady   = (dy > 0.0f) ? dy : -dy;
	if(fabs(adx) < 1.0f && fabs(ady) < 1.0f) {
		// fix it   theta = M_PI
		theta = 0.0f;	
	} else {
		theta = (adx > ady) ? atan(ady/adx) : (M_PI / 2 - atan(adx/ady));
	}
	if(dx < 0) { theta = M_PI - theta; }
    if(dy < 0) { theta = -theta;       }


** 获取旋转信息时, prop.rot , 在 set时，需要传入 角度值 ， 在 get时，返回的是 弧度度，用起来不爽
** 吐槽一下，这个引擎没有设置 Node 锚点信息的API, 只能用 Toboggan 工具，对图片资源设置 中心锚点，这一点用起来不方便 , 另外这个锚点也只能设置9个点 ，无法设置其实位置，可能有特殊的需求，旋转不在这9个点的时候，就没法实现


#游戏项目路径
**/playgroundoss/Engine/WorldCup

#游戏最终出包，以及视频展示 路径
**/playgroundoss/OutPut
 WorldCup.apk 为最终Demo的安卓牌的安装包


#游戏项目目录结构说明
* WorldCup/  ------ 游戏根目录
* WorldCup/start.lua------游戏入口
* WorldCup/globalVar.lua ---- 用于定义全局变量，以及 界面之间的变量/信息 的传递与保存
* WorldCup/teamSelect.lua ---- 用于世界杯，选择32支球队中的6支球队参加比赛
* WorldCup/WorldCup_Main.lua ---- 踢球主界面
* WorldCup/winnerTeamShow.lua ---- 比赛结束后，获胜队伍的扮奖界面
**** The Following is Game Core Configure File ******
* WorldCup/worldCupCfg.json  ---- *** 数据配置文件 *** ，用于配置32支球队的数值 , 球场的长宽信息, 世界杯的半径 ， 球的半径 ， 世界杯的移动速度， 球的移动速度， 等信息


#游戏编译和启动
1. 在mac环境下，使用xcode打开项目工程下的 SampleProject.xcodeproj 
2. 把WorldCup/publish 目录整个拖到 工程下的 SampleProject/ProjectResources 下
!!!! 注意 !!!!
如果 WorldCup 下面有子目录，这些所有的子目录，必须以 !!!Folder Reference!!! 的方式进行添加，不然运行时，会路径找不到 资源

#开发心得
1. 学习了安卓的打包过程 ， 在mac下执行 python 脚本 , 项中 -a 表示要打出 apk 包，不加 -a 只编译生成 .so .lib 库
// 目前，设置 compileSdkVersion 18 , 因为下载的 ADT 不带 17 版本的Andriod SDK  ，具体修改 build.gradle 中 android { compileSdkVersion 17 改成 18 } , OK
// 当然在这之前，需要做很多准备工作
// 1. 设置 NDK 和 Andriod-SDK 的路径 到 PATH 环境变量中
// 2. build.py 其实是调用 Java gradle 命令进行打包的，最终打包过程中，需要 调用 aapt 命令，所以需要把 appt 也加入到 PATH 环境变量中 
// 3. aapt <your adt path>/adt-bundle-mac-x86_64-20130917/sdk/build-tools/android-4.3/aapt 
$  ./build.py --rebuild --project SampleProject -a

2. 学习了PlaygroundOSS 游戏引擎的基本框架，以及开发的基础知识
   使用 lua 脚本为主要开发语言 , 以及一些基本的控件
3. 游戏部分，用 UI_SimpleItem + UTIL_IntervalTimer + TASK_Generic 进行基本的逻辑控制

// 吐槽一下第4点，为啥没有 Scene 和 Layer的概念，每次界面切换，
// 如果不调用 Task_kill(xxx) , 之前的 UI_SimpleItem 都在舞台上
// 如果有 scene.close , scene.leave 这样子的，自动清理舞台上已添加的控件，那用起来才方便
4. 游戏中资源的清理用了Task_kill，TASK_StageClear这两个函数。 // 吐槽一下，为啥没有 Scene 和 Layer的概念，每次界面切换， Task_kill

5. 游戏的声音是不带 扩展名的 不要加 .mp3 , 因为 iOS 读取 .mp3 文件 ， Andriod 读取 .ogg 文件 , 另外发现一个小bug问题， iOS 的声音文件的文件名可能是[!!!不!!!]区分大小写字母 , Andriod 下是区分大小写字母的
6. 游戏的字体用的是 .otf  字体文件，为什么没有默认字体， 比如说 arial 字体 ， AlexBrush-Regular-OTF.otf 是圆体的英文字体，不好看 :-(



---------------------------------------------------------------------------

# Playground OSS

This is the 'Playground' game engine and is released in open source under Apache License v2.0.

 * All the needed documentation is in the /Doc folder.
 * Source code are under the /Engine folder.
 * Tool to compile a sample project is under /Tools folder.
 * Sample showing the scripting APIs are available under the /Tutorial folder.

Other folders (CSharpVersion, SampleProject) are more related to prototype features or detailed implementations.

To get started, please read the /Doc/Project.md

The dev team.

## Build Status
[![Build Status](https://travis-ci.org/KLab/PlaygroundOSS.png?branch=master)](https://travis-ci.org/KLab/PlaygroundOSS)


## LICENSE
'Playground OSS' is released under Apache Software License, Version 2.0 (Apache 2.0). Please refer http://www.apache.org/licenses/LICENSE-2.0 file for detail.


---------------------------------------------------------------------------
