local term = require('term')
local shell = require('shell')
local fs = require('filesystem')
local component = require('component')

term.clear()

local option
local num

function isquarry() -- Function for install main server quarry.
    term.clear()
    print("Installing Server Quarry on your computer, please be patient.")
    shell.execute('wget -fq "https://github.com/MajestadESP/oc_quarry/blob/main/quarry/quarry.lua" "/bin/quarry.lua"')
    os.sleep(5)
    shell.execute('wget -fq "https://raw.githubusercontent.com/MajestadESP/oc_quarry/main/lib/AcceptableInput.lua" "/lib/AcceptableInput.lua"')
    shell.execute('wget -fq "https://raw.githubusercontent.com/MajestadESP/oc_quarry/main/lib/CheckBounds.lua" "/lib/CheckBounds.lua"')
    shell.execute('wget -fq "https://raw.githubusercontent.com/MajestadESP/oc_quarry/main/lib/ChunkData.lua" "/lib/ChunkData.lua"')
    shell.execute('wget -fq "https://raw.githubusercontent.com/MajestadESP/oc_quarry/main/lib/ChunkDataCollection.lua" "/lib/ChunkDataCollection.lua"')
    shell.execute('wget -fq "https://raw.githubusercontent.com/MajestadESP/oc_quarry/main/lib/FilePutContents.lua" "/lib/FilePutContents.lua"')
    shell.execute('wget -fq "https://raw.githubusercontent.com/MajestadESP/oc_quarry/main/lib/GetFileContents.lua" "/lib/GetFileContents.lua"')
    shell.execute('wget -fq "https://raw.githubusercontent.com/MajestadESP/oc_quarry/main/lib/UI.lua" "/lib/UI.lua"')
    shell.execute('wget -fq "https://raw.githubusercontent.com/MajestadESP/oc_quarry/main/lib/split.lua" "/lib/split.lua"')
    os.sleep(1)
    fs.makeDirectory("/lib/UI")
    shell.execute('wget -fq "https://raw.githubusercontent.com/MajestadESP/oc_quarry/main/lib/UI/ButtonElement.lua" "/lib/UI/ButtonElement.lua"')
    shell.execute('wget -fq "https://raw.githubusercontent.com/MajestadESP/oc_quarry/main/lib/UI/CellMap.lua" "/lib/UI/CellMap.lua"')
    shell.execute('wget -fq "https://raw.githubusercontent.com/MajestadESP/oc_quarry/main/lib/UI/ElementCollection.lua" "/lib/UI/ElementCollection.lua"')
    shell.execute('wget -fq "https://raw.githubusercontent.com/MajestadESP/oc_quarry/main/lib/UI/LabelElement.lua" "/lib/UI/LabelElement.lua"')
    shell.execute('wget -fq "https://raw.githubusercontent.com/MajestadESP/oc_quarry/main/lib/UI/TableElement.lua" "/lib/UI/TableElement.lua"')
    shell.execute('wget -fq "https://raw.githubusercontent.com/MajestadESP/oc_quarry/main/lib/UI/TextInputElement.lua" "/lib/UI/TextInputElement.lua"')
    os.sleep(5)
    print("All is installed correctly.")
    os.sleep(1)
    term.clear()
end

function ibquarry() -- Function for install robot quarry service.
    term.clear()
    print("Installing Client Quarry on your robot, please be patient.")
    shell.execute('wget -fq "https://github.com/MajestadESP/oc_quarry/blob/main/quarry/botQuarry.lua" "/bin/botQuarry.lua"')
    os.sleep(5)
    shell.execute('wget -fq "https://raw.githubusercontent.com/MajestadESP/oc_quarry/main/lib/Position.lua" "/lib/Position.lua"')
    print("All is installed correctly.")
    os.sleep(1)
    term.clear()
end

print("Welcome to Quarry Services installer.")
::OPTION::
print("Please select one option to install:")
print("")
print("")
print("1) Install Quarry Server, only for computers.")
print("2) Install Quarry Client, only for robots.")
print("")
print("Choose an option:")

option = term.read()
num = tonumber(option)

if num == nil then
    print("Please type a proper option.")
    term.clear()
    goto OPTION
elseif num == 0 then
    print("Please type a proper option.")
    term.clear()
    goto OPTION
elseif num == 1 then
    isquarry()
elseif num == 2 then
    ibquarry()
elseif num > 2 then
    print("Please type a proper option.")
    term.clear()
    goto OPTION
end

term.clear()