众所周知，在达芬奇中开发2D游戏是一件极为痛苦的一件事，在初次接触后便产生了制作一个2D引擎来简化开发，于是便有了这个项目 [Davinci2DEngine.smap](https://davinci-worldcdn.lilithgames.com/oversea/assets/c5qts49303fa31jckevg) 

由于接触达芬奇引擎时间较短，所以会存在引擎API不熟悉的问题，这可能导致制作的2D引擎存在一些效率问题，如有问题，还请大神们帮忙指出



在上面的项目中，有一个可以运行的demo

整体项目结构为

![img](https://hanzoy-picture.oss-cn-chengdu.aliyuncs.com/img/c5qtvh1303fbs9im7pvg.png)

在Archetype中预制了常用的Component

![img](https://hanzoy-picture.oss-cn-chengdu.aliyuncs.com/img/c5qu0o9303fbs9im7q00.png)

使用方法类似与unity的Component挂载

例如我在player上挂载了Rigidbody BoxCollider Script Animator

![img](https://hanzoy-picture.oss-cn-chengdu.aliyuncs.com/img/c5qu3u9303fbs9im7q10.png)

**Rigidbody**

**![img](https://hanzoy-picture.oss-cn-chengdu.aliyuncs.com/img/c5qu4o9303fbs9im7q1g.png)**

Main脚本：该脚本将Rigidbody注册到引擎中，实现托管

API脚本：该脚本提供了对外调用的API

velocity：挂载物体的速度

useGravity：是否受重力影响

isStatic：是否为静态

Mass：质量

gravityScale：受重力影响程度

restitution：恢复系数

tempOffset、tempVelocity计算中间量

Direction：方向

**BoxCollider**

![img](https://hanzoy-picture.oss-cn-chengdu.aliyuncs.com/img/c5qu7u9303fa31jckf10.png)

Main脚本：该脚本将BoxCollider注册到引擎中，实现托管

isTrigger：是否为触发器

​     当该选项为true时，将不会计算碰撞体积，会改为调用挂载物体下Script下的onTrigger函数

tag：标签，同一标签的Collider将不会计算碰撞

若要挂载BoxCollider组件，则必须在同一物体下挂载Rigidbody组件

如何修改BoxCollider大小？

在窗口中选中BoxCollider直接修改大小即可

![img](https://hanzoy-picture.oss-cn-chengdu.aliyuncs.com/img/c5quash303fa31jckf20.png)

**Script**

![img](https://hanzoy-picture.oss-cn-chengdu.aliyuncs.com/img/c5quc71303fbs9im7q30.png)

_MainScript脚本：该脚本将Script注册到引擎中，实现托管

Script脚本：该脚本为用户逻辑脚本

模板为：

![img](https://hanzoy-picture.oss-cn-chengdu.aliyuncs.com/img/c5qud5h303fbs9im7q40.png)

其中Start函数为物体初次加载时执行一次

Update函数为每一次页面刷新执行一次

onTrigger函数为同一物体下有触发器触发时调用。tag为触发器标签，colliders为触发器检测到的碰撞体

**Animator**

**![img](https://hanzoy-picture.oss-cn-chengdu.aliyuncs.com/img/c5quf21303fbs9im7q50.png)**

Main脚本：该脚本将Animator注册到引擎中，实现托管

API脚本：该脚本提供了对外调用的API

StateScript脚本：状态机脚本，由于无法使用图形化状态机，所以通过代码的形式代替图形化状态机

defaults：默认的动画

后面的文件夹均为对应动画文件夹

例如idle：

![img](https://hanzoy-picture.oss-cn-chengdu.aliyuncs.com/img/c5quh69303fa31jckf2g.png)

其中idle1-6分别为帧动画素材

Main脚本：同样是托管脚本，不过这里需要填写对应帧动画素材

![img](https://hanzoy-picture.oss-cn-chengdu.aliyuncs.com/img/c5quhvh303fa31jckf30.png)

API脚本：该脚本提供了对外调用的api

limitTime：帧动画播放时间，默认是每8帧更换一次

DistanceDifference：由于两个方向的素材可能存在中心点不一致的问题，该参数用于调整中心点偏移的问题，如果左右完全对称的则填（0，0）

IsLoop：该动画是否循环播放

为什么要准备两个不同方向的素材？

主要是达芬奇编辑器本身不支持镜像UI素材，所以需要额外准备两个不同方向的素材

更换方向后出现偏移现象通过DistanceDifference能完全解决吗？

可以的，DistanceDifference除了调整动画的位置，还会调整Collider的位置偏移，但是从计算量来看，我还是更推荐使用左右镜像后中心点不发生改变的素材

**camera**

![img](https://hanzoy-picture.oss-cn-chengdu.aliyuncs.com/img/c5qulj9303fa31jckf40.png)

通过Script组件实现的摄像机功能

target为跟踪的对象，采用简单插值方式进行跟踪

**物理引擎方面**

碰撞主要采用SAT碰撞检测

详细代码见Engine.Colliders

先通过矩形检测进行初检测，然后通过SAT算法进行细校验

SAT本身能计算出碰撞点对与碰撞法线、穿透深度，但是由于lua本身效率的问题和达芬奇引擎本身的支持

并不容易计算刚体角速度从而不大容易建立速度约束方程，同时由于碰撞过程写死在引擎中，所以目前暂时还不支持具有旋转的碰撞和自定义材质，后续会逐步更新完善或寻找更好的解决办法

 

写在最后：由于刚接触达芬奇还不是很熟悉，所以这个解决方案目前还只是测试版，后续我会整理总结前辈们的解决方案，整合出更好的2D开发方案，同时也希望达芬奇能原生支持2D开发QWQ
