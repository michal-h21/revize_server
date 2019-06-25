local config = {}

function config.load(str,env)
  -- load configuration file in Lua
  local env = env or {}
  local fn, msg = load(str, nil, "t", env)
  if fn then
    fn()
    return env
  end
  return nil, msg
end

function config.load_file(filename, env)
  local f = io.open(filename, "r")
  if f then
    local content = f:read("*all")
    f:close()
    return config.load(content, env)
  end
  return nil
end

return config

-- local str = [[
-- a = 10
-- b = "ahoj"
-- ]]
-- 
-- local x = config.load(str)
-- if type(x)=="table" then
--   for k,v in pairs(x) do
--     print(k,v)
--   end
-- end
