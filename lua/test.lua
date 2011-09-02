-- Remove later
require "luarocks.loader"

-- Imports
local json = require("json")
local http = require("socket.http")
local mime = require("mime")
local ltn12 = require("ltn12")


Session = {}
function Session:new(root, login, passwd)
  self.root = root
  self.login = login
  self.passwd = passwd
  
  self.auth = 'Basic ' .. mime.b64(login .. ":" .. passwd)
  self.cookie = nil
 
  self:fetchAPI()
  return self
end

function Session:fetchAPI()
  response = Session:jsonRPC(self.root, {}, nil)
  self.operations = {}
  for k, operation in pairs(response['operations']) do
    self.operations[operation.id] = operation
  end
end

function Session:jsonRPC(url, add_headers, data)
  -- Prepare request parameters
  headers = {
    Authorization=self.auth,
  }
  for k, v in pairs(add_headers) do
    headers[k] = v
  end
  received_chunks = {}
  if data then
    method = "POST"
    headers['Content-Length'] = string.len(data)
  else
    method = "GET"
  end
  
  r, c, h = http.request{
    method=method,
    url=url,
    headers=headers,
    source=ltn12.source.string(data),
    sink=ltn12.sink.table(received_chunks),
  }
  self.cookie = h['set-cookie']
  received = table.concat(received_chunks)
  
  -- Decode as JSON only if needed
  ctype = h['content-type']
  if ctype and string.find(ctype, 'application/json') == 1 then
    return json.decode(received)
  else
    return received
  end
end  

function Session:_execute(command, input, params)
    --self:_checkParams(command, input, params)
    headers = {
        ["Content-Type"]="application/json+nxrequest",
    }
    d = {}
    if params then
        d['params'] = {}
        for k, v in pairs(params) do
--[[            if k == 'properties' then
                s = ""
                for propname, propvalue in pairs(v) do
                    s += "%s=%s\n" % (propname, propvalue)
                d['params'][k] = s.strip()
                else:
                    d['params'][k] = v
]]
            d['params'][k] = v
        end
    end
    if input then
        d['input'] = input
    end
    if d then
        data = json.encode(d)    
    else
        data = nil
    end
    
    res = self:jsonRPC(self.root .. command, headers, data)
    return res
end 

function Session:create(ref, type, name)
  return self:_execute("Document.Create", "doc:"..ref, {type=type, name=name})
end  

function Session:getChildren(ref)
  return self:_execute("Document.GetChildren", "doc:"..ref)
end  

function Session:delete(ref)
  return self:_execute("Document.Delete", "doc:"..ref)
end

-- TODO: add more methods 

-- Tests

local lunit = require("lunit")

URL = "http://localhost:8080/nuxeo/site/automation/"
LOGIN = 'Administrator'
PASSWD = 'Administrator'

module("AutomationTestCase", package.seeall, lunit.testcase)

function test_session()
  session = Session:new(URL, LOGIN, PASSWD)
  assert_equal(URL, session.root)
  assert_equal(LOGIN, session.login)
  assert_equal(PASSWD, session.passwd)
  
  list = session:getChildren("/")
  assert_equal(type(list), "table")

  doc = session:create("/", "Folder", "Test Folder")
  assert(string.match(doc.title, "^Test Folder"))
  assert_equal(doc.type, "Folder")

  session:delete(doc.uid)
end

lunit.main()