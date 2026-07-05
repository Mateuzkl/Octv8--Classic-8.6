# OTCv8 Classic 8.60 Protocol Features

This document explains the 8.60 feature flags used by OTCv8 Classic and how they differ from AstraClient.

PT-BR version: `docs/protocol-features-8.60.pt-BR.md`

Read this before changing any `g_game.enableFeature(...)` or `g_game.disableFeature(...)` call. Some flags are visual, but others change packet layout. Enabling the wrong flag can desync the protocol parser.

## Important Files

- `modules/game_features/features.lua`: default feature profile by client version.
- `modules/gamelib/const.lua`: Lua feature ids.
- `src/client/const.h`: C++ feature ids.
- `src/client/protocolgameparse.cpp`: packet parser and `parseFeatures`.
- `modules/client_entergame/entergame.lua`: features received from HTTP login.

On the server side, the main reference is `ProtocolGame::sendFeatures()` in `src/protocolgame.cpp`.

## Main Rule

Not every feature is just UI.

Some features change packet size or packet field order. If the client enables one of those features and the server does not send the matching extra bytes, the next fields are read from the wrong offset.

Common symptoms:

- wrong item ids;
- broken containers;
- black map or wrong tiles;
- unknown opcode errors;
- look/use stops working;
- crash or disconnect when opening backpacks, corpses, loot, or store inbox.

## How OTC Classic Enables Features

OTCv8 Classic uses version ranges in `modules/game_features/features.lua`.

Examples:

- `if version >= 770`
- `if version >= 780`
- `if version >= 840`
- `if version >= 860`
- `if version >= 910`

That means a feature added in `version >= 860` may also stay enabled for later versions unless another block changes it later.

Features can also be negotiated by the server:

- HTTP login `features` field;
- game packet `GameServerFeatures` (`0x43`), parsed by `parseFeatures`.

Features that change packet layout should follow that server handshake.

## OTC Classic 8.60 Base Features

Before the 8.60 block, the client already enables older protocol features:

```lua
-- version >= 770
GameLooktypeU16
GameMessageStatements
GameLoginPacketEncryption

-- version >= 780
GamePlayerAddons
GamePlayerStamina
GameNewFluids
GameMessageLevel
GamePlayerStateU16
GameNewOutfitProtocol

-- version >= 790
GameWritableDate

-- version >= 840
GameProtocolChecksum
GameAccountNames
GameDoubleFreeCapacity

-- version >= 841
GameChallengeOnLogin
GameMessageSizeCheck
GameTileAddThingWithStackpos

-- version >= 854
GameCreatureEmblems
```

## OTC Classic 8.60 Client Extensions

In the `if(version >= 860) then` block, this branch enables:

```lua
GameAttackSeq
GameBot
GameExtendedOpcode
GameSkillsBase
GamePlayerMounts
GameMagicEffectU16
GameDistanceEffectU16
GameDoubleHealth
GameOfflineTrainingTime
GameBaseSkillU16
GameAdditionalSkills
GameIdleAnimations
GameEnhancedAnimations
GameExtendedClientPing
GameSpritesU32
GameDoublePlayerGoodsMoney
GameCreatureIcons
GamePurseSlot
GamePrey
```

Notes:

- `GameSpritesU32` must match the extended `.spr` assets used by the client.
- `GamePurseSlot` is hardcoded in this OTC Classic 8.60 profile.
- `GameDoubleSkills` and `GameDoubleMagicLevel` are commented out in this block.
- `GameSpritesAlphaChannel` is also commented out for 8.60.

## Intentionally Disabled Features

These three lines are intentional in the 8.60 block:

```lua
g_game.disableFeature(GameQuickLootFlags)
g_game.disableFeature(GameThingUpgradeClassification)
g_game.disableFeature(GameItemTierByte)
```

Do not change them to `enableFeature` unless the server is changed at the same time.

## Dangerous Flags

These three flags are the most common source of protocol bugs:

```lua
GameQuickLootFlags              -- id 123
GameThingUpgradeClassification  -- id 130
GameItemTierByte                -- id 131
```

### GameQuickLootFlags

Changes item/container quick-loot flag parsing. If the client expects this byte and the server does not send it, the parser consumes the next packet field as a flag.

### GameThingUpgradeClassification

Changes item classification/tier parsing. The current server sends this feature as `false` for OTCv8/Astra.

### GameItemTierByte

Adds a tier byte to item parsing. It must be enabled only when the server also sends that byte.

## Server-Negotiated Features

The server can send features through packet `0x43` (`GameServerFeatures`). OTC Classic also accepts features from HTTP login.

The current server `sendFeatures()` sends to OTCv8/Astra, among others:

```cpp
ExtendedOpcode = true
SkillsBase = true
PlayerMounts = true
MagicEffectU16 = true
OfflineTrainingTime = true
DoubleSkills = true
BaseSkillU16 = true
AdditionalSkills = true
ExtendedClientPing = true
CreatureIcons = true
ContainerPagination = true
BrowseField = true
QuickLootFlags = shouldSendQuickLootFlags()
ThingUpgradeClassification = false
ItemTierByte = shouldSendItemTierByte()
```

If the server sends `QuickLootFlags=false`, `ThingUpgradeClassification=false`, or `ItemTierByte=false`, the client should respect it.

## Differences From AstraClient

AstraClient uses a direct `version == 860` profile, not a long chain of `version >=` blocks.

Astra 8.60 enables some features that should not be copied automatically into OTC Classic:

```lua
GameColorizedLootValue
GameBrowseField
GamePlayerFamiliars
GameProficiency
GameUnjustifiedPoints
```

Astra also has its own C++/Lua feature flags that do not exist in this OTC Classic branch:

```lua
GameAstraCreatureIcons
GameAstraQuiverCountU16
GameAstraOutfitStoreMode
GameAstraItemMetadata
```

Those flags depend on Astra parser support and on the server recognizing AstraClient. Copying them into OTC Classic does not make the feature work.

## Checklist Before Changing a Feature

- [ ] Is the feature UI-only, or does it change network packets?
- [ ] Does the id exist in both `modules/gamelib/const.lua` and `src/client/const.h`?
- [ ] Does the server send the same feature in `sendFeatures()` or HTTP login?
- [ ] If it affects items, did you check `getItem`, `addItem`, containers, map, and inventory?
- [ ] If it affects creatures/outfits, did you check outfit window, creature icons, and login?
- [ ] Did you test login, walking, look, use, backpack, corpse, store inbox, and logout?
- [ ] If the feature is negotiated, did you test both `false` and `true`?

## Practical Rule

For OTC Classic 8.60:

- keep the `version >= 860` block separate from Astra;
- do not copy Astra-only features into this client;
- keep `GameQuickLootFlags`, `GameThingUpgradeClassification`, and `GameItemTierByte` disabled by default;
- packet-layout features should be negotiated by the server;
- if the server changes `sendFeatures()`, review the client parser in the same PR.
