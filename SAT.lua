---获取两点的距离
function GetDis(vec1,vec2)
	local x1 = vec1.x or vec1[1]
    local y1 = vec1.y or vec1[2]
    local x2 = vec2.x or vec2[1]
    local y2 = vec2.y or vec2[2]

    local disX = x1 - x2
    local disY = y1 - y2
    local dis = math.sqrt(disX * disX + disY * disY)
    return dis
end

---向量归一化
function Normalize(vec)
    local x = vec[1] or vec.x
    local y = vec[2] or vec.y
    local mag = math.sqrt(x*x + y*y)
    if type(vec) == "table" then
        vec[1] = x/mag
        vec[2] = y/mag
    end
    vec.x = x/mag
    vec.y = y/mag
end

---点乘
function Dot(vec1,vec2)
    local x1 = vec1.x or vec1[1]
    local y1 = vec1.y or vec1[2]
    local x2 = vec2.x or vec2[1]
    local y2 = vec2.y or vec2[2]
    return x1*x2 + y1*y2
end

---精确到小数点后n位
---num 浮点数
---n 浮点数精确位数
function FloatAccurateN(num,n)
    if type(num) ~= "number" then
        return num;
    end
    n = n or 0;
    n = math.floor(n)
    if n < 0 then
        n = 0;
    end
    local nDecimal = 10 ^ n
    local nTemp = math.floor(num * nDecimal);
    local nRet = nTemp / nDecimal;
    return nRet;
end

---二维向量的向量积
---大小的绝对值表示两个向量构成的三角形的面积的2倍
---正负表示与两个向量构成的平面的法线的方向
function VectorProduct(vec1,vec2)
    local vec1X = vec1.x or vec1[1]
    local vec1Y = vec1.y or vec1[2]
    local vec2X = vec2.x or vec2[1]
    local vec2Y = vec2.y or vec2[2]
    return vec1X*vec2Y - vec2X*vec1Y
end

function Add(pt1,pt2)
    return {x = pt1.x + pt2.x , y = pt1.y + pt2.y }
end

function Sub(pt1,pt2)
    return {x = pt1.x - pt2.x , y = pt1.y - pt2.y }
end

-- 计算圆周上的点位置
function CalCirclePos(centerPos, radius, angleRadians)
    return Add(centerPos, {x=math.cos(angleRadians)*radius, y=math.sin(angleRadians)*radius}),Sub(centerPos, {x=math.cos(angleRadians)*radius, y=math.sin(angleRadians)*radius})
end

--创建一个多边形
--name:多边形名字
--offset:实际点与多边形的偏移量，offset为多边形的原点，多边形的顶点位置都是相对于这个点的偏移量
--vertices ： 多边形的顶点数组，位置相对于offset
--rotation ： 旋转角度（角度不是弧度（0~180为逆时针，0~-180为顺时针） 
function Polyon(name,offset,vertices,rotation)
	local polyon = {}
    polyon.name = name or "polyon"
	polyon.offset = {offset.x or offset[1] or 0,offset.y or offset[2] or 0}
	-- 弧度
	polyon.rotation = math.rad(changeRotationToInverse(rotation))
    --- 模板顶点，相对于offset为原点的顶点数组
    polyon._tempVertices = {}
    for i, vertice in ipairs(vertices) do
        local x = vertices[i][1]
        local y = vertices[i][2]
        table.insert(polyon._tempVertices,{x=x,y=y})
    end
	--顶点数组,实际顶点坐标
	polyon._vertices = {}
	-- 平面中，一个点(x,y)绕任意点(dx,dy)逆时针旋转a度后的坐标
    -- xx= (x - dx)*cos(a) - (y - dy)*sin(a) + dx ;
    -- yy= (x - dx)*sin(a) + (y - dy)*cos(a) +dy ;
    for i, vertice in ipairs(vertices or {}) do
        local x = (vertices[i][1]*math.cos(polyon.rotation))-(vertices[i][2]*math.sin(polyon.rotation))
        local y = (vertices[i][1]*math.sin(polyon.rotation))+(vertices[i][2]*math.cos(polyon.rotation))
        table.insert(polyon._vertices,{x=x,y=y})
    end

	---边
    polyon._edges = {}
    for i=1,#polyon._vertices do
        table.insert(polyon._edges, createSegment(polyon._vertices[i], polyon._vertices[1+i%(#polyon._vertices)]))
    end

    polyon.centerPoint = {x=0,y=0}

    --- 注册点到中心点的距离
    polyon._centerToAnchorDistance = GetDis({0,0},polyon.offset)
    --- 中心点相对于注册点的旋转弧度
	
    -- polyon._centerToAnchorRadian = math.atan(Vector2.Angle(Vector2(polyon.offset[2], polyon.offset[1]), Vector2(0,1))) --[[适配达芬奇]]--
    polyon._centerToAnchorRadian = math.atan2(polyon.offset[2], polyon.offset[1])

	return polyon
end

---将角度转换为逆时针角度
---rotation (0 ~ 180逆时针,0 ~ -180顺时针)
function changeRotationToInverse(rotation)
    rotation = rotation or 0
    if rotation < 0 then
        rotation = rotation + 360
    end
    return rotation or 0
end

---多边形的边
---@param vertice1 第一个顶点
---@param vertice2 第二个顶点
function createSegment(vertice1,vertice2)
    local segment = {pointA = vertice1,pointB = vertice2,dir = {vertice2.x - vertice1.x,vertice2.y - vertice1.y}}
    return segment
end

---设置多边形的实际位置，更新多边形的信息
---polyon 多边形
---x 碰撞体的实际位置X
---y 碰撞体的实际位置y
---rotation 是角度不是弧度
function setPolyon(polyon, x, y, rotation)
    rotation = changeRotationToInverse(rotation) or 0
    local r = math.rad(rotation)
    polyon.rotation = r
    ---相对于世界坐标系旋转的弧度
    local radian = polyon._centerToAnchorRadian + r
    local dx = polyon._centerToAnchorDistance * math.cos(radian)
    local dy = polyon._centerToAnchorDistance * math.sin(radian)
    ---中心点的世界坐标
    polyon.centerPoint.x = x + dx
    polyon.centerPoint.y = y + dy

    ---更新多边形顶点位置（相对于世界坐标的）
    for i, vertice in ipairs(polyon._vertices) do
        local x = polyon._tempVertices[i].x
        local y = polyon._tempVertices[i].y
        polyon._vertices[i].x = polyon.centerPoint.x + (x*math.cos(polyon.rotation))-(y*math.sin(polyon.rotation))
        polyon._vertices[i].y = polyon.centerPoint.y + (x*math.sin(polyon.rotation))+(y*math.cos(polyon.rotation))
    end

    ---更新边的信息
    for i=1,#polyon._vertices do
        local pointA = polyon._vertices[i]
        local pointB = polyon._vertices[1+i%(#polyon._vertices)]
        polyon._edges[i].pointA = pointA
        polyon._edges[i].pointB = pointB
        polyon._edges[i].dir[1] = pointB.x - pointA.x
        polyon._edges[i].dir[2] = pointB.y - pointA.y
    end
end

---计算多边形在轴上的投影
---polyon 多边形
---axis 投影的轴
---返回值为投影两端的最大值与最小值
function getProjectionWithAxis(polyon,axis)
    Normalize(axis)
    ---在轴上面的投影
    local min = Dot(polyon._vertices[1],axis)
    local max = min
    for i,v in ipairs(polyon._vertices) do
        local proj =  Dot(v, axis)
        if proj < min then
             min = proj
        end
        if proj > max then 
            max = proj 
        end
    end
    return FloatAccurateN(min,3),FloatAccurateN(max,3)
end

---polygonA 多边形
---polygonB 多边形
---分离轴，以多边形的每条边的法向量为轴，将多边形投影到轴上，如有任意一个轴上的两个多边形的投影不相交，那么这两个多边形就是分离的
function detectorPolygonvsPolygon(polygonA, polygonB)
    local aProjection = {}
    local bProjection = {}
    local segmentNormal  = {}
    for i, segment in ipairs(polygonA._edges) do
        ---边的法线向量
        segmentNormal[1] = segment.dir[2]
        segmentNormal[2] = -segment.dir[1]
        ---两个多边形在当前轴上的投影
        aProjection[1],aProjection[2] = getProjectionWithAxis(polygonA,segmentNormal)
        bProjection[1],bProjection[2] = getProjectionWithAxis(polygonB,segmentNormal)
        if not projectionContains(aProjection,bProjection) then
            return false
        end
    end

    for i, segment in ipairs(polygonB._edges) do
        ---边的法线向量
        segmentNormal[1] = segment.dir[2]
        segmentNormal[1] = -segment.dir[1]
        ---两个多边形在当前轴上的投影
        aProjection[1],aProjection[2] = getProjectionWithAxis(polygonA,segmentNormal)
        bProjection[1],bProjection[2] = getProjectionWithAxis(polygonB,segmentNormal)
        if not projectionContains(aProjection,bProjection) then
            return false
        end
    end
    return true
end

---多边形与点的碰撞(判断一个点是在多边形内，还是在多边形上，还是在多边形外)
---polygon 多边形
---point 需要检测的点
---多边形可看做从某点出发的闭合回路，内部的点永远在回路的同一边。通过边与点的连线的向量积(叉积)的正负表示方向，
---顺时针方向，所有向量积数值均为负，逆时针方向，所有向量积数值均为正
function detectorPolygonvsPoint(polygon,point)
    local pointX = point.x or point[1]
    local pointY = point.y or point[2]
    local fristvectorproduct = 0
    for i, edge in ipairs(polygon._edges) do
        local vertice = edge.pointA
        ---边的第一个顶点point的向量
        local vertice2point = {pointX - vertice.x,pointY - vertice.y}
        ---边与vertice2point的向量积
        local vectorproduct = FloatAccurateN(VectorProduct(edge.dir,vertice2point),3)
        ---点在多边形的边上
        if vectorproduct == 0 then
            return true
        end
        if i == 1 then
            fristvectorproduct = vectorproduct
        else
            if fristvectorproduct * vectorproduct < 0 then
                return false
            end
        end
    end
    return true
end

function projectionContains(a,b)
    local aMin = a[1]
    local aMax = a[2]
    local bMin = b[1]
    local bMax = b[2]
    if (aMax<aMin) then 
        aMin = aMax
        aMax = a[1]
    end
    if (bMax<bMin) then 
        bMin = bMax
        bMax = b[1]
    end
    return not (aMin > bMax or aMax < bMin)
end

function PrintPolygon(polyon)
    print(polyon.name.." offset ",polyon.offset[1],polyon.offset[2])
    print(polyon.name.." centerPoint ",polyon.centerPoint.x,polyon.centerPoint.y)
    print(polyon.name.."模板顶点信息：===========================================")
    for index, value in ipairs(polyon._tempVertices) do
        print(string.format("x = %f, y = %f",polyon._tempVertices[index].x,polyon._tempVertices[index].y))
    end
    print(polyon.name.."模板顶点信息：===========================================")
    print(polyon.name.."实际顶点信息：===========================================")
    for index, value in ipairs(polyon._vertices) do
        print(string.format("x = %f, y = %f",polyon._vertices[index].x,polyon._vertices[index].y))
    end
    print(polyon.name.."实际顶点信息：=======================================")
    print(polyon.name.."边信息：===========================================")
    for index, value in ipairs(polyon._edges) do
        print(string.format("dir = (%f,%f)",polyon._edges[index].dir[1],polyon._edges[index].dir[2]))
    end
    print(polyon.name.."边信息：=======================================")
end

--创建一个圆
--name:圆名字
--offset:实际点与圆形的偏移量，offset为圆形的原点，圆的顶点位置都是相对于这个点的偏移量
--radius ： 半径
function Circle(name, offset, radius)
    local Circle = {}
	Circle.name = name or "circle"
    Circle.radius = radius or 0
    Circle.offset = {x=offset.x and offset[1] or 0, y=offset.y and offset[2] or 0}
    Circle.centerPoint = {x=0,y=0}
    return Circle
end

---设置圆的实际位置，更新圆的信息
---circle 多边形
---x 碰撞体的实际位置X
---y 碰撞体的实际位置y
---radius 半径
function CircleSet(circle,x,y,radius)
    circle.centerPoint.x = x + circle.offset.x
    circle.centerPoint.y = y + circle.offset.y
    circle.radius = radius or circle.radius
end

---计算圆形在轴上的投影
---axis 投影的轴
---返回投影两端的最大值与最小值
function getClicleProjectionWithAxis(circle,axis)
    Normalize(axis)
    ---线段的夹角
    local rad = math.atan2(axis.y, axis.x)
    ---经过圆心，线段与圆相交的两个点的位置
    local pointInCircle1,pointInCircle2 = CalCirclePos(circle.centerPoint,circle.radius,rad)
    ---分别两个点在轴上的投影
    local min = Dot(pointInCircle1,axis)
    local max = min
    local min2 = Dot(pointInCircle2,axis)
    if min2 < min then min = min2 end
    if min2 > max then max = min2 end
    return FloatAccurateN(min,3),FloatAccurateN(max,3)
end

---polygon 多边形
---circle 圆形
---原理与多边形判断一样
function detectorPolygonvsCircle(polygon,circle)
    local aProjection = {}
    local bProjection = {}
    local circleCenter = circle.centerPoint
    for i, segment in ipairs(polygon._edges) do
        ---多边形的边的法线向量
        local axes = {segment.dir[2],-segment.dir[1]}
        ---多边形在当前轴上的投影
        aProjection[1],aProjection[2] = getProjectionWithAxis(polygon,axes)
        ---圆在当前轴上的投影
        bProjection[1],bProjection[2] = getClicleProjectionWithAxis(circle,axes)
        if not projectionContains(aProjection,bProjection) then
            return false
        end
    end
    return true
end

local polyonA = Polyon("polyonA",{0,0},{{32,32},{32,-32},{-32,-32},{-32,32}},0)
setPolyon(polyonA,0,0,0)
local polyonB = Polyon("polyonB",{0,0},{{32,32},{32,-32},{-32,-32},{-32,32}},0)
setPolyon(polyonB,0,-70,0)
print("多边形A,B碰撞 ： ",detectorPolygonvsPolygon(polyonA,polyonB))

--[[
local polyonA = Polyon("polyonA",{1,1},{{0,1},{-1,0},{-1,-1},{1,-1},{1,0}},0)
setPolyon(polyonA,0,0,0)
local polyonB = Polyon("polyonB",{1,1},{{0,1},{-1,0},{-1,-1},{1,-1},{1,0}},0)
setPolyon(polyonB,2,0,0)
print("多边形A,B碰撞 ： ",detectorPolygonvsPolygon(polyonA,polyonB))

local polyonA = Polyon("polyonA",{0,0},{{0,1},{-1,0},{-1,-1},{1,-1},{1,0}},0)
setPolyon(polyonA,0,0,60)
local polyonB = Polyon("polyonB",{0,0},{{0,1},{-1,0},{-1,-1},{1,-1},{1,0}},0)
setPolyon(polyonB,2.5,0,-30)
print("多边形A,B碰撞 ： ",detectorPolygonvsPolygon(polyonA,polyonB))

--测试数据
local polyonA = Polyon("polyonA",{1,1},{{0,1},{-1,0},{-1,-1},{1,-1},{1,0}},0)
setPolyon(polyonA,0,0,0)
local circleA = Circle({0,0},1)
CircleSet(circleA,2,0,1)
print("多边形A与圆B碰撞 ： ",detectorPolygonvsCircle(polyonA,circleA))

local polyonA = Polyon("polyonA",{0,0},{{0,1},{-1,0},{-1,-1},{1,-1},{1,0}},0)
setPolyon(polyonA,0,0,-45)
local circleA = Circle({0,0},1)
CircleSet(circleA,2,0,1)
print("多边形A与圆B碰撞 ： ",detectorPolygonvsCircle(polyonA,circleA))

local polyonA = Polyon("polyonA",{0,0},{{0,1},{-1,0},{-1,-1},{1,-1},{1,0}},0)
setPolyon(polyonA,0,0,0)
local pointB = {x=0,y=1}
print("多边形A与点B碰撞 ： ",detectorPolygonvsPoint(polyonA,pointB))

local polyonA = Polyon("polyonA",{0,0},{{0,1},{-1,0},{-1,-1},{1,-1},{1,0}},0)
setPolyon(polyonA,0,0,30)
local pointB = {x=0,y=1}
print("多边形A与点B碰撞 ： ",detectorPolygonvsPoint(polyonA,pointB))

--]]

-- local polyonA = Polyon("polyonA",{0,0},{{0,1},{-1,0},{-1,-1},{1,-1},{1,0}},0)
-- setPolyon(polyonA,0,0,30)
-- local pointB = {x=0,y=1}
-- print("多边形A与点B碰撞 ： ",detectorPolygonvsPoint(polyonA,pointB))