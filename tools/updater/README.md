# OTCv8 Local Auto Updater

Este kit cria um fluxo local para testar o updater do OTCv8 Classic.

## Uso rapido

1. Edite ou adicione arquivos em `data`, `modules` ou `init.lua`.
2. Edite `tools/updater/changelog.txt` com as notas da atualizacao.
3. Rode `2_Abrir_Client_AutoUpdater.bat`.

O BAT gera `updater_dist/manifest.json`, liga um servidor local em
`http://127.0.0.1:8080/updater` e abre o client de `release_client`.
Na primeira vez ele cria `release_client/data.zip`. Nas proximas vezes ele
mantem esse `data.zip`, entao os arquivos novos entram pelo updater.

## Bats

- `1_Gerar_Update.bat`: gera somente o manifest/update local.
- `2_Abrir_Client_AutoUpdater.bat`: gera o update, liga o servidor e abre o client.
- `3_Recriar_Release_Limpo.bat`: recria `release_client/data.zip` do zero.

## Como o updater funciona

O `init.lua` so chama o updater quando o client esta rodando por `data.zip`.
Por isso o BAT abre o client pela pasta `release_client`, que nao tem `init.lua`,
`data` e `modules` soltos. O client carrega `data.zip`, consulta o servidor local,
baixa os arquivos com CRC diferente e recria o `data.zip` automaticamente.

Para publicar em site real, altere `tools/updater/updater_config.json` e use uma
URL publica no lugar do servidor local.
