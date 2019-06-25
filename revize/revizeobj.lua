local revize = {
  codefile = false,
  codes = {},
}

revize.__index = revize

function revize:parse_line(line) 
  return line:match("(.-)@(.+)")
end

function revize:save_barcode(barcode, section)
  self.codefile:write(string.format("%s@%s\n", barcode, section))
end

function revize:add_code(barcode, section)
  print("add", barcode, section)
  table.insert(self.codes, {barcode = barcode, section = section})
  -- ToDo: handle loaded barcodes
end

-- handle newly scanned barcodes
function revize:send_barcode(barcode, section)
  self:save_barcode(barcode, section)
  -- return status
  return self:add_code(barcode, section)
end

function revize:load_codes(filename)
  self.codefile = io.open(filename, "a+") -- don't overwrite
  for line in self.codefile:lines() do
    local barcode, section = self:parse_line(line)
    if barcode then
      self:add_code(barcode, section)
    end
  end
end

function revize:load_TSV(filename)
  local f = io.open(filename,"r")
  local t = {}
  for line in f:lines() do
    local l = {}
    for s in line:gmatch('([^\t]+)') do
      -- what was this supposed to do?
      -- local p = s:gsub('[$&]','.') 
      table.insert(l,s)
    end
    -- and this???
    -- t[l[2]] = l
    table.insert(t,l)
  end
  return t
end

-- make table accessible by the barcodes
function revize:prepare_data(data)
  local records = {}
  if type(data)== "table" and #data > 1 then
    local head = data[1]
    for i=2,#data do
      local record = data[i]
      local t = {}
      local barcode = record[1]
      for k,v in ipairs(record) do
        t[head[k]] = v
      end
      t.pos = i
      records[barcode] = t
    end
  end
  return records
end

-- load TSV file with data for the current revision
function revize:load_data(filename)
  local data = self:load_TSV(filename)
  -- make table accessible by barcodes
  self.records = self:prepare_data(data)
  return self.records
end

-- return  setmetatable({}, revize)
-- local math = require "math"

local test = setmetatable({}, revize)


local data = test:load_data("data/studovna-revize.tsv")
for k,v in pairs(data["2599210012"]) do 
  print(k, v)
end

test:load_codes("data/text.txt")

-- math.randomseed( os.time() )

-- for i =1, 3 do
  -- test:send_barcode(math.random(), "test")
-- end
--

test:send_barcode("2599210012","PŘÍRUČKA")
os.exit()

