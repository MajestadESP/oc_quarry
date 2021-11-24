local GetFileContents = require('GetFileContents')
local FilePutContents = require('FilePutContents')
local ui = require('UI')
local split = require('split')
local serialization = require('serialization')
local term = require('term')
local event = require('event')
local fs = require('filesystem')
local component = require('component')
local gpu = component.gpu
local modem = component.modem
local running = true
term.clear()

