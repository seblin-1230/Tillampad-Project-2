local utils = require("utils")

---Convert a string in to a integer based on its bytes, taken from (https://stackoverflow.com/questions/5241799/lua-dealing-with-non-ascii-byte-streams-byteorder-change)
---@param str string
---@param endian "big"|"little"
---@param signed boolean
---@return integer
local function bytes_to_int(str, endian, signed)
    local t = { str:byte(1, -1) }
    if endian == "big" then --reverse bytes
        local tt = {}
        for k = 1, #t do
            tt[#t - k + 1] = t[k]
        end
        t = tt
    end
    local n = 0
    for k = 1, #t do
        n = n + t[k] * 2 ^ ((k - 1) * 8)
    end
    if signed then
        n = (n > 2 ^ (#t * 8 - 1) - 1) and (n - 2 ^ (#t * 8)) or n -- if last bit set, negative.
    end
    return n
end

---Split a string into "size" sized chunks
---@param str string
---@param size integer
---@return table
local function chunk_string(str, size)
    local chunks = {}
    for i = 1, #str, size do
        table.insert(chunks, string.sub(str, i, i+size-1))
    end

    return chunks
end

---Convert an integer into a hex string padded by "pad" using 0s
---@param num number
---@param pad integer
---@return string
local function int_to_hex(num, pad)
    local format = string.format("%%0%dx", pad)
    return string.format(format, num)
end

local function split_()
    
end

---Reutrns a nonce, current implemention temporary until i implement better randomness
---@return [number,number,number] nonce An array containing three 32 bit random numbers
local function generate_nonce()
    return { math.random(0, 0xFFFFFFFF), math.random(0, 0xFFFFFFFF), math.random(0, 0xFFFFFFFF) }
end

---Generate the matrix state
---@param key string A 32 character long string
---@param block_count number The current block count
---@param nonce [number, number, number] Three random 32 bit numbers
local function initilize_matrix(key, block_count, nonce)
    local matrix = { 0x61707865, 0x3320646e, 0x79622d32, 0x6b206574 }

    for i = 1, #key, 4 do
        table.insert(matrix, bytes_to_int(string.sub(key, i, i + 3), "little", false))
    end

    table.insert(matrix, block_count)

    for _, sub_nonce in ipairs(nonce) do
        table.insert(matrix, sub_nonce)
    end

    return matrix
end

---A quater round of chacha encryption
---@param matrix_state integer[]
---@param a_i integer
---@param b_i integer
---@param c_i integer
---@param d_i integer
local function quater_round(matrix_state, a_i, b_i, c_i, d_i)
    local a, b, c, d = matrix_state[a_i], matrix_state[b_i], matrix_state[c_i], matrix_state[d_i]

    a = a + b
    d = bit32.bxor(d, a)
    d = bit32.lrotate(d, 16)

    c = c + d
    b = bit32.bxor(b, c)
    b = bit32.lrotate(b, 12)

    a = a + b
    d = bit32.bxor(d, a)
    d = bit32.lrotate(d, 8)

    c = c + d
    b = bit32.bxor(b, c)
    b = bit32.lrotate(b, 7)

    matrix_state[a_i], matrix_state[b_i], matrix_state[c_i], matrix_state[d_i] = a, b, c, d
end

---Does both a collumn round and a diagonal round on the matrix state
---@param matrix_state integer[]
local function double_round(matrix_state)
    quater_round(matrix_state, 1, 5, 9, 13) -- Column rounds
    quater_round(matrix_state, 2, 6, 10, 14)
    quater_round(matrix_state, 3, 7, 11, 15)
    quater_round(matrix_state, 4, 8, 12, 16)
    quater_round(matrix_state, 1, 6, 11, 16) -- Diagonal rounds
    quater_round(matrix_state, 2, 7, 12, 13)
    quater_round(matrix_state, 3, 8, 9, 14)
    quater_round(matrix_state, 4, 5, 10, 15)
end

local function serialize_matrix(matrix_state)
    local keystream_block = ""
    for _, value in ipairs(matrix_state) do
        keystream_block = keystream_block .. "tmo"
    end
end

---Encrypt a 512 bit chunk of the plaintext
---@param plaintext_chunk string
---@param key string
---@param block_count integer
---@param nonce [integer, integer, integer]
local function encrypt_chunk(plaintext_chunk, key, block_count, nonce)
    local matrix_state = initilize_matrix(key, block_count, nonce)
    local initial_matrix_state = utils.copy_table(matrix_state)
    
    for i = 1, 1 do
        double_round(matrix_state)
    end

    
end

---Encrypts text using ChaCha20
---@param plaintext string The text to encrypt
---@param key string A 32 character long string
---@param nonce? [number, number, number] Three random 32 bit numbers, if unspecified automaticaly generated.
---@return string ciphertext The encrypted text
---@return [number, number, number] nonce The nonce used to encrypt the text
local function encrypt(plaintext, key, nonce)
    if nonce == nil then nonce = generate_nonce() end

    local ciphertext = ""
    for i = 1, #plaintext, 512 do
        ciphertext = ciphertext .. encrypt_chunk(string.sub(plaintext, i, i+511), key, i, nonce)
    end

    return ciphertext, nonce
end

local key = string.char(0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
    0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f)
local text =
[[Gary didn't understand why Doug went upstairs to get one dollar bills when he invited him to go cow tipping.
She wore green lipstick like a fashion icon.
His son quipped that power bars were nothing more than adult candy bars.
The sight of his goatee made me want to run and hide under my sister-in-law's bed.
There is no better feeling than staring at a wall with closed eyes.]]

print(encrypt(text, key, { 0, 0, 0 }))






    -- local print_matrix = {}
    -- for i, value in ipairs(matrix_state) do
    --     table.insert(print_matrix, int_to_hex(value, 8))
    -- end
    -- textutils.pagedTabulate(print_matrix)