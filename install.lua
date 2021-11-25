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
local wget = fs.wg
term.clear()

local bin = '/bin'
local lib = '/lib'

do
    if not fs.exists('/mnt') then
        print("Please install OpenOS before install Quarry services")
        os.sleep(5)
        os.exit()
    end
end

function isquarry() -- Function for install main server quarry.
    
end

function ibquarry() -- Function for install robot quarry service.
    
end