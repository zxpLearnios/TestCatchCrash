//  CatchCrashManager
//  系统异常捕获 全局异常捕获 保存
/**
 
 0. 一种是由EXC_BAD_ACCESS引起的，原因是访问了不属于本进程的内存地址，有可能是访问已被释放的内存;
 另一种是未被捕获的目标C异常（NSException）记录，导致程序向自身发送了SIGABRT信号而崩溃。
 其实对于未捕获的目标C异常，我们是有办法将它记录下来的，如果日志记录得当，能够解决绝大部分崩溃的问题。这里对于UI线程与后台线程分别说明
 一、系统崩溃
 对于系统崩溃而引起的程序异常退出，可以通过NSSetUncaughtExceptionHandler机制捕获，然后在启动appdidFinishLaunchingWithOptions的时候设置

 NSSetUncaughtExceptionHandler (&UncaughtExceptionHandlers);//系统异常捕获
 当捕获到异常时，就会调用UncaughtExceptionHandlers来出来异常

 二、处理signal
 使用Objective-C的异常处理是不能得到signal的，如果要处理它，我们还要利用unix标准的signal机制，注册SIGABRT, SIGBUS, SIGSEGV等信号发生时的处理函数。该函数中我们可以输出栈信息，版本信息等其他一切我们所想要的。NSSetUncaughtExceptionHandler 用来做异常处理，但功能非常有限.而引起崩溃的大多数原因如：内存访问错误，重复释放等错误就无能为力了，因为这种错误它抛出的是Signal，所以必须要专门做Signal处理，代码如下：
 首先定义一个UncaughtExceptionHandler类，用来捕获处理所有的崩溃信息

 1. SignalHandler不要在debug环境下测试。因为系统的debug会优先去拦截。我们要运行一次后，关闭debug状态。应该直接在模拟器上点击我们build上去的app去运行。而NSGetUncaughtExceptionHandler可以在调试状态下捕捉。
 2. 崩溃发生时，在控制台需使用 pro hand -p true -s false SIGABRT命令以查看个别信息, 如
 NAME         PASS   STOP   NOTIFY
 ===========  =====  =====  ======
 SIGABRT      true   false  true
 
 
 
*/

#import "CatchCrashManager.h"
//#include <execinfo.h>
#import "execinfo.h"

static NSUncaughtExceptionHandler *previousExceptionHandler;
@interface CatchCrashManager ()
@end

@implementation CatchCrashManager



+(instancetype)shared {
    static CatchCrashManager *_sharedSingleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedSingleton = [[self alloc] init];
    });
    return _sharedSingleton;
}

/// 1. 注册系统普通异常
-(void)registExceptionHandler {
     previousExceptionHandler = NSGetUncaughtExceptionHandler();
    
    /**  设置系统处理函数，crash前最后一刻调用
     但是，大部分第三方 SDK 也是通过这种方式来收集异常的，当我们通过 NSSetUncaughtExceptionHandler 设置异常处理函数时，会覆盖其它 SDK 设置的回调函数，导致它们无法上报统计，反之，也可能出现我们设置的回调函数被其他人覆盖。
     那如何解决这种覆盖的问题呢？其实很简单，苹果也为我们提供了 NSGetUncaughtExceptionHandler 函数，用于获取之前设置的异常处理函数。
     所以，我们可以在调用 NSSetUncaughtExceptionHandler 注册异常处理函数之前，先通过 NSGetUncaughtExceptionHandler 拿到已有的异常处理函数并保存下来。然后在我们自己的处理函数执行之后，再调用之前保存的处理函数就可以了。
     */
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
}

// 1.1 处理具体的异常
void uncaughtExceptionHandler(NSException *exception)
{
    // 异常的堆栈信息
    NSArray *stackArray = [exception callStackSymbols];
    // 出现异常的原因
    NSString *reason = [exception reason];
    // 异常名称
    NSString *name = [exception name];
    NSString *exceptionInfo = [NSString stringWithFormat:@"Exception reason：%@，\nException name：%@，\nException stack：%@",name, reason, stackArray];
    // 具体的异常位置，类名、方法名
    NSString *mainCallStackSymbolMsg = [[CatchCrashManager shared] getMainCallStackSymbolMessageWithCallStackSymbols:stackArray];
    
    NSMutableArray *tmpArr = [NSMutableArray arrayWithArray:stackArray];
    [tmpArr insertObject:reason atIndex:0];
    NSString *errorPlace = [NSString stringWithFormat:@"Error Place%@", mainCallStackSymbolMsg];
//    NSLog(@"具体的发生异常的位置：%@", errorPlace);
    
    // 拼接全部错误信息,  异常栈、具体的异常位置
    NSString *allErrorInfo = [exceptionInfo stringByAppendingFormat:@"，\n %@", errorPlace];
    NSString *file =[NSString stringWithFormat:@"%@/Documents/error.log", NSHomeDirectory()];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:file]) { // 文件不存在
        // 保存到本地  --  当然你可以在下次启动的时候，上传这个log
        [allErrorInfo writeToFile:file atomically:YES encoding:NSUTF8StringEncoding error:nil];
    } else { // 文件以存在，则插入文件最后
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:file];
        // 跳转只文件末尾
        [fileHandle seekToEndOfFile];
        // 在错误信息前面拼接一空行并换行
        NSString *tmpAllErrorStr = [NSString stringWithFormat:@"\n\n%@", allErrorInfo];
        NSData *data = [tmpAllErrorStr dataUsingEncoding:NSUTF8StringEncoding];
        // 写入数据到文件末尾
        if (data != nil) {
            NSError *fileHandleWriteError;
            if (@available(iOS 13.0, *)) {
                BOOL isWriteSuccess = [fileHandle writeData:data error:&fileHandleWriteError];
                if (!isWriteSuccess) {
                    NSLog(@"发生异常crash，写入异常信息只文件末尾时失败！");
                }
                // 关闭文件
                [fileHandle closeFile];
            } else {
                [fileHandle writeData:data];
                // 关闭文件
                [fileHandle closeFile];
            }
        } else {
            NSLog(@"发生异常crash时，异常信息为空！");
        }
    }
    
    // 执行sdk的异常处理
    
    // 是否继续运行app
    if ([CatchCrashManager shared].isGoOnRunWhenExecption) {
        CFRunLoopRef runLoop = CFRunLoopGetCurrent();
        CFArrayRef modes = CFRunLoopCopyAllModes(runLoop);
        while (true) {
            for (NSString *mode in (__bridge NSArray *)modes) {
                CFRunLoopRunInMode((CFRunLoopMode)mode, 0.001, true);
            }
        }
    }
    
    NSLog(@"我把问题上传到服务器了____%@", exceptionInfo);
}

/// 1.2
-(NSString *)getMainCallStackSymbolMessageWithCallStackSymbols:(NSArray<NSString *> *)callStackSymbols {
    // mainCallStackSymbolMsg的格式为   +[类名 方法名]  或者 -[类名 方法名]
    __block NSString *mainCallStackSymbolMsg = nil;
    
    // 匹配出来的格式为 +[类名 方法名]  或者 -[类名 方法名]
    NSString *regularExpStr = @"[-\\+]\\[.+\\]";
    
    NSRegularExpression *regularExp = [[NSRegularExpression alloc] initWithPattern:regularExpStr options:NSRegularExpressionCaseInsensitive error:nil];
    for (int index = 2; index < callStackSymbols.count; index++) {
        NSString *callStackSymbol = callStackSymbols[index];
        
        [regularExp enumerateMatchesInString:callStackSymbol options:NSMatchingReportProgress range:NSMakeRange(0, callStackSymbol.length) usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
            if (result) {
                NSString* tempCallStackSymbolMsg = [callStackSymbol substringWithRange:result.range];
                
                // get className
                NSString *className = [tempCallStackSymbolMsg componentsSeparatedByString:@" "].firstObject;
                className = [className componentsSeparatedByString:@"["].lastObject;
                // 找到具体的类文件对应的bundle
                NSBundle *bundle = [NSBundle bundleForClass:NSClassFromString(className)];
                // filter category and system class
                if (![className hasSuffix:@")"] && bundle == [NSBundle mainBundle]) {
                    mainCallStackSymbolMsg = tempCallStackSymbolMsg;
                }
                *stop = YES;
            }
        }];
        
        if (mainCallStackSymbolMsg.length) {
            break;
        }
    }
    return mainCallStackSymbolMsg;
}


#pragma mark 2. 注册系统signal异常
-(void)registSignalExceptionHandler {
    InstallSignalHandler();
}

// 2.1 获取signal信息
void InstallSignalHandler(void) {
   signal(SIGHUP, SignalExceptionHandler);
   signal(SIGINT, SignalExceptionHandler);
   signal(SIGQUIT, SignalExceptionHandler);
 
   signal(SIGABRT, SignalExceptionHandler);
   signal(SIGILL, SignalExceptionHandler);
   signal(SIGSEGV, SignalExceptionHandler);
   signal(SIGFPE, SignalExceptionHandler);
   signal(SIGBUS, SignalExceptionHandler);
   signal(SIGPIPE, SignalExceptionHandler);
}


// 2.2 具体的signal信息处理函数， 程序由于abort()函数调用发生的程序中止信号
void SignalExceptionHandler(int signal)
{
   NSMutableString *mstr = [[NSMutableString alloc] init];
   [mstr appendString:@"Stack:\n"];
   void* callstack[128];
   int i, frames = backtrace(callstack, 128);
   char** strs = backtrace_symbols(callstack, frames);
   for (i = 0; i <frames; ++i) {
       [mstr appendFormat:@"signal异常：%s\n", strs[i]];
   }
   // 保存信息
    UIAlertController *alert = [[UIAlertController alloc]init];
    UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alert addAction:cancelAction];
    [alert addAction:sureAction];
    
    alert.message = mstr;
    
    UIViewController *rootVc = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootVc presentViewController:alert animated:YES completion:nil];
}



#pragma mark 3. 取消系统异常的捕获
-(void)unRegistExceptionHandler {
    NSSetUncaughtExceptionHandler(NULL);
}

#pragma mark 4. 取消signal异常的捕获
-(void)unRegistSignalExceptionHandler {
    signal(SIGHUP, SIG_DFL);
    signal(SIGINT, SIG_DFL);
    signal(SIGQUIT, SIG_DFL);
    
    signal(SIGABRT, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGSEGV, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGPIPE, SIG_DFL);
}

#pragma mark 5。 取消所有异常处理
-(void)unRegistAllExceptionHandler {
    [self unRegistExceptionHandler];
    [self unRegistSignalExceptionHandler];
}


@end
