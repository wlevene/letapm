    ┏┓　　　　　　　　　　　　　　　　　　　　　　　　　　　　　
    ┃┃┏━┓┏━━┓┏━┓┏━┓┏━━┓　┏━┓┏━┓┏━━┓
    ┃┃┃┻┫┗┓┏┛┃━┃┃┃┃┃┃┃┃┏┓┃┣┫┃┃┃┃┃┃┃
    ┗┛┗━┛ ┗┛ ┗┻┛┃┏┛┗┻┻┛┗┛┗━┛┗━┛┗┻┻┛
                ┗┛　　　　　　　　　　　　　　　　　


项目暂停进入维护中，开源 iOS SDK代码供各位学习，交流。喜欢就给个星 :)

#LetAPM接入说明

sdk的作用是发现在真实用户那里出现的所有的http相关的问题，  会把http出错时的用户环境、出错码、错误内容等信息上报，以真实用户的使用数据来并评估http的性能，供开发人员快速定位问题

- 打开http://www.letapm.com, 使用邮箱注册一个账号
- 新建app得到appkey
- 将Letapm.framework引入到xcode工程
- 在工程***Build Settings***中选择***Other Linker Flags***，添加`-ObjC`编译项目
- 添加头文件

```objectivec
#import <Letapm/Letapm.h>
```

- 初始化LetAPM，在`application:(UIApplication *)application didFinishLaunchingWithOptions`方法里添加以下代码

```objectivec****
    // [LetAPM showLog:YES]; // 打开日志输出默认为NO
    [LetAPM initWithAppKey:@"appkey" withAppSecret:@"appsecret"];  
```

目前使用时将appsecret的值也传为appkey的值, 这两个值传入相同的内容


#注意事项
- 支持ios6以上
- SDK的初始化方法在app启动的过程调用，并尽量早一点执行初始化方法
- iOS9的系统需要设置letapm.com域名使用http连接


