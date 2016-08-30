//
//  update.h
//  Letapm
//
//  Created by Gang.Wang on 10/19/15.
//  Copyright © 2015 Gang.Wang. All rights reserved.
//

#ifndef update_h
#define update_h

////////////////////////////////////      更新日志     /////////////////////////////////

/*
 @brief:0.1.7更新内容：
 uninstallletapm时的崩溃
 */
#define LETAPM_VERSION  @"0.1.7"


/*
 @brief:0.1.6更新内容：
    正式发布电量功能 调整电量获取在主线程调用
 */
//#define LETAPM_VERSION  @"0.1.6"


/*
 @brief:0.1.5更新内容：
 获取运营商
 */
//#define LETAPM_VERSION  @"0.1.5"

/*
 @brief:0.1.4更新内容：
 self.asyncSocket writeData 调用间隔0.5s 会造成cpu较高，调整为1s， 后定位到真实原因是sleep 导致的,已修复
 */
//#define LETAPM_VERSION  @"0.1.4"


/*
 @brief:0.1.3更新内容：
 支持battery收集的功能
 */
//#define LETAPM_VERSION  @"0.1.3"


/*
 @brief:0.1.2更新内容：
 在一台iPod上获取时间会不正确 改为nsdate获取函数执行时间
 */
//#define LETAPM_VERSION  @"0.1.2"

/*
 @brief:0.1.1更新内容：
 修复nsdata的一处bug并开放webview
 */
//#define LETAPM_VERSION  @"0.1.1"

/*
 @brief:0.1.0更新内容：
 first version release
 */
//#define LETAPM_VERSION  @"0.1.0"


#endif /* update_h */
