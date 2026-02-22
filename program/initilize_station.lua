local needed_peripherals = {
    ["modem"] = true,
    ["turtle"] = true,
    ["redstone_relay"] = true,
    ["focal_port"] = true,
    ["cleric_impetus"] = true
}

local connected_peripherals = {}

for i, periph in ipairs(peripheral.getNames()) do
    connected_peripherals[peripheral.getType(periph)] = true
end


for i, periph in ipairs(needed_peripherals) do
    if connected_peripherals[periph] then
        connected_peripherals[periph] = false
    end
end

for i, missing in ipairs(connected_peripherals) do
    print("Peripheral \"" .. missing .. "\" not found, please add it")
end
if not next(connected_peripherals) then
    goto exit
end

-- settings.define("test", {description = "A test setting", type = "boolean"})

settings.save()


::exit::