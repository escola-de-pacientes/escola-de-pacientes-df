# Nome da doença
ACERVO: slug-da-pagina-de-tema-antiga
ICONE: nome_do_icone_material_symbols
COR: azul
ORDEM: 10
CURTO: Nome curto para o menu
BUSCA: sinônimos que ajudam a busca do site

Este arquivo é só o modelo e não vira página (o nome começa com "_").
Para criar uma revisão nova, copie-o para build/revisao/<slug>.md. O endereço
da página será escoladepacientes.com/revisao/<slug>/.

CABEÇALHO
- "# Nome" é o título da página.
- ACERVO: a página de tema que já existe (build/content/<slug>.md). Ela ganha
  uma faixa no alto apontando para a revisão e vira o "acervo completo" do
  tema. Deixe em branco se não houver página antiga.
- ICONE: um nome de https://fonts.google.com/icons (ex.: cardiology, glucose,
  nephrology, pulmonology, blood_pressure, ecg_heart, pest_control).
- COR: vermelho, azul, ambar, verde, roxo, rosa, teal ou indigo.
- ORDEM: posição no menu e nas listas (menor vem antes).

ITENS — uma linha por item, campos separados por " | ":
  - tipo | endereço ou ID | título | fonte | extras opcionais

Tipos:
  video   — YouTube. Endereço do vídeo, do shorts ou só o ID.
            extra "formato: vertical" para shorts.
  podcast — episódio do Spotify (open.spotify.com/episode/...) ou vídeo do YouTube.
  drive   — PDF ou imagem no Google Drive (endereço do arquivo ou só o ID).
  doc     — Documento Google (capítulos do Tratado de MFC, por exemplo).
  slides  — Apresentação Google.
  link    — site externo, ou página do próprio site começando com "/".
  artigo  — só em "Novo na pesquisa": endereço do artigo (DOI) e extras
            "pubmed: <número>" e "drive: <ID do PDF no Drive>". Com o drive,
            o artigo completo abre numa janela dentro da página.
            Só artigo de ACESSO ABERTO no PubMed Central. O PDF é gerado por
            ferramentas/novo-na-pesquisa-pdf/ (EB Garamond, preto, estilo PubMed) e
            vai para a pasta "SEÇÃO NOVO NA PESQUISA" do Drive.

Extras são "chave: valor", ex.: "duracao: 6 min".

⚠️ Arquivo do Drive precisa estar como "qualquer pessoa com o link pode ver",
senão a janela mostra um erro do Google para o público.
⚠️ Nunca coloque aqui roteiro, checklist de correção ou nome de caso do
SimulaPacientes: a página é pública e isso entregaria o gabarito.

SEÇÕES — os nomes são os mesmos que aparecem no site:
  ## Novo na pesquisa  — opcional; um artigo recente (tipo "artigo").
  ## Passo 1           — "O básico": vídeo curto e podcast.
  ## Passo 2           — "Como atender": protocolos, capítulos, vídeos longos.
  ## Passo 3           — "Aprofunde": cada "### Assunto" vira um botão.
  Os nomes antigos ("## Novidade", "## Etapa N") ainda funcionam.

Linhas que não começam com "-", "#" ou CHAVE: são notas, como estas, e são
ignoradas.

## Novo na pesquisa
- artigo | https://doi.org/10.xxxx/xxxxx | Título original do artigo | Revista · mês ano · nome do estudo | pubmed: 00000000 | drive: ID_DO_PDF

## Passo 1
- video | https://youtu.be/XXXXXXXXXXX | Título do vídeo curto | Canal
- podcast | https://open.spotify.com/episode/XXXXXXXXXXXXXXXXXXXXXX | Título do episódio | Podcast

## Passo 2
- drive | ID_DO_PDF | Protocolo Clínico e Diretrizes Terapêuticas | Ministério da Saúde · ano
- doc | ID_DO_DOCUMENTO | Capítulo do Tratado de MFC | Gusso, 2019
- video | https://youtu.be/XXXXXXXXXXX | Aula mais longa | Canal

## Passo 3
### Farmacologia
- drive | ID_DO_PDF | Capítulo de farmacologia | Livro
### Semiologia
- drive | ID_DO_PDF | Capítulo de semiologia | Livro
