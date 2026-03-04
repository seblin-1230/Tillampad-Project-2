local function string_to_bytes()
    
end

---Reutrns a nonce, current implemention temporary untill i implement better randomness
---@return [number,number,number] nonce An array containing three 32 bit random numbers
local function generate_nonce()
    return {math.random(0, 0xFFFFFFFF), math.random(0, 0xFFFFFFFF), math.random(0, 0xFFFFFFFF)}
end

---Generate the matrix state
---@param key string A 32 character long string
---@param block_count number The current block count
---@param nonce [number, number, number] Three random 32 bit numbers
local function initilize_matrix(key, block_count, nonce)
    local matrix = {0x61707865, 0x3320646e, 0x79622d32, 0x6b206574}
    print(key)
    for i = 1, #key do
        print(string.byte(key[i]))
    end
end

---comment
---@param plaintext string The text to encrypt
---@param key string A 32 character long string
---@param nonce? [number, number, number] Three random 32 bit numbers, if unspecified automaticaly generated.
---@return string ciphertext The encrypted text
---@return [number, number, number] nonce The nonce used to encrypt the text
local function encrypt(plaintext, key, nonce)
    if nonce == nil then nonce = generate_nonce() end

    local matrix_state = initilize_matrix(key, 1, nonce)

    for i, word in ipairs(matrix_state) do
        print(i, string.format("%08x", word))
    end

    return "temp", nonce
end

local key = string.char(0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f)
local text = [[Gary didn't understand why Doug went upstairs to get one dollar bills when he invited him to go cow tipping.
She wore green lipstick like a fashion icon.
His son quipped that power bars were nothing more than adult candy bars.
The sight of his goatee made me want to run and hide under my sister-in-law's bed.
There is no better feeling than staring at a wall with closed eyes.]]

print(encrypt(text, key, {0, 0, 0}))