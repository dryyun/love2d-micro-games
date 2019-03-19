windowWidth = 800 -- 宽
windowHeight = 600 -- 高
rectangleSize = 25 -- 长方形长度
rectangleSpace = 1 -- 长方形间隔
rectangleUsage = rectangleSize + rectangleSpace
scoreFont = 50 -- 分数字体大小

score = 0 -- 分数
map = {} -- 地图，二维数组，type:false=空，'#1'=墙壁，'#2'=蛇头，'#3'=蛇身体，'#4'=食物
snake = {} -- 蛇 table
snakeInit = 6-- 蛇初始长度
food = { x = 0, y = 0 } -- 食物坐标

-- 颜色
color = {}
color['#1'] = { 255, 255, 255 }
color['#2'] = { 0, 0, 255 }
color['#3'] = { 0, 0, 255 }
color['#4'] = { 255, 0, 0 }

-- 方向
directions = {}
directions['up'] = { x = 0, y = -1 } -- 上
directions['down'] = { x = 0, y = 1 } -- 下
directions['left'] = { x = -1, y = 0 } -- 左
directions['right'] = { x = 1, y = 0 } -- 右
currentDirection = { x = -1, y = 0 } -- 当前方向


timerInit = 0.5 -- 初始刷新速度
timerMin = 0.1 -- 最小刷新速度
timer = timerInit -- 刷新速度
speed = 1 -- 初始速度
speedMax = 12 -- 最大速度
speedInterval = 3  -- 速度间隔吃了几个
speedEveryStep = 0.04 -- speed +1 =》timer = timer - speedEveryStep

gameState = 1  -- 游戏状态， 1:暂停、未开始 2:进行中 3:gameover


-- 初始化地图，根据长方形重新计算界面的宽高
function initMap()
    local xNum = math.floor(windowWidth / rectangleUsage)
    windowWidth = xNum * rectangleUsage

    local yNum = math.floor((windowHeight - scoreFont) / rectangleUsage)
    windowHeight = yNum * rectangleUsage + scoreFont

    for x = 1, xNum do
        map[x] = {}
        for y = 1, yNum do
            if x == 1 or x == xNum or y == 1 or y == yNum then
                map[x][y] = '#1'
            else
                map[x][y] = false
            end
        end
    end
end

-- 初始化蛇，随机位置，目前设置为横线向左
function initSnake()
    snake = {}
    math.randomseed(os.time())
    local xs = math.random(3, #map - snakeInit - 2)
    local ys = math.random(3, #map[1] - 3)
    for i = 1, snakeInit do
        snake[i] = { x = i + xs, y = ys }
    end
    setSnakeMap(true)
end

-- 初始化蛇方向
function initDirection()
    currentDirection = { x = -1, y = 0 }
end

-- 设置贪吃蛇地图
function setSnakeMap(type)
    for k, v in pairs(snake) do
        if type and k == 1 then
            map[v.x][v.y] = '#2'
        elseif type then
            map[v.x][v.y] = '#3'
        else
            map[v.x][v.y] = false
        end
    end
end


-- 生成食物
function newFood()
    math.randomseed(os.time())
    repeat
        food.x = love.math.random(2, #map - 1)
        food.y = love.math.random(2, #map[1] - 1)
    until getMapNode(food.x, food.y) == false
    map[food.x][food.y] = '#4'
end

-- 获取 map 某点
function getMapNode(x, y)
    return map[x][y]
end

-- 计算蛇头三角形的三个点
function calTrianglePoints(mapX, mapY)
    local point1, point2, point3
    if currentDirection.x == 0 and currentDirection.y == -1 then
        point1 = { x = (mapX - 1 + 0.5) * rectangleUsage, y = (mapY - 1) * rectangleUsage + scoreFont }
        point2 = { x = (mapX - 1) * rectangleUsage, y = mapY * rectangleUsage + scoreFont }
        point3 = { x = mapX * rectangleUsage, y = mapY * rectangleUsage + scoreFont }
    elseif currentDirection.x == 0 and currentDirection.y == 1 then
        point1 = { x = (mapX - 1 + 0.5) * rectangleUsage, y = mapY * rectangleUsage + scoreFont }
        point2 = { x = mapX * rectangleUsage, y = (mapY - 1) * rectangleUsage + scoreFont }
        point3 = { x = (mapX - 1) * rectangleUsage, y = (mapY - 1) * rectangleUsage + scoreFont }
    elseif currentDirection.x == -1 and currentDirection.y == 0 then
        point1 = { x = (mapX - 1) * rectangleUsage, y = (mapY - 1 + 0.5) * rectangleUsage + scoreFont }
        point2 = { x = mapX * rectangleUsage, y = mapY * rectangleUsage + scoreFont }
        point3 = { x = mapX * rectangleUsage, y = (mapY - 1) * rectangleUsage + scoreFont }
    elseif currentDirection.x == 1 and currentDirection.y == 0 then
        point1 = { x = mapX * rectangleUsage, y = (mapY - 1 + 0.5) * rectangleUsage + scoreFont }
        point2 = { x = (mapX - 1) * rectangleUsage, y = mapY * rectangleUsage + scoreFont }
        point3 = { x = (mapX - 1) * rectangleUsage, y = (mapY - 1) * rectangleUsage + scoreFont }
    end
    return point1, point2, point3
end

function drawMap()
    for x, line in pairs(map) do
        for y, b in pairs(line) do
            love.graphics.setColor(255, 255, 255)

            local mode = b and "fill" or "line"
            if b then
                love.graphics.setColor(color[b][1], color[b][2], color[b][3])
            end
            if b == '#2' then
                local point1, point2, point3 = calTrianglePoints(x, y)
                love.graphics.polygon('fill', point1.x, point1.y, point2.x, point2.y, point3.x, point3.y)
            else
                love.graphics.rectangle(mode, (x - 1) * rectangleUsage, scoreFont + (y - 1) * rectangleUsage, rectangleSize, rectangleSize, 5, 5)
            end
        end
    end
end

function updateSnake()
    local targetX, targetY = snake[1].x + currentDirection.x, snake[1].y + currentDirection.y
    local node = getMapNode(targetX, targetY)
    if node == '#1' or node == '#3' then
        gameState = 3
    elseif node == '#4' then
        table.insert(snake, { x = targetX, y = targetY })
        score = score + 1
        newFood()
    end

    setSnakeMap(false)
    for i = #snake, 2, -1 do
        snake[i].x = snake[i - 1].x
        snake[i].y = snake[i - 1].y
    end
    snake[1].x = snake[1].x + currentDirection.x
    snake[1].y = snake[1].y + currentDirection.y
    setSnakeMap(true)

end

-- 计算刷新时间和刷新速度
function calTimerAndSpeed()
    local currentSpeed = speed

    local setSpeed = math.floor((#snake - snakeInit) / speedInterval) + 1
    if setSpeed > currentSpeed then
        currentSpeed = currentSpeed + 1
    end

    if setSpeed > speedMax then
        setSpeed = speedMax
    end

    local setTimer = timerInit - setSpeed * speedEveryStep
    if setTimer < timerMin then
        setTimer = timerMin
    end

    return setTimer, setSpeed

end

function love.load()
    initMap()
    love.window.setMode(windowWidth, windowHeight)
    initSnake()
    initDirection()
    newFood()
end

function love.update(dt)
    if gameState == 2 then
        timer = timer - dt
        if timer < 0 then
            timer, speed = calTimerAndSpeed()
            updateSnake()
        end
    end

end

function love.draw()
    love.graphics.setFont(love.graphics.newFont(scoreFont - 3))
    love.graphics.printf("Score:" .. score .. '  Speed:' .. speed, 0, 0, love.graphics.getWidth(), "center")

    drawMap()

    if gameState == 1 then
        love.graphics.printf("Press Space to Start or Stop", 0, 200, love.graphics.getWidth(), "center")
    end

    if gameState == 3 then
        love.graphics.printf("Game Over", 0, 200, love.graphics.getWidth(), "center")
        love.graphics.printf("Press Space to Restart ", 0, 200 + scoreFont, love.graphics.getWidth(), "center")
    end

end

function love.keypressed(key, scancode, isrepeat)
    -- 控制上下左右
    if (key == 'up' or key == 'down' or key == 'left' or key == 'right') and gameState == 2 then
        if key == "up" then
            if currentDirection.y ~= 1 then
                currentDirection = directions[key]
            end
        elseif key == "down" then
            if currentDirection.y ~= -1 then
                currentDirection = directions[key]
            end
        elseif key == "left" then
            if currentDirection.x ~= 1 then
                currentDirection = directions[key]
            end
        elseif key == "right" then
            if currentDirection.x ~= -1 then
                currentDirection = directions[key]
            end
        end
    end

    -- 控制暂停、开始、重新开始
    if key == 'space' then
        if gameState == 1 then
            gameState = 2
        elseif gameState == 2 then
            gameState = 1
        elseif gameState == 3 then
            initMap()
            initSnake()
            initDirection()
            newFood()
            score = 0
            timer = timerInit
            speed = 1
            gameState = 1
        end
    end

end

