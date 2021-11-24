local GetFileContents = require('GetFileContents')
local FilePutContents = require('FilePutContents')
local cpu = require('computer')
local ui = require('UI')
local split = require('split')
local serialization = require('serialization')
local term = require('term')
local event = require('event')
local fs = require('filesystem')
local component = require('component')
local gpu = component.gpu
local modem = component.modem
term.clear()

do
    cpu.getDeviceInfo()
end

function isquarry() -- Function for install main server quarry.
    
end

function ibquarry() -- Function for install robot quarry service.
    
end