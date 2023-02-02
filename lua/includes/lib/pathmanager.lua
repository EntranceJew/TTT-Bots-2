--[[
TODO goals for pathmanager:
    - Send a request to the pathmanager to generate a path between two vectors.
        If there is no path between the two vectors, return false.
        If there is a path, return the path as a table of CNavAreas. Finer details can be added later.

    - Once a path is generated, it should be cached by its CNavArea start and end points.
        If a path is requested between the same two CNavAreas, return the cached path.
        If it is unaccessed for more than 5 seconds, remove it from the cache, to save memory.

    - Once a path is generated, store its output in the bot's LatestPath field.
]]

TTTBots.PathManager = {}
TTTBots.PathManager.cache = {}
TTTBots.PathManager.cullSeconds = 5
TTTBots.PathManager.maxCachedPaths = 200
TTTBots.PathManager.completeRange = 100


--[[ Define local A* functions ]]

-- A* Heuristic: Euclidean distance
local function heuristic_cost_estimate( start, goal )
	return start:GetCenter():Distance( goal:GetCenter() )
end

-- using CNavAreas as table keys doesn't work, we use IDs
local function reconstruct_path( cameFrom, current )
	local total_path = { current }

	current = current:GetID()
	while ( cameFrom[ current ] ) do
		current = cameFrom[ current ]
		table.insert( total_path, navmesh.GetNavAreaByID( current ) )
    end
	return total_path
end

local function Astar( start, goal )
	-- Return false if either navarea is invalid or if start == goal
	if ( not IsValid( start ) or not IsValid( goal ) ) then return false end 
	if ( start == goal ) then return true end 

	-- cameFrom is a table that will be used to reconstruct the path at the end
	local cameFrom = {} 

	-- Clear the search lists and add the start navarea to the open list
	start:ClearSearchLists()
	start:AddToOpenList()

	-- Set the cost so far and total cost of the start navarea
	start:SetCostSoFar( 0 )
	start:SetTotalCost( heuristic_cost_estimate( start, goal ) )
	start:UpdateOnOpenList() 

	-- Continue looping until the open list is empty
	while ( not start:IsOpenListEmpty() ) do
		-- Pop the navarea with the lowest total cost off the open list and add it to the closed list
		local current = start:PopOpenList()

		-- If the current navarea is the goal navarea, reconstruct and return the path
		if ( current == goal ) then
			return table.Reverse(reconstruct_path( cameFrom, current ))
		end

		current:AddToClosedList()

		-- Examine each of the current navarea's neighbors
		for k, neighbor in pairs( current:GetAdjacentAreas() ) do
			-- Calculate the cost of reaching the neighbor from the start navarea
			local newCostSoFar = current:GetCostSoFar() + heuristic_cost_estimate( current, neighbor )

			-- Skip this neighbor if it is underwater
			if ( neighbor:IsUnderwater() ) then
				continue
			end
			
			-- Skip this neighbor if it has already been fully explored and has a lower cost
			if ( ( neighbor:IsOpen() or neighbor:IsClosed() ) and neighbor:GetCostSoFar() <= newCostSoFar ) then
				continue
			else
				-- Update the neighbor's cost so far and total cost
                neighbor:SetCostSoFar(newCostSoFar);
                
                -- Add a cost if we need to fall down to get to the neighbor
                if (neighbor:ComputeGroundHeightChange(current) > 100) then
                    neighbor:SetCostSoFar(neighbor:GetCostSoFar() + 1000);
                end

				neighbor:SetTotalCost( newCostSoFar + heuristic_cost_estimate( neighbor, goal ) )

				-- If the neighbor was on the closed list, remove it
				if ( neighbor:IsClosed() ) then
					neighbor:RemoveFromClosedList()
				end

				-- If the neighbor was on the open list, update its position on the list
				if ( neighbor:IsOpen() ) then
					neighbor:UpdateOnOpenList()
				-- Otherwise, add the neighbor to the open list
				else
					neighbor:AddToOpenList()
				end

				-- Update the cameFrom table to reflect that the path to the neighbor goes through the current navarea
				cameFrom[ neighbor:GetID() ] = current:GetID()
			end
		end
	end

	-- Return false if no path was found
	return false
end

local function AstarVector( start, goal )
	-- Find the nearest navareas to the start and goal positions
	local startArea = navmesh.GetNearestNavArea( start )
	local goalArea = navmesh.GetNearestNavArea( goal )

	-- Find a path between the start and goal navareas
	return Astar( startArea, goalArea )
end


--[[]]


local PathManager = TTTBots.PathManager

-- Request the creation of a path between two vectors. Returns pathinfo, which contains the path as a table of CNavAreas and the time of generation.
-- If it already exists, then return the cached path.
function PathManager.RequestPath(startpos, finishpos)
    -- Check if the path already exists in the cache
    local path = PathManager.GetPath(startpos, finishpos)
    if path then
        return path
    end

    -- If it doesn't exist, generate it
    local path = PathManager.GeneratePath(startpos, finishpos)
    if path then
        return path
    end

    -- If it still doesn't exist, return false
    return false
end

-- See the RequestPath function for external use.
-- This function is only used internally, and should not be called from outside the PathManager file.
function PathManager.GeneratePath(startpos, finishpos)
    -- Find the nearest navareas to the start and goal positions
    local startArea = navmesh.GetNearestNavArea(startpos)
    local goalArea = navmesh.GetNearestNavArea(finishpos)

    -- Find a path between the start and goal navareas
    local path = Astar(startArea, goalArea)
    if not path then return false end

    local pathinfo = {
        path = path,
        generatedAt = CurTime(),
        TimeSince = function (self)
            return CurTime() - self.generatedAt
        end
    }

    -- Cache the path
    PathManager.cache[startArea:GetID() .. "-" .. goalArea:GetID()] = pathinfo

    -- Return the pathinfo table
    return pathinfo
end

-- Return an existing pathinfo for a path between two vectors, or false if it doesn't exist.
-- Used internally in the RequestPath function, prefer to use RequestPath instead.
function PathManager.GetPath(startpos, finishpos)
    local nav1 = navmesh.GetNearestNavArea(startpos)
    local nav2 = navmesh.GetNearestNavArea(finishpos)
    if not nav1 or not nav2 then return false end

    local pathinfo = PathManager.cache[nav1:GetID() .. "-" .. nav2:GetID()]
    return pathinfo
end

-- Bezier curve function; p0 is the start point, p1 is the control point, p2 is the end point, and t is the time.
-- t ranges from 0 to 1, and represents the percentage of the path that has been travelled.
local function bezierQuadratic(p0, p1, p2, t)
    local x = (1 - t) ^ 2 * p0.x + 2 * (1 - t) * t * p1.x + t ^ 2 * p2.x
    local y = (1 - t) ^ 2 * p0.y + 2 * (1 - t) * t * p1.y + t ^ 2 * p2.y
    local z = (1 - t) ^ 2 * p0.z + 2 * (1 - t) * t * p1.z + t ^ 2 * p2.z
    return Vector(x, y, z)
end

local function getBezierPoints(start, control, finish, numpoints)
    local points = {}
    for i = 0, numpoints do
        local t = i / numpoints
        local point = bezierQuadratic(start, control, finish, t)
        table.insert(points, point)
    end
end

-- Smooths a path of CNavAreas using bezier curves. Returns a table of vectors.
-- smoothness is an integer that represents the number of points to be generated between each navarea.
function PathManager.SmoothPath(path, smoothness)
    -- The start is the center of the first navarea, the control point is the center of the second navarea, and the end is the center of the third navarea.

    local smoothPath = {}
    local n = 0 -- track number of points for next step

    for i = 1, #path-2, 3 do
        n = n + 1
        local p0 = path[i]:GetCenter()
        local p1 = path[i + 1]:GetCenter()
        local p2 = path[i + 2]:GetCenter()

        for j = 1, smoothness do
            local t = j / smoothness
            local point = bezierQuadratic(p0, p1, p2, t)
            table.insert(smoothPath, point)
        end
    end

    -- If the path is not divisible by 3, then we need to add the last navarea(s) to the path.
    if #path % 3 == 1 then
        table.insert(smoothPath, path[#path]:GetCenter())
    elseif #path % 3 == 2 then
        table.insert(smoothPath, path[#path - 1]:GetCenter())
        table.insert(smoothPath, path[#path]:GetCenter())
    end

    return smoothPath
end

-- Cull the cache of paths that are older than the cullSeconds, and cull the oldest if we have too many paths.
function PathManager.CullCache()
    local cullSeconds = PathManager.cullSeconds
    local maxPaths = PathManager.maxCachedPaths

    local paths = PathManager.cache
    local pathsToCull = {}

    -- Find paths that are older than cullSeconds
    for k, path in pairs(paths) do
        if path:TimeSince() > cullSeconds then
            table.insert(pathsToCull, k)
        end
    end

    -- If we have too many paths, cull the oldest
    if table.Count(paths) > maxPaths then
        local oldestPath = nil
        local oldestTime = 0
        for k, path in pairs(paths) do
            if path:TimeSince() > oldestTime then
                oldestPath = k
                oldestTime = path:TimeSince()
            end
        end
        table.insert(pathsToCull, oldestPath)
    end

    -- Cull the paths
    for k, path in pairs(pathsToCull) do
        paths[path] = nil
    end
end

-- Create timer to cull paths every 5 seconds
timer.Create("TTTBotsPathManagerCullCache", 5, 0, function ()
    PathManager.CullCache()
end)