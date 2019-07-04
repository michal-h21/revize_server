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
local header = ("pořadí\tČK\toddíl\tchyba\tSYSNO\tnázev\tlokace\tstatus\tsignatura\tsignatura2\tzpracování")
print(header)
for i, code in ipairs(revizeobj.codes) do
  local barcode = code.barcode
  local section = code.section
  settings.current_pos = i
  local messages = revizeobj:run_tests(barcode, section, settings, settings.tests) 
  local record = revizeobj:get_record(barcode) or {}
  local rest = {record.sysno, record.nazevautor,record.lokace,record.status,record.signatura, record["signatura2"], record.zpracovani}
  print(i,barcode, section, table.concat(messages, ","),table.concat(rest, "\t"))

end
