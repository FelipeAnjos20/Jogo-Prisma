# Simulador de fases do PRISMA

Ferramenta de apoio ao level design (fora do Godot, ignorada pelo editor via `tools/.gdignore`).

- `levels.json`: fonte de verdade das 10 fases (posições, ângulos iniciais, cores, textos).
- `sim.js`: reproduz a mesma lógica de `scripts/light_beam.gd` (reflexão, divisor, filtro, prisma,
  bloqueios e paredes) e, para cada fase, testa todas as combinações de ângulos dos espelhos giráveis.

Ele verifica que:
1. toda fase tem solução;
2. nenhuma fase já começa resolvida;
3. calcula o `par` (menor número de rotações) e a `solution` usada pela dica de 2º nível.

## Uso (Node.js 18+)

```bash
cd tools/level_simulator
node sim.js ../../scripts/levels.gd preview.svg
```

O primeiro argumento gera `scripts/levels.gd`; o segundo (opcional) gera uma imagem SVG com cada fase resolvida.
