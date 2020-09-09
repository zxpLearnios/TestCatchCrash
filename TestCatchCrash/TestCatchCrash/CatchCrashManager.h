//
//  CatchCrashManager.h

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

typedef void (^CatchCrashManagerExceptionBlock)(NSString *error);
typedef void (^CatchCrashManagerSignalExceptionBlock)(NSString *error);

@interface CatchCrashManager : NSObject

/// 在崩溃发生后，是否继续运行app, 若继续运行则性能会大大不如以前
@property (nonatomic, assign) BOOL isGoOnRunWhenExecption;

/// 普通异常、系统异常
@property (nonatomic, copy) CatchCrashManagerExceptionBlock normalExceptionBlock;
/// signal异常
@property (nonatomic, copy) CatchCrashManagerSignalExceptionBlock signalExceptionBlock;

void uncaughtExceptionHandler(NSException *exception);

+(instancetype)shared;
/// 1. 注册系统非signal异常处理
-(void)registExceptionHandler;

/// 2. 获取signal信息
-(void)registSignalExceptionHandler;

/// 3. 取消系统异常的捕获
-(void)unRegistExceptionHandler;
/// 4. 取消signal异常的捕获
-(void)unRegistSignalExceptionHandler;

/// 5。 取消所有异常处理
-(void)unRegistAllExceptionHandler;

@end
