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
local color = require("lib.batteries.colour")

---- CONSTANTS ----

local function hsva (h, s, v, a)
    local r, g, b = color.hsv_to_rgb(h / 360, s / 100, v / 100)
    return { r, g, b, a or 1 }
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

local TILE_LENGTH = 50

local tile_map = {
    tiles = {},
    height = 16,
    width = 12,
}

function tile_map:position_to_index (x, y)
    return y * self.width + x + 1
end

for y = 0, tile_map.height - 1 do
    for x = 0, tile_map.width - 1 do
        local index = tile_map:position_to_index(x, y)
        tile_map.tiles[index] = {
            vector = Vector2(x, y),
            occupant = false
        }
    end
end

function tile_map:get_entity_at (x, y)
    return self.tiles[self:position_to_index(x, y)].occupant
end