# 004 - Trunk-based development

## Status

Aceito.

## Contexto

O projeto e mantido por um numero pequeno de pessoas, com prazos de entrega
academicos, e precisa de um fluxo de trabalho em git simples de seguir e de
explicar. Fluxos com multiplas branches de longa duracao (ex.: `develop`,
branches de release) adicionam overhead de merge e coordenacao que nao se
justifica para esse contexto.

## Decisao

Adotar trunk-based development: a branch `main` e a fonte unica de verdade,
recebe commits pequenos e frequentes (diretamente ou por branches de vida
curta que sao integradas rapidamente), e e sempre mantida em um estado que
passa nos testes automatizados. Commits seguem a convencao
[Conventional Commits](https://www.conventionalcommits.org/) (`feat:`,
`fix:`, `test:`, `docs:`, `ci:`, `refactor:`, etc.) para manter o historico
legivel. Versoes publicadas sao marcadas com tags anotadas (`vMAJOR.MINOR.PATCH`)
diretamente sobre a `main`.

## Consequencias

- A integracao continua (`.github/workflows/ci.yml`) roda a cada push/PR
  contra `main`, funcionando como a rede de seguranca que permite integrar
  com frequencia sem branches intermediarias.
- Publicar uma nova versao e criar uma tag sobre a `main`; a publicacao da
  build (`.github/workflows/cd.yml`) e disparada por essa tag, sem precisar
  de uma branch de release separada.
- Exige disciplina para manter commits pequenos e a `main` sempre em estado
  funcional, ja que nao ha uma branch `develop` intermediaria absorvendo
  trabalho em andamento.
- Caso o projeto cresca em numero de colaboradores ou precise suportar
  multiplas versoes em paralelo, esta decisao deveria ser revisitada.
