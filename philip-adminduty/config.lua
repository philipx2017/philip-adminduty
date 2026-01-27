Lang = {
    ['hu'] = {
        dutyOn = 'Beléptél adminszolgálatba!',
        dutyOff = 'Kiléptél adminszolgálatból!',

        dutyOnGlobal = ' adminszolgálatba lépett',
        dutyOffGlobal = ' kilépett az adminszolgálatból',

        noPerm = 'Nincs jogosultságod ehhez.'
    },
    ['en'] = {
        dutyOn = 'You are in duty!',
        dutyOff = 'You are no longer in duty!',

        dutyOnGlobal = ' entered admin duty',
        dutyOffGlobal = ' left admin duty',

        noPerm = 'You do not have permission.'
    }
}

Config = {
    -- General
    Lang = 'en',

    -- Commands (defaults: /aduty /atag)
    Commands = {
        Duty = 'aduty',
        Tag  = 'atag',
    },

    -- Unified whitelist access for both commands (license/discord)
    -- Examples:
    --  license:11000010abcdef12
    --  discord:123456789012345678
    Access = {
        licenses = {
            -- 'license:11000010abcdef12',
        },
        discords = {
            -- 'discord:123456789012345678',
        },
        -- If true: empty whitelist denies everyone
        -- If false: empty whitelist allows everyone (not recommended)
        denyIfEmpty = true
    },

    -- Admin duty ped settings (optional)
    AdminPed = {
        enabled = false,         -- set true to swap model on duty
        model = 's_m_y_cop_01',  -- ped model name or hash; used only if enabled=true
    },

    -- Appearance restore integration
    Appearance = {
        -- 'auto' will detect the first started resource based on the lists below.
        -- You can force: 'qb-clothing' | 'illenium-appearance' | 'fivem-appearance'
        system = 'auto',

        debug = false, -- prints to F8 console what was detected and which restore calls ran

        -- If your resources are renamed, add the folder name here.
        resources = {
            illenium = { 'illenium-appearance' },
            fivem    = { 'fivem-appearance' },
            qb       = { 'qb-clothing', 'qb-clothes' },
        },

        
        qb = {
            serverEvents = {
                'qb-clothing:loadPlayerSkin',
                'qb-clothes:loadPlayerSkin',
            },
            clientEvents = {
                'qb-clothing:client:loadPlayerClothing',
                'qb-clothes:client:loadPlayerClothing',
            }
        },

        -- illenium-appearance extras (optional)
        illenium = {
            reloadSkinClientEvent = 'illenium-appearance:client:reloadSkin'
        },

        -- Safety timings (ms) for model swap + appearance apply
        delays = {
            afterModelSwap = 250,
            afterApplyAppearance = 900,
        }
    },

    -- Global duty UI banner (top of the screen for everyone)
    DutyBanner = {
        enabled = true,
        durationMs = 3500,
    },

    -- Overhead logo draw
    DrawDistance = 50,

    -- Logo position (head-bone based)
    LogoPosition = {
        useHeadBone = true,
        headBoneId = 31086, -- SKEL_Head
        headOffset = { x = 0.0, y = 0.0, z = 0.50 },
    },

    -- Legacy fallback (only used if useHeadBone=false)
    AdminLogoHeight = 1.5,

    -- Marker options (used mainly for YTD marker mode)
    LogoSpin = false,
    LogoMovingWithCamera = true,
    LogoBouncing = false,

    -- Logo source
    Logo = {
        -- Method:
        --  'ytd'         => streamed texture dict
        --  'runtime_png' => runtime PNG texture (no .ytd needed)
        Method = 'runtime_png',

        Ytd = {
            Dict = 'logo',
            Texture = 'logo'
        },

        RuntimePng = {
            Dict = 'adminduty_logo',
            Texture = 'logo',
            File = 'images/logo.png'
        }
    },
}
