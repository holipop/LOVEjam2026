-- khao ui
-- by holipop

local TRANSPARENT = { 0, 0, 0, 0 }
local WHITE = { 1, 1, 1, 1 }
local BLACK = { 0, 0, 0, 1 }
local RED = { 1, 0, 0, 1 }
local GREEN = { 0, 1, 0, 1 }
local BLUE = { 0, 0, 1, 1 }

local AXES = { "width", "height" }
local SIZING = {
    width = "width_sizing",
    height = "height_sizing",
}
local MIN = {
    width = "min_width",
    height = "min_height",
}
local MAX = {
    width = "max_width",
    height = "max_height",
}
local ON_AXIS_COORD = {
    width = "x",
    height = "y",
}
local ON_AXIS_LENGTH = {
    width = "w",
    height = "h",
}
local ON_AXIS_DIRECTION = {
    width = "row",
    height = "column",
}
local ON_AXIS_ALIGNMENT = {
    width = "align_x",
    height = "align_y",
}
local ON_AXIS_ALIGN_START = {
    width = "left",
    height = "top",
}
local ON_AXIS_ALIGN_END = {
    width = "right",
    height = "bottom",
}
local ON_AXIS_PADDING_START = {
    width = "padding_left",
    height = "padding_top",
}
local ON_AXIS_PADDING_END = {
    width = "padding_right",
    height = "padding_bottom",
}

local CROSS_AXIS_COORD = {
    width = "y",
    height = "x",
}
local CROSS_AXIS_LENGTH = {
    width = "h",
    height = "w",
}
local CROSS_AXIS_DIRECTION = {
    width = "column",
    height = "row",
}
local CROSS_AXIS_ALIGNMENT = {
    width = "align_y",
    height = "align_x",
}
local CROSS_AXIS_ALIGN_START = {
    width = "top",
    height = "left",
}
local CROSS_AXIS_ALIGN_END = {
    width = "bottom",
    height = "right",
}
local CROSS_AXIS_PADDING_START = {
    width = "padding_top",
    height = "padding_left",
}
local CROSS_AXIS_PADDING_END = {
    width = "padding_bottom",
    height = "padding_right",
}

local DEFAULT_SIZING_VALUES = {
    grow = 1,
    fixed = 0,
    fit = 0
}

local function sort_by_max_width (a, b)
    return (a.max_width or math.huge) < (b.max_width or math.huge)
end

local function sort_by_max_height (a, b)
    return (a.max_height or math.huge) < (b.max_height or math.huge)
end

local function sort_by_min_width (a, b)
    return (a.min_width or 0) > (b.min_width or 0)
end

local function sort_by_min_height (a, b)
    return (a.min_height or 0) > (b.min_height or 0)
end

local SORT_BY_MAX = {
    width = sort_by_max_width,
    height = sort_by_max_height,
}

local SORT_BY_MIN = {
    width = sort_by_min_width,
    height = sort_by_min_height,
}

local DEFAULT_FONT = love.graphics.getFont()

local function ternary (a, b, c)
    if a then 
        return b
    else
        return c
    end
end

local function safe_clamp (num, min, max)
    if min and num < min then
        return min
    elseif max and num > max then
        return max
    end

    return num
end


---- Element ----

---@alias khao.Axis "width"|"height"
---@alias khao.SizingType "fixed"|"fit"|"grow"
---@alias khao.DirectionType "row"|"column"
---@alias khao.HorizontalAlignment "left"|"center"|"right"
---@alias khao.VerticalAlignment "top"|"center"|"bottom"

---@class khao.ElementConfig
---@field [number] khao.ElementConfig
---@field [string] any
---@field width_sizing khao.SizingType?
---@field height_sizing khao.SizingType?
---@field width number?
---@field height number?
---@field min_width number?
---@field max_width number?
---@field min_height number?
---@field max_height number?
---@field align_x khao.HorizontalAlignment?
---@field align_y khao.VerticalAlignment?
---@field direction khao.DirectionType?
---@field padding number?
---@field padding_left number?
---@field padding_right number?
---@field padding_top number?
---@field padding_bottom number?
---@field gap number?
---@field name string?
---@field color [number, number, number, number]?
---@field on_update fun(self: khao.Element, dt: number)?
---@field on_draw fun(self: khao.Element, x: number, y: number)?
---@field post_draw fun(self: khao.Element, x: number, y: number)?

---@class khao.Element : khao.ElementConfig
---@field private __index khao.Element
---@field private __call fun(self, config: table): khao.Element
---@field [number] khao.Element
---@field [string] any
---@field x number
---@field y number
---@field w number
---@field h number
---@field parent khao.Element?
---@field width_sizing khao.SizingType
---@field height_sizing khao.SizingType
---@field width number
---@field height number
---@field min_width number?
---@field max_width number?
---@field min_height number?
---@field max_height number?
---@field align_x khao.HorizontalAlignment
---@field align_y khao.VerticalAlignment
---@field direction khao.DirectionType
---@field padding nil
---@field padding_left number
---@field padding_right number
---@field padding_top number
---@field padding_bottom number
---@field gap number
---@field name string
---@field color [number, number, number, number]
---@field on_update fun(self: khao.Element, dt: number)?
---@field on_draw fun(self: khao.Element, x: number, y: number)?
---@field post_draw fun(self: khao.Element, x: number, y: number)?
---@overload fun(config: khao.ElementConfig): khao.Element
local Element = {}

---@diagnostic disable-next-line: assign-type-mismatch
Element.__index = Element

---Initialization for this Element, intended to be overriden by subclasses.
function Element:init ()
    -- abstract
end

---Converts a configuration table into an Element.
---@param config khao.ElementConfig
---@return khao.Element
function Element:from (config)
    local instance = setmetatable(config, self)
    instance:init()
    instance:_set_defaults()

    for index, child in ipairs(instance) do 
        if not getmetatable(child) then
            child = self:from(child) 
        end

        child.parent = instance --[[@as khao.Element]]
    end

    return instance --[[@as khao.Element]]
end

---@diagnostic disable-next-line: param-type-mismatch
setmetatable(Element, { __call = Element.from })
Element.__call = Element.from

---Creates a shallow copy of a given configuration table, converting the clone into an Element.
---@param config khao.ElementConfig
---@return khao.Element
function Element:new (config)
    local instance = {}
    for key, value in pairs(config) do
        instance[key] = value
    end

    return self:from(instance)
end

---Default values for all Elements.
---@private
function Element:_set_defaults ()
    self.x = 0
    self.y = 0
    self.w = 0
    self.h = 0

    self.width = self.width or 0
    self.height = self.height or 0
    self.width_sizing = self.width_sizing or "fixed"
    self.height_sizing = self.height_sizing or "fixed"

    self.align_x = self.align_x or "left"
    self.align_y = self.align_y or "top"
    self.direction = self.direction or "row"
    self.gap = self.gap or 0
    
    self.padding = self.padding or 0
    self.padding_left = self.padding_left or self.padding
    self.padding_right = self.padding_right or self.padding
    self.padding_top = self.padding_top or self.padding
    self.padding_bottom = self.padding_bottom or self.padding

    self.padding = nil -- padding is just a shorthand
    
    self.name = self.name or ""
    self.color = self.color or WHITE
end

---Add the given children to the end of this Element's list of children.
---@param ... table | khao.Element
---@return self
function Element:add_children (...)
    local length = select("#", ...)
    
    for index = 1, length do
        local child = select(index, ...)

        if not setmetatable(child) then
            child = self:from(child)
        end

        self[#self + 1] = child
        child.parent = self
    end

    return self
end

---Returns a class that inherits this class. 
---@return self
function Element:extend ()
    local Class = setmetatable({}, self)
    Class.__index = Class
    Class.__call = Element.from

    return Class
end

---Sets the width and height of each element to their default value.
---@protected
function Element:_reset ()
    for index, child in ipairs(self) do
        child:_reset()
    end

    if self.width_sizing == "fixed" then
        self.w = self.width
    elseif self.width_sizing == "grow" then
        self.w = self.min_width or 0
    else
        self.w = 0
    end

    if self.height_sizing == "fixed" then
        self.h = self.height
    elseif self.height_sizing == "grow" then
        self.h = self.min_height or 0
    else
        self.h = 0
    end
end

---Sets the width or height of all elements with "fit" sizing.
---@protected
---@param axis khao.Axis
function Element:_fit (axis)
    local sizing = SIZING[axis]
    local output = ON_AXIS_LENGTH[axis]
    local min, max = MIN[axis], MAX[axis]
    local on_padding = self[ON_AXIS_PADDING_START[axis]] + self[ON_AXIS_PADDING_END[axis]]
    local cross_padding = self[CROSS_AXIS_PADDING_START[axis]] + self[CROSS_AXIS_PADDING_END[axis]]

    for index, child in ipairs(self) do
        child:_fit(axis)
    end

    local parent = self.parent

    if self[sizing] == "fit" then
        if self.direction == ON_AXIS_DIRECTION[axis] then
            self[output] = self[output] + on_padding + self.gap * (#self - 1)
        elseif self.direction == CROSS_AXIS_DIRECTION[axis] then
            self[output] = self[output] + cross_padding
        end
        self[output] = safe_clamp(self[output], self[min], self[max])
    end

    if parent and parent[sizing] == "fit" then
        if parent.direction == ON_AXIS_DIRECTION[axis] then
            parent[output] = parent[output] + self[output]
        elseif parent.direction == CROSS_AXIS_DIRECTION[axis] then
            parent[output] = math.max(parent[output], self[output])
        end
    end
end

---Sets the width or height of all Elements with "grow" sizing.
---@protected
---@param axis khao.Axis
function Element:_grow (axis)
    local sizing = SIZING[axis]
    local output = ON_AXIS_LENGTH[axis]
    local min, max = MIN[axis], MAX[axis]
    local padding = self[ON_AXIS_PADDING_START[axis]] + self[ON_AXIS_PADDING_END[axis]]

    if #self < 1 then
        goto continue
    end

    if self.direction == ON_AXIS_DIRECTION[axis] then
        local available_space = self[output] - ((#self - 1) * self.gap + padding)
        local total_grow = 0
        local growing_children = {}

        for index, child in ipairs(self) do
            if child[sizing] == "grow" then
                total_grow = total_grow + child[axis]
                growing_children[#growing_children + 1] = child
            else
                available_space = available_space - child[output]
            end
        end
        
        -- if remaining_length is zero, there's no need to grow or shrink anything
        if available_space == 0 then
            goto continue
        end

        table.sort(growing_children, SORT_BY_MAX[axis])

        for index, child in ipairs(growing_children) do
            local slice = (available_space * (child[axis] / total_grow)) - child[output]
            child[output] = safe_clamp(child[output] + slice, child[min], child[max])

            available_space = math.max(available_space - child[output], 0)
            total_grow = total_grow - child[axis]
        end
    elseif self.direction == CROSS_AXIS_DIRECTION[axis] then
        local length = self[output] - padding

        for index, child in ipairs(self) do
            if child[sizing] == "grow" then
                child[output] = safe_clamp(length, child[min], child[max])
            end
        end
    end

    ::continue::

    for index, child in ipairs(self) do
        child:_grow(axis)
    end
end

---This method exists purely so Text elements can wrap text.
---@protected
function Element:_wrap ()
    for index, child in ipairs(self) do
        child:_wrap()
    end
end

---Sets the position of this element's children relative to it.
---@protected
function Element:_position ()
    if #self <= 0 then
        return
    end

    local axis = ternary(self.direction == "row", "width", "height")
    local on_axis_padding = self[ON_AXIS_PADDING_START[axis] ] + self[ON_AXIS_PADDING_END[axis] ]
    local cross_axis_padding = self[CROSS_AXIS_PADDING_START[axis] ] + self[CROSS_AXIS_PADDING_END[axis] ]

    local on_axis_space = self[ON_AXIS_LENGTH[axis] ] - on_axis_padding
    local cross_axis_space = self[CROSS_AXIS_LENGTH[axis] ] - cross_axis_padding

    on_axis_space = on_axis_space - (#self - 1) * self.gap

    for index, child in ipairs(self) do
        on_axis_space = on_axis_space - child[ON_AXIS_LENGTH[axis] ]
    end

    local on_axis_coord = self[ON_AXIS_PADDING_START[axis] ] 

    if self[ON_AXIS_ALIGNMENT[axis] ] == ON_AXIS_ALIGN_START[axis] then
        on_axis_coord = on_axis_coord + 0
    elseif self[ON_AXIS_ALIGNMENT[axis] ] == "center" then
        on_axis_coord = on_axis_coord + on_axis_space / 2
    elseif self[ON_AXIS_ALIGNMENT[axis] ] == ON_AXIS_ALIGN_END[axis] then
        on_axis_coord = on_axis_coord + on_axis_space
    end

    for index, child in ipairs(self) do
        local cross_axis_coord = self[CROSS_AXIS_PADDING_START[axis] ]

        if self[CROSS_AXIS_ALIGNMENT[axis] ] == CROSS_AXIS_ALIGN_START[axis] then
            cross_axis_coord = cross_axis_coord + 0
        elseif self[CROSS_AXIS_ALIGNMENT[axis] ] == "center" then
            cross_axis_coord = cross_axis_coord + (cross_axis_space - child[CROSS_AXIS_LENGTH[axis] ]) / 2
        elseif self[CROSS_AXIS_ALIGNMENT[axis] ] == CROSS_AXIS_ALIGN_END[axis] then
            cross_axis_coord = cross_axis_coord + (cross_axis_space - child[CROSS_AXIS_LENGTH[axis] ])
        end

        child[ON_AXIS_COORD[axis] ] = on_axis_coord
        child[CROSS_AXIS_COORD[axis] ] = cross_axis_coord

        on_axis_coord = on_axis_coord + child[ON_AXIS_LENGTH[axis] ] + self.gap

        child:_position()
    end
end

---A dummy method for recursively calling `:on_calc`
---@protected
function Element:_calc ()
    self:on_calc()
    
    for index, child in ipairs(self) do
        child:_calc()
    end
end

---Calculate the dimensions and relative positions of this Element and its descendents.
function Element:calculate ()
    self:_reset()
    self:_fit("width")
    self:_grow("width")
    self:_wrap()
    self:_fit("height")
    self:_grow("height")
    self:_position()
    self:_calc()
end

---A callback fired after this element's dimensions and positions are calculated, intended to be overridden by subclasses.
function Element:on_calc ()
    -- abstract
end

---Update the element and trigger it and its children's `:on_update` methods.
---Elements are updated in depth-first pre-order.
---@param dt number
function Element:update (dt)
    self:on_update(dt)

    for index, child in ipairs(self) do
        child:update(dt)
    end
end

---Draw the element and trigger it and its children's draw methods.
---`:on_draw` is called in depth-first pre-order while `:post_draw` is post-order.
---@param x number
---@param y number
function Element:draw (x, y)
    x = x + self.x
    y = y + self.y

    love.graphics.push("all")
    self:on_draw(x, y)

    for index, child in ipairs(self) do
        child:draw(x, y)
    end

    self:post_draw(x, y)
    love.graphics.pop()
end

---A callback for when this element is updated, intended to be overridden by subclasses.
---@param dt number
function Element:on_update (dt)
    -- abstract
end

---A callback for when this element is drawn, intended to be overridden by subclasses.
---@param x number
---@param y number
function Element:on_draw (x, y)
    -- abstract
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", x, y, self:get_dimensions())

    love.graphics.setColor(BLACK)
    love.graphics.print(self.name, x, y, self:get_dimensions())
end

---A callback for after this element and its child elements are drawn, intended to be overridden by subclasses.
function Element:post_draw (x, y)
    -- abstract
end

---@return number w
---@return number h
function Element:get_dimensions ()
    return self.w, self.h
end


---- Text ---- 

---@class khao.Text : khao.Element
---@field content string
---@field font love.Font
---@field on_update fun(self: khao.Text, dt: number)?
---@field on_draw fun(self: khao.Text, x: number, y: number)?
---@field post_draw fun(self: khao.Text, x: number, y: number)?
---@overload fun(config: khao.ElementConfig): khao.Text
local Text = Element:extend()

function Text:init ()
    self.content = self.content or ""
    self.font = self.font or love.graphics.getFont()

    self.width_sizing = "grow"
    self.height_sizing = "grow"
    self.width = 1
    self.height = 1

    self.min_width = self.min_width or self.font:getHeight()
    self.max_width = self.max_width or self.font:getWidth(self.content)
    self.min_height = self.min_height or self.font:getHeight()
    self.max_height = self.max_height or 0

    self.color = self.color or BLACK
end

function Text:_wrap ()
    local _, wrapped_text = self.font:getWrap(self.content, self.w)
    
    local height = self.font:getHeight() * #wrapped_text
    self.h = height
    self.max_height = height
    self.min_height = self.max_height
end

function Text:on_draw (x, y)
    love.graphics.setColor(self.color)
    love.graphics.setFont(self.font)
    love.graphics.printf(self.content, x, y, self.w)
end


---- Image ----

---@class khao.Image : khao.Element
---@field image love.Image
---@field quad love.Quad
---@field path string?
---@field settings table?
---@field angle number
---@field skew_x number
---@field skew_y number
---@field scale_x number
---@field scale_y number
---@field offset_x number
---@field offset_y number
---@field on_update fun(self: khao.Image, dt: number)?
---@field on_draw fun(self: khao.Image, x: number, y: number)?
---@field post_draw fun(self: khao.Image, x: number, y: number)?
---@overload fun(config: khao.ElementConfig): khao.Image
local Image = Element:extend()

function Image:init ()
    self.path = self.path
    self.settings = self.settings
    self.image = self.image or love.graphics.newImage(self.path, self.settings)
    
    local image_width, image_height = self.image:getDimensions()
    self.quad = self.quad or love.graphics.newQuad(0, 0, image_width, image_height, image_width, image_height)

    self.width = self.width or image_width
    self.height = self.height or image_height

    self.sx = 1
    self.sy = 1

    self.angle = self.angle or 0
    self.skew_x = self.skew_x or 0
    self.skew_y = self.skew_y or 0
    self.scale_x = self.scale_x or 1
    self.scale_y = self.scale_y or 1
    self.offset_x = self.offset_x or 0
    self.offset_y = self.offset_y or 0

    self.color = self.color or WHITE
end

function Image:on_calc ()
    local image_width, image_height = self.image:getDimensions()

    self.sx = self.w / image_width
    self.sy = self.h / image_height
end

function Image:on_draw (x, y)
    love.graphics.setColor(self.color)
    love.graphics.draw(
        self.image, 
        self.quad,
        x, y,
        self.angle,
        self.scale_x * self.sx, self.scale_y * self.sy,
        self.offset_x, self.offset_y,
        self.skew_x, self.skew_y
    )
end


---- Transform ----

---@class khao.Transform : khao.Element
---@field transform love.Transform
---@field angle number
---@field skew_x number
---@field skew_y number
---@field scale_x number
---@field scale_y number
---@field origin_x number
---@field origin_y number
---@field on_update fun(self: khao.Transform, dt: number)?
---@field on_draw fun(self: khao.Transform, x: number, y: number)?
---@field post_draw fun(self: khao.Transform, x: number, y: number)?
---@overload fun(config: khao.ElementConfig): khao.Transform
local Transform = Element:extend()

function Transform:init ()
    self.angle = self.angle or 0
    self.skew_x = self.skew_x or 0
    self.skew_y = self.skew_y or 0
    self.scale_x = self.scale_x or 1
    self.scale_y = self.scale_y or 1
    self.origin_x = self.origin_x or 0
    self.origin_y = self.origin_y or 0

    self.transform = love.math.newTransform(
        0, 0,
        self.angle,
        self.scale_x, self.scale_y, 
        self.origin_x, self.origin_y,
        self.skew_x, self.skew_y
    )
end

function Transform:draw (x, y)
    x = x + self.x
    y = y + self.y

    self.transform:setTransformation(
        x, y, 
        self.angle, 
        self.scale_x, self.scale_y, 
        self.origin_x, self.origin_y,
        self.skew_x, self.skew_y
    )

    love.graphics.push("all")
    love.graphics.applyTransform(self.transform)
    self:on_draw(0, 0)

    for index, child in ipairs(self) do
        child:draw(0, 0)
    end

    self:post_draw(0, 0)
    love.graphics.pop()
end


local khao = {
    _LICENSE = [[
        MIT License

        Copyright (c) 2026 holipop

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.
    ]],
    CONSTANTS = {
        AXES,
        SIZING,
        MIN,
        MAX,
        ON_AXIS_COORD,
        ON_AXIS_LENGTH,
        ON_AXIS_DIRECTION,
        ON_AXIS_ALIGNMENT,
        ON_AXIS_ALIGN_START,
        ON_AXIS_ALIGN_END,
        ON_AXIS_PADDING_START,
        ON_AXIS_PADDING_END,
        CROSS_AXIS_COORD,
        CROSS_AXIS_LENGTH,
        CROSS_AXIS_DIRECTION,
        CROSS_AXIS_ALIGNMENT,
        CROSS_AXIS_ALIGN_START,
        CROSS_AXIS_ALIGN_END,
        CROSS_AXIS_PADDING_START,
        CROSS_AXIS_PADDING_END,
        DEFAULT_SIZING_VALUES,
        SORT_BY_MAX,
        SORT_BY_MIN,
    },
    Element = Element,
    Text = Text,
    Image = Image,
    Transform = Transform,
}

return khao