-- get script path
local path = arg[0]:gsub("[^/]+$", "")
package.path = path .."?.lua;./?.lua;" .. package.path

local revizeobj = require("revize/revizeobj")
local config = require("revize/config")


local dir = arg[1]:gsub("/$", "")


local config_file = dir .. "/config.lua" 


local settings = config.load_file(config_file)

local codes = settings.codes or "data/codes.txt"
local data = settings.data or "data/data.tsv"
codes = codes:gsub("^data", dir)
data = data:gsub("^data", dir)
revizeobj:load_data(data)
revizeobj:load_codes(codes)
local result = revizeobj:revize_data(revizeobj.records, revizeobj.codes)
print(result)
