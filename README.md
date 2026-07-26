# Escola de Pacientes DF — site

Site estático da **Escola de Pacientes DF**, estratégia de integração ensino-serviço-comunidade
ativa desde 2016 no Distrito Federal (UnB · SES-DF), coordenada pelo Prof. Dr. Estêvão Cubas Rolim.

O site é publicado pelo GitHub Pages a partir da pasta [`docs/`](docs/).

## Estrutura

```
build/
  manifest.txt      # slug | título | categoria | grupo — taxonomia das páginas (breadcrumb/busca)
  build.pl          # gerador: converte build/content*/ em HTML dentro de docs/
                    #   · o MENU principal é a estrutura @NAV no topo do build.pl (curado, enxuto)
                    #   · gera também /temas (índice de temas) e /az (índice A–Z do acervo)
  landing.html      # template da página inicial (vitrine institucional)
  nucleo-ep.html    # template da página do Núcleo EP (sistema de gestão do grupo)
  vitrine-dados.md  # dados curados da vitrine (publicações, prêmios, reportagens, trajetória)
  assets/           # CSS, JS de busca e imagens copiados para docs/assets/
  content/          # conteúdo das páginas principais (markdown simplificado)
  content2/         # conteúdo das subpáginas (nome de arquivo usa "__" como separador de pasta)
docs/               # SITE GERADO — não editar à mão
```

As páginas-portal por público ficam em `build/content/para-pacientes.md`, `para-estudantes.md`,
`para-pesquisadores.md` e `para-profissionais.md`.

Para trocar as fotos: substitua os arquivos em `build/assets/img/` (`logo.png`, `dr-estevao.jpg`,
`unb-fm.jpg`) mantendo os nomes, e rode o gerador novamente.

## Como editar

1. Edite o conteúdo em `build/content/` ou `build/content2/` (ou os templates em `build/`).
2. Gere o site novamente:
   ```sh
   perl build/build.pl
   ```
3. Faça commit e push — o GitHub Pages publica automaticamente.

### Formato do conteúdo

- `# Título` — título da página (aparece no cabeçalho)
- `## Seção` / linha TODA EM MAIÚSCULAS — subtítulos
- `- item` — lista
- `[texto](url)` — link
- `[EMBED: rótulo](url)` — arquivo do Drive, documento Google, pasta ou vídeo do YouTube embutido

### Para adicionar uma página nova

1. Crie `build/content/minha-pagina.md`.
2. Acrescente uma linha em `build/manifest.txt` com a categoria desejada.
3. Rode `perl build/build.pl`.

## Carrossel de fotos da página inicial

O topo da home mostra um carrossel de fotos do Campus Darcy Ribeiro. As fotos
são **opcionais**: cada uma só entra se o arquivo existir em
`build/assets/img/`. Enquanto nenhuma estiver na pasta, a home exibe a foto
estática de sempre (`unb-campus.jpg`) — o site nunca fica sem imagem. Com uma
foto só, vira figura estática, sem controles.

Salve os JPGs com estes nomes e rode `perl build/build.pl`:

| Arquivo | Foto |
|---|---|
| `unb-icc-jardim.jpg`     | Jardim entre as alas do ICC, com palmeira ao centro |
| `unb-primaveras.jpg`     | Primaveras floridas sob as vigas de concreto |
| `unb-jardim-interno.jpg` | Jardim interno entre os blocos, com canteiros elevados |
| `unb-zinias.jpg`         | Canteiro de zínias diante da colunata do ICC |
| `unb-convivencia.jpg`    | Pessoas sentadas em um banco no jardim |

A lista — com o texto alternativo e a legenda de cada foto — fica em
`@HERO_SLIDES`, no `build.pl`. É lá que se muda a ordem, a legenda ou o
crédito do fotógrafo. O comportamento do carrossel está em
`build/assets/carousel.js` (troca automática a cada 6,5 s, com pausa).

> Formato sugerido: JPG de 2000 px de largura, com o assunto no centro — a
> foto é cortada para preencher a faixa, que muda de altura conforme a tela.

## Página do Núcleo EP

O **Núcleo EP** é o sistema de gestão interno do grupo de pesquisa
(`https://adm-epdf.vercel.app`, acesso restrito aos integrantes). A página de
apresentação fica em `build/nucleo-ep.html` — é HTML direto, não markdown,
porque tem uma ilustração da interface desenhada em CSS.

### Publicar capturas de tela reais

A página aceita prints do sistema, mas eles são **opcionais**: só entram no site
se o arquivo existir. Para publicar, salve os PNGs em `build/assets/img/` com
estes nomes e rode `perl build/build.pl`:

| Arquivo | Tela |
|---|---|
| `nucleo-minha-area.png` | Minha área de trabalho |
| `nucleo-dashboard.png`  | Dashboard |
| `nucleo-cronograma.png` | Cronograma |
| `nucleo-projetos.png`   | Projetos |

Uma seção "O sistema por dentro" aparece sozinha assim que houver ao menos um
arquivo. A lista fica em `@NUCLEO_SHOTS`, no `build.pl`.

> Antes de publicar um print, confira que não há nome de pessoa, e-mail ou
> título de projeto que o grupo prefira não tornar público.

## Origem do conteúdo

Conteúdo migrado do site original em Google Sites (escoladepacientes.com) em julho de 2026.
