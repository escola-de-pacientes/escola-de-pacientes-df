# Escola de Pacientes — site

Site estático da **Escola de Pacientes**, estratégia de integração ensino-serviço-comunidade
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
  revisao/          # uma revisão guiada por doença (/revisao/<slug>/) — ver seção própria
ferramentas/
  novidade-pdf/     # gera o PDF do artigo da Novidade (não é publicado no site)
  assets/           # CSS, JS de busca e imagens copiados para docs/assets/
  content/          # conteúdo das páginas principais (markdown simplificado)
  content2/         # conteúdo das subpáginas (nome de arquivo usa "__" como separador de pasta)
                    #   · coluna-do-estevao__*.md = textos da Coluna do Estêvão (ver seção própria)
docs/               # SITE GERADO — não editar à mão
```

As páginas-portal por público ficam em `build/content/para-pacientes.md`, `para-estudantes.md`,
`para-pesquisadores.md` e `para-profissionais.md`.

Para trocar as fotos: substitua os arquivos em `build/assets/img/` (`logo.png`, `dr-estevao.jpg`)
mantendo os nomes, e rode o gerador novamente. As fotos do topo da home ficam na seção
[Carrossel de fotos da página inicial](#carrossel-de-fotos-da-página-inicial).

## Como editar

1. Edite o conteúdo em `build/content/` ou `build/content2/` (ou os templates em `build/`).
2. Faça commit e push da pasta `build/`.
3. Pronto. O GitHub gera a pasta `docs/` sozinho e o Pages publica.

> ⚠️ **Não gere o site na sua máquina para depois enviar a pasta `docs/`.**
> Quem faz isso é o GitHub, pelo `.github/workflows/publicar-site.yml`.
>
> Esse aviso tem motivo: em 26/07/2026 um envio automático feito a partir de
> uma cópia local desatualizada devolveu `build.pl` e `style.css` a versões
> antigas, apagou a revisão visual inteira e deixou a página `/nucleo-ep/` no
> ar sem estilo nenhum. Gerando no GitHub, não existe cópia local para ficar
> velha e isso não pode se repetir.

Se quiser ver o resultado antes de enviar, pode rodar `perl build/build.pl`
localmente — só não envie a `docs/` gerada junto; deixe o GitHub cuidar dela.

### Tirar uma página do `build/` tira ela do site

Até 05/09/2026 o gerador só criava e sobrescrevia: quem removesse um `.md` de
`build/content/` removia o link, e a página continuava publicada e indexável,
sem fonte nenhuma no repositório. Hoje o gerador **varre `docs/` no fim** e
remove o que ele não escreveu naquela rodada.

Três coisas que a varredura respeita, e que estão comentadas em `build.pl`:

- **no fim, nunca no começo** — se o gerador morrer no meio, nada é removido e o
  site continua sendo o que estava no ar;
- **piso de arquivos** — rodada que escreveu pouco é rodada quebrada, e rodada
  quebrada não apaga nada;
- **`docs/CNAME` fica sempre** — é o domínio, não é gerado por `build/` nenhum, e
  removê-lo tiraria o site do ar. `Verificar o gerador` confere que ele
  sobreviveu à geração.

> Rodando o gerador na sua máquina **sem `qrencode`**, os `qr.png` que já existem
> são preservados — senão a varredura apagaria centenas de figuras boas que
> aquela rodada não teve como escrever.

### O que a publicação faz quando alguma coisa dá errado

Duas falhas silenciosas já aconteceram, e as duas correções vivem dentro dos
workflows. `Verificar o gerador` confere, em todo PR, que elas continuam lá:

| Situação | O que acontece |
|---|---|
| **A `main` anda enquanto o site está sendo gerado** (merge de PR, commit dos números) | o envio é recusado, e a publicação **refaz o site sobre a ponta nova** — até três vezes. Não reaplica a `docs/` velha: ela teria sido gerada a partir de um `build/` que já não é o do repositório |
| **A atualização dos números falha** | a publicação não roda. `completed` não quer dizer `success` |
| **O Hub não responde, ou responde fora de forma** | nada é comitado, e o site fica com os números da última atualização boa — mas a execução **avisa**. Passados três dias sem número novo, ela fica vermelha: uma execução verde não pode esconder um número velho |

⚠️ A `main` **não tem proteção de branch**. Ela não pode ter enquanto a
publicação empurrar `docs/` direto para ela — exigir PR quebraria a publicação
no mesmo dia. A ordem para resolver isso é: primeiro migrar o Pages para
publicação por artefato (que acaba com os commits de `docs/`), e só então
proteger a `main` exigindo PR e o check `Verificar o gerador`.

### Rodar o gerador localmente (opcional)

```sh
perl build/build.pl        # precisa do módulo URI::Escape
```

### Formato do conteúdo

- `# Título` — título da página (aparece no cabeçalho)
- `## Seção` / linha TODA EM MAIÚSCULAS — subtítulos
- `- item` — lista
- `[texto](url)` — link
- `[EMBED: rótulo](url)` — arquivo do Drive, documento Google, pasta ou vídeo do YouTube embutido

### Links de conteúdo nos planos de aula

Em cada bloco **“Aula — tema clínico”**, o primeiro cartão deve abrir a página do tema no site. Quando o tema tem **revisão guiada** (`/revisao/<doença>/`), é ela a página do tema: o cartão aponta para lá e se chama **“— revisão guiada”**. Temas sem revisão continuam com o cartão **“conteúdo completo”** apontando para a página do tema, que reúne slides, Tratado MFC, PACK, checklists e orientações.

> **Link para tema com revisão vai para a revisão.** Desde 06/10/2026 o gerador
> troca sozinho, no conteúdo em markdown, todo link para uma página de tema que
> tem revisão (`/hipertensao`, `/diabetes`, `/dislipidemia`, `/dengue`,
> `/cardio-infarto-do-miocardio`, `/cardio-insuficiencia-cardiaca`) pelo link da
> revisão; o índice de Temas Clínicos também. A página antiga virou o **acervo
> completo** — é assim que aparece na busca e no A–Z — e se chega nela pelo botão
> "Acervo completo do tema" da revisão. Para linkar o acervo de propósito (um
> slide, um PDF que só existe lá), termine o link com `#acervo`:
> `[slides](/hipertensao#acervo)`. Nas páginas escritas em HTML a troca não é
> automática: os cartões dos planos de aula foram trocados à mão, e os botões
> “Slides — …” e o link do PDF do PACK continuam no acervo, que é onde eles estão.

Atalhos diretos para apresentações vêm depois e devem deixar claro que são o recorte mínimo — por exemplo: **“sem tempo? veja pelo menos os slides”**. Arquivos avulsos de orientação pertencem à página do tema clínico, não ao plano de aula; assim, o plano organiza o encontro e o acervo clínico continua centralizado em um só lugar.

### QR code no fim de cada página

Toda página termina com o QR que aponta para ela mesma — mostrar a tela do
celular para a pessoa do lado é mais rápido do que ditar o endereço. **Não há
nada a fazer para isso acontecer:** o gerador cria o `qr.png` ao lado do
`index.html` de cada página, e o workflow instala o `qrencode` antes de rodar.

Rodando o gerador na sua máquina sem o `qrencode` instalado, as páginas saem
sem a figura — o site não quebra, e a publicação pelo GitHub continua com os
QR no lugar. Para ver igual ao que vai ao ar: `sudo apt-get install qrencode`.

As duas exceções são a página inicial, que é vitrine e tem o endereço no
próprio nome, e a página de erro 404 — ninguém divulga um endereço que não
existe.

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

## Revisão por doença

Uma página por doença em `/revisao/<doença>/`, com índice em `/revisao/`. É o
destino do link que o SimulaPacientes vai mostrar ao fim de uma simulação com
resultado insatisfatório: o estudante cai no conteúdo da doença do paciente que
acabou de atender.

A página segue sempre a mesma linha de raciocínio:

| Bloco | O que tem |
|---|---|
| **Novidade** (no topo) | um artigo recente de pesquisa sobre a doença |
| **Etapa 1 — pouco tempo** | vídeo curto e podcast |
| **Etapa 2 — abordagem e terapêutica** | protocolos nacionais e capítulos em janelas do Drive, e vídeos mais longos |
| **Etapa 3 — aprofundamento** | abas por área: farmacologia, semiologia, fisiopatologia, diretrizes, saúde pública… |

**Não há texto próprio sobre a doença** — decisão da coordenação (06/10/2026).
A página aponta para o material (protocolo, capítulo, aula, vídeo) e não o
resume. O texto que aparece é só a moldura, igual em todas as doenças.

**Para criar ou editar uma revisão, mexa só em `build/revisao/<slug>.md`.** O
formato está explicado em [`build/revisao/_modelo.md`](build/revisao/_modelo.md):
uma linha por item, `- tipo | endereço | título | fonte`. O menu, a busca, o
índice A–Z, o bloco da página inicial e a faixa no alto da página de tema antiga
(`ACERVO:`) se ajustam sozinhos. O gerador lê o arquivo com rigor: item que ele
não entende para a geração com o número da linha.

> ⚠️ **Janela do Drive só abre se o arquivo estiver como "qualquer pessoa com o
> link pode ver".** A pasta "3. CONTEÚDOS DE DOENÇAS PARA O SITE DO EPDF" já está
> assim, e o que entra nela herda. Arquivo de outra pasta precisa ser conferido —
> é o erro que aparece hoje em `/neuro-ave-derrame/`, onde a pasta embutida
> não existe mais e a janela mostra um 404 do Google.

> ⚠️ **Nunca coloque numa revisão roteiro, checklist de correção ou nome de caso
> do SimulaPacientes.** A página é pública, e o par caso → doença entregaria o
> gabarito.

### O tutorial: "Como funciona esta página"

Pedido da coordenação (06/10/2026): quem chega precisa entender a página sem
ninguém explicar — que a Novidade é um artigo atual, que a Etapa 1 é para quem
tem pouco tempo, e assim por diante. Toda revisão, e o índice `/revisao/`, têm:

- o botão **"Como funciona esta página"** no topo e o botão flutuante
  **"Tutorial"** no canto da tela, que abrem um passo a passo: a página rola até
  cada parte, só ela fica acesa, e um cartão explica para que ela serve (9
  passos na revisão, 5 no índice). Setas do teclado avançam e voltam; Esc fecha;
- um **convite** na primeira visita ("Primeira vez aqui?"), perto do botão
  flutuante. Ele **não abre o tutorial sozinho** — quem veio só buscar um PDF não
  pode ser interrompido — e não volta depois de dispensado ou visto (fica
  guardado no navegador, valendo para todas as revisões).

Os textos de cada passo ficam no `build.pl` (`rv_tour_passos_doenca` e
`rv_tour_passos_indice`), não no JavaScript: são moldura, como o nome das
etapas. Cada passo aponta para um seletor da página; passo cujo alvo não existe
(uma revisão sem Novidade, por exemplo) é pulado sozinho. Sem JavaScript, os
botões do tutorial nem aparecem.

### A Novidade: o artigo e o PDF

- **Só artigo de acesso aberto no PubMed Central.** O texto completo fica
  público numa janela do site, e artigo pago (NEJM, Lancet, Nature Medicine
  fechados) não pode. Os primeiros escolhidos eram pagos e foram trocados em
  06/10/2026 por estudos de 2025–2026 de acesso aberto.
- **O PDF fica no Drive**, na pasta "3. CONTEÚDOS DE DOENÇAS PARA O SITE DO EPDF /
  SEÇÃO NOVIDADES" (pública por link). Na revisão, ele entra pelo campo
  `drive:` da linha `- artigo`, e a janela "Texto completo do artigo" aparece
  aberta logo abaixo do título.
- **PDFs novos seguem o padrão de [`ferramentas/novidade-pdf/`](ferramentas/novidade-pdf/README.md)**:
  EB Garamond, texto 100% preto e formatação semelhante à ficha do PubMed. Os
  oito publicados em 06/10/2026 foram feitos antes desse padrão (fonte sem
  serifa, cinzas e azul) e, por decisão da coordenação, **ficam como estão**.

### Ligar o SimulaPacientes às revisões

O site já está pronto; o que falta é do lado do Hub, que é privado. O gerador
publica `https://escoladepacientes.com/revisao/revisoes.json` com o endereço de
cada revisão:

```json
{ "slug": "dengue",
  "url": "https://escoladepacientes.com/revisao/dengue/",
  "urlDaSimulacao": "https://escoladepacientes.com/revisao/dengue/?origem=simulapacientes" }
```

- O Hub guarda, **só lá**, qual caso leva a qual `slug`.
- No fim de uma simulação com resultado insatisfatório, ele mostra um link para
  `urlDaSimulacao`. Com `?origem=simulapacientes`, a página abre com a faixa
  "Você veio do SimulaPacientes" e um botão de volta.
- Opcional: `&volta=<endereço>` troca o destino desse botão. Só endereços
  `https://simulapacientes.escoladepacientes.com/...` ou
  `https://hub-de-ll-ms.vercel.app/...` são aceitos; qualquer outro é ignorado,
  para a página não virar um redirecionador aberto com a cara da Escola.
- Os slugs de hoje: `hipertensao`, `diabetes`, `dislipidemia`, `dengue`,
  `doenca-renal-cronica`, `doenca-arterial-coronariana`,
  `insuficiencia-cardiaca`, `dpoc`. **Renomear um arquivo muda o endereço** e
  quebra o link do Hub.

### Por que o cabeçalho mudou junto

O menu ganhou um sexto item, "Revisão por doença", e o cabeçalho não tinha
folga nenhuma — o menu ocupava os 1200px do contêiner até o último pixel. Para
caber sem empurrar a busca para fora da tela: acima de 1380px o cabeçalho usa até
1360px; até 1420px o nome ao lado da logo sai (a logo traz o nome escrito); e
até 1599px o item aparece como "Revisões". Conferido de 375 a 1940px, sem
rolagem horizontal. As regras estão no fim do `style.css`.

### Histórico das revisões

| Data | O que mudou |
|---|---|
| 06/10/2026 | Oito revisões publicadas (Hipertensão, Diabetes tipo 2, Dislipidemia, Dengue, DRC, DAC, IC, DPOC), índice `/revisao/`, item no menu, bloco na página inicial, link em Estudantes, faixa nas páginas de tema antigas e `revisoes.json` para o Hub — PR #29 |
| 06/10/2026 | Novidade trocada por artigos de acesso aberto; PDFs na pasta SEÇÃO NOVIDADES do Drive, ligados pelo campo `drive:` — PR #29 |
| 06/10/2026 | Tutorial guiado em todas as revisões e no índice; padrão novo dos PDFs da Novidade (EB Garamond, preto, estilo PubMed) em `ferramentas/novidade-pdf/` — PR #30 |
| 06/10/2026 | Links para os temas com revisão (SFC 2, planos de aula, índice de Temas Clínicos, páginas de tema) passam a abrir a revisão; a página antiga aparece como "acervo completo" na busca e no A–Z |

## Coluna do Estêvão

Área autoral do coordenador — textos pessoais, reflexões, memórias e
posicionamentos. Fica em `/coluna-do-estevao/`, no menu **A Escola**, ao lado
da página pessoal do autor. Não é a área de notícias: comunicado
institucional e notícia técnica continuam em `noticias` e `reportagens`.

**Para publicar um texto novo, crie um arquivo — só isso:**

```
build/content2/coluna-do-estevao__slug-do-texto.md
```

```md
# Título do texto
DATA: 2026-08-22
CHAMADA: uma frase curta, que aparece na listagem e na página inicial

Primeiro parágrafo do texto…
```

As linhas `DATA:` e `CHAMADA:` são retiradas do corpo antes de ele virar
HTML — são apresentação, não texto do autor. A partir daí tudo se ajusta
sozinho:

- a listagem da coluna se reordena, **do mais recente para o mais antigo**;
- o texto do topo passa a aparecer na página inicial, junto do bloco
  "Quem coordena" (enquanto não houver texto nenhum, esse bloco não aparece);
- o texto entra na busca do site (sob o nome da coluna) e no índice A–Z;
- cada texto ganha página própria, com data, chamada, assinatura e links
  para o texto vizinho.

Nenhum arquivo do gerador precisa ser editado para publicar. A apresentação
da coluna está em `build/content/coluna-do-estevao.md`, e o código que monta
a listagem, o cabeçalho e o pé de cada texto está na seção
"Coluna do Estêvão" do `build.pl`.

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

## Simulações em números

A página `/simulacoes-em-numeros/` é o espelho público dos dados das simulações.
Ela **não calcula nada**: lê `build/assets/dados-simulacoes.json`, que uma Action
busca do Hub todo dia, e desenha o que já veio protegido (piso de dez simulações,
supressão complementar). Quem decide o que pode ser publicado é o Hub.

O bloco "De onde vêm as simulações" é uma **rosca com a tabela ao lado**, na mesma
figura. A tabela fica visível, não escondida num `details`: quem lê cor vê a
proporção de relance, quem precisa do número exato o tem na mesma linha.

- **O SimulaPacientes é sempre a primeira linha e a primeira fatia.** É ordenação
  de apresentação, feita em `composicao_ordenada`: o Hub manda as origens na ordem
  em que a Escola as usou, e nessa ordem a única origem viva cai na última linha.
  Nenhum número muda de lugar junto.
- **O bloco não é um cartão.** O `.grafico` de vidro é da vitrine da home; aqui a
  página é um documento, e a figura usa o mesmo `h3` em caixa alta com traço e a
  mesma tabela sem moldura dos blocos vizinhos. O anel fica à direita e a tabela à
  esquerda, encostada na margem do texto, para a coluna "Origem" nascer no mesmo
  ponto que "Competência" e "Condição". No celular o anel volta para cima.
- **As cores estão em `--pz-1` a `--pz-6`, no `style.css`**, e são os pastéis
  Google que o site já usa: azul, verde, roxo, amarelo, vermelho. `--pz-1` é
  `--g-azul` sem mudar um dígito e `--pz-5` é `--g-vermelho`; verde e amarelo
  estão um degrau adiante do token, porque o original era claro ou escuro demais
  para virar marca de gráfico. No tema escuro o azul é o mesmo `#4a90e2` das
  barras do gráfico de prêmios.
- As cores acompanham a *posição* da fatia no anel, não o rótulo, e **a ordem foi
  conferida**: cada par de fatias vizinhas continua distinguível por quem enxerga
  cor de outro jeito (pior par: ΔE 18,6 no claro, 8,8 no escuro). Azul e roxo não
  podem se encostar; verde e vermelho também não. **Reordenar sem refazer a
  conferência desfaz a propriedade.** `--pz-1` é sempre o SimulaPacientes.
- Acima de cinco origens, a cauda vira uma fatia cinza ("Outras origens"), mas
  continua nomeada linha a linha na tabela, recuada sob ela.

### O treinamento, o acervo e a bibliografia

Três blocos entraram em 04/09/2026, a pedido da coordenação, e vêm do mesmo JSON:

- `[SIMULACOES-TREINAMENTO]` — **quantidade, e nenhuma nota.** Quantas rodadas
  por capítulo da CIAP-2 e por paciente digital. O pedido foi *"sem dar
  desempenho nem nada"*, e a garantia não é de redação: o Hub manda essas
  células no tipo `Contagem`, que **não tem campo de percentual**. Não há o que
  esconder aqui porque não há o que veio.
- `[SIMULACOES-ACERVO]` — os casos publicados (título, capítulo, tamanho da
  rubrica, duração) e a **bibliografia** que sustenta os itens, ordenada pela
  fila de revisão: quanto mais itens dependem de um documento, mais a edição
  nova dele pede releitura.

> ⚠️ **O título esconde o diagnóstico, e esta página é pública e indexada.**
> "Febre e dor no corpo há dois dias" não diz *dengue* porque descobrir é a
> tarefa do estudante. Por isso o acervo sai **sem diagnóstico e sem condição
> clínica**, e a bibliografia diz em **quantas** simulações cada documento é
> usado, **nunca em quais** — o par documento↔simulação responderia o gabarito
> de um caso em uma linha. Quem carrega essa regra é `acervo-publico.ts`, no
> Hub, e `verificar:publicos` varre o acervo real para provar que nada vazou.

> **A lista publicada é de doutrina.** Protocolos, diretrizes, manuais, notas
> técnicas e normas. Os documentos internos da Escola (o padrão metodológico e
> os rascunhos de 2019 do acervo) ficam de fora da lista por dois motivos que
> apontam para o mesmo lugar: moram num Drive restrito, onde o leitor não pode
> conferir nada, e foram batizados por quem já sabia o gabarito — um deles traz
> o diagnóstico no próprio nome. **Quantos** itens dependem deles continua
> publicado; o número era a informação, o nome do rascunho não.

Enquanto a Action não buscar um espelho com esses blocos, os dois marcadores
dizem que os números entram na próxima atualização — não mostram tabela vazia,
que se leria como "ninguém treinou".

### O gráfico de evolução, e por que ele ainda não aparece

Existe um gráfico de colunas, "Evolução do SimulaPacientes", que **só aparece
quando há pelo menos dois períodos publicados**. Hoje o Hub publica um mês só
(`2026-08`), então a tabela "Mês a mês" continua no lugar dele. Assim que o
segundo mês entrar no JSON, o gráfico aparece sozinho — não há nada a fazer aqui.

Sobre **agrupar por semana**: o gerador já sabe desenhar isso. Se o JSON trouxer
um bloco `porSemana` (rótulos no formato `2026-W35`), é ele que vira gráfico, e o
`porMes` continua como tabela. Mas a decisão **não é desta página**, por dois
motivos:

1. O site não fatia mês em semana, e não deve: o recorte tem que sair do Hub já
   protegido, com o mesmo piso de dez e a mesma supressão complementar. Repetir
   essa regra em Perl criaria uma segunda implementação da mesma proteção.
2. A própria página promete, em "O que estes números são, e o que não são", que
   **o tempo aparece só em mês** — porque dia e hora, numa turma que simula na
   noite de terça, diriam quem estava na sala. Semana anda nessa direção. Publicar
   semana exige rever essa promessa e o texto da metodologia, no Hub e aqui.

Ou seja: a semana está pronta para ser desenhada, e falta decidir se ela deve ser
publicada. Enquanto não for, nada muda no site.

## Origem do conteúdo

Conteúdo migrado do site original em Google Sites (escoladepacientes.com) em julho de 2026.
