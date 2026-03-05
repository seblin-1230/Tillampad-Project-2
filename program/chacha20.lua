local utils = require("utils")

---Generate the matrix state
---@param key string A 32 character long string
---@param block_count number The current block count
---@param nonce string A 12 byte long string
local function initilize_matrix(key, block_count, nonce)
    local matrix = { 0x61707865, 0x3320646e, 0x79622d32, 0x6b206574 }

    for i = 1, #key, 4 do
        table.insert(matrix, utils.bytes_to_int(string.sub(key, i, i + 3), "little", false))
    end

    table.insert(matrix, block_count)

    for i = 1, #nonce, 4 do
        table.insert(matrix, utils.bytes_to_int(string.sub(nonce, i, i + 3), "big", false))
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

    a = utils.add32(a, b)
    d = bit32.bxor(d, a)
    d = bit32.lrotate(d, 16)

    c = utils.add32(c, d)
    b = bit32.bxor(b, c)
    b = bit32.lrotate(b, 12)

    a = utils.add32(a, b)
    d = bit32.bxor(d, a)
    d = bit32.lrotate(d, 8)

    c = utils.add32(c, d)
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

local function generate_keystream_block(key, nonce, block_count)
    local matrix_state = initilize_matrix(key, block_count, nonce)
    local initial_matrix_state = utils.copy_table(matrix_state)

    for i = 1, 10 do
        double_round(matrix_state)
    end

    for i = 1, #matrix_state do
        matrix_state[i] = utils.add32(matrix_state[i], initial_matrix_state[i])
    end

    return matrix_state
end

---Generates a keystream long enough to encrypt a message of length `length`
---@param key string The key to encrypt with
---@param nonce string The random nonce sent as a string 12 bytes long
---@param length integer THe minimum length of the keystream
---@return integer[] keystream The resulting keystream
local function generate_keystream(key, nonce, length)
    local keystream = {}
    for block_count = 1, math.ceil(length / 64) do
        local block = generate_keystream_block(key, nonce, block_count)

        for _, word in ipairs(block) do
            local bytes = utils.int_to_bytes(word, "little", false)
            for _, byte in ipairs(bytes) do
                table.insert(keystream, byte)
            end
        end
    end

    return keystream
end

---Encrypts text using ChaCha20
---@param plaintext string The text to encrypt
---@param key string A 32 character long string
---@param nonce string A random string 12 bytes long, if unspecified automaticaly generated.
---@return string ciphertext The encrypted text
---@return string nonce The nonce used to encrypt the text
local function encrypt(plaintext, key, nonce)
    -- if nonce == nil then nonce = generate_nonce() end

    local keystream = generate_keystream(key, nonce, #plaintext)

    local cipherbytes = {}
    for i = 1, #plaintext do
        local plainbyte = string.byte(string.sub(plaintext, i))
        table.insert(cipherbytes, bit32.bxor(keystream[i], plainbyte))
    end

    return cipherbytes, nonce
end

local key = string.char(0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
    0x10, 0x11, 0x12, 0x13,
    0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f)
local text =
[[
Ladies and Gentlemen of the class of '99: If I could offer you only one tip forthe future, sunscreen would be it.
]]

local ciphertext, nonce = encrypt(text, key, "\x00\x00\x00\x00\x4a\x00\x00\x00\x00\x00\x00\x00")

local print_matrix = {}
for i, value in ipairs(ciphertext) do
    table.insert(print_matrix, utils.int_to_hex(value, 1))
end
textutils.pagedTabulate(print_matrix)
