# PDF da Novidade

Gera o PDF do artigo que abre no topo de cada revisão por doença
(`/revisao/<doença>/`, bloco **Novidade**). Esta pasta **não é publicada** no
site: o gerador só lê `build/`.

## O padrão (pedido da coordenação, 06/10/2026)

- **Fonte EB Garamond** e **texto 100% preto** — títulos, links e rodapé também.
- **Formatação semelhante à ficha do PubMed**, nesta ordem:
  1. linha de citação no alto (`BMJ. 2025 Jan 22;388:e081820.` e o DOI);
  2. título em negrito;
  3. autores, com o número da afiliação sobrescrito, e a lista de afiliações;
  4. identificadores: PMID, PMCID e DOI;
  5. **Abstract** estruturado, com o rótulo em negrito na mesma linha
     (**Objective:** …, **Results:** …), e as palavras-chave;
  6. um quadro com a origem do texto (versão de acesso aberto do PubMed Central,
     uso educacional, sem fins comerciais);
  7. o texto completo, com os títulos de seção.

> Os **oito PDFs publicados em 06/10/2026** foram feitos antes deste padrão
> (fonte sem serifa, cinzas e azul) e **ficam como estão**. O padrão vale para os
> próximos.

## Como escolher o artigo

- Pesquisa **recente** (do ano corrente ou do anterior) sobre a doença.
- **Acesso aberto no PubMed Central** — no PubMed, o filtro
  `"pubmed pmc open access"[filter]`. Artigo pago não pode: o texto completo vai
  ficar público numa janela do site.
- Prefira ensaio clínico ou coorte grande, de revista reconhecida, com algo que
  mude ou questione a prática.

## Como gerar

1. Com o conector PubMed (no Claude, por exemplo), busque o texto completo e os
   metadados do artigo e salve as duas respostas em JSON:
   - `get_full_text_article` com o PMCID → `texto.json`
   - `get_article_metadata` com o PMID → `meta.json`
2. Instale o reportlab (uma vez): `pip install reportlab`
3. Rode, dando o PMID, o slug da revisão e o nome da doença:

   ```sh
   python3 ferramentas/novidade-pdf/gerar_pdf.py \
       --texto texto.json --metadados meta.json \
       --doenca 41403717 dengue "Dengue" \
       --saida pdfs/
   ```

   O arquivo sai como `NOVIDADE - Dengue - dengue.pdf`. `--doenca` pode se
   repetir para gerar vários de uma vez, se os JSON tiverem vários artigos.

4. Suba o PDF na pasta **"3. CONTEÚDOS DE DOENÇAS PARA O SITE DO EPDF / SEÇÃO
   NOVIDADES"** do Drive (ela é pública por link; o arquivo herda).
5. Em `build/revisao/<slug>.md`, troque a linha `- artigo` pela do novo artigo e
   ponha o ID do PDF no fim: `| pubmed: <PMID> | drive: <ID do arquivo>`.

## O que a extração não traz

O texto do PubMed Central chega sem figuras, com as tabelas desmontadas (uma
célula por linha) e sem índices sub/sobrescritos ("HbA1c" pode virar "HbA").
O script junta as células de tabela numa linha separada por "·", conserta frases
grudadas ("worldwide.Several" → "worldwide. Several") e avisa o leitor no quadro
de origem. Para a versão diagramada, o PDF e a página levam ao artigo pelo DOI.

## Fontes

- `EBGaramond-*.ttf` — EB Garamond, SIL Open Font License (`OFL-EBGaramond.txt`).
  Convertidas dos arquivos do pacote `@fontsource/eb-garamond` (subconjuntos
  latino, latino estendido e grego juntados num arquivo por estilo).
- `DejaVuSerif*-simbolos.ttf` — recorte da DejaVu Serif só com símbolos
  (≥, ≤, setas, operadores), usado nos caracteres que a EB Garamond não tem.
  Licença em `LICENSE-DejaVu.txt`.
