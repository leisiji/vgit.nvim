local async = require('plenary.async.async')

local loop = {}
local global_timer = {}

loop.suspend = async.wrap

loop.coroutine = async.void

loop.suspend_textlock = loop.suspend(vim.schedule, 1)

function loop.free_textlock(times)
  for _ = 1, times or 1 do
    loop.suspend_textlock()
  end

  return loop
end

function loop.debounce(fn, ms, opts)
  opts = opts or {}
  local key = tostring(fn)

  if global_timer[key] == nil then
    global_timer[key] = vim.loop.new_timer()
  end

  local args, argc
  local timer = global_timer[key]

  return function(...)
    args = { ... }
    argc = select('#', ...)

    timer:stop()
    timer:start(ms, 0, function()
      fn(unpack(args, 1, argc))
    end)
  end
end

function loop.debounce_coroutine(fn, ms)
  return loop.debounce(loop.coroutine(fn), ms)
end

return loop
