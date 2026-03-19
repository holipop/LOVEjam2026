-- LÖVE Jam 2026
-- by holipop

local khao = require("lib.khao")
local flux = require("lib.flux")
local baton = require("lib.baton")
local StateMachine = require("lib.batteries.state_machine")

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

local function ternary (a, b, c)
    if a then 
        return b
    else
        return c
    end
end

local function wait (t)
    local start = love.timer.getTime()

    while love.timer.getTime() - start < t do
        coroutine.yield()
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

local enemies = {
    list = {},
    hash = {},
}

function enemies:add ()
    local x, y, key = 0, 0, 0

    repeat 
        x = love.math.random(1, 15)
        y = love.math.random(1, 11)
        key = x * 100 + y
    until not enemies.hash[key]
    
    local instance = {
        x = x,
        y = y,
        key = key,
        i = #self.list + 1
    }

    self.list[#self.list + 1] = instance
    self.hash[key] = instance
end

function enemies:remove_at (x, y)
    local key = x * 100 + y
    local instance = self.hash[key]

    if instance then
        table.remove(self.list, instance.i)
        self.hash[key] = nil

        for index, enemy in ipairs(enemies.list) do
            enemy.i = index
        end
    end
end

enemies:add()
enemies:add()
enemies:add()
enemies:add()
enemies:add()
enemies:add()
enemies:add()
enemies:add()
enemies:add()
enemies:add()
enemies:add()
enemies:add()
enemies:add()
enemies:add()
enemies:add()
enemies:add()

local t = 0
local player = {
    x = 0,
    y = 0,
    r = DIRECTIONS.EAST,
    next_df = 0,
    sprite_x = 0,
    sprite_y = 0,
}

local movement_states = {
    idle = {
        update = function (state, dt)
            local is_movement_queued = (player.next_df ~= 0)
            if is_movement_queued then
                local dx = DX_DIRECTIONS[player.r]
                local dy = DY_DIRECTIONS[player.r]

                print(dx, dy)

                --[[ flux.to(player, .25, { ]]
                    player.x = player.x + dx * player.next_df
                    player.y = player.y + dy * player.next_df
                --[[ }) ]]

                flux.to(player, .25, {
                    sprite_x = player.x,
                    sprite_y = player.y,
                })

                player.next_df = 0

                return "moving"
            elseif input:pressed("move_forward") or input:pressed("move_backward") then
                local df = ternary(input:get("move_forward") > 0, 1, -1)

                local dx = DX_DIRECTIONS[player.r]
                local dy = DY_DIRECTIONS[player.r]

                --[[ flux.to(player, .25, { ]]
                    player.x = player.x + dx * df
                    player.y = player.y + dy * df
                --[[ }) ]]

                flux.to(player, .25, {
                    sprite_x = player.x,
                    sprite_y = player.y,
                })

                return "moving"
            end
        end,
    },
    moving = {
        enter = function (state)
            state.t = 0
        end,
        update = function (state, dt)
            state.t = state.t + dt
            
            if input:pressed("movement") then
                local _, df = input:get("movement")

                player.next_df = df
            end

            if state.t > .25 then
                return "idle"
            end
        end
    }
}

local movement_sm = StateMachine(movement_states, "idle")

local bullet = {
    x1 = 0,
    x2 = 0,
    y1 = 0,
    y2 = 0,
    active = false,
    t = 0,
}

function player:update (dt)
    if input:pressed("rotate_left") or input:pressed("rotate_right") then
        local dr = ternary(input:get("rotate_right") > 0, 1, -1)

        player.r = (player.r + dr) % 4
    end

    if bullet.t > 0 then
        bullet.t = bullet.t - dt
    end

    if bullet.t <= 0 then
        bullet.active = false
    end

    if input:pressed("action") then
        bullet.t = .1
        bullet.active = true
        bullet.x1 = player.x
        bullet.y1 = player.y
        bullet.x2 = player.x
        bullet.y2 = player.y

        local dx = DX_DIRECTIONS[player.r]
        local dy = DY_DIRECTIONS[player.r]
        local key = 0
        local enemy

        repeat
            bullet.x2 = bullet.x2 + dx
            bullet.y2 = bullet.y2 + dy
            key = bullet.x2 * 100 + bullet.y2
            enemy = enemies.hash[key]

            if 
                bullet.x2 > 16 or 
                bullet.x2 < 0 or
                bullet.y2 > 12 or
                bullet.y2 < 0
            then
                break
            end
        until enemy

        if enemy then
            enemies:remove_at(bullet.x2, bullet.y2)
        end
    end

    movement_sm:update(dt)
end


function love.update (dt)
    t = t + dt

    input:update()
    flux.update(dt)
    player:update(dt)
end

function love.draw ()
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1, 0.5)

    for i = 0, love.graphics.getWidth(), TILE_LENGTH do
        for j = 0, love.graphics.getHeight(), TILE_LENGTH do
            love.graphics.rectangle("line", i, j, TILE_LENGTH, TILE_LENGTH)
        end
    end

    love.graphics.setColor(0, 0, 1, 1)
    for index, enemy in ipairs(enemies.list) do
        love.graphics.rectangle("fill", enemy.x * TILE_LENGTH, enemy.y * TILE_LENGTH, TILE_LENGTH, TILE_LENGTH)
    end

    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.rectangle("fill", player.sprite_x * TILE_LENGTH, player.sprite_y * TILE_LENGTH, TILE_LENGTH, TILE_LENGTH)

    love.graphics.setColor(1, 1, 0, 1)
    if bullet.active then
        love.graphics.line(
            (bullet.x1 * TILE_LENGTH) + (TILE_LENGTH / 2), 
            (bullet.y1 * TILE_LENGTH) + (TILE_LENGTH / 2),
            (bullet.x2 * TILE_LENGTH) + (TILE_LENGTH / 2),
            (bullet.y2 * TILE_LENGTH) + (TILE_LENGTH / 2)
        )
    end

    local dx = DX_DIRECTIONS[player.r]
    local dy = DY_DIRECTIONS[player.r]

    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.setLineWidth(5)
    love.graphics.line(
        (player.sprite_x * TILE_LENGTH) + (TILE_LENGTH / 2), 
        (player.sprite_y * TILE_LENGTH) + (TILE_LENGTH / 2),
        (player.sprite_x * TILE_LENGTH + dx * TILE_LENGTH) + (TILE_LENGTH / 2),
        (player.sprite_y * TILE_LENGTH + dy * TILE_LENGTH) + (TILE_LENGTH / 2)
    )

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(
        "x: " .. player.x .. "\n" .. 
        "y: " .. player.y .. "\n" ..
        "r: " .. player.r .. "\n"--[[  .. 
        "next_x: " .. player.next_x .. "\n" .. 
        "next_y: " .. player.next_y .. "\n" ]],
        50, 50
    )
end