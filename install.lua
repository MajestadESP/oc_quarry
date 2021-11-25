local GetFileContents = require('GetFileContents')
local FilePutContents = require('FilePutContents')
local cpu = require('computer')
local ui = require('UI')
local split = require('split')
local serialization = require('serialization')
local term = require('term')
local shell = require('shell')
local event = require('event')
local fs = require('filesystem')
local component = require('component')
local www = require('internet')
local gpu = component.gpu
local modem = component.modem

term.clear()

do
    shell.execute('wget -fq "https://raw.githubusercontent.com/MajestadESP/oc_quarry/main/lib/Position.lua" "/lib"')
    shell.execute('wget -fq "https://raw.githubusercontent.com/MajestadESP/oc_quarry/main/lib/AcceptableInput.lua" "/lib"')
    shell.execute('wget -fq "https://raw.githubusercontent.com/MajestadESP/oc_quarry/main/lib/CheckBounds.lua" "/lib"')
    shell.execute('wget -fq "https://raw.githubusercontent.com/MajestadESP/oc_quarry/main/lib/ChunkData.lua" "/lib"')
    shell.execute('wget -fq "https://raw.githubusercontent.com/MajestadESP/oc_quarry/main/lib/ChunkDataCollection.lua" "/lib"')
    shell.execute('wget -fq "https://raw.githubusercontent.com/MajestadESP/oc_quarry/main/lib/FilePutContents.lua" "/lib"')
    shell.execute('wget -fq "https://raw.githubusercontent.com/MajestadESP/oc_quarry/main/lib/GetFileContents.lua" "/lib"')
    shell.execute('wget -fq "https://raw.githubusercontent.com/MajestadESP/oc_quarry/main/lib/UI.lua" "/lib"')
    shell.execute('wget -fq "https://raw.githubusercontent.com/MajestadESP/oc_quarry/main/lib/split.lua" "/lib"')
    os.sleep(1)
    fs.makeDirectory("/lib/UI")
    shell.execute('wget -fq "https://raw.githubusercontent.com/MajestadESP/oc_quarry/main/lib/UI/ButtonElement.lua" "/lib/UI"')
    shell.execute('wget -fq "https://raw.githubusercontent.com/MajestadESP/oc_quarry/main/lib/UI/CellMap.lua" "/lib/UI"')
    shell.execute('wget -fq "https://raw.githubusercontent.com/MajestadESP/oc_quarry/main/lib/UI/ElementCollection.lua" "/lib/UI"')
    shell.execute('wget -fq "https://raw.githubusercontent.com/MajestadESP/oc_quarry/main/lib/UI/LabelElement.lua" "/lib/UI"')
    shell.execute('wget -fq "https://raw.githubusercontent.com/MajestadESP/oc_quarry/main/lib/UI/TableElement.lua" "/lib/UI"')
    shell.execute('wget -fq "https://raw.githubusercontent.com/MajestadESP/oc_quarry/main/lib/UI/TextInputElement.lua" "/lib/UI"')
    os.sleep(5)
end

local bin = '/bin'
local lib = '/lib'

local resolution = {gpu.getResolution()}

function isquarry() -- Function for install main server quarry.
    print("Installing Server Quarry on your computer, please be patient.")
    shell.execute('wget -fq "https://github.com/MajestadESP/oc_quarry/blob/main/quarry/quarry.lua" "/bin"')
    os.sleep(5)
    print("All is installed correctly.")
    os.sleep(1)
    term.clear()
end

function ibquarry() -- Function for install robot quarry service.
    print("Installing Client Quarry on your robot, please be patient.")
    shell.execute('wget -fq "https://github.com/MajestadESP/oc_quarry/blob/main/quarry/botQuarry.lua" "/bin"')
    os.sleep(5)
    print("All is installed correctly.")
    os.sleep(1)
    term.clear()
end

local tblSelIns = ui.table.new(60, 10, 20, {
    {text="",width=15}
})
collection:add(tblSelIns)

collection:addRow(id, 'Quarry Server')
collection:addRow(id, 'Quarry Client')

local btnSetIns = ui.button.new(60,8,'Install')
btnSetIns.onClick = function()
    local row = SelIns:getSelected()
    
    SelIns:alterSelected(row)
end