#!/usr/bin/env texlua

-- tranfortmuj xlsx soubor z almy na tsv
kpse.set_program_name "luatex"



local unicode = require "unicode"
local domobject = require "luaxml-domobject"
local log = require "spreadsheet.spreadsheet-log"
local lower = unicode.utf8.lower

log.level = "warn"

local function help()
  print("./alma_revize.lua [vysledekhledanizalmy.xml] > revize.tsv")
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
[""] = "dilciknihovna",
["MMS Id"] = "sysno",
["Location Name"] = "lokace",
["Výpůjční pravidla"] = "status",
-- [""] = "nazevautor",
["Signatura jednotky"]="signatura",
["Holdingová signatura"]="signatura2",
["Čárový kód"]="ck",
["Typ procesu"] = "zpracovani",
-- ["Process Type"] = "pujceno"
}

-- Location Name   nil
-- Item Call Number        nil
-- Barcode nil
-- Material Type   nil
-- Item Policy     nil
-- Inventory Number        nil
-- Description     nil
-- Enum A  nil
-- Enum B  nil
-- MMS Id  nil
-- Author  nil
-- Title   nil
-- Publication Date        nil
-- Process Type    nil


local function read_data(dom)
  local records = {}
  local header = {}
  -- <xsd:element name="C0" type="xsd:string" minOccurs="1" maxOccurs="1" saw-sql:type="varchar" saw-sql:sqlFormula="&quot;Physical Items&quot;.&quot;Location&quot;.&quot;Location N      ame&quot;" saw-sql:displayFormula="&quot;Location&quot;.&quot;Location Name&quot;" saw-sql:aggregationRule="none" saw-sql:aggregationType="nonAgg" saw-sql:tableHeading="Location" saw-s      ql:columnHeading="Location Name" saw-sql:isDoubleColumn="false" saw-sql:columnID="cc0036169d9c49e95" saw-sql:length="255" saw-sql:scale="0" saw-sql:precision="255"/> 
  for _, column in ipairs(dom:query_selector("xsd|element")) do

    local i = column:get_attribute("name")
    local name = column:get_attribute("saw-sql:columnheading")
    local mapped_header = mapping[name]
    if mapped_header then
      header[i] = mapped_header 
    else
      header[i] = name
    end
    -- print(name, mapped_header, i)
  end

  for _,line in ipairs(dom:query_selector("R")) do
    -- inicalizujeme záznam se jménem čtenáře a fake id
    local rec = {}
    for i, x in ipairs(line:get_children()) do
      if x:is_element() then
        local i = x:get_element_name()
        local key = header[i]
        if key then
          rec[key] = x:get_text()
        end
        -- print(i, key, x:get_text())
      end
    end
    records[#records+1] = rec
    -- os.exit()
  end
  return records
end

local function print_records(records)
  print(table.concat(poradi, "\t"))
  for _,rec in ipairs(records) do
    -- pujceno obsahuje datum, pokud je kniha pujcena
    -- my potrebujeme Y nebo N
    rec.pujceno =  rec.zpracovani == "Loan" and "Y" or "N"
    rec.nazevautor = (rec["Název"] or "")  .. ", " .. (rec.Autor or "")
    rec.lokace = "-"
    rec.zpracovani = rec.zpracovani == "None" and "Nezpracovává se" or rec.zpracovani
    local t = {}
    for _,field in ipairs(poradi) do
      t[#t+1] = rec[field]
    end
    print(table.concat(t, "\t"))
  end
end
local input = arg[1]

if not input then
  print "Chybí vstupní soubor"
  help()
end



-- ToDo: a teď získat data

local datafile = io.open(input, "r")

local xmldata = datafile:read("*all")
local dom = domobject.parse(xmldata)

local records, msg = read_data(dom)
if not records then
  print(msg)
  os.exit()
end

print_records(records)
-- local authors = make_authors(records)
-- make_files(authors, template)

