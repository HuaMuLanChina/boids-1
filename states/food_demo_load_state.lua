local food_demo_load = state:new()
food_demo_load.label = 'food_demo_load'

local state = food_demo_load

--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      INPUT
--[[----------------------------------------------------------------------]]--
function food_demo_load.keypressed(key)
end
function food_demo_load.keyreleased(key)
end
function food_demo_load.mousepressed(x, y, button)
end
function food_demo_load.mousereleased(x, y, button)
end

--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      LOAD
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function food_demo_load.load(str)
  local level = level:new()
  state.level = level
  state.pre_level_load(level)
  level:load()
end

-- PRE LEVEL LOAD FUNCTIONS
function food_demo_load.initialize_audio(level)
end

function food_demo_load.initialize_camera(level)
  local x = TILE_WIDTH * 75
  local y = TILE_HEIGHT * 55
  local start_pos = vector2:new(x, y)
  local camera = camera2d:new(start_pos)
  level:set_camera(camera)
end

function food_demo_load.construct_level_map(level)
  -- colours
  local C_BLACK = {0, 0, 0, 255}
  local ncolors = 200
  
  local dir = "gradients/named/"
  local blend = 0.02
  local g_background = tile_gradient:new(require( dir.."orange1"), ncolors)
  local g_wall1 = tile_gradient:new(require( dir.."allwhite"), ncolors)
  local g_black = tile_gradient:new(require( dir.."orange"), ncolors)
                                         
  g_wall1:add_diagonals()
  g_wall1:add_border(C_BLACK, blend)
  g_black:add_diagonals()
  g_black:add_border({255, 255, 255, 255}, 0.1)
  g_background:add_border(C_BLACK, blend)
                                         
  local palette = tile_palette:new()
  palette:add_gradient(g_background, "allwhite")
  palette:add_gradient(g_wall1, "blue")
  palette:add_gradient(g_black, "black")
  palette:load()
  state.level:set_tile_palette(palette)
  
  -- load map
  local map_directory = "images/menu"
  local back = "background.png"
  local wall = "wall1.png"
  local map_data = require(map_directory.."/menu_map_data")
  
  -- source images
  local imgdata_layers = {}
  imgdata_layers[back] = li.newImageData(map_directory.."/"..back)
  
  -- construct level map
  local level_map = level_map:new(level)
  for i=1,#map_data do
  	local slice_data = map_data[i]
  	local offx, offy = slice_data[back].x + 1, slice_data[back].y + 1
  	local w, h = slice_data[back].width, slice_data[back].height
  	
  	local tmap = tile_map:new(level, w, h)
  	if slice_data[back] then
  	  local layer_data = slice_data[back]
  	  local x, y = layer_data.x, layer_data.y
  	  local w, h = layer_data.width, layer_data.height
  	  local layer = tile_layer:new(imgdata_layers[back], x, y, w, h, 
  	                               palette:get_gradient("allwhite"), 0, T_WALK)
      tmap:add_tile_layer(layer)
  	end
  	level_map:add_tile_map(tmap, offx, offy)
  end
  level:set_level_map(level_map)
end

function food_demo_load.pre_level_load(level)
  state.initialize_camera(level)
  state.initialize_audio(level)
  state.construct_level_map(level)
end

-- POST LEVEL LOAD FUNCTIONS
function food_demo_load.initialize_player(level)
end
function food_demo_load.initialize_tile_explosions(level)
end
function food_demo_load.initialize_cube_shard_set(level)
end
function food_demo_load.initialize_shard_sets(level)
end
function food_demo_load.initialize_mouse_input(level)
  level:set_mouse(MOUSE_INPUT)
end
function food_demo_load.initialize_audio_objects(level)
end
function food_demo_load.initialize_polygonizer(level)
  local level_map = level:get_level_map()
  local palette = level:get_tile_palette()
  local tile_gradient = palette:get_gradient("black")
  local tile_type = T_WALL
  level_map:set_polygonizer(tile_type, tile_gradient)
  level_map:set_source_polygonizer(T_WALK, tile_gradient)
end

function food_demo_load.post_level_load(level)
  state.initialize_mouse_input(level)
  state.initialize_player(level)
  state.initialize_shard_sets(level)
  state.initialize_tile_explosions(level)
  state.initialize_audio_objects(level)
  state.initialize_polygonizer(level)
end


--##########################################################################--
--[[----------------------------------------------------------------------]]--
--      UPDATE
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function food_demo_load.update(dt)
  local level = state.level
  level:update(dt)

  if level:is_loaded() then
    state.post_level_load(level)
    BOIDS:load_next_state(level)
  end
end
  

--##########################################################################--
--[[----------------------------------------------------------------------]]--
--     DRAW
--[[----------------------------------------------------------------------]]--
--##########################################################################--
function food_demo_load.draw()
  love.graphics.setBackgroundColor(0, 0, 0, 255)
end

return food_demo_load


















