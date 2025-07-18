local revize = {
  codefile = false,
  codes = {},
  records = {},
  sequence = {}
}

revize.__index = revize

function revize:parse_line(line) 
  return line:match("(.-)@(.+)")
end

function revize:save_barcode(barcode, section)
  self.codefile:write(string.format("%s@%s\n", barcode, section))
end

function revize:add_code(barcode, section)
  -- print("add", barcode, section)
  if section then
    section = string.gsub(section,"%s$", "")
  end
  table.insert(self.codes, {barcode = barcode, section = section})
  -- ToDo: handle loaded barcodes
end

-- handle newly scanned barcodes
function revize:send_barcode(barcode, section)
  self:save_barcode(barcode, section)
  -- return status
  print("add", barcode, section)
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
  if not f then 
    print("Cannot load data file: " .. filename)
    os.exit()
  end
  local t = {}
  for line in f:lines() do
    local l = {}
    for s in line:gmatch('([^\t]*)') do
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
  local sequence = {} -- sequence of barcodes as they appeared in the tsv
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
      sequence[#sequence+1] = barcode -- save barcode sequence
      records[barcode] = t
    end
  end
  return records, sequence
end

-- load TSV file with data for the current revision
function revize:load_data(filename)
  local data = self:load_TSV(filename)
  -- make table accessible by barcodes
  self.records, self.sequence = self:prepare_data(data)
  return self.records
end

-- test functions
-- each test function takes barcode, section and table with test parameters

-- test existence of the barcode
function revize:get_record(barcode)
  return self.records[barcode], "Neznámý čárový kód"
end

function revize:test_barcode(barcode, section, params)
  return self:get_record(barcode), "Neznámý čárový kód"
end

-- 
function revize:revize_data(data, codes, params, tests)
  local navic = {}
  local sorted_data = {}
  for _, code in ipairs(codes) do
    local barcode = code.barcode
    local section = code.section
    local record = data[barcode]
    if record then
      -- print(barcode, record["signatura2"] == section)
      record.tested = record.tested or (record["signatura2"] == section)
      record.section = section
      -- print(record.tested)
    else
      table.insert(navic, code)
    end
  end
  -- sort data records back to their original position
  for _, record in pairs(data) do table.insert(sorted_data, record) end
  table.sort(sorted_data, function(a,b) return a.pos < b.pos end)
  local header = ("ČK\tSYSNO\tnázev\tlokace\tstatus\tsignatura\tsignatura2\toddíl\tzpracování\tpůjčeno\tnačteno\tshoda oddílů")
  local lines = {header}
  -- print if all records have been checked and put in the correct section
  for _, rec in ipairs(sorted_data) do
    local nacteno = rec.tested~= nil and "ano" or "ne"
    local shoda = rec.tested == true and "ano" or "ne"
    local t = {rec.ck, rec.sysno, rec.nazevautor, rec.lokace, rec.status, rec.signatura, rec["signatura2"], rec.section or "", rec.zpracovani, rec.pujceno, nacteno, shoda}
    table.insert(lines, table.concat(t,"\t"))
  end
  -- print all unknown barcodes
  for _, code in ipairs(navic) do
    table.insert(lines, code.barcode)
  end
  return table.concat(lines, "\n")
end


function revize:test_section(barcode, section, params)
  local record, msg = self:get_record( barcode )
  if not record then return nil, msg end
  local rec_section = record["signatura2"]
  return rec_section == section, "Chybná 2. signatura"
end

function revize:test_pujceno(barcode, section, params)
  local record,msg = self:get_record(barcode)
  if not record then return nil, msg end
  return record.pujceno == "N", "Jednotka je vypůjčená"
end

function revize:test_status(barcode, section, params)
  local record, msg = self:get_record(barcode)
  if not record then return nil, msg end
  local statusy = params.statusy
  return statusy[record.status], "Chybný status jednotky"
end

function revize:test_lokace(barcode, section, params)
  local record, msg = self:get_record(barcode)
  if not record then return nil, msg end
  return record.lokace == params.lokace, "Chybná lokace"
end

function revize:test_zpracovani(barcode, section, params)
  local record, msg = self:get_record(barcode)
  if not record then return nil, msg end
  return record.zpracovani == "Nezpracovává se", "Chybný status zpracování"
end

function revize:test_signatury(barcode, section, params)
  local get_sig_number = function(signatura) 
    local number = signatura:match("^C?-?[0-9]?[A-Za-z]+([0-9]+)")
    return tonumber(number)
  end
  -- testuje posloupnost signatur
  local current, msg = self:get_record(barcode)
  if not current then return nil, msg end
  local previous_number = params.current_pos or #self.codes-1

  local previous_code = self.codes[previous_number]
  -- first code?
  if not previous_code then return true, "První kód" end
  local previous = self:get_record(previous_code.barcode)
  -- previous code doesn't exist
  if not previous then return true, "unkonown previous code" end
  local sig1 = get_sig_number(current.signatura)
  local sig2 = get_sig_number(previous.signatura)
  if sig1 == nil or sig2 == nil then return false, "Nelze rozpoznat signaturu: " .. (current.signatura  or "") .. ", " .. (previous.signatura or "") end
  return sig1 >= sig2 , "Předešlá signatura je vyšší, než současná"
end

function revize:test_vyradit(barcode, section, params)
  -- pokud v tsv souboru není sloupeček vyradit, vůbec netestujeme
  local current, msg = self:get_record(barcode)
  if not current.vyradit then return true end
  local current, msg = self:get_record(barcode)
  if not current then return nil, msg end
  -- test sloupečku vyřadit
  if current.vyradit == "true" then
    return false, "Jednotka k vyřazení"
  else
    return true
  end
end


function revize:run_tests(barcode, section, params, tests)
  -- spustit soubor testů
  -- tests je pole s názvy testů bez prefixu test_
  local messages = {}
  for _, test in ipairs(tests) do
    local name = "test_"..test
    local status, msg = self[name](self,barcode, section, params)
    -- normálně test vrací hodnotu, nebo false
    -- nil znamená fatální chybu, po které nebudem spouštět další testy
    if status == nil then
      table.insert(messages, msg)
      return messages
    elseif status == false then 
      table.insert(messages, msg)
    end
  end
  return messages
end

-- return  setmetatable({}, revize)
--local math = require "math"

--local test = setmetatable({}, revize)


--local data = test:load_data("data/studovna-revize.tsv")
--for k,v in pairs(data["2599210012"]) do 
--  print(k, v)
--end

--test:load_codes("data/text.txt")

---- math.randomseed( os.time() )

---- for i =1, 3 do
---- test:send_barcode(math.random(), "test")
---- end
----

--local barcode = "2599210012"
--local section = "PŘÍRUČKA"
--local parameters = {statusy = {["Nelze půjčit"]=true},lokace = "Rett-studovna" }

--test:send_barcode(barcode,section)
--test:send_barcode("2592021830", section) -- následující signatura CD
--test:send_barcode("2592021830", "test") -- špatná sekce
--test:send_barcode("2597810717", "VV 1")  -- všechno v pořádku
--test:send_barcode("2597611899", "VV 2")  -- špatná sekce

--print("Existuje?", test:test_barcode(barcode,section))
--print("signatura 2?", test:test_section(barcode,section))
--print("Je půjčená?", test:test_pujceno(barcode, section))
--print("Status jednotky", test:test_status(barcode, section, parameters))
--print("Lokace", test:test_lokace(barcode,  section, parameters))
--print("Zpracování", test:test_zpracovani(barcode, section))
--print("Posloupnost signatur", test:test_signatury("2592021830", section))

--local messages = test:run_tests("21191", section, parameters, {"barcode", "section", "pujceno", "status", "lokace", "zpracovani" })
--print("Počet zpráv", #messages)
--for k,v in ipairs(messages) do print("chyba", v) end

--test:revize_data(test.records, test.codes)

return  setmetatable({}, revize)

