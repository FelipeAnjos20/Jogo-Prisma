# Como abrir o PRISMA no seu computador

Tutorial passo a passo para abrir e jogar o PRISMA. Leva cerca de **5 minutos** e não exige
conhecimento de programação. Versão para imprimir: [docs/Como_Abrir.pdf](docs/Como_Abrir.pdf).

Escolha uma das duas opções:

| Opção | Para quem | O que precisa |
| --- | --- | --- |
| **[A — Só jogar](#opção-a--só-jogar-windows)** (recomendada) | Quem quer jogar | Windows 10 ou 11 |
| **[B — Abrir o projeto no Godot](#opção-b--abrir-o-projeto-no-godot)** | Quem quer ver o código, as cenas e rodar pelo motor | Windows, Linux ou macOS + Godot 4.6.3 |

---

## Opção A — Só jogar (Windows)

**1. Baixe o jogo.** Abra a página de download:

> **https://github.com/FelipeAnjos20/Jogo-Prisma/releases/latest**

Em **Assets**, clique em **`Prisma-windows-v3.0.0.zip`** (41 MB). Não é preciso ter conta no GitHub.

![Página de download no GitHub](docs/img/github_release.png)

**2. Extraia o arquivo.** Na pasta **Downloads**, clique com o **botão direito** em
`Prisma-windows-v3.0.0.zip` → **Extrair Tudo...** → **Extrair**.

> Não abra o jogo direto de dentro do zip, porque ele não funciona assim. Extraia primeiro.

**3. Abra o jogo.** Na pasta extraída, dê **dois cliques em `Prisma.exe`**. Se o Windows estiver
escondendo as extensões, o arquivo aparece como **Prisma**, do tipo "Aplicativo".

> O arquivo `Prisma.pck` precisa ficar **na mesma pasta** do `Prisma.exe`, porque ele contém o jogo.

**4. Se aparecer "O Windows protegeu o computador":** clique em **Mais informações** e depois em
**Executar assim mesmo**. O aviso aparece porque o jogo não tem uma assinatura digital paga, o que é
comum em projetos acadêmicos e independentes.

**5. Jogue!** No menu, clique em **Jogar**. Veja os [primeiros passos no jogo](#primeiros-passos-no-jogo).

---

## Opção B — Abrir o projeto no Godot

**1. Baixe o Godot 4.6.3.** Abra a página:

> **https://godotengine.org/download/archive/4.6.3-stable/**

Baixe a versão **Standard** para o seu sistema. **Não use a versão .NET.** No Windows, o arquivo se
chama `Godot_v4.6.3-stable_win64.exe.zip`. Extraia o zip. O Godot não tem instalador: o programa é o
próprio arquivo `Godot_v4.6.3-stable_win64.exe`.

**2. Baixe o projeto.** Na página do repositório,
**https://github.com/FelipeAnjos20/Jogo-Prisma**, clique no botão verde **Code** e depois em
**Download ZIP**.

![Botão Code no GitHub](docs/img/github_repo.png)

Extraia o zip, de preferência num caminho curto, como `C:\Jogo-Prisma-main`. Dentro dessa pasta deve
haver o arquivo **`project.godot`**.

> Quem usa Git pode clonar: `git clone https://github.com/FelipeAnjos20/Jogo-Prisma.git`

**3. Importe o projeto no Godot.**

1. Abra o `Godot_v4.6.3-stable_win64.exe`. Aparece o **Gerenciador de Projetos**.
2. Clique em **Importar**. No editor em inglês, o botão se chama **Import**.
3. Navegue até a pasta extraída e selecione o arquivo **`project.godot`**.
4. Clique em **Importar e Editar** (**Import & Edit**).

**4. Aguarde a primeira importação.** Leva de 5 a 20 segundos e acontece só na primeira vez.

**5. Rode o jogo.** Aperte **F5**, ou clique no botão **▶** no canto superior direito do editor.
O jogo abre no menu principal.

---

## Primeiros passos no jogo

1. No menu, clique em **Jogar**.
2. A **fase 1 tem um tutorial**: uma seta mostra qual espelho girar, e o assistente **Echo** explica o
   que fazer.
3. **Objetivo:** levar o raio de luz do emissor até **todos os cristais** da sala ao mesmo tempo.
   Quando todos acendem, a fase está concluída e a próxima é liberada.
4. **Não existe derrota.** Dá para tentar quantas vezes quiser. Quanto menos giros, mais estrelas (até 3 por fase).

![Fase 1 com tutorial](docs/img/fase1_tutorial.png)

**Controles principais**

| Para... | Faça |
| --- | --- |
| Selecionar um espelho | Clique nele (ou teclas `1`–`9`) |
| Girar o espelho (15° por vez) | Arraste a ponta dele, use `Q` / `E` ou a roda do mouse |
| Desfazer o último giro | `Z` |
| Pedir uma dica | `H` (apertando de novo, aparece o ângulo certo de um espelho) |
| Reiniciar a fase | `R` |
| Pausar / voltar ao menu | `Esc` |
| Ir para a próxima fase depois de vencer | `N` ou `Enter` |
| Tela cheia | `F11` |
| Mostrar/esconder os ângulos (incidência e reflexão) | `G` |

> **Dica:** pare o mouse sobre qualquer peça para saber o que ela faz. O assistente **Echo** também
> comenta o que você faz: avisa quando o raio passou perto, quando a cor está errada e oferece ajuda.
> Ao vencer, clique em **Por que funcionou?** para ver a explicação da sua solução.

A lista completa de controles, regras e elementos do jogo está no [README](README.md#6-como-jogar-iniciar-uma-partida-e-controles)
e no menu **Como jogar** dentro do jogo.

---

## Problemas comuns

| Problema | Solução |
| --- | --- |
| O jogo não abre e reclama de um arquivo `.pck` | Extraia o zip inteiro e mantenha `Prisma.exe` e `Prisma.pck` juntos na mesma pasta. |
| O Windows bloqueou o arquivo | Clique em **Mais informações → Executar assim mesmo**. Se não houver essa opção: botão direito em `Prisma.exe` → **Propriedades** → marque **Desbloquear** → **OK**. |
| O Godot diz que o projeto é de outra versão | Use o **Godot 4.6.3** (ou outro 4.6.x), versão **Standard**. |
| Tela preta ou erro de vídeo | Atualize o driver da placa de vídeo. O jogo precisa de OpenGL 3.3, que quase todo computador tem. |
| Sem som | Confira o volume do Windows e, no jogo, **Opções** (volume) e a tecla `M` (liga e desliga a música). |
| O jogo abriu pausado | Ele pausa sozinho quando a janela perde o foco. Clique em **Continuar** ou aperte `Esc`. |

Mais detalhes técnicos estão no [README](README.md) e no [Manual de reconstrução](docs/Manual_de_Reconstrucao.pdf).
