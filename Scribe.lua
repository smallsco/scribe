--- SCRÏBE: A message box library for Love2D 
-- @version 0.2
-- @license MIT https://github.com/smallsco/scribe/blob/master/LICENSE
local Scribe = {}
Scribe.__index = Scribe
setmetatable( Scribe, {
  __call = function (cls, ...)
    return cls.new(...)
  end,
})
local require_path = (...):match( "(.-)[^%.]+$" )
local popo = require( require_path .. '.popo.Text' )


--- The default click callback function. Creates a "link" operation that opens the "param"
--- as a URL (i.e. using your web browser) if the left mouse button is pressed.
-- @param number x The absolute x coordinate of the click
-- @param number y The absolute y coordinate of the click
-- @param string button The left "l" or right "r" mouse button pressed
-- @param string op The operation to perform
-- @param string param The parameter to use with the operation
local function defaultClickCallback( x, y, button, op, param )

    if op == 'link' and button == 'l' then
        love.system.openURL( param )
    end

end


--- Gets the x/y scale factors required to resize a source image to a target size.
-- @see https://love2d.org/forums/viewtopic.php?f=4&t=79756
-- @param userdata image The source Image object
-- @param number newWidth The target width
-- @param number newHeight The target height
-- @return number The x scale factor
-- @return number The y scale factor
local function getImageScaleForNewDimensions( image, newWidth, newHeight )

    local currentWidth, currentHeight = image:getDimensions()
    return ( newWidth / currentWidth ), ( newHeight / currentHeight )
    
end


--- Draws the "container", or "message box" to the screen - not the text itself.
-- This provides a default in the event that the user does not set a "bg" option.
-- @param number x How many pixels to draw the container from the left
-- @param number y How many pixels to draw the container from the top
-- @param number w How wide in pixels to make the container
-- @param number h How tall in pixels to make the container
local function renderDefaultContainer( x, y, w, h )

    love.graphics.setColor( { 140, 0, 26, 192 } )
    love.graphics.rectangle( 'fill', x, y, w, h )
    love.graphics.setLineWidth( 2 )
    love.graphics.setColor( { 255, 255, 255 } )
    love.graphics.rectangle( 'line', x, y, w, h )
    love.graphics.setColor( { 128, 128, 128 } )
    love.graphics.rectangle( 'line', x+2, y+2, w-4, h-4 )

end


--- Constructor / Factory Function
-- @param table opt A table containing initialization options
-- @return Scribe
function Scribe.new( opt )

    local self = setmetatable( {}, Scribe )
    local opt = opt or {}
    
    self.font = opt.font or love.graphics.getFont()
    self.x = opt.x or 10
    self.xpad = opt.xpad or 10
    self.ypad = opt.ypad or 10
    self.y = ( opt.y or love.graphics.getHeight() - ( self.font:getHeight() * 4 ) - 10 ) - ( self.ypad * 2 )
    self.w = opt.w or love.graphics.getWidth() - 10 - 10
    self.h = opt.h or ( self.font:getHeight() * 4 ) + ( self.ypad * 2 )
    self.bg = opt.bg or renderDefaultContainer
    self.scale_bg = ( opt.scale_bg == nil ) and true or opt.scale_bg
    self.click_callback = ( opt.click_calback == nil ) and opt.click_callback or defaultClickCallback
    self.color = opt.color or { 255, 255, 255 }
    self.name = opt.name
    self.name_color = opt.name_color or { 255, 255, 0 }
    self.text = opt.text
    self.text_speed = opt.text_speed or 50
    self.spinner = opt.spinner
    self.typewriter = ( opt.typewriter == nil ) and true or opt.typewriter
    self.text_modifiers = opt.text_modifiers or {}
    
    self:regenerate()
    
    return self

end


--- Regenerates the underlying Popo text object.
-- @param string append Optional text to append to the contents of the message box
function Scribe:regenerate( append )

    local opts = {
        font = self.font,
        wrap_width = self.w - ( 2 * self.xpad ),
        _spinnerImg = self.spinner,
        _spinnerInit = function( c )
            c.ox = c.image:getWidth() / 2
            c.oy = c.image:getHeight() / 2
        end,
        _spinner = function( dt, c, x, y )
            if not c.r then
                c.r = math.rad( 0 )
            else
                c.r = c.r + math.rad(4)
                if c.r >= math.rad(360) then
                    c.r = math.rad(0)
                end
            end
            c.x = x - c.ox
            c.y = y - c.oy
        end,
        _typewriterInit = function( c )
            c.t0 = love.timer.getTime()
        end,
        _typewriter = function( dt, c, start )
            if not start then start = 0 end
            local r, g, b, a = love.graphics.getColor()
            local nc = math.floor( self.text_speed * ( love.timer.getTime() - c.t0 ) )
            love.graphics.setColor( r, g, b, 0 )
            if c.position < nc + start then
                love.graphics.setColor( r, g, b, a )
            end
        end,
        color = function( dt, c, r, g, b )
            love.graphics.setColor( r, g, b )
        end,
        onclick = function( dt, c, op, param )
            if not c.click_op then
                c.click_op = op
                c.click_param = param
            end
        end,
        customDraw = function( x, y, c )
            love.graphics.print(
                c.character,
                ( x or c.text.x ) + c.x,
                ( y or c.text.y ) + c.y,
                c.r or 0,
                c.sx or 1,
                c.sy or 1,
                c.ox or 0,
                c.oy or 0
            )
            love.graphics.setColor( self.color )
        end,
        customDrawImage = function( img, x, y, c )
            love.graphics.draw(
                img,
                ( x or c.text.x ) + c.x,
                ( y or c.text.y ) + c.y,
                c.r or 0,
                c.sx or 1,
                c.sy or 1,
                c.ox or 0,
                c.oy or 0
            )
            love.graphics.setColor( self.color )
        end,
    }
    
    -- FIXME: figure out how to reference 'self' outside of this class
    -- so that custom text modifiers can reference it
    for k, v in pairs( self.text_modifiers ) do
        if k == 'customDraw' or k == 'customDrawImage' then
            error( 'cannot override the customDraw / customDrawImage functions' )
        elseif k:sub( 1, 1 ) == '_' then
            error( 'cannot start modifiers with an underscore' )
        end
        opts[ k ] = v
    end
    
    local name = ''
    if self.name then
        name = '[' .. self.name .. '](color: ' .. self.name_color[1] .. ', ' .. self.name_color[2] .. ', ' .. self.name_color[3] .. ')@n'
    end
    
    local spinner = ''
    if self.spinner then
        spinner = '[ ](_spinnerImg;_spinner: ' .. ( self.w - 2*self.xpad ) .. ', ' .. ( self.h - 2*self.ypad ) .. ')'
    end
    
    
    if append then
        if self.typewriter then
            self.popo = popo( 0, 0, name .. self.text .. '[' .. append .. spinner .. '](_typewriter: ' .. self.popo.str_text:len() .. ')', opts )
        else
            self.popo = popo( 0, 0, name .. self.text .. append .. spinner, opts )
        end
        self.text = self.text .. append
    else
        if self.typewriter then
            self.popo = popo( 0, 0, name .. '[' .. self.text .. spinner .. '](_typewriter)', opts )
        else
            self.popo = popo( 0, 0, name .. self.text .. spinner, opts )
        end
    end

end



function Scribe:mousepressed( x, y, button )
    for _, v in ipairs( self.popo.characters ) do
        if v.click_op ~= nil then
        
            -- translate the localized x, y into absolute coordinates
            local tx = v.x + self.x + self.xpad
            local ty = v.y + self.y + 10
        
            if x >= tx and x < self.popo.font:getWidth( v.character ) + tx then
                if y >= ty and y < self.popo.font:getHeight() + ty then
                    self.click_callback( x, y, button, v.click_op, v.click_param )
                end
            end
            
        end
    end
end


--- Updates the background of the message box.
-- @param mixed bg The new background of the message box. Can be an image or a function.
function Scribe:setBackground( bg )
    self.bg = bg or renderDefaultContainer
end


--- Updates the click callback function.
-- @param function f The new click callback function
function Scribe:setClickCallback( f )
    if type( f ) == 'function' then
        self.click_callback = f
    else
        error( 'Click callback must be a function' )
    end
end


--- Updates the default text color of the message box.
-- @param table color The new default color for text in the message box
function Scribe:setColor( color )
    self.color = color or { 255, 255, 255 }
end


--- Updates the default font of the message box.
-- @param userdata font The new default font for text in the message box
function Scribe:setFont( font )
    self.font = font or love.graphics.getFont()
end


--- Updates the name color of the message box.
-- @param table color The new name color for the message box
function Scribe:setNameColor( color )
    self.name_color = color
end


--- Updates the name in the message box.
-- @param string str The text to replace the name of the message box with
function Scribe:setName( str )
    self.name = str
end


--- Updates the text of the message box.
-- @param string str The text to replace the contents of the message box with
function Scribe:setText( str )
    self.text = str
    self:regenerate()
end


--- Updates the speed of the typewriter effect.
-- @param number speed The speed at which to print text to the screen, when using
-- the typewriter effect
function Scribe:setTextSpeed( speed )
    self.text_speed = speed or 50
end


--- Appends text to the message box.
-- @param string str The text to append the contents of the message box with
function Scribe:append( str )
    self:regenerate( str )
end


--- Wraps popo's update function. Call this on love.update()
-- @param number dt Delta Time
function Scribe:update( dt )
    self.popo:update( dt )
end


--- Renders the message box. Call this on love.draw()
function Scribe:draw()

    -- Render container
    if type( self.bg ) == 'function' then
        self.bg( self.x, self.y, self.w, self.h )
    elseif type( self.bg ) == 'userdata' and self.bg:type() == 'Image' then
        local scaleX, scaleY = 1
        if self.scale_bg then
            scaleX, scaleY = getImageScaleForNewDimensions( self.bg, self.w, self.h )
        end
        love.graphics.setColor( { 255, 255, 255 } )
        love.graphics.draw( self.bg, self.x, self.y, 0, scaleX, scaleY )
    end
    
    -- Render Text
    -- FIXME: get rid of hardcoded 10 (y margin from bottom)
    love.graphics.setColor( self.color )
    self.popo:draw(
        self.x + self.xpad,
        self.y + 10
    )
    
end


return Scribe