local pbkdf2 = require("libs.encryption.pbkdf2")

local verify = {}

local master_disk_ids = {
    [1] = true,
    [4] = true
}

function verify.master_disk(drive_name, salt)
    local drive = assert(peripheral.wrap(drive_name))

    if not master_disk_ids[drive.getDiskID()] then
        return false, "Invalid id"
    end

    local identity_file = fs.open(fs.combine(drive.getMountPath(), "identity.txt"), "r")
    if identity_file == nil then
        return false, "No identity file"
    end

    local identity = identity_file.readAll()
    identity_file.close()

    local verification_file = assert(fs.open("rom/hashes/master_disk_identity.hash", "r"))
    local verification_hash = verification_file.readAll()
    verification_file.close()

    local salt_file = fs.open("rom/hashes/salt.txt", "r")
    local salt = salt_file.readLine()
    salt_file.close()

    local identity_hash = pbkdf2.derive(identity, salt, 20000, "Deriving identity: ")
    if identity_hash ~= verification_hash then
        return false, "Failed hash"
    end

    return true
end


return verify