# HxH 5e RPG — Roblox Studio (backup local)

Backup do código-fonte do jogo Roblox do sistema HxH 5e RPG.
Este repositório é **local** (ainda não publicado no GitHub) — export
feito diretamente do Roblox Studio via MCP em 2026-08-27/28.

**Não confundir com** `Criadores-HxH-5e/Ficha_HxH5e` — aquele é o
webapp de referência (ficha-hx-h5e.vercel.app), um projeto separado
que serve de fonte de verdade para a engine que estamos construindo aqui.

## Estrutura

```
src/
  ReplicatedStorage/HxH5e/Shared/   -- CharacterSchema, SystemDB (dados compartilhados)
  ServerScriptService/HxH5e/        -- ServerBootstrap, CharacterService,
                                        CharacterRepository, NenService,
                                        HatsuService, BuffManager, CombatService
  StarterGui/HxH5e/                 -- FichaClient, ActionBarClient (interface)
```

Não inclui: assets de teste do Workspace ("weird monster thing", "Rig")
nem o sistema "SquareArena" (ProceduralGeneration) em ServerStorage —
não fazem parte do sistema HxH5e.

## Como manter atualizado

Sempre que houver mudanças relevantes feitas direto no Roblox Studio,
pedir para re-exportar os scripts alterados para este repositório.
