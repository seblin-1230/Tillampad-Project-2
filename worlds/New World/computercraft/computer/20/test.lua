-- This will list all methods available via Plethora modules
local modules = peripheral.wrap("left")
if modules then
    print(textutils.serialize(modules.listModules()))
end
