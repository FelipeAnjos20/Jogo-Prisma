# PRISMA

Jogo serio de puzzle geometrico em Godot 4.6 — ensina angulo, reflexao e
simetria atraves de um mecanismo de espelhos giratorios e um feixe de luz.

O jogador observa a posicao do emissor, dos espelhos e do cristal receptor,
seleciona espelhos, gira-os em passos fixos de 15 graus e acompanha em tempo
real a mudanca no caminho do feixe, ate acerta-lo no cristal.

Para o contexto completo do projeto, veja [docs/contexto.md](docs/contexto.md).

## Como rodar

1. Abra o projeto no Godot 4.6 (ou compativel).
2. Rode o projeto com `F5`, ou abra `scenes/main.tscn` e rode a cena com `F6`.

## Controles

| Tecla / acao         | Efeito                                             |
|-----------------------|-----------------------------------------------------|
| Clique esquerdo        | Seleciona o espelho clicado                         |
| `1` a `4`              | Seleciona o espelho correspondente                  |
| `Tab`                  | Alterna para o proximo espelho giravel disponivel   |
| `Q`                    | Gira o espelho selecionado no sentido anti-horario  |
| `E`                    | Gira o espelho selecionado no sentido horario       |
| `R`                    | Reinicia a fase atual                                |
| `N`                    | Avanca para a proxima fase (apos ativar o cristal)  |
| `M`                    | Liga/desliga a musica                                |
| `Esc`                  | Volta para o menu principal                          |

No menu principal, o painel de opcoes permite ajustar o volume e ligar/desligar
o som pelo mouse.

## Estrutura do repositorio

```
prisma-project/
├── project.godot              # Configuracao do projeto Godot
├── export_presets.cfg         # Presets de exportacao (ex.: Windows Desktop)
├── icon.svg / icon.svg.import # Icone do projeto
├── scenes/                    # Cenas jogaveis (menu, fase principal, tela de conclusao)
├── scripts/                   # Logica em GDScript de cada objeto/cena
│   └── geometria.gd           # Regras geometricas puras (rotacao de espelho), cobertas por testes
├── assets/                    # Assets do jogo (audio)
├── ui/                        # Reservado para temas, fontes e elementos de interface futuros
├── tests/
│   └── run_tests.gd           # Testes automatizados (godot --headless --script res://tests/run_tests.gd)
├── docs/
│   ├── contexto.md            # Contexto e escopo do projeto
│   ├── creditos.md            # Creditos de desenvolvimento, ferramentas e audio
│   └── adr/                   # Registros de decisao de arquitetura (ADRs)
├── .github/
│   └── workflows/
│       ├── ci.yml             # Roda os testes automatizados a cada push/PR na main
│       └── cd.yml             # Publica uma build/release a cada tag vMAJOR.MINOR.PATCH
├── README_PROTOTIPO.md         # Notas originais do prototipo (referencia historica)
└── CHANGELOG.md                # Historico de mudancas do projeto
```

## Testes

Os testes automatizados cobrem as regras geometricas isoladas em
`scripts/geometria.gd`. Para rodar localmente com o Godot instalado:

```bash
godot --headless --script res://tests/run_tests.gd
```

Esses mesmos testes rodam automaticamente no CI (`.github/workflows/ci.yml`)
a cada push ou pull request para `main`.

## Releases

Criar e enviar uma tag `vMAJOR.MINOR.PATCH` dispara o pipeline de publicacao
(`.github/workflows/cd.yml`), que exporta uma build Windows Desktop e a
publica como release no GitHub.

## Decisoes de arquitetura

As decisoes de design e arquitetura relevantes estao documentadas em
[docs/adr/](docs/adr/), incluindo a escolha de representar fases como dados em
script, o passo de rotacao de 15 graus, o limite de reflexoes do feixe de luz
e o fluxo de trabalho em git (trunk-based development).

## Creditos

Veja [docs/creditos.md](docs/creditos.md).
