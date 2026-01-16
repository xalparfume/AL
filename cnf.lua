--[[ 
   FILENAME: cnf.lua
   DESKRIPSI: Config User
]]

-- Variabel diganti jadi 'CNF' agar sesuai nama file
getgenv().CNF = {
    -- 1. Webhook
    Webhook_URL = "MASUKKAN_URL_WEBHOOK_DISCORD_KAMU_DI_SINI",

    -- 2. Daftar Secret
    SecretList = {
        "Orca",
        "Crystal Crab",
        "Monster Shark",
        "Eerie Shark",
        "Great Whale",
        "Robot Kraken",
        "King Crab",
        "Queen Crab",
        "Kraken",
        "Grand Maja",
        "Bone Whale",
        "Worm Fish",
        "Ghost Shark",
        "Megalodon",
        "Skeleton Narwhal",
    },

    -- 3. Daftar Stone/Item
    StoneList = {
        "Ruby",
        "Sandy Ruby",
        "Enchant Stone",
    }
}

-- =============================================================
-- LOADER: PANGGIL FILE LOGIC (xal.lua)
-- Masukkan Link Raw xal.lua di bawah ini
-- =============================================================

loadstring(game:HttpGet("PASTE_LINK_RAW_GITHUB_XAL_LUA_DISINI"))()
