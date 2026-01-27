# philip-adminduty (v2.0)

A lightweight admin duty + overhead tag script designed for **QBCore servers**, modernized for current FiveM practices.

## What’s new in v2.0

### Major changes
- **Configurable command names**  
  Default: `/aduty` and `/atag` (both can be renamed in `config.lua`).
- **Unified whitelist permission system (license / discord)**  
  No more `admin/god` permission groups. Access is controlled via:
  - `license:xxxxxxxx...`
  - `discord:123456789012345678`
- **Duty announcements via UI (not chat)**  
  When someone toggles duty, a clean **top-screen UI banner** appears for everyone.
- **Overhead logo without .ytd (optional)**  
  Supports:
  - `runtime_png` (recommended): uses `images/logo.png`
  - `ytd` (legacy): uses a streamed texture dictionary
- **More accurate overhead logo position**  
  Uses **head bone** positioning + configurable offset, so it sits consistently above the head.
- **Admin ped swap is optional**  
  If enabled, duty ON swaps to the configured ped model; duty OFF restores back.
- **Appearance system support**  
  Best-effort restore for:
  - **qb-clothing**
  - **illenium-appearance**
  - **fivem-appearance**
  Includes auto-detection and debug logs.

### Stability / behavior improvements
- **Duty state is explicit** (server tells client ON/OFF) to avoid toggle desync.
- **Resource restart safety**  
  When the resource stops/restarts, duty is forced OFF and restore runs.

## Requirements
- **QBCore**
- For appearance restore (optional, auto-detected):
  - `qb-clothing` **or**
  - `illenium-appearance` **or**
  - `fivem-appearance`

## Installation

1. Put the resource folder into your `resources/` directory.
2. Ensure `fxmanifest.lua` includes the UI and the logo file:
   - `html/index.html`, `html/style.css`, `html/app.js`
   - `images/logo.png`
3. Add to your server config:
   ```cfg
   ensure philip-adminduty
   ```
4. Configure `config.lua` (see below).

## Commands

- `/aduty`  
  Toggles admin duty ON/OFF.
- `/atag`  
  Toggles the overhead tag/logo visibility (for whitelisted users).

> Command names can be changed in `Config.Commands`.

## Configuration

All config options are grouped in `config.lua` for readability. Key sections:

### Language
`Lang` table is at the top. Select active language:
```lua
Config.Lang = 'hu' -- or 'en'
```

### Commands
```lua
Config.Commands = {
  Duty = 'aduty',
  Tag  = 'atag',
}
```

### Whitelist (permissions)
Both commands use the **same unified whitelist**:
```lua
Config.Access = {
  licenses = {
    'license:11000010abcdef12',
  },
  discords = {
    'discord:123456789012345678',
  },
  denyIfEmpty = true
}
```

- If `denyIfEmpty = true` and the lists are empty → nobody can use commands.
- If `denyIfEmpty = false` and the lists are empty → everyone can use commands (not recommended).

### Duty UI Banner
```lua
Config.DutyBanner = {
  enabled = true,
  durationMs = 3500,
}
```

### Optional Admin Ped Swap
```lua
Config.AdminPed = {
  enabled = true,
  model = 's_m_y_cop_01',
}
```

- If disabled, duty won’t change the player model at all.

### Appearance / Skin Restore
```lua
Config.Appearance.system = 'auto'
```

Options:
- `auto` (recommended)
- `qb-clothing`
- `illenium-appearance`
- `fivem-appearance`

If your resources are renamed, add your actual folder names here:
```lua
Config.Appearance.resources = {
  illenium = { 'illenium-appearance' },
  fivem    = { 'fivem-appearance' },
  qb       = { 'qb-clothing', 'qb-clothes' },
}
```

Debug output (F8 console):
```lua
Config.Appearance.debug = true
```

### Overhead Logo

#### Recommended: runtime PNG (no .ytd)
```lua
Config.Logo.Method = 'runtime_png'
Config.Logo.RuntimePng.File = 'images/logo.png'
```

Use a PNG like **256×256 or 512×512** with transparent background.

#### Legacy: YTD
```lua
Config.Logo.Method = 'ytd'
Config.Logo.Ytd.Dict = 'logo'
Config.Logo.Ytd.Texture = 'logo'
```

### Logo Position
Uses head-bone positioning by default:
```lua
Config.LogoPosition = {
  useHeadBone = true,
  headBoneId = 31086,
  headOffset = { x = 0.0, y = 0.0, z = 0.10 },
}
```

If the logo is too high/low, adjust `headOffset.z`.

## Compatibility

### Fully supported
- **QBCore** (required)
- **qb-clothing** (restore via qb events)
- **illenium-appearance** (restore via exports + optional reload event)
- **fivem-appearance** (restore via exports)

### Notes
- Some servers rename appearance resources; update `Config.Appearance.resources` accordingly.
- Discord identifier availability depends on server/client conditions; **license** is the most reliable identifier.

## Troubleshooting

### “My skin doesn’t restore after duty”
1. Enable debug:
   ```lua
   Config.Appearance.debug = true
   ```
2. Toggle duty ON then OFF, open F8 and check what system was detected.
3. If it shows `nil` or the wrong one, your appearance resource name is different → add the correct folder name(s) to:
   ```lua
   Config.Appearance.resources
   ```

### “Logo shows as a white box”
- Check `fxmanifest.lua` includes:
  - `files { 'images/logo.png' }`
- Confirm the file exists at: `images/logo.png`
- Keep PNG size reasonable (256/512) and ensure it is a real PNG.

## Credits
- **Philip** (original author)
- v2.0 modernization and compatibility improvements
