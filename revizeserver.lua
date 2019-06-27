#!/usr/bin/env lua

-- asi to nebude fungovat kvůli ssl

--[[
A simple todo-list server example.
This example requires the restserver-xavante rock to run.
A fun example session:
curl localhost:8080/todo
curl -v -H "Content-Type: application/json" -X POST -d '{ "task": "Clean bedroom" }' http://localhost:8080/todo
curl -v localhost:8080/todo
curl -v -H "Content-Type: application/json" -X POST -d '{ "task": "Groceries" }' http://localhost:8080/todo
curl -v localhost:8080/todo
curl -v localhost:8080/todo/2/status
curl -v localhost:8080/todo/2/done
curl -v localhost:8080/todo/2/status
curl -v localhost:8080/todo/9/status
curl -v -H "Content-Type: application/json" -X DELETE http://localhost:8080/todo/2
curl -v localhost:8080/todo
]]

package.path = "./?.lua;" .. package.path
local restserver = require("restserver")
local config = require("revize/config")
local revizeobj = require("revize/revizeobj")

local settings = config.load_file("data/config.lua")

local codes = settings.codes or "data/codes.txt"
local data = settings.data or "data/data.tsv"

revizeobj:load_data(data)
revizeobj:load_codes(codes)

local server = restserver:new():port(8080)

local todo_list = {}
local next_id = 0

local f = io.open("tpl/reader.html", "r")

local page = f:read("*all")
f:close()

server:add_resource("", {
   {
      method = "GET",
      path = "end",
      produces = "application/json",
      handler = function()
        result = {
          msg = "Konec",
          state = "end"
        }
        print("Konec")
        os.exit()
        -- return restserver.response():status(200):entity(result)
      end
   },
   {
      method = "GET",
      path = "/",
      produces = "text/html",
      handler = function()
        print "Load page"
        return restserver.response():status(200):entity(page)
      end,
   },
   
   {
      method = "POST",
      path = "/",
      consumes = "application/json",
      produces = "application/json",
      input_schema = {
         barcode = { type = "string" },
         section = { type = "string" }
      },
      handler = function(task_submission)
        local barcode, section = task_submission.barcode, task_submission.section
        print("Received barcode: " .. task_submission.barcode .. "@".. task_submission.section)
        next_id = next_id + 1
        task_submission.id = next_id
        task_submission.done = false
        table.insert(todo_list, task_submission)
        local result = {
          id = task_submission.id,
          msg = "Ok",
          state = "ok",
          signatura = "",
          signatura2 = "",
          nazev= ""
        }
        if section == "" then
          result.state = "error"
          result.msg = "Chybí název oddílu"
        else
          revizeobj:send_barcode(barcode, section)
          local messages = revizeobj:run_tests(barcode, section, settings, settings.tests)
          local record = revizeobj:get_record(barcode) or {}
          -- any message means error
          if #messages > 0 then
            result.state = "error"
            result.msg = table.concat(messages, ",")
          end
          result.signatura = record.signatura or ""
          result.nazev = record.nazevautor or ""
          result.signatura2 = record.signatura2 or ""
          for k,v in pairs(record) do print(k,v) end
        end
        return restserver.response():status(200):entity(result)
      end,
   },

   {
      method = "GET",
      path = "{id:[0-9]+}/status",
      produces = "application/json",
      handler = function(_, id)
         for _, task in ipairs(todo_list) do
            if task.id == tonumber(id) then
               return restserver.response():status(200):entity(task)
            end
         end
         return restserver.response():status(404):entity("Id not found.")
      end,
   },

   {
      method = "GET",
      path = "{id:[0-9]+}/done",
      produces = "application/json",
      handler = function(_, id)
         for _, task in ipairs(todo_list) do
            if task.id == tonumber(id) then
               task.done = true
               return restserver.response():status(200):entity(task)
            end
         end
         return restserver.response():status(404):entity("Id not found.")
      end,
   },

   {
      method = "DELETE",
      path = "{id:[0-9]+}",
      produces = "application/json",
      handler = function(_, id)
         for i, task in ipairs(todo_list) do
            if task.id == tonumber(id) then
               table.remove(todo_list, i)
               return restserver.response():status(200):entity(task)
            end
         end
         return restserver.response():status(404):entity("Id not found.")
      end,
   },

   {
      method = "GET",
      path = "/reset",
      produces = "application/json",
      handler = function()
         todo_list = {}
         next_id = 0
         return restserver.response():status(200)
      end,
   },
   
})

-- This loads the restserver.xavante plugin
server:enable("restserver.xavante"):start()
