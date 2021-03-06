
--##########################################################################--
--[[----------------------------------------------------------------------]]--
-- flock object - a flock of boids in 3d space
--[[----------------------------------------------------------------------]]--
--##########################################################################--
local fk = {}
fk.table = 'fk'
fk.debug = false
fk.level = nil
fk.bbox = nil
fk.temp_collision_bbox = nil
fk.free_boids = nil
fk.active_boids = nil
fk.collider_cell_width = 150
fk.collider_cell_height = 150
fk.draw_boids = nil

fk.user_interface = nil

fk.num_initial_boids = 1000
fk.gradient = require("gradients/named/greenyellow")

local fk_mt = { __index = fk }
function fk:new(level, x, y, width, height, depth)
  local fk = setmetatable({}, fk_mt)
  fk.level = level
  
  fk:_init_bbox(x, y, width, height, depth)
  fk:_init_boids()
  fk:_init_collider()
  
  fk.user_interface = flock_interface:new(level, fk)
  fk.draw_boids = {}
  
  return fk
end

function fk:keypressed(key)
  self.user_interface:keypressed(key)
end
function fk:keyreleased(key)
  self.user_interface:keyreleased(key)
end
function fk:mousepressed(x, y, button)
  self.user_interface:mousepressed(x, y, button)
end
function fk:mousereleased(x, y, button)
  self.user_interface:mousereleased(x, y, button)
end

function fk:_init_boids()
  self.free_boids = {}
  self.active_boids = {}
  for i=1,self.num_initial_boids do
    self.free_boids[i] = boid:new(self.level)
  end
end

function fk:_init_bbox(x, y, width, height, depth)
  self.bbox = bbox:new(x, y, width, height)
  self.bbox.depth = depth
  self.temp_collision_bbox = bbox:new(0, 0, 0, 0)

end

function fk:_init_collider()
  local x, y, width, height = self.bbox:get_dimensions()
  local cw, ch = self.collider_cell_width, self.collider_cell_height
  self.collider = collider:new(self.level, x, y, width, height, cw, ch)
end

function fk:contains_point(x, y, z)
  return self.bbox:contains_coordinate(x, y) and z >= 0 and z <= self.bbox.depth
end

function fk:get_bbox()
  return self.bbox
end

function fk:set_gradient(grad_table)
  self.gradient = grad_table
end

function fk:set_camera_tracking_off()
  self.user_interface:set_camera_tracking_off()
end

function fk:set_camera_tracking_on()
  self.user_interface:set_camera_tracking_on()
end

function fk:add_boid(x, y, z, dirx, diry, dirz, gradient)
  z = z or 0
  if not x or not y then
    print("ERROR in flock:add_boid - no position specified")
    return
  end
  
  local new_boid = nil
  if #self.free_boids > 0 then
    new_boid = self.free_boids[#self.free_boids]
    self.free_boids[#self.free_boids] = nil
  else
    new_boid = boid:new(self.level)
  end
  new_boid:init(self, x, y, z, dirx, diry, dirz)
  if gradient then
    new_boid:set_gradient(gradient)
  else
    new_boid:set_gradient(self.gradient)
  end
  self.active_boids[#self.active_boids + 1] = new_boid
  
  return new_boid
end

function fk:remove_boid(boid)
  local active = self.active_boids
  for i=#active,1,-1 do
    if active[i] == boid then
      table.remove(active, i)
      self.free_boids[#self.free_boids + 1] = boid
      boid:destroy()
      break
    end
  end
end

function fk:get_active_boids()
  return self.active_boids
end

function fk:get_boids_in_radius(x, y, r, storage)
  local bbox = self.temp_collision_bbox
  bbox.x, bbox.y = x - r, y - r
  bbox.width, bbox.height = 2 * r, 2 * r
  
  self.collider:get_objects_at_bbox(bbox, storage)
  for i=#storage,1,-1 do
    local boid = storage[i]
    local p = boid.position
    local dx, dy, dz = p.x - x, p.y - y
    if dx*dx + dy*dy > r * r then
      table.remove(storage, i)
    end
  end
  
end

function fk:get_boids_in_sphere(x, y, z, r, storage)
  local bbox = self.temp_collision_bbox
  bbox.x, bbox.y = x - r, y - r
  bbox.width, bbox.height = 2 * r, 2 * r
  
  self.collider:get_objects_at_bbox(bbox, storage)
  for i=#storage,1,-1 do
    local boid = storage[i]
    local p = boid.position
    local dx, dy, dz = p.x - x, p.y - y, p.z - z
    if dx*dx + dy*dy + dz*dz > r * r then
      table.remove(storage, i)
    end
  end
  
end

function fk:get_boids_in_bbox(bbox, storage)
  self.collider:get_objects_at_bbox(bbox, storage)
end

function fk:get_collider()
  return self.collider
end


------------------------------------------------------------------------------
function fk:_update_boids(dt)
  for i=1,#self.active_boids do
    self.active_boids[i]:update(dt)
  end
  
  -- find boids on screen and sort by depth for correct draw order
  local padx, pady = 200, 500
  local w, h = SCR_WIDTH + 2*padx, SCR_HEIGHT + 2*pady
  local cx, cy = self.level:get_camera():get_viewport()
  local bbox = self.temp_collision_bbox
  bbox.x, bbox.y = cx - padx, cy - pady
  bbox.width, bbox.height = w, h
  local objects = self.draw_boids
  table.clear(objects)
  self.collider:get_objects_at_bbox(bbox, objects)
  
  table.sort(objects, function(a, b) 
                                  return a.position.z < b.position.z
                                end)

end

function fk:update(dt)
  self.user_interface:update(dt)

  self:_update_boids(dt)
  self.collider:update(dt)
end

------------------------------------------------------------------------------
function fk:draw()
  for i=1,#self.draw_boids do
    self.draw_boids[i]:draw_shadow()
  end
  for i=1,#self.draw_boids do
    self.draw_boids[i]:draw()
  end

  self.user_interface:draw()
  
  if not self.debug then return end
  
  lg.setColor(255, 0, 0, 255)
  self.bbox:draw()
  
  self.collider.debug = self.debug
  --self.collider:draw()
  
end

return fk



























