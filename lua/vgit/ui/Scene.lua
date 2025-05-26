local Object = require('vgit.core.Object')

local Scene = Object:extend()

function Scene:constructor()
  return {
    length = 0,
    components = {},
    component_order = {},
    default_global_opts = {},
  }
end

function Scene:get_components()
  local ordered_components = {}

  for key, component in pairs(self.components) do
    local order = self.component_order[key]
    ordered_components[order] = component
  end

  return ordered_components
end

function Scene:set(key, component)
  self.length = self.length + 1
  self.components[key] = component
  self.component_order[key] = self.length

  return self
end

function Scene:get(key)
  return self.components[key]
end

function Scene:on(event_name, callback)
  for _, component in pairs(self.components) do
    component:on(event_name, callback)
  end

  return self
end

function Scene:set_keymap(configs)
  for _, config in ipairs(configs) do
    for _, component in pairs(self.components) do
      component:set_keymap(config, config.handler)
    end
  end

  return self
end

function Scene:destroy()
  local components = self:get_components()
  for _, component in pairs(components) do
    component:unmount()
  end

  return self
end

function Scene:jump()
  local jump = false
  local components = self:get_components()
  ::AGAIN::
  for _, component in pairs(components) do
    local win = component.window.win_id
    if jump then
      vim.api.nvim_set_current_win(win)
      return
    end
    if vim.api.nvim_get_current_win() == win then jump = true end
  end
  if jump then goto AGAIN end
end

return Scene
