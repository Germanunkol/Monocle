monocle = require('monocle')

local _lg = love.graphics
local _mouse = love.mouse
pi = math.pi

local moreLights = {}

function love.load()
	map_height = 12
	map_width = 18
	tileSize = 40
	player = require('player')
	level = GenerateMap(map_width,map_height)
	DEBUG = false
	monocle:init( false, 0,0,0,100 )
	monocle:setGrid( level, tileSize )
	playerlight = monocle:addLight( 2, 2, 255, 255, 255, 100)
end

function love.update(dt)

	playerlight.r = 255*(0.5 + 0.5*math.sin(love.timer.getTime()))
	player:update(dt, level)
	playerlight.x, playerlight.y = player.x, player.y
	monocle:update( DEBUG )
end

function toggleMoreLights()

	if #moreLights == 0 then
		--local l = monocle:addLight( 3, 2, 255, 255, 255, 60)
		--moreLights[#moreLights+1] = l
		
		l = monocle:addLight( 8, 8.5, 255, 150, 150, 100)
		moreLights[#moreLights+1] = l
		
		
		--l = monocle:addLight( 3, 2, 255, 255, 255, 100 )
		--moreLights[#moreLights] = l
	else
		for k, l in pairs(moreLights) do
			monocle:removeLight(l)
			moreLights[k] = nil
		end
	end
end

function toggleBlur()
	if not blur then
		monocle:setBlur( 1 )
		blur = 1
	else
		blur = blur + 1
		if blur == 5 then
			monocle:setBlur( 0 )
			blur = 0
		else
			monocle:setBlur( blur )
		end
	end
end

function love.draw()
	
	-- draw background:#
	_lg.setColor(100,100,100, 255)
	for i = 1, #level do
		for j = 1, #level[i] do
			if not level[i][j].solid then
				_lg.rectangle('fill', j*tileSize, i*tileSize, tileSize, tileSize)
			end
		end
	end
	
	player:draw()
	
	monocle:draw()
	
	-- draw walls:
	_lg.setColor(50,50,200)
	for i = 1, #level do
		for j = 1, #level[i] do
			if level[i][j].solid then
			_lg.rectangle('fill', j*tileSize, i*tileSize, tileSize, tileSize)
			end
		end
	end
	
	_lg.setColor(255,255,255)
	_lg.print('X:' .. player.x .. ';Y:' .. player.y, 0,0)
	_lg.print('Press "D" to toggle debug mode',0,12)
	_lg.print('Press "N" to toggle Monocle mode',0,24)
	_lg.print('Press "T" to teleport player to (3,3)',0,36)
	_lg.print('Press "L" to toggle additional light(s)',0,48)
	_lg.print('Press "B" to control blur',0,60)
end

function love.keypressed(key,code)
	if key == 'd' then
		DEBUG = not DEBUG
	elseif key == 'n'then
		draw_monocle = not draw_monocle
	elseif key == 't' then
		player.x=3
		player.y=3
	elseif key == 'l' then
		toggleMoreLights()
	elseif key == 'b' then
		toggleBlur()
	end
end

function love.mousepressed(x,y,button)

end

function CheckTileCollisions(map, rectx, recty, rectw, recth, tileSize)
	local firstTileX = math.floor(rectx / tileSize)
	local firstTileY = math.floor(recty / tileSize)
	local lastTileX = math.floor((rectx + rectw) / tileSize)
	local lastTileY = math.floor((recty + recth) / tileSize)
	local noCollision = true
	
	for i = firstTileY, lastTileY do
		for j = firstTileX, lastTileX do
			if map[i] then
				if map[i][j] then
					if map[i][j].solid then
						noCollision = false
						return noCollision
					end
				end
				
			end
		end
	end
	
	return noCollision
end

function GenerateMap(w,h)

	local map = {}
	for i = 1,math.ceil(h) do
		map[i] = {}
		for j = 1,math.ceil(w) do
			map[i][j] = {}
			if this_level[i][j] == 1 then
				map[i][j].solid = true
			else
				map[i][j].solid = false
			end 
		end
	end

	return map	
end

function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

--[[this_level2 = {
	{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,1},
	{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
}]]

this_level = {
	{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
	{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,1,0,0,0,1,0,1,1,0,1},
	{1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1,0,1},
	{1,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,1},
	{1,0,0,1,1,1,0,0,0,0,1,0,1,0,1,0,0,1},
	{1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,1,1,1,0,0,0,0,1,0,1,0,1,0,0,1},
	{1,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,0,0,0,0,0,0,0,0,0,1,0,1,0,1,0,0,1},
	{1,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1},
	{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
}
