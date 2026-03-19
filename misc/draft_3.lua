-- Perfect Judgement
-- entry for LÖVE Jam 2026
-- by holipop

-- special thanks to:
-- julie
-- josh
-- ellipses

--[[

Notes:

There is an insane amount of jumping around and coupling. I feel suffocated in this.

]]

local baton = require("lib.baton")
local roomy = require("lib.roomy")
local flux = require("lib.flux")
local khao = require("lib.khao")

local StateMachine = require("lib.batteries.state_machine")
local Vector2 = require("lib.batteries.vec2")
local pathfind = require("lib.batteries.pathfind")
local color = require("lib.batteries.colour")

---- CONSTANTS ----

local function hsva (h, s, v)
    return function (a)
        local r, g, b = color.hsv_to_rgb(h / 360, s / 100, v / 100)
        return r, g, b, a or 1
    end
end

local PINK_1 = hsva(357, 29, 91)
local PINK_2 = hsva(357, 48, 81)
local PINK_3 = hsva(355, 47, 74)
local PINK_4 = hsva(352, 45, 65)
local PINK_5 = hsva(345, 43, 53)
local PINK_6 = hsva(322, 33, 35)
local PINK_7 = hsva(322, 80, 17)

local CYAN_1 = hsva(177, 18, 92)
local CYAN_2 = hsva(178, 47, 81)
local CYAN_3 = hsva(182, 44, 64)
local CYAN_4 = hsva(188, 41, 51)
local CYAN_5 = hsva(195, 37, 41)
local CYAN_6 = hsva(204, 33, 35)

local TILE_LENGTH = 50
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
    return DIRECTIONS.NORTH
end

local function ternary (a, b, c)
    if a then 
        return b
    else
        return c
    end
end

local input = baton.new({
    controls = {
        left = { "key:left" },
        right = { "key:right" },
        forward = { "key:up" },
        backward = { "key:down" },
        action = { "key:z" },
        parry = { "key:x" },
    },
    pairs = {
        movement = { "left", "right", "forward", "backward" }
    }
})

---- tile_map ----

local tile_map = {
    entities = {},
    vectors = {},
    height = 12,
    width = 16,
}

for y = 0, tile_map.height - 1 do
    local column = {}
    for x = 0, tile_map.width - 1 do
        column[x + 1] = Vector2(x, y)
    end
    tile_map.vectors[y + 1] = column
end

function tile_map:get_entity_at (x, y)
    for index, entity in ipairs(self.entities) do
        if entity.position.x == x and entity.position.y == y then
            return entity
        end
    end
end

function tile_map:get_vector_at (x, y)
    return self.vectors[y + 1][x + 1]
end

function tile_map:is_within_bounds (x, y)
    return (
        x >= 0 and
        y >= 0 and
        x < self.width and
        y < self.height
    )
end

function tile_map:add_entity (entity, x, y)
    assert(not self:get_entity_at(x, y), "tile already occupied")
    assert(self:is_within_bounds(x, y), "tile out of bounds")

    entity.position:sset(x, y)
    entity.sprite.position:sset(x, y)

    self.entities[#self.entities + 1] = entity
end

function tile_map:add_entity_random (entity)
    local x, y = 0, 0

    repeat
        x = love.math.random(0, self.width - 1)
        y = love.math.random(0, self.height - 1)
    until not self:get_entity_at(x, y)

    self:add_entity(entity, x, y)
end

---- Entity ----

local MOVE_SECONDS = .2

local Entity = {}
Entity.__index = Entity

function Entity:new(Brain, Sprite)
    local instance = {
        active = true,
        position = Vector2(0, 0),
        rotation = DIRECTIONS.EAST,
        sprite = {
            position = Vector2(0, 0)
        },
    }
    instance.brain = Brain:new(instance)
    
    return setmetatable(instance, self)
end

function Entity:delta ()
    return DX_DIRECTIONS[self.rotation], DY_DIRECTIONS[self.rotation]
end

function Entity:move (direction)
    local df = ternary(direction == "forward", 1, -1)
    local dx, dy = self:delta()

    local next_x = self.position.x + dx * df
    local next_y = self.position.y + dy * df
    local entity = tile_map:get_entity_at(next_x, next_y)

    if entity and entity.active then
        df = 0
    end

    self.position:scalar_add_inplace(dx * df, dy * df)

    flux.to(self.sprite.position, MOVE_SECONDS, {
        x = self.position.x,
        y = self.position.y,
    })
end

function Entity:get_entity_in_los ()
    local target_x = self.position.x
    local target_y = self.position.y

    local dx, dy = self:delta()
    local entity = nil

    repeat
        target_x = target_x + dx
        target_y = target_y + dy
        entity = tile_map:get_entity_at(target_x, target_y)

        if not tile_map:is_within_bounds(target_x, target_y) then
            break
        end
    until entity and entity.active 

    return entity
end

function Entity:update (dt)
    self.brain:update(dt)
end

function Entity:draw ()
    love.graphics.setColor(CYAN_6(ternary(self.active, 1, .25)))
    love.graphics.rectangle(
        "fill",
        self.sprite.position.x * TILE_LENGTH,
        self.sprite.position.y * TILE_LENGTH,
        TILE_LENGTH,
        TILE_LENGTH
    )

    -- pointer
    local dx, dy = self:delta()

    love.graphics.setColor(CYAN_2())
    love.graphics.setLineWidth(5)
    love.graphics.line(
        (self.sprite.position.x * TILE_LENGTH) + (TILE_LENGTH / 2), 
        (self.sprite.position.y * TILE_LENGTH) + (TILE_LENGTH / 2),
        (self.sprite.position.x * TILE_LENGTH + dx * TILE_LENGTH) + (TILE_LENGTH / 2),
        (self.sprite.position.y * TILE_LENGTH + dy * TILE_LENGTH) + (TILE_LENGTH / 2)
    )
end

---- EmptyBrain ----

local EmptyBrain = {}
EmptyBrain.__index = EmptyBrain

function EmptyBrain:new()
    local instance = {}
    
    return setmetatable(instance, self)
end

function EmptyBrain:update (dt)
end

---- PlayerBrain ----

local INPUT_QUEUE_SECONDS = .2

local PlayerBrain = {}
PlayerBrain.__index = PlayerBrain

function PlayerBrain:new (entity)
    local instance = {
        entity = entity,
        input_queued = nil,
        input_timer = 0,
    }

    instance.states = {}
    instance.states.idle = {
        update = function (state, dt)
            if instance.input_queued == "forward" or instance.input_queued == "backward" then
                instance.entity:move(instance.input_queued)

                instance.input_queued = nil
                instance.input_timer = 0

                return "wait"
            elseif instance.input_queued == "action" then
                instance.input_queued = nil
                instance.input_timer = 0

                local target = instance.entity:get_entity_in_los()

                if target then
                    target.active = false
                end

                return "wait"
            end
        end
    }
    instance.states.wait = {
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

    instance.sm = StateMachine(instance.states, "idle")
    
    return setmetatable(instance, self)
end

function PlayerBrain:update (dt)
    if input:pressed("left") or input:pressed("right") then
        local dr = ternary(input:get("right") > 0, 1, -1)

        self.entity.rotation = (self.entity.rotation + dr) % 4
    end

    if input:pressed("forward") then
        self.input_queued = "forward"
        self.input_timer = INPUT_QUEUE_SECONDS
    elseif input:pressed("backward") then
        self.input_queued = "backward"
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

    self.sm:update(dt)
end

local player = Entity:new(PlayerBrain)

---- SwordBrain ----

local SWORD_DECISION_SECONDS = 1

local function sword_pathfind_is_goal (v)
    return v:equals(player.position)
end

local function sword_pathfind_neighbours (v)
    local neighbors = {}
    for index, dir in pairs(DIRECTIONS) do
        local dx = DX_DIRECTIONS[dir]
        local dy = DY_DIRECTIONS[dir]
        if tile_map:is_within_bounds(v.x + dx, v.y + dy) then
            local entity = tile_map:get_entity_at(v.x + dx, v.y + dy)
            if entity and entity.position:equals(player.position) then
                neighbors[#neighbors + 1] = tile_map:get_vector_at(v.x + dx, v.y + dy)
            elseif not entity then
                neighbors[#neighbors + 1] = tile_map:get_vector_at(v.x + dx, v.y + dy)
            end
        end
    end
    return neighbors
end

local function sword_pathfind_heuristic (v)
    return v:distance(player.position) 
end

local SwordBrain = {}
SwordBrain.__index = SwordBrain

function SwordBrain:new(entity, x, y)
    local instance = {
        entity = entity
    }

    instance.pathfind_args = {
        start = tile_map:get_vector_at(instance.entity.position:unpack()),
        is_goal = sword_pathfind_is_goal,
        neighbours = sword_pathfind_neighbours,
        distance = Vector2.distance,
        heuristic = sword_pathfind_heuristic,
    }

    instance.states = {}
    instance.states.idle = {
        enter = function (state)
            state.t = 0
        end,
        update = function (state, dt)
            state.t = state.t + dt

            if not instance.entity.active then
                return "dead"
            end

            if state.t < SWORD_DECISION_SECONDS then
                return nil
            end

            local path = pathfind(instance.pathfind_args)
            if path then
                local next = path[2] or instance.entity.position
                local dx = next.x - instance.entity.position.x
                local dy = next.y - instance.entity.position.y

                instance.entity.rotation = delta_to_direction(dx, dy)
                instance.entity:move("forward")
                return "idle"
            end
        end
    }
    instance.states.dead = {}

    instance.sm = StateMachine(instance.states, "idle")
    
    return setmetatable(instance, self)
end

function SwordBrain:update (dt)
    self.sm:update(dt)
end

---- Main Loop ----

local t = 0

function love.load ()
    --[[ for i = 1, 30 do
        tile_map:add_entity_random(Wall:new(0, 0))
    end ]]

    --[[ for i = 1, 30 do
        tile_map:add_entity_random(Entity:new(EmptyBrain))
    end ]]

    tile_map:add_entity_random(player)

    tile_map:add_entity_random(Entity:new(SwordBrain))
    tile_map:add_entity_random(Entity:new(SwordBrain))
    tile_map:add_entity_random(Entity:new(SwordBrain))
    tile_map:add_entity_random(Entity:new(SwordBrain))

    --[[ tile_map.entities[1].active = false
    tile_map.entities[2].active = false
    tile_map.entities[3].active = false ]]
end

function love.update (dt)
    t = t + dt

    flux.update(dt)
    input:update()

    for _, entity in pairs(tile_map.entities) do
        entity:update(dt)
    end
end

function love.draw ()
    -- background
    love.graphics.setBackgroundColor(CYAN_1())

    love.graphics.setColor(CYAN_6(.25))
    for i = 0, love.graphics.getWidth(), TILE_LENGTH do
        for j = 0, love.graphics.getHeight(), TILE_LENGTH do
            love.graphics.rectangle("line", i, j, TILE_LENGTH, TILE_LENGTH)
        end
    end

    for _, entity in pairs(tile_map.entities) do
        love.graphics.push("all")
        entity:draw()
        love.graphics.pop()
    end

    -- debug
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print(
        "position: " .. tostring(player.position) .. "\n" ..
        "rotation: " .. tostring(player.rotation) .. "\n" ..
        "input_queued: " .. tostring(player.brain.input_queued) .. "\n" ..
        "input_timer: " .. tostring(player.brain.input_timer) .. "\n",
        50, 50
    )
end
