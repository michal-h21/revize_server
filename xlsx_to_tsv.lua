#!/usr/bin/env texlua

-- tranfortmuj xlsx soubor z almy na tsv
kpse.set_program_name "luatex"


local input = arg[1]

local unicode = require "unicode"
local xlsx = require "spreadsheet-xlsx-reader"
local log = require "spreadsheet.spreadsheet-log"
local lower = unicode.utf8.lower

log.level = "warn"

local function help()
  print("xlsx_to_tex.lua [vysledekhledanizalmy.xlsx] > revize.tsv")
  os.exit()
end

local function is_dir(name)
  if type(name)~="string" then return false end
  local cd = lfs.currentdir()
  local is = lfs.chdir(name) and true or false
  lfs.chdir(cd)
  return is
end

-- convert XLSX data to table
local function read_row(row)
  local data = {}
  for _, cell in ipairs(row) do
    local t = {}
    for _, x in ipairs(cell) do
      t[#t+1] = x.value
    end
    data[#data+1] = table.concat(t)
  end
  return data
end

local poradi =  { "ck","sysno","lokace","status","nazevautor","signatura","signatura2","zpracovani","pujceno" }

local mapping = {
["Knihovna"] = "dilciknihovna",
["ID MMS"] = "sysno",
["Trvalé umístění"] = "lokace",
["Výpůjční pravidla pro danou jednotku"] = "status",
["Titul"] = "nazevautor",
["Signatura jednotky"]="signatura",
["Signatura"]="signatura2",
["Čárový kód"]="ck",
["Status"] = "zpracovani",
["Termín vrácení"] = "pujceno"
}


local function read_data(data, ctenar, id)
  local records = {}
  local lines = data.table or {}
  local first_line = read_row(table.remove(lines, 1) or {})
  local header = {}
  for i, column in ipairs(first_line) do
    local mapped_header = mapping[column]
    if mapped_header then
      header[i] = mapped_header 
    end
  end

  for _,line in ipairs(lines) do
    -- inicalizujeme záznam se jménem čtenáře a fake id
    local rec = {}
    local r = read_row(line)
    for i, x in ipairs(r) do
      local key = header[i]
      if key then
        rec[key] = x
      end
    end
    records[#records+1] = rec
  end
  return records
end

if not input then
  print "Chybí vstupní soubor"
  help()
end



local workbook, msg = xlsx.load(input)
local sheet = workbook:get_sheet(1)
-- ToDo: a teď získat data

if not sheet then 
  print(msg)
  os.exit()
end

-- local datafile = io.open(input, "r")

-- local data = datafile:read("*all")
local records, msg = read_data(sheet, ctenar, id)
if not records then
  print(msg)
  os.exit()
end
print "zpracovano"
-- local authors = make_authors(records)
-- make_files(authors, template)

