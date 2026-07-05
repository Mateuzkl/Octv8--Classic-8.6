# OTCv8 Classic 8.60 protocol features

Este guia separa as features usadas pelo OTCv8 Classic das features usadas pelo AstraClient.

O objetivo e evitar bug de protocolo causado por ligar `g_game.enableFeature(...)` sem o servidor mandar os bytes esperados.

## Arquivos importantes

- `modules/game_features/features.lua`: features padrao por versao do client.
- `modules/gamelib/const.lua`: ids das features no Lua.
- `src/client/const.h`: ids das features no C++.
- `src/client/protocolgameparse.cpp`: parser de pacotes e `parseFeatures`.
- `modules/client_entergame/entergame.lua`: features recebidas via login HTTP.

No server, a referencia principal e `ProtocolGame::sendFeatures()` em `src/protocolgame.cpp`.

## Regra principal

Nem toda feature e apenas visual.

Algumas features mudam o tamanho ou a ordem dos pacotes. Se o client habilita uma dessas features e o server nao envia os bytes extras, o parser sai de alinhamento.

Sintomas comuns:

- item aparece com ID errado;
- container abre quebrado;
- map fica preto ou com tiles errados;
- erro de opcode desconhecido;
- look/use para de funcionar;
- crash ou disconnect ao abrir backpack, loot, corpo ou store inbox.

## Como o OTC Classic habilita features

O OTCv8 Classic usa faixas de versao em `modules/game_features/features.lua`.

Exemplos:

- `if version >= 770`
- `if version >= 780`
- `if version >= 840`
- `if version >= 860`
- `if version >= 910`

Ou seja: uma feature adicionada em um bloco `version >= 860` tambem pode ficar ativa para versoes maiores, a menos que outro bloco depois altere isso.

Tambem existem features que podem vir do server:

- login HTTP: campo `features`;
- game packet `GameServerFeatures` (`0x43`), lido por `parseFeatures`.

Features que mudam pacote devem seguir esse handshake do server.

## OTC Classic 8.60: features base

Antes do bloco 8.60, o client ja liga algumas features por versoes antigas:

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

## OTC Classic 8.60: extensoes habilitadas no client

No bloco `if(version >= 860) then`, o OTC Classic desta branch habilita:

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

Observacoes:

- `GameSpritesU32` precisa bater com os assets estendidos (`.spr`) usados pelo client.
- `GamePurseSlot` esta hardcoded no OTC Classic 8.60 desta branch.
- `GameDoubleSkills` e `GameDoubleMagicLevel` estao comentadas nesse bloco.
- `GameSpritesAlphaChannel` tambem esta comentada para 8.60.

## Features desligadas de proposito

Estas tres linhas sao intencionais no bloco 8.60:

```lua
g_game.disableFeature(GameQuickLootFlags)
g_game.disableFeature(GameThingUpgradeClassification)
g_game.disableFeature(GameItemTierByte)
```

Nao troque por `enableFeature` sem alterar o server junto.

## Features perigosas

Estas tres sao as mais comuns de causar bug de protocolo:

```lua
GameQuickLootFlags              -- id 123
GameThingUpgradeClassification  -- id 130
GameItemTierByte                -- id 131
```

### GameQuickLootFlags

Muda leitura/escrita de flags de quick loot em itens/containers. Se o client espera a flag e o server nao envia, o proximo byte do pacote vira lixo para o parser.

### GameThingUpgradeClassification

Muda leitura de classificacao/tier em item. No server atual, essa feature e enviada como `false` para OTCv8/Astra.

### GameItemTierByte

Muda leitura de tier com um byte extra. So deve ficar ativa quando o server tambem envia esse byte.

## Features negociadas pelo server

O server pode enviar features pelo packet `0x43` (`GameServerFeatures`). O OTC Classic tambem aceita features pelo login HTTP.

No server atual, `sendFeatures()` envia para OTCv8/Astra, entre outras:

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

Se o server mandar `QuickLootFlags=false`, `ThingUpgradeClassification=false` ou `ItemTierByte=false`, o client deve respeitar.

## Diferencas para AstraClient

O AstraClient desta branch usa perfil direto para `version == 860`, nao uma cadeia grande de `version >=`.

O Astra 8.60 habilita algumas features que nao devem ser copiadas automaticamente para o OTC Classic:

```lua
GameColorizedLootValue
GameBrowseField
GamePlayerFamiliars
GameProficiency
GameUnjustifiedPoints
```

O Astra tambem possui features proprias no C++/Lua que nao existem no OTC Classic desta branch:

```lua
GameAstraCreatureIcons
GameAstraQuiverCountU16
GameAstraOutfitStoreMode
GameAstraItemMetadata
```

Essas flags dependem do parser do Astra e do server reconhecer o AstraClient. Copiar para o OTC Classic nao torna a feature funcional.

## Checklist antes de mexer em feature

- [ ] A feature e so visual/UI ou muda pacote de rede?
- [ ] O id existe em `modules/gamelib/const.lua` e `src/client/const.h`?
- [ ] O server envia a mesma feature em `sendFeatures()` ou login HTTP?
- [ ] Se muda item, conferi `getItem`, `addItem`, container, map e inventory?
- [ ] Se muda creature/outfit, conferi outfit window, creature icons e login?
- [ ] Testei login, walk, look, use, open backpack, corpse, store inbox e logout?
- [ ] Testei com a feature `false` e `true` quando ela e negociada?

## Regra pratica

Para o OTC Classic 8.60:

- mantenha o bloco `version >= 860` separado do Astra;
- nao copie feature Astra-only para ca;
- mantenha `GameQuickLootFlags`, `GameThingUpgradeClassification` e `GameItemTierByte` desligadas por padrao;
- feature que muda pacote deve vir do server por handshake;
- se o server mudar `sendFeatures()`, revise o parser do client no mesmo PR.
