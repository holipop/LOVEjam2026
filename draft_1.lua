-- Perfect Judgement
-- entry for LÖVE Jam 2026
-- by holipop

local baton = require("lib.baton")
local roomy = require("lib.roomy")
local flux = require("lib.flux")
local khao = require("lib.khao")
local StateMachine = require("lib.batteries.state_machine")

---- constants ----

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

local INPUT_QUEUE_SECONDS = .2
local TILE_LENGTH = 50

local function ternary (a, b, c)
    if a then 
        return b
    else
        return c
    end
end

local function make_key (x, y)
    return x * 100 + y
end

local function wait_state (seconds, return_state)
    return {
        enter = function (state)
            state.t = 0
        end,
        update = function (state, dt)
            state.t = state.t + dt

            if state.t > seconds then
                return return_state
            end
        end
    }
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

---- TileEntity ----

local TileEntity = {}
TileEntity.__index = TileEntity
--[[ function TileEntity:new (tbl, x, y, r)
    local instance = tbl or {}

    instance.x = x
    instance.y = y
    instance.r = r or DIRECTIONS.NORTH
    instance.sprite = {}
    instance.states = {}
    instance.sm = StateMachine(self.states)
    
    return setmetatable(instance, self)
end ]]

function TileEntity:update (dt)
    self.sm:update(dt)
end

function TileEntity:draw ()
    self.sm:draw()
end

---- Player ----

local Player = setmetatable({}, TileEntity)
Player.__index = Player

function Player:new (tbl, x, y, r)
    local instance = tbl or {}

    instance.x = x
    instance.y = y
    instance.r = r or DIRECTIONS.EAST
    instance.sprite = {
        x = x,
        y = y,
    }
    instance.input_queued = nil
    instance.input_timer = 0

    instance.states = {
        idle = {
            update = function (state, dt)
                if instance.input_queued == "move_forward" or instance.input_queued == "move_backward" then
                    local df = ternary(instance.input_queued == "move_foward", 1, -1)

                    local dx = DX_DIRECTIONS[instance.r]
                    local dy = DY_DIRECTIONS[instance.r]

                    instance.x = instance.x + dx * df
                    instance.y = instance.y + dy * df

                    flux.to(instance.sprite, .25, {
                        x = instance.x,
                        y = instance.y,
                    })

                    return "moving"
                end
            end
        },
        moving = wait_state(INPUT_QUEUE_SECONDS, "idle")
    }

    instance.sm = StateMachine(self.states, "idle")
    
    return setmetatable(instance, self)
end

function Player:update (dt)
    if input:pressed("rotate_left") or input:pressed("rotate_right") then
        local dr = ternary(input:get("rotate_right") > 0, 1, -1)

        self.r = (self.r + dr) % 4
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

    self.input_timer = self.input_timer - dt

    if self.input_timer <= 0 then
        self.input_queued = nil
    end
end

function Player:draw ()
    love.graphics.push("all")

    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.rectangle("fill", self.sprite.x * TILE_LENGTH, self.sprite.y * TILE_LENGTH, TILE_LENGTH, TILE_LENGTH)

    love.graphics.pop()
end


local tile_map = {}

function tile_map:is_tile_occupied (x, y)
    for index, tile in ipairs(self) do
        if tile.x == x and tile.y == y then
            return true
        end
    end

    return false
end

function tile_map:add_at (Type, tbl, x, y)
    assert(not self:is_tile_occupied(x, y), string.format("(tile_map:add at) [%d, %d] is already occupied", x, y))
    
    self[#self + 1] = Type:new(tbl, x, y)
end

function tile_map:remove_at (x, y)
    local entity
    for index, tile in ipairs(self) do
        if tile.x == x and tile.y == y then
            entity = table.remove(self, index)
            break
        end
    end
    return entity
end



function love.load ()
    tile_map:add_at(Player, {}, 2, 3)
end

function love.update (dt)
    flux:update(dt)

    for index, entity in ipairs(tile_map) do
        entity:update(dt)
    end
end

function love.draw ()
    -- background
    for i = 0, love.graphics.getWidth(), TILE_LENGTH do
        for j = 0, love.graphics.getHeight(), TILE_LENGTH do
            love.graphics.rectangle("line", i, j, TILE_LENGTH, TILE_LENGTH)
        end
    end

    for index, entity in ipairs(tile_map) do
        entity:draw()
    end
end