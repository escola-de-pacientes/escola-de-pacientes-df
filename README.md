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

Para trocar as fotos: substitua os arquivos em `build/assets/img/` (`logo.png`, `dr-estevao.jpg`)
mantendo os nomes, e rode o gerador novamente. As fotos do topo da home ficam na seção
[Carrossel de fotos da página inicial](#carrossel-de-fotos-da-página-inicial).

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

Fotos publicadas hoje, todas da Secom UnB:

| Arquivo | Foto | Crédito | Original |
|---|---|---|---|
| `unb-icc-jardim.jpg`     | Jardim entre as alas do ICC, com palmeira ao centro | Júlio Minasi | 6677 px |
| `unb-fs-fm.jpg`          | Estudantes na entrada da FS–FM, ao entardecer       | Beto Monteiro | 799 px |
| `unb-primaveras.jpg`     | Primaveras floridas ao longo do corredor do ICC     | Secom UnB | 3888 px |
| `unb-estudo.jpg`         | Estudante escrevendo em um banco do jardim          | Secom UnB | 4642 px |
| `unb-jardim-interno.jpg` | Jardineiro cuidando dos canteiros do ICC            | Secom UnB | 4634 px |

Para acrescentar, tirar ou reordenar fotos, mexa em `@HERO_SLIDES`, no
`build.pl` — é lá que ficam o texto alternativo e a legenda com o crédito de
cada uma. O comportamento do carrossel está em `build/assets/carousel.js`
(troca automática a cada 6,5 s, com pausa).

### Tamanhos das fotos

Cada foto pode ter versões `-800`, `-1400` e `-2000` ao lado do arquivo
principal (ex.: `unb-estudo-800.jpg`). Quando existem, o gerador monta um
`srcset` e o navegador baixa só a que serve para a tela: **cerca de 100 KB no
celular em vez de 560 KB**. Quando não existem, ele usa o arquivo único —
então **para acrescentar uma foto nova basta jogar um JPG na pasta**, sem
gerar tamanho nenhum. As versões atuais foram feitas com Pillow a partir dos
originais da Secom, a 80 de qualidade.

Além disso, o carrossel só baixa a foto que vai mostrar (e adianta a
seguinte), em vez de baixar as cinco ao abrir a página.

`unb-fs-fm.jpg` é a única em resolução baixa (799 px) — não achamos o
original em alta. Ela fica um pouco mais macia que as outras, mas é a única
foto que mostra as faculdades da área da saúde, por isso foi mantida.

Fora do carrossel, a pasta guarda `unb-fm.jpg` (placa da Faculdade de
Medicina) e `unb-campus.jpg`, que é a foto de reserva: se nenhuma da lista
estiver na pasta, é ela que aparece.

> Para trocar uma foto: jogue o JPG na pasta com o mesmo nome (de preferência
> com 2000 px de largura) e apague as versões `-800`/`-1400`/`-2000` antigas,
> ou gere as novas. O assunto deve estar no centro — a foto é cortada para
> preencher a faixa, que muda de altura conforme a tela.

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
