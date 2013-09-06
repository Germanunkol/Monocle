
local index = require 'index'
local tuple = require 'tuple'

local _lg = love.graphics

local Monocle = {
	edges = index(),
	canvas = _lg.newCanvas()
}

function Monocle:draw(x, y, grid, tileSize, moved, debug)
	self.x = x
	self.y = y
	self.grid = grid
	self.moved = moved or true
	self.tileSize = tileSize
	self.debug = debug
	self.edges = index()
	self:get_forward_edges()
	self:link_edges()
	self:add_projections()


	--self:draw_triangles()
	if debug then
		self:draw_debug()
	end
end

function Monocle:get_forward_edges()
	for i, row in ipairs(self.grid) do
		for j, point in ipairs(row) do
			if point.solid then
				if self.x<j and self.grid[i][j-1] and not self.grid[i][j-1].solid then
					self:add_edge(j,i,j,i+1) --left
				elseif self.x > j + 1 and self.grid[i][j+1] and not self.grid[i][j+1].solid then
					self:add_edge(j+1,i+1,j+1,i) --right
				end

				if self.y < i and self.grid[i-1] and not self.grid[i-1][j].solid then 
					self:add_edge(j+1,i,j,i) -- top
				elseif self.y > i + 1 and self.grid[i+1] and not self.grid[i+1][j].solid then
					self:add_edge(j,i+1,j+1,i+1) --bottom
				end
			end
		end
	end
end

function Monocle:link_edges()
	for e in self.edges:values() do
		local x1,y1,x2,y2 = unpack(e[1])
		next_candidate = tuple(x2,y2,x2,y2-1)
		if x2 < self.x and self.edges[next_candidate] then
			e[2] = next_candidate
			self.edges[next_candidate][3] = e[1]
		end
		next_candidate = tuple(x2,y2,x2,y2+1)
		if x2 >= self.x and self.edges[next_candidate] then
			e[2] = next_candidate
			self.edges[next_candidate][3] = e[1]
		end
		next_candidate = tuple(x2,y2,x2+1,y2)
		if y2 < self.y and self.edges[next_candidate] then
			e[2] = next_candidate
			self.edges[next_candidate][3] = e[1]
		end
		next_candidate = tuple(x2,y2,x2-1,y2)
		if y2 >= self.y and self.edges[next_candidate] then
			e[2] = next_candidate
			self.edges[next_candidate][3] = e[1]
		end
	end
end

function Monocle:add_projections()
	local edges_to_add = {}
	for e in self.edges:values() do
		local x1,y1,x2,y2 = unpack(e[1])
		if not e.projection and not e.split then
			--add Next
			if not e[2] then
				table.insert(edges_to_add, {e,x2,y2, true, 
								['distance'] = self.distPointToLine(self.x,self.y,x1,y1,x2,y2),
								['angle'] = math.atan2(y2-self.y,x2-self.x)})
			end
			--add Previous
			if not e[3] then
				table.insert(edges_to_add, {e, x1,y1, false, 
								['distance'] = self.distPointToLine(self.x,self.y,x1,y1,x2,y2),
								['angle'] = math.atan2(y1-self.y,x1-self.x)})
			end
		end
	end

	table.sort( edges_to_add, function(a,b) return a['distance'] < b['distance'] end)

	for _, e in ipairs(edges_to_add) do
		self:add_projection_edge(unpack(e))
	end

end

function Monocle:add_projection_edge(e, x1,y1, isNext)
	local borderX, borderY = self:get_border_intersection(x1,y1)
	local dist2 = false
	local closest_intersectionX, closest_intersectionY = false, false
	local found_edge = false
	for search_edge in self.edges:values() do
		local sx1,sy1,sx2,sy2 = unpack(search_edge[1])
		if search_edge[1] ~= e[1] and not search_edge.projection then
			local intersectX, intersectY = self:findIntersect(x1,y1,borderX,borderY,sx1,sy1,sx2,sy2,true,true)
			if intersectX then
				local new_dist2 = (intersectX - x1)^2 + (intersectY - y1)^2
				if not dist2 or new_dist2 < dist2 then
					dist2 = new_dist2
					closest_intersectionX, closest_intersectionY = intersectX, intersectY
					found_edge = search_edge
				end
			end
		end
	end
	if not found_edge then
		return false
	else 
		local sx1,sy1,sx2,sy2 = unpack(found_edge[1])

		if isNext then

			if not found_edge[2] then
				self:add_projection_edge(found_edge,sx2,sy2,true)
			end

			proj_edge = tuple(x1,y1,closest_intersectionX,closest_intersectionY)
			self:add_edge(x1,y1,closest_intersectionX,closest_intersectionY, true)

			new_edge = tuple(closest_intersectionX,closest_intersectionY,sx2,sy2)
			self:add_edge(closest_intersectionX,closest_intersectionY,sx2,sy2, false, true)

			new_edge2 = tuple(sx1,sy1,closest_intersectionX,closest_intersectionY)
			self:add_edge(sx1,sy1,closest_intersectionX,closest_intersectionY, false, true)

			self.edges[proj_edge][2] = new_edge
			self.edges[proj_edge][3] = e[1]

			self.edges[new_edge][3] = proj_edge
			self.edges[new_edge][2] = found_edge[2]

			self.edges[new_edge2][3] = false
			self.edges[new_edge2][2] = false

			self.edges[found_edge[1]] = nil

			for search_edge in self.edges:values() do
				if search_edge[3] == found_edge[1] then
					search_edge[3] = new_edge2
				end
				if search_edge[2] == found_edge[1] then
					search_edge[2] = new_edge
				end
			end

			e[2] = proj_edge

		else

			if not found_edge[3] then
				self:add_projection_edge(found_edge,sx1,sy1,false)
			end


			proj_edge = tuple(closest_intersectionX,closest_intersectionY,x1,y1)
			self:add_edge(closest_intersectionX,closest_intersectionY,x1,y1, true)

			new_edge = tuple(sx1,sy1,closest_intersectionX,closest_intersectionY)
			self:add_edge(sx1,sy1,closest_intersectionX,closest_intersectionY, false, true)

			new_edge2 = tuple(closest_intersectionX,closest_intersectionY,sx2,sy2)
			self:add_edge(closest_intersectionX,closest_intersectionY,sx2,sy2, false, true)

			self.edges[proj_edge][3] = new_edge
			self.edges[proj_edge][2] = e[1]

			self.edges[new_edge][3] = found_edge[3]
			self.edges[new_edge][2] = proj_edge

			--print(found_edge[1], found_edge[2], found_edge[3])
			if found_edge[3] then
				self.edges[found_edge[3]][2] = new_edge
			end
			self.edges[new_edge2][3] = false
			self.edges[new_edge2][2] = false

			self.edges[found_edge[1]] = nil

			for search_edge in self.edges:values() do
				if search_edge[3] == found_edge[1] then
					search_edge[3] = new_edge2
				end
				if search_edge[2] == found_edge[1] then
					search_edge[2] = new_edge
				end 
			end

			e[3] = proj_edge

		end
	end

end

function Monocle:draw_triangles()
	_lg.setCanvas(self.canvas)
	_lg.setColor(0,0,0)
	_lg.rectangle('fill', 0, 0, _lg.getWidth(), _lg.getHeight())
	_lg.setBlendMode('alpha')
	_lg.setColor(255,255,255)

	local start = self:get_closest_edge()
	local current_edge = start[1]
	local count = 0
	--print(start[1], start[2], start[3])
	repeat
		local x1,y1,x2,y2 = unpack(current_edge)
		_lg.triangle('fill', self.x*self.tileSize,self.y*self.tileSize,
						x1*self.tileSize,y1*self.tileSize,x2*self.tileSize,y2*self.tileSize)
		if self.edges[current_edge] then
			current_edge = self.edges[current_edge][2]
		else
			break
		end
		count = count + 1
	until current_edge == start[1] or count > 200
	print('Drew ' .. count .. ' triangles.')
	_lg.setCanvas()
end

function Monocle:get_closest_edge()
	local closest = false
	local dist = false
	for e in self.edges:values() do
		local x1,y1,x2,y2 = unpack(e[1])
		new_dist = self.distPointToLine(self.x,self.y,x1,y1,x2,y2)
		if not closest or new_dist<dist then
			dist = new_dist
			closest = e
		end
	end
	return closest
end

function Monocle:draw_vision_edge()
	--this is the maximum number of cycles.
	--used to prevent infinite loops.
	local tolerance = 500

	local start = self:get_closest_edge()
	local current_edge = start[1]
	local count = 0

	local x1,y1,x2,y2 = unpack(current_edge)
	_lg.setColor(255,255,0)
	_lg.line(self.x*tileSize,self.y*tileSize,x1*tileSize,y1*tileSize)
	_lg.line(self.x*tileSize,self.y*tileSize,x2*tileSize,y2*tileSize)

	_lg.setColor(255,0,0)
	--print(start[1], start[2], start[3])
	repeat
		--print(current_edge)
		local x1,y1,x2,y2 = unpack(current_edge)
		_lg.line(x1*tileSize,y1*tileSize,x2*tileSize,y2*tileSize)
		if self.edges[current_edge] and self.edges[current_edge][2] then
			current_edge = self.edges[current_edge][2]
		else
			break
		end
		count = count + 1
	until current_edge == start[1] or count > tolerance
	_lg.setColor(255,255,255)
end

function Monocle:add_edge(x1,y1,x2,y2,is_proj, split)
	local split = split or false
	local is_proj = is_proj or false
	local tup = tuple(x1,y1,x2,y2)
	local dist = self.distPointToLine(self.x,self.y,x1,y1,x2,y2)
	self.edges[tup] = {tup, false, false, 
						['projection'] = is_proj, 
						['distance'] = dist,
						['split'] = split}
end

function Monocle:draw_debug()
	for e in self.edges:values() do

		local x1,y1,x2,y2 = unpack(e[1])

		_lg.setColor(0,200,50)
		local edge_scaled = {}
		for i, _ in ipairs(e[1]) do
			edge_scaled[i] = e[1][i] * tileSize
		end
		_lg.line(edge_scaled)
		_lg.setColor(0,0,0)
		_lg.circle('fill',x1* tileSize,y1* tileSize,2)
		_lg.circle('fill',x2* tileSize,y2* tileSize,2)

		if e[2] == false then
			_lg.setColor(255,0,0)
			_lg.circle('fill',(x1/3 + 2*x2/3) * tileSize,(y1/3 + 2*y2/3) * tileSize,2)
		end
		if e[3] == false then
			_lg.setColor(255,255,0)
			_lg.circle('fill',(2*x1/3 + x2/3) * tileSize,(2*y1/3 + y2/3) * tileSize,2)
		end
	end
	self:draw_vision_edge()
end

function Monocle:get_border_intersection(x1,y1)
	grid_height = #self.grid
	grid_width = #self.grid[1]

	if self.x <= x1 then
		local intersectX, intersectY = self:findIntersect(self.x,self.y,x1,y1,grid_width, 0, grid_width, grid_height)
		if intersectX then 
			return intersectX, intersectY
		end
	elseif self.x > x1 then
		local intersectX, intersectY = self:findIntersect(self.x,self.y,x1,y1,0, 0, 0, grid_height)
		if intersectX then 
			return intersectX, intersectY
		end
	end

	if self.y <= y1 then
		local intersectX, intersectY = self:findIntersect(self.x,self.y,x1,y1,0, grid_height, grid_width, grid_height)
		if intersectX then 
			return intersectX, intersectY
		end
	elseif self.y > y1 then
		local intersectX, intersectY = self:findIntersect(self.x,self.y,x1,y1,0, 0, grid_width, 0)
		if intersectX then 
			return intersectX, intersectY
		end
	end
end

-- Checks if two lines intersect (or line segments if seg is true)
-- Lines are given as four numbers (two coordinates)
function Monocle:findIntersect(l1p1x,l1p1y, l1p2x,l1p2y, l2p1x,l2p1y, l2p2x,l2p2y, seg1, seg2)
	-- added tolerance
	local tolerance = 0.00000000001
	local round_to = 50
	local a1,b1,a2,b2 = l1p2y-l1p1y, l1p1x-l1p2x, l2p2y-l2p1y, l2p1x-l2p2x
	local c1,c2 = a1*l1p1x+b1*l1p1y, a2*l2p1x+b2*l2p1y
	local det = a1*b2 - a2*b1
	if det==0 then return false, "The lines are parallel." end
	local x,y = (b2*c1-b1*c2)/det, (a1*c2-a2*c1)/det
	if seg1 or seg2 then
	    local min,max = math.min, math.max
	    if seg1 and not (min(l1p1x,l1p2x) <= x + tolerance and x <= max(l1p1x,l1p2x) + tolerance and min(l1p1y,l1p2y) <= y + tolerance 
	       and y <= (max(l1p1y,l1p2y)) + tolerance) or
	       seg2 and not (min(l2p1x,l2p2x) <= x + tolerance and x <= max(l2p1x,l2p2x) + tolerance and min(l2p1y,l2p2y) <= y + tolerance 
	          and y <= (max(l2p1y,l2p2y)) + tolerance) then
	        return false, "The lines don't intersect."
	    end
	end
	return x,y
	--return self.round(x,round_to),self.round(y,round_to)
end

function Monocle.distPointToLine(px,py,x1,y1,x2,y2)
  local dx,dy = x2-x1,y2-y1
  local length = math.sqrt(dx*dx+dy*dy)
  dx,dy = dx/length,dy/length
  local posOnLine = dx*(px-x1) + dy*(py-y1)
  if posOnLine < 0 then
    -- first end point is closest
    dx,dy = px-x1,py-y1
    return math.sqrt(dx*dx+dy*dy)
  elseif posOnLine > length then
    -- second end point is closest
    dx,dy = px-x2,py-y2
    return math.sqrt(dx*dx+dy*dy)   
  else
    -- point is closest to some part in the middle of the line
    return math.abs( dy*(px-x1) - dx*(py-y1))
  end
end

function Monocle.dist_points(x1,y1,x2,y2)
	return math.sqrt((y2-y1)^2 + (x2-x1)^2)
end

function Monocle.round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end
--taken from http://stackoverflow.com/questions/15706270/sort-a-table-in-lua
function Monocle:spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

return Monocle