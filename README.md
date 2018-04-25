# FFAVPlayer
#### 1、改变view的frame，layer的frame是否会变化？改变layer.frame，view的frame是否会变化？请问原因是什么？
答：都会改变。每个UIView内部都有一个CALayer在提供内容的绘制和显示，并且View的尺寸都是油Layer所提供的。
