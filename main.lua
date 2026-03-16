-- Perfect Judgement
-- entry for LÖVE Jam 2026
-- by holipop

local baton = require("lib.baton")
local roomy = require("lib.roomy")
local flux = require("lib.flux")
local khao = require("lib.khao")

local StateMachine = require("lib.batteries.state_machine")
local Vector2 = require("lib.batteries.vec2")
local pathfind = require("lib.batteries.pathfind")

---- CONSTANTS ----

local DIRECTIONS = {
    NORTH = 0,
    EAST = 1,
    SOUTH = 2,
    WEST = 3,
}
local DX_DIRECTIONS = {
    [DIRECTIONS.NORTH] = 0,
    [DIRECTIONS.EAST] = 1,
    [DIRECTIONS.SOUTH] = 0,
    [DIRECTIONS.WEST] = -1,
}
local DY_DIRECTIONS = {
    [DIRECTIONS.NORTH] = -1,
    [DIRECTIONS.EAST] = 0,
    [DIRECTIONS.SOUTH] = 1,
    [DIRECTIONS.WEST] = 0,
}
local function direction_to_delta (dir)
    return DX_DIRECTIONS[dir], DY_DIRECTIONS[dir]
end
local function delta_to_direction (dx, dy)
    if dx == 0 and dy == -1 then
        return DIRECTIONS.NORTH
    elseif dx == 1 and dy == 0 then
        return DIRECTIONS.EAST
    elseif dx == 0 and dy == 1 then
        return DIRECTIONS.SOUTH
    elseif dx == -1 and dy == 0 then
        return DIRECTIONS.WEST
    end
end

local TILE_LENGTH = 50

local function ternary (a, b, c)
    if a then 
        return b
    else
        return c
    end
end

local input = baton.new({
    controls = {
        rotate_left = { "key:left" },
        rotate_right = { "key:right" },
        move_forward = { "key:up" },
        move_backward = { "key:down" },
        action = { "key:z" },
        parry = { "key:x" },
    },
    pairs = {
        movement = { "rotate_left", "rotate_right", "move_backward", "move_forward" }
    }
})


---- tile_map ----

local tile_map = {}

function tile_map:at (x, y)
    for index, tile in ipairs(self) do
        if tile.position.x == x and tile.position.y == y then
            return tile
        end
    end

    return nil
end

function tile_map:add_at (entity, x, y)
    assert(not self:at(x, y), string.format("(tile_map:add at) [%d, %d] is already occupied", x, y))
    
    entity.position.x = x
    entity.position.y = y
    entity.sprite.position.x = x
    entity.sprite.position.y = y

    tile_map[#tile_map + 1] = entity
end

function tile_map:add_random (entity)
    local x, y = 0, 0
    repeat
        x = love.math.random(0, 15)
        y = love.math.random(0, 11)
    until not self:at(x, y)

    self:add_at(entity, x, y)
end

function tile_map:remove_at (x, y)
    local entity
    for index, tile in ipairs(self) do
        if tile.position.x == x and tile.position.y == y then
            entity = table.remove(self, index)
            break
        end
    end
    return entity
end


---- player ----

local INPUT_QUEUE_SECONDS = .2

local player = {
    active = true,
    position = Vector2(0, 0),
    rotation = DIRECTIONS.EAST,
    sprite = {
        position = Vector2(0, 0),
    },
    input_queued = nil,
    input_timer = 0,
}

local bullet = {
    active = false,
    t = 0,
    --[[ x1 = 0,
    x2 = 0,
    y1 = 0,
    y2 = 0, ]]
    v1 = Vector2(0, 0),
    v2 = Vector2(0, 0),
}

player.states = {}
player.states.idle = {
    update = function (state, dt)
        if player.input_queued == "move_forward" or player.input_queued == "move_backward" then
            local df = ternary(player.input_queued == "move_forward", 1, -1)
            player.input_queued = nil

            local dx = DX_DIRECTIONS[player.rotation]
            local dy = DY_DIRECTIONS[player.rotation]

            local next_x = player.position.x + dx * df
            local next_y = player.position.y + dy * df
            local entity = tile_map:at(next_x, next_y)

            if entity and entity.active then
                return "wait"
            end

            --[[ player.position.x = player.position.x + dx * df
            player.position.y = player.position.y + dy * df ]]
            player.position:scalar_add_inplace(dx * df, dy * df)

            flux.to(player.sprite.position, INPUT_QUEUE_SECONDS, {
                x = player.position.x,
                y = player.position.y,
            })

            return "wait"
        elseif player.input_queued == "action" then
            bullet.active = true
            bullet.t = .05
            --[[ bullet.x1 = player.position.x
            bullet.y1 = player.position.y ]]
            --[[ bullet.x2 = player.position.x
            bullet.y2 = player.position.y ]]

            bullet.v1:vector_set(player.position)
            bullet.v2:vector_set(player.position)

            local dx = DX_DIRECTIONS[player.rotation]
            local dy = DY_DIRECTIONS[player.rotation]
            local entity = nil
            repeat
                --[[ bullet.x2 = bullet.x2 + dx
                bullet.y2 = bullet.y2 + dy ]]
                bullet.v2:scalar_add_inplace(dx, dy)

                if 
                    bullet.v2.x > 16 or 
                    bullet.v2.x < 0 or
                    bullet.v2.y > 12 or
                    bullet.v2.y < 0
                then
                    break
                end

                entity = tile_map:at(bullet.v2:unpack())
            until entity and entity.active

            if entity then
                entity.active = false
            end

            return "wait"
        end
    end
}
player.states.wait = {
    enter = function (state)
        state.t = 0
    end,
    update = function (state, dt)
        state.t = state.t + dt

        if state.t > INPUT_QUEUE_SECONDS then
            return "idle"
        end
    end
}
player.sm = StateMachine(player.states, "idle")

function player:update (dt)
    if input:pressed("rotate_left") or input:pressed("rotate_right") then
        local dr = ternary(input:get("rotate_right") > 0, 1, -1)

        self.rotation = (self.rotation + dr) % 4
    end

    if input:pressed("move_forward") then
        self.input_queued = "move_forward"
        self.input_timer = INPUT_QUEUE_SECONDS
    elseif input:pressed("move_backward") then
        self.input_queued = "move_backward"
        self.input_timer = INPUT_QUEUE_SECONDS
    elseif input:pressed("action") then
        self.input_queued = "action"
        self.input_timer = INPUT_QUEUE_SECONDS
    elseif input:pressed("parry") then
        self.input_queued = "parry"
        self.input_timer = INPUT_QUEUE_SECONDS
    end

    if self.input_timer > 0 then
        self.input_timer = self.input_timer - dt
    else
        self.input_queued = nil
        self.input_timer = 0
    end

    if bullet.t > 0 then
        bullet.t = bullet.t - dt
    else
        bullet.active = false
        bullet.t = 0
    end

    self.sm:update(dt)
end

function player:draw ()
    self.sm:draw()

    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.rectangle("fill", self.sprite.position.x * TILE_LENGTH, self.sprite.position.y * TILE_LENGTH, TILE_LENGTH, TILE_LENGTH)

    -- pointer
    local dx = DX_DIRECTIONS[self.rotation]
    local dy = DY_DIRECTIONS[self.rotation]

    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.setLineWidth(5)
    love.graphics.line(
        (self.sprite.position.x * TILE_LENGTH) + (TILE_LENGTH / 2), 
        (self.sprite.position.y * TILE_LENGTH) + (TILE_LENGTH / 2),
        (self.sprite.position.x * TILE_LENGTH + dx * TILE_LENGTH) + (TILE_LENGTH / 2),
        (self.sprite.position.y * TILE_LENGTH + dy * TILE_LENGTH) + (TILE_LENGTH / 2)
    )
    
    -- bullet
    love.graphics.setColor(1, 1, 0, 1)
    if bullet.active then
        love.graphics.line(
            (bullet.v1.x * TILE_LENGTH) + (TILE_LENGTH / 2), 
            (bullet.v1.y * TILE_LENGTH) + (TILE_LENGTH / 2),
            (bullet.v2.x * TILE_LENGTH) + (TILE_LENGTH / 2),
            (bullet.v2.y * TILE_LENGTH) + (TILE_LENGTH / 2)
        )
    end

    -- debug
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(
        "position: " .. tostring(player.position) .. "\n" ..
        "rotation: " .. tostring(player.rotation) .. "\n" ..
        "input_queued: " .. tostring(player.input_queued) .. "\n" ..
        "input_timer: " .. tostring(player.input_timer) .. "\n",
        50, 50
    )
end


---- Wall ----

local Wall = {}
Wall.__index = Wall

function Wall:new(x, y)
    local instance = {
        active = true,
        position = Vector2(x, y),
        rotation = DIRECTIONS.EAST,
        sprite = {
            position = Vector2(x, y),
        },
    }

    -- instance.states = {}
    instance.sm = StateMachine({})
    
    return setmetatable(instance, self)
end

function Wall:update (dt)
end

function Wall:draw ()
    local opacity = ternary(self.active, 1, .25)
    love.graphics.setColor(0, 0, 1, opacity)
    love.graphics.rectangle("fill", self.sprite.position.x * TILE_LENGTH, self.sprite.position.y * TILE_LENGTH, TILE_LENGTH, TILE_LENGTH)
end

---- Enemy ----

local ENEMY_REACTION_SECONDS = 1

local function enemy_pathfind_is_goal (v)
    return v == player.position
end

local function enemy_pathfind_neighbours (v)
    local neighbors = {}
    for index, dir in pairs(DIRECTIONS) do
        local dx = DX_DIRECTIONS[dir]
        local dy = DY_DIRECTIONS[dir]

        local entity = tile_map:at(v.x + dx, v.y + dy)

        if entity and entity.position:equals(player.position) then
            neighbors[#neighbors + 1] = entity.position
        elseif not entity then
            neighbors[#neighbors + 1] = Vector2(v.x + dx, v.y + dy)
        end
    end
    return neighbors
end

local function enemy_pathfind_heuristic (v)
    return v:distance(player.position) 
end

local Enemy = {}
Enemy.__index = Enemy

function Enemy:new(x, y)
    local instance = {
        active = true,
        position = Vector2(x, y),
        rotation = DIRECTIONS.EAST,
        sprite = {
            position = Vector2(x, y),
        },
    }

    instance.pathfind_args = { 
        start = instance.position,
        is_goal = enemy_pathfind_is_goal,
        neighbours = enemy_pathfind_neighbours,
        distance = Vector2.distance,
        heuristic = enemy_pathfind_heuristic,
    }

    instance.states = {}
    instance.states.idle = {
        enter = function (state)
            state.t = 0
        end,
        update = function (state, dt)
            state.t = state.t + dt

            if not instance.active then
                return "dead"
            end

            if state.t < ENEMY_REACTION_SECONDS then
                return nil
            end

            local path = pathfind(instance.pathfind_args)
            if path then
                local next = path[2]
                local dx = next.x - instance.position.x
                local dy = next.y - instance.position.y

                instance.rotation = delta_to_direction(dx, dy)

                if next:equals(player.position) then
                    return
                end
                
                instance.position.x = next.x
                instance.position.y = next.y

                flux.to(instance.sprite.position, INPUT_QUEUE_SECONDS, {
                    x = instance.position.x,
                    y = instance.position.y,
                })

                return "idle"
            end

            state.t = 0
        end
    }
    instance.states.dead = {}

    instance.sm = StateMachine(instance.states, "idle")
    
    return setmetatable(instance, self)
end

function Enemy:update (dt)
    self.sm:update(dt)
end

function Enemy:draw ()
    local opacity = ternary(self.active, 1, .25)
    love.graphics.setColor(0, .75, .75, opacity)
    love.graphics.rectangle("fill", self.sprite.position.x * TILE_LENGTH, self.sprite.position.y * TILE_LENGTH, TILE_LENGTH, TILE_LENGTH)

    -- pointer
    local dx = DX_DIRECTIONS[self.rotation]
    local dy = DY_DIRECTIONS[self.rotation]

    love.graphics.setColor(0, 1, 1, opacity)
    love.graphics.setLineWidth(5)
    love.graphics.line(
        (self.sprite.position.x * TILE_LENGTH) + (TILE_LENGTH / 2), 
        (self.sprite.position.y * TILE_LENGTH) + (TILE_LENGTH / 2),
        (self.sprite.position.x * TILE_LENGTH + dx * TILE_LENGTH) + (TILE_LENGTH / 2),
        (self.sprite.position.y * TILE_LENGTH + dy * TILE_LENGTH) + (TILE_LENGTH / 2)
    )

    self.sm:draw()
end


---- Main Loop ----

local t = 0

function love.load ()
    --tile_map:add_at(Player, {}, 2, 3)

    for i = 1, 25 do
        tile_map:add_random(Wall:new(0, 0))
    end
    tile_map:add_random(Enemy:new(0, 0))
    tile_map:add_random(Enemy:new(0, 0))

    tile_map:add_random(player)

end

function love.update (dt)
    t = t + dt

    flux.update(dt)
    input:update()

    for index, entity in ipairs(tile_map) do
        entity:update(dt)
    end
end

function love.draw ()
    -- background
    love.graphics.setColor(1, 1, 1, .5)
    for i = 0, love.graphics.getWidth(), TILE_LENGTH do
        for j = 0, love.graphics.getHeight(), TILE_LENGTH do
            love.graphics.rectangle("line", i, j, TILE_LENGTH, TILE_LENGTH)
        end
    end

    for index, entity in ipairs(tile_map) do
        love.graphics.push("all")
        entity:draw()
        love.graphics.pop()
    end
end