-- načte tsv soubor ze standartního vstupu a rozfiltruje podle signatur


local basename = arg[1] or "signatura-"
--
local t = {}
for line in io.lines() do
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

local signatury = {}
local signaturapos
if #t == 0 then
  print("Nenalezena data")
  os.exit()
end
-- první řádek tsv souboru musí obsahovat popisky sloupců
local header = t[1]
local header_line = table.concat(header, "\t") .. "\n"
-- najít pozici sloupce se signaturami
for i,name in ipairs(header) do
  if name=="signatura" then
    signaturapos = i
    break
  end
end

if not signaturapos then
  print("Nemůžu najít pozici signatury")
  print("Obsahuje první řádek TSV souboru buňku signatura?")
  os.exit()
end

for i=2,#t do
  local radek = t[i]
  local signatura = radek[signaturapos] 
  if not signatura then
    print("chybí signatura", table.concat(radek, "\t"))
  end
  -- najít název signatury
  local prefix = signatura:match("^([0-9]*[A-Za-z]+)")
  -- získat pole, kde jsou všechny současné signatury
  local current = signatury[prefix] or {}
  table.insert(current, table.concat(radek, "\t"))
  signatury[prefix] = current
end

for sig, data in pairs(signatury) do
  local new_tsv = basename .. sig .. ".tsv"
  local f = io.open(new_tsv, "w")
  f:write(header_line)
  -- data obsahují už spojené řádky
  f:write(table.concat(data, "\n"))
  f:close()
  
end
