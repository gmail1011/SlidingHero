//
//  SLTestFaceView.h
//  SlidingHero
//
//  Created by 文有智 on 2025/3/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SLTestFaceViewDelegate;

@interface SLTestFaceView : UIView

@property (nonatomic, weak) id<SLTestFaceViewDelegate> delegate;
- (void)loadInfoMethod;

@end

@protocol SLTestFaceViewDelegate <NSObject>

@optional
- (void)infoLoadFinish:(BOOL)isHidden;

@end


NS_ASSUME_NONNULL_END
