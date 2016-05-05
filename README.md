##设置圆角的四种方法

####一、设置CALayer的cornerRadius
   
cornerRadius属性影响layer显示的background颜色和前景框border，对layer的contents不起作用。故一个imgView(类型为UIImageView)的image不为空，设置imgView.layer的cornerRadius，是看不出显示圆角效果的，因为image是imgView.layer的contents部分。

这种情况下将layer的masksToBounds属性设置为YES，可以正确的绘制出圆角效果。但是cornerRadius>0，masksToBounds=YES，会触发GPU的离屏渲染，当一个屏幕上有多处触发离屏渲染，会影响性能。通过勾选Instruments->Core Animation->Color Offscreen-Rendered Yellow，可以看到屏幕上触发离屏渲染的会被渲染成黄色。离屏渲染的代价昂贵，苹果也意识到会产生性能问题，所以iOS9以后的系统里能不产生离屏渲染的地方也就不用离屏渲染了。比如对UIImageView里png图片设置圆角不会触发离屏渲染。

1. 对contents为空的视图设置圆角

		view.backgroundColor = [UIColor redColor];
    	view.layer.cornerRadius = 25;
    	
    	//UILabel设置backgroundColor的行为被更改，不再是设定layer的背景色而是为contents设置背景色
    	label.layer.backgroundColor = aColor
		label.layer.cornerRadius = 5
    	
2. 对contents不为空的视图设置圆角
 		
    	imageView.image = [UIImage imageNamed:@"img"];
    	imageView.image.layer.cornerRadius = 5;
    	imageView.image.layer.masksToBounds = YES;
 
 		
    
####二、设置CALayer的mask

通过设置view.layer的mask属性，可以将另一个layer盖在view上，也可以设置圆角，但是mask同样会触发离屏渲染。

有两种方式来生成遮罩，一是通过图片生成，图片的透明度影响着view绘制的透明度，图片遮罩透明度为1的部分view被绘制成的透明度为0，相反图片遮罩透明度为0的部分view被绘制成的透明度为1。二是通过贝塞尔曲线生成，view中曲线描述的形状部分会被绘制出来。

	// 通过图片生成遮罩，
    UIImage *maskImage = [UIImage imageNamed:@"someimg"];
    CALayer *mask = [CALayer new];
    mask.frame = CGRectMake(0, 0, maskImage.size.width, maskImage.size.height);
    mask.contents = (__bridge id _Nullable)(maskImage.CGImage);
    view.layer.mask = mask;
    
    //通过贝塞尔曲线生成
    CAShapeLayer *mask = [CAShapeLayer new];
    mask.path = [UIBezierPath bezierPathWithOvalInRect:view.bounds].CGPath;
    view.layer.mask = mask;

####三、通过Core Graphics重新绘制带圆角的视图

通过CPU重新绘制一份带圆角的视图来实现圆角效果，会大大增加CPU的负担，而且相当于多了一份视图拷贝会增加内存开销。但是就显示性能而言，由于没有触发离屏渲染，所以能保持较高帧率。下例是绘制一个圆形图片，绘制其它UIView并无本质区别。重新绘制的过程可以交由后台线程来处理。
	
	@implementation UIImage (CircleImage)
	
	- (UIImage *)drawCircleImage {
    	CGFloat side = MIN(self.size.width, self.size.height);
    	UIGraphicsBeginImageContextWithOptions(CGSizeMake(side, side), false, [UIScreen mainScreen].scale);
    	CGContextAddPath(UIGraphicsGetCurrentContext(),
                     	[UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, side, side)].CGPath);
    	CGContextClip(UIGraphicsGetCurrentContext());
    	CGFloat marginX = -(self.size.width - side) / 2.f;
    	CGFloat marginY = -(self.size.height - side) / 2.f;
    	[self drawInRect:CGRectMake(marginX, marginY, self.size.width, self.size.height)];
    	CGContextDrawPath(UIGraphicsGetCurrentContext(), kCGPathFillStroke);
    	UIImage *output = UIGraphicsGetImageFromCurrentImageContext();
    	UIGraphicsEndImageContext();
    	return output;
	}	
	@end
	
	//在需要圆角时调用如下
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *img = [[UIImage imageNamed:@"image.png"] drawCircleImage];
        dispatch_async(dispatch_get_main_queue(), ^{
            view.image = img;
        });
    });
	
####四、通过混合图层

此方法就是在要添加圆角的视图上再叠加一个部分透明的视图，只对圆角部分进行遮挡。图层混合的透明度处理方式与mask正好相反。此方法虽然是最优解，没有离屏渲染，没有额外的CPU计算，但是应用范围有限。

####总结

1. 在可以使用混合图层遮挡的场景下，优先使用第四种方法。
2. 即使是非iOS9以上系统，第一种方法在综合性能上依然强于后两者，iOS9以上由于没有了离屏渲染更是首选。
3. 方法二和方法三由于使用了贝塞尔曲线，都可以应对复杂的圆角。只不过前者牺牲帧率，后者需要大量计算和增加部分内存，需要实际情况各自取舍。

以上四种方法的[Objective-C实现](https://github.com/tjuzjf/RoundCornerDemo) 