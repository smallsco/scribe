# Scribe

A textbox library for LÖVE.

## Usage

Place [Scribe.lua](https://github.com/smallsco/scribe/blob/master/Scribe.lua) into your project's directory, and require it like this:

```lua
Scribe = require 'Scribe'
```

A Scribe object is returned, which acts as a Factory. Using this object, you can create many textboxes.

## Table of Contents

* [Examples](#examples)
  * [Creating a textbox](#creating-a-textbox)
  * [Positioning the textbox](#positioning-the-textbox)
  * [Fonts and Colors](#fonts-and-colors)
  * [Text-Modifying Functions](#text-modifying-functions)
  * [Images](#images)
  * [Clicks](#clicks)
  * [Setting the Background](#setting-the-background)
  * [Setting a Name](#setting-a-name)
  * [Adding or Replacing Text](#adding-or-replacing-text)
  * [Spinner](#spinner)
  * [Regeneration](#regeneration)
* [Copyright and License](#copyright-and-license)

## Examples

### Creating a textbox

Creates a textbox object and then updates and draws it:

```lua
function love.load()
    textbox = Scribe({
        text = 'Hello, World!'
    })
end

function love.update( dt )
    textbox:update( dt )
end

function love.draw()
    textbox:draw()
end

-- Optional, only necessary if you want to use click functions.
function love.mousepressed( x, y, b )
	textbox:mousepressed( x, y, b )
end
```

![ex1](http://i.imgur.com/bbX3GVq.gif)

You can set the `typewriter` parameter to false if you want to disable the typewriter effect. The speed of the effect can be changed by playing with the `text_speed` parameter - lower numbers are slower, higher numbers are faster. The default is 50.

### Positioning the textbox

If a position for the textbox is not explicitly specified, it will be created at the bottom of the window, stretched across the width of the window. The height will be automatically calculated based on the size of the font, in order to accomodate up to four lines of text.

To set an explicit position for the textbox, the `x`, `y`, `w`, and `h` parameters can be set when creating the box:

```lua
textbox = Scribe({
    text = 'Hello, World!',
    x = 50,
    y = 100,
    w = 250,
    h = 50
})
```

![ex2](http://i.imgur.com/hE5HNmL.gif)

### Fonts and Colors

In order to set the default font used by the textbox, simply set the `font` parameter to a LÖVE Font object when creating the box. This also allows you to set the size of the text.

To set the default color, use the `color` parameter and pass in a table containing the r, g, and b values for that color:

```lua
textbox = Scribe({
    text = 'Hello, World!',
    font = love.graphics.newFont( 'animeace2_reg.ttf', 24 ),
    color = {0,255,0}
})
```
![ex3](http://i.imgur.com/4JiSxGy.gif)

You can use multiple fonts by adding a new font to the `text_modifiers` table, like this:

```lua
textbox = Scribe({
    text = 'Hello [again](italic), [World](color:0,255,0)!',
    font = love.graphics.newFont( 'animeace2_reg.ttf', 24 ),
    text_modifiers = {
        italic = love.graphics.newFont( 'animeace2_ital.ttf', 24 ),
    }
})
```
![ex4](http://i.imgur.com/2FZTgPk.gif)

To use multiple colors - as seen above - use the `color` text modifier and pass in the R, G, and B values to it as arguments.

More on how text modifiers work below.

### Text-Modifying Functions

Text-Modifying Functions, or "text modifiers", can be used to change the appearance of the text dynamically. For example, this code makes the text change color each time love.draw() is called:

```lua
textbox = Scribe({
    text = '[Hello, World!](randomColor)',
    font = love.graphics.newFont( 'animeace2_reg.ttf', 24 ),
    text_modifiers = {
        randomColor = function(dt, c)
            love.graphics.setColor(math.random(32, 222), math.random(32, 222), math.random(32, 222))
        end
    }
})
```

![ex5](http://i.imgur.com/c5Crqda.gif)

This functionality is made possible thanks to [Popo](https://github.com/adonaac/popo/), the underlying library which SCRÏBE uses to render text. Popo's text modifiers are very powerful, and are documented here:

* [Functions](https://github.com/adonaac/popo/blob/master/README.md#functions)
* [Multiple functions](https://github.com/adonaac/popo/blob/master/README.md#multiple-functions)
* [Init functions](https://github.com/adonaac/popo/blob/master/README.md#init-functions)
* [Passing values to functions](https://github.com/adonaac/popo/blob/master/README.md#passing-parameters-to-functions)
* [Syntax](https://github.com/adonaac/popo/blob/master/README.md#syntax)

### Images

One particularly special text-modifying function allows you to replace that piece of text with an image, like so:

```lua
textbox = Scribe({
    text = 'Hello, [   ](smiley) World!',
    font = love.graphics.newFont( 'animeace2_reg.ttf', 24 ),
    text_modifiers = {
        smiley = love.graphics.newImage( 'smiley.png' )
    }
})
```
![ex6](http://i.imgur.com/3DpTjZE.gif)

Note that images are not automatically resized in any way. It is up to you to ensure that enough space is reserved for the image, and that it is no bigger than the height of a single row of text.

### Clicks

SCRÏBE allows you to run a callback function when clicking on a particular piece of text. The default callback function allows you to create hyperlinks, and works like this:

```lua
textbox = Scribe({
    text = '[Hello, World!](onclick: "link", "http://www.google.ca")',
    font = love.graphics.newFont( 'animeace2_reg.ttf', 24 )
})
```

Clicking on the "Hello, World!" text will launch Google in your system default web browser.

You can override the default callback function when creating the textbox object, by setting the `click_callback` parameter. The function you provide takes five values as input:

* `x` - The absolute x coordinate of where the click occurred
* `y` - The absolute y coordinate of where the click occurred
* `button` - The mouse button pressed - `l` for left or `r` for right
* `op` - The operation to perform, so that your callback function may perform many different operations.
* `param` - The parameter required to execute the operation.

For example, here's how you could implement both hyperlinks and a simple logger:

```lua
function hyperlinksAndLogger( x, y, button, op, param )
    if op == 'link' and button == 'l' then
        love.system.openURL( param )
    elseif op == 'log' and button == 'l' then
        print( param )
    end
end
textbox = Scribe({
    text = '[Hello](onclick: "log", "Hello, Log!"), [World!](onclick: "link", "http://www.google.ca")',
    font = love.graphics.newFont( 'animeace2_reg.ttf', 24 ),
    click_callback = hyperlinksAndLogger
})
```


### Setting the Background

SCRÏBE supports two different methods of setting the textbox background. The first is to write your own function to draw it. The function must accept four parameters - `x`, `y`, `w`, and `h` - so that SCRÏBE can tell it what size box to draw and where to draw it. The function then needs to be passed into the `bg` parameter when creating the textbox:

```lua
function renderGreenBox( x, y, w, h )
    love.graphics.setColor( { 0, 160, 80, 192 } )
    love.graphics.rectangle( 'fill', x, y, w, h )
    love.graphics.setLineWidth( 2 )
    love.graphics.setColor( { 255, 255, 255 } )
    love.graphics.rectangle( 'line', x, y, w, h )
    love.graphics.setColor( { 128, 128, 128 } )
    love.graphics.rectangle( 'line', x+2, y+2, w-4, h-4 )
end
textbox = Scribe({
    text = 'Hello, World!',
    font = love.graphics.newFont( 'animeace2_reg.ttf', 24 ),
    bg = renderGreenBox
})
```

![ex7](http://i.imgur.com/LlaZeCm.gif)

You can also use an image for the background, by setting an Image object as the `bg` parameter. The image will be resized, unless you also set the `scale_bg` parameter to `false` when creating the textbox (which will cause the image to be resized to the textbox size):

```lua
textbox = Scribe({
    text = 'Hello, World!',
    font = love.graphics.newFont( 'animeace2_reg.ttf', 24 ),
    bg = love.graphics.newImage( 'oldmaptb.png' ),
    scale_bg = true
})
```

![ex8](http://i.imgur.com/lHtSSq3.gif)

Finally, you can adjust the padding (space between the start of the background and the start of the text) by modifying the `xpad` and `ypad` parameters when creating the textbox.

### Setting a Name

Some games, such as RPGs or Visual Novels, make use of a textbox to indicate when a certain character is speaking. SCRÏBE allows you to assign a "name" to a textbox, in order to make developing these kinds of games easier:

* The name is displayed at the top of the textbox, followed by a newline character
* The name is excluded from the typewriter effect
* The name can optionally be shown in a different color from the rest of the text

The name and its' color can be set with the `name` and `name_color` parameters when creating the textbox:

```lua
textbox = Scribe({
    text = 'Hello, World!',
    font = love.graphics.newFont( 'animeace2_reg.ttf', 24 ),
    name = 'Narrator',
    name_color = {0,255,0}
})
```

![ex9](http://i.imgur.com/yd9QYc5.gif)

### Adding or Replacing Text

To append additional text to an already-created box, use the `apppend` function of the textbox object, and pass in the text that you would like to append as a parameter:

`textbox:append( 'Hello some more!' )`

To replace the contents of an already-created box with something new, use the `setText` function in the same manner:

`textbox:setText( 'Nope, Goodbye!' )`

### Spinner

A "spinner" is an animated icon used in some games that include a textbox. It indicates that the textbox is waiting for user input (i.e. a keypress or mouse click) before showing additional text.

You can set a spinner image in SCRÏBE by setting the `spinner` property to a LÖVE Image object when creating the textbox. The image will automatically be rotated around its' center, and placed in the bottom right corner of the textbox - this behavior cannot be changed at this time.

```lua
textbox = Scribe({
    text = 'Hello, World!',
    font = love.graphics.newFont( 'animeace2_reg.ttf', 24 ),
    spinner = love.graphics.newImage( 'spinner.png' )
})
```

![ex10](http://i.imgur.com/CaymmkV.gif)

### Regeneration

The `regenerate` function is used to recreate the underlying Popo object whenever a change is made to the text or a text modifier. This function is automatically called when calling `setText` or `append`, as it is assumed that you will want to see the new text immediately.

However, if you are changing other properties of the box (for example the color, or the background) you will need to manually call the `regenerate` function before they take effect. For example:

```lua

function love.load()
    textbox = Scribe({
        text = 'Click to change background and text color!',
        font = love.graphics.newFont( 'animeace2_reg.ttf', 24 )
    })
end

function love.keypressed()
	textBox:setBackground( love.graphics.newImage( 'images/oldmaptb.png' ) )
	textBox:setColor( { 0, 0, 0 } )
	textbox:regenerate()
end

function love.update( dt )
    textbox:update( dt )
end

function love.draw()
    textbox:draw()
end

```


## Copyright and License

Copyright (c)2015 Scott Small.

SCRÏBE is licensed under the [MIT license](https://github.com/smallsco/scribe/blob/master/LICENSE).

Internally, SCRÏBE makes use of [Popo](https://github.com/adonaac/popo/), which is copyright (c)2015 adn and is also under the [MIT license](https://github.com/adonaac/popo/blob/master/LICENSE).