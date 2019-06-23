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


return  setmetatable({}, revize)
-- local math = require "math"

-- local test = setmetatable({}, revize)
-- test:load_codes("data/text.txt")

-- math.randomseed( os.time() )

-- for i =1, 3 do
--   test:send_barcode(math.random(), "test")
-- end

-- os.exit()

