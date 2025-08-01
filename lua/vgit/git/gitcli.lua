local loop = require('vgit.core.loop')

local gitcli = {}

gitcli.run = loop.suspend(function(args, opts, callback)
  opts = opts or {}

  local Job = require('plenary.job')
  Job:new({
    command = 'git',
    args = args,
    on_exit = function(j, _)
      local result = j:result()
      if result ~= nil then
        callback(result, nil)
      else
        callback(nil, j:stderr_result())
      end
    end,
  }):start()
end, 3)

return gitcli
