#!/usr/bin/env python3
"""PDF do artigo da seção Novidade das revisões por doença.

Monta o PDF que vai para a pasta "SEÇÃO NOVIDADES" do Drive e abre numa
janela no topo de cada revisão (/revisao/<doença>/). O padrão foi pedido pela
coordenação em 06/10/2026:

  - fonte EB Garamond, texto 100% preto (inclusive links e títulos);
  - formatação semelhante à ficha do PubMed: linha de citação no alto, título,
    autores com afiliações numeradas, identificadores (PMID, PMCID, DOI),
    resumo estruturado com os rótulos em negrito, palavras-chave e, depois, o
    texto completo.

Os oito PDFs publicados em 06/10/2026 foram feitos ANTES deste padrão (fonte
DejaVu, cinzas e azul) e ficam como estão. Este script vale para os próximos.

Entrada: os dois JSON que o conector PubMed devolve —
  get_full_text_article   (texto completo do PubMed Central)
  get_article_metadata    (autores, afiliações, revista, data, palavras-chave)
Só artigo de ACESSO ABERTO no PubMed Central: é o único cujo texto completo
pode ficar público numa janela do site.

Uso:
  python3 gerar_pdf.py --texto texto.json --metadados meta.json \\
      --doenca 41403717 dengue "Dengue" --saida pasta/

  (--doenca pode repetir: PMID, slug da revisão e nome que vai no arquivo)

Depende só de reportlab (pip install reportlab). As fontes estão em fontes/.
"""
import argparse
import html
import json
import os
import re

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import cm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (HRFlowable, Paragraph, SimpleDocTemplate,
                                Spacer, Table, TableStyle)

AQUI = os.path.dirname(os.path.abspath(__file__))
FONTES = os.path.join(AQUI, 'fontes')
PRETO = colors.black

# ---------------- fontes ----------------
# EB Garamond (SIL OFL) nos quatro estilos. O que ela não tem — ≥, ≤, setas,
# alguns símbolos matemáticos — cai num recorte da DejaVu Serif, também preto,
# para nenhum caractere virar quadradinho.
pdfmetrics.registerFont(TTFont('Gar', os.path.join(FONTES, 'EBGaramond-Regular.ttf')))
pdfmetrics.registerFont(TTFont('Gar-B', os.path.join(FONTES, 'EBGaramond-Bold.ttf')))
pdfmetrics.registerFont(TTFont('Gar-I', os.path.join(FONTES, 'EBGaramond-Italic.ttf')))
pdfmetrics.registerFont(TTFont('Gar-BI', os.path.join(FONTES, 'EBGaramond-BoldItalic.ttf')))
pdfmetrics.registerFont(TTFont('Simb', os.path.join(FONTES, 'DejaVuSerif-simbolos.ttf')))
pdfmetrics.registerFont(TTFont('Simb-B', os.path.join(FONTES, 'DejaVuSerif-Bold-simbolos.ttf')))
pdfmetrics.registerFontFamily('Gar', normal='Gar', bold='Gar-B', italic='Gar-I', boldItalic='Gar-BI')
TEM_GLIFO = set(pdfmetrics.getFont('Gar').face.charToGlyph.keys())


def txt(s, negrito=False):
    """Escapa para o Paragraph e troca de fonte só nos caracteres sem glifo."""
    fora = 'Simb-B' if negrito else 'Simb'
    saida = []
    for ch in s:
        e = html.escape(ch, quote=False)
        if ord(ch) > 127 and ord(ch) not in TEM_GLIFO and not ch.isspace():
            e = f'<font name="{fora}">{e}</font>'
        saida.append(e)
    return ''.join(saida)


def estilo(nome, **kw):
    base = dict(fontName='Gar', textColor=PRETO, fontSize=11, leading=15)
    base.update(kw)
    return ParagraphStyle(nome, **base)


ST = {
    'selo': estilo('selo', fontSize=8, leading=10, fontName='Gar-B'),
    'cita': estilo('cita', fontSize=9.5, leading=12.5),
    'titulo': estilo('titulo', fontName='Gar-B', fontSize=21, leading=25, spaceBefore=4, spaceAfter=8),
    'autores': estilo('autores', fontSize=10.5, leading=14, spaceAfter=6),
    'rotulo': estilo('rotulo', fontName='Gar-B', fontSize=9.5, leading=12, spaceBefore=4, spaceAfter=1),
    'afil': estilo('afil', fontSize=8.8, leading=11.2, leftIndent=10, firstLineIndent=-10, spaceAfter=1),
    'ids': estilo('ids', fontSize=9.5, leading=12.5, spaceBefore=6),
    'h1': estilo('h1', fontName='Gar-B', fontSize=14.5, leading=18, spaceBefore=14, spaceAfter=5),
    'h2': estilo('h2', fontName='Gar-B', fontSize=11.5, leading=14.5, spaceBefore=9, spaceAfter=3),
    'resumo': estilo('resumo', fontSize=11, leading=15.2, spaceAfter=6, alignment=4),
    'p': estilo('p', fontSize=11, leading=15.2, spaceAfter=7, alignment=4, firstLineIndent=0),
    'tab': estilo('tab', fontSize=9, leading=11.8, spaceAfter=7, leftIndent=8, rightIndent=8),
    'nota': estilo('nota', fontSize=8.8, leading=11.6),
    'chaves': estilo('chaves', fontSize=10, leading=13.5, spaceBefore=6),
}

# títulos de seção de primeiro nível, como o PMC os escreve
TOPO = {'introduction', 'background', 'methods', 'results', 'discussion', 'conclusions', 'conclusion',
        'references', 'acknowledgements', 'acknowledgments', 'funding', 'supplementary data',
        'supplementary material', 'declarations', 'data availability', 'data availability statement',
        'conflict of interest', 'competing interests', 'research in context', 'summary',
        'strengths and limitations', 'ethics', 'author contributions', 'limitations'}

MESES = {'jan': 'Jan', 'feb': 'Feb', 'mar': 'Mar', 'apr': 'Apr', 'may': 'May', 'jun': 'Jun', 'jul': 'Jul',
         'aug': 'Aug', 'sep': 'Sep', 'oct': 'Oct', 'nov': 'Nov', 'dec': 'Dec'}
NUM_MES = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']


def mes_pubmed(m):
    m = str(m or '').strip()
    if m.isdigit() and 1 <= int(m) <= 12:
        return NUM_MES[int(m) - 1]
    return MESES.get(m[:3].lower(), m)


def linha_de_citacao(meta):
    """Ex.: 'Eur Heart J. 2026 Feb 11;47(6):123-34.' — como no alto da ficha do PubMed."""
    j = (meta.get('journal') or {})
    abrev = j.get('iso_abbreviation') or j.get('title') or ''
    d = meta.get('publication_date') or {}
    data = ' '.join(x for x in [str(d.get('year') or ''), mes_pubmed(d.get('month')), str(d.get('day') or '').lstrip('0')] if x)
    c = meta.get('citation') or {}
    vol = ''
    if c.get('volume'):
        vol = str(c['volume']) + (f"({c['issue']})" if c.get('issue') else '')
        if c.get('pages'):
            vol += ':' + str(c['pages'])
    partes = f'{abrev.rstrip(".")}. {data}' + (f';{vol}' if vol else '') + '.'
    return partes


def autores_e_afiliacoes(meta, maximo=25):
    """Autores com o número da(s) afiliação(ões), e a lista numerada — o formato do PubMed."""
    afiliacoes, linhas = [], []
    for a in (meta.get('authors') or [])[:maximo]:
        nome = f"{a.get('fore_name', '')} {a.get('last_name', '')}".strip()
        if not nome:
            continue
        nums = []
        for af in a.get('affiliations') or []:
            af = af.strip()
            if af not in afiliacoes:
                afiliacoes.append(af)
            nums.append(str(afiliacoes.index(af) + 1))
        sup = f'<super><font size="7">{",".join(nums)}</font></super>' if nums else ''
        linhas.append(txt(nome) + sup)
    resto = len(meta.get('authors') or []) - maximo
    texto = ', '.join(linhas) + (f', et al. ({resto} outros autores)' if resto > 0 else '')
    return texto, afiliacoes


def resumo_estruturado(abstract):
    """'Objective\\n\\nTo assess...' vira '<b>Objective:</b> To assess...', como no PubMed."""
    linhas = [l.strip() for l in re.sub(r'^\s*Abstract\s*', '', abstract or '').split('\n') if l.strip()]
    saida, rotulo = [], None
    for l in linhas:
        if len(l) < 45 and not re.search(r'[.:;?!,]$', l):
            if rotulo:
                saida.append(Paragraph(f'<b>{txt(rotulo, True)}.</b>', ST['resumo']))
            rotulo = l
            continue
        if rotulo:
            saida.append(Paragraph(f'<b>{txt(rotulo, True)}:</b> {txt(descola(l))}', ST['resumo']))
            rotulo = None
        else:
            saida.append(Paragraph(txt(descola(l)), ST['resumo']))
    if rotulo:
        saida.append(Paragraph(f'<b>{txt(rotulo, True)}.</b>', ST['resumo']))
    return saida


def descola(s):
    """O PMC tira as chamadas de referência e às vezes gruda duas frases:
    'worldwide.Several' vira 'worldwide. Several'. Só minúscula ou parêntese
    antes do ponto, para não separar siglas como 'U.S.'."""
    return re.sub(r'(?<=[a-z0-9)%])\.(?=[A-Z][a-z])', '. ', s)


def corpo(texto):
    """Texto completo. O PMC devolve títulos como linhas curtas e as tabelas
    desmontadas, uma célula por linha: linhas curtas em sequência viram um
    bloco de tabela em linha, separado por '·'."""
    blocos, buf = [], []
    for l in (x.strip() for x in (texto or '').split('\n')):
        if not l:
            continue
        if len(l) < 70 and not re.search(r'[.:;?!]$', l):
            buf.append(l)
            continue
        if buf:
            blocos.append(('curtas', buf))
            buf = []
        blocos.append(('p', l))
    if buf:
        blocos.append(('curtas', buf))
    out = []
    for tipo, b in blocos:
        if tipo == 'p':
            out.append(Paragraph(txt(descola(b)), ST['p']))
        elif len(b) <= 2:
            for l in b:
                st = ST['h1'] if l.lower() in TOPO else ST['h2']
                out.append(Paragraph(txt(l, True), st))
        else:
            out.append(Paragraph(' · '.join(txt(x) for x in b), ST['tab']))
    return out


def gerar(art, meta, slug, doenca, saida):
    ids = art['identifiers']
    pmid, pmc, doi = ids.get('pmid', ''), ids.get('pmcid', ''), ids.get('doi', '')
    titulo = (meta.get('title') or art.get('title') or '').rstrip('.')
    citacao = linha_de_citacao(meta)
    autores, afiliacoes = autores_e_afiliacoes(meta)
    arquivo = os.path.join(saida, f'NOVIDADE - {doenca} - {slug}.pdf')

    doc = SimpleDocTemplate(arquivo, pagesize=A4, leftMargin=2.3 * cm, rightMargin=2.3 * cm,
                            topMargin=2 * cm, bottomMargin=2 * cm, title=titulo,
                            author=', '.join(f"{a.get('fore_name', '')} {a.get('last_name', '')}".strip()
                                             for a in (meta.get('authors') or [])[:6]),
                            subject=f'Novidade — revisão guiada de {doenca} — Escola de Pacientes')
    f = [
        Paragraph(f'ESCOLA DE PACIENTES · REVISÃO GUIADA · NOVIDADE — {txt(doenca.upper(), True)}', ST['selo']),
        Spacer(1, 4),
        HRFlowable(width='100%', thickness=0.6, color=PRETO, spaceAfter=6),
        Paragraph(txt(citacao) + (f'<br/>doi: {txt(doi)}' if doi else ''), ST['cita']),
        Paragraph(txt(titulo, True), ST['titulo']),
        Paragraph(autores, ST['autores']),
    ]
    if afiliacoes:
        f.append(Paragraph('Afiliações', ST['rotulo']))
        for i, af in enumerate(afiliacoes[:20], 1):
            f.append(Paragraph(f'{i}. {txt(af)}', ST['afil']))
        if len(afiliacoes) > 20:
            f.append(Paragraph(f'… e mais {len(afiliacoes) - 20} afiliações (ver o artigo original).', ST['afil']))
    idlinha = '    '.join(x for x in [f'<b>PMID:</b> {pmid}' if pmid else '', f'<b>PMCID:</b> {pmc}' if pmc else '',
                                         f'<b>DOI:</b> <link href="https://doi.org/{doi}"><u>{txt(doi)}</u></link>' if doi else ''] if x)
    f += [Paragraph(idlinha, ST['ids']), Spacer(1, 4),
          HRFlowable(width='100%', thickness=0.4, color=PRETO, spaceBefore=6, spaceAfter=2)]

    if art.get('abstract'):
        f.append(Paragraph('Abstract', ST['h1']))
        f += resumo_estruturado(art['abstract'])
    chaves = meta.get('keywords') or []
    if chaves:
        f.append(Paragraph('<b>Keywords:</b> ' + txt('; '.join(chaves)) + '.', ST['chaves']))

    aviso = Table([[Paragraph(
        'Texto completo da versão de acesso aberto depositada no PubMed Central'
        + (f' (<link href="https://pmc.ncbi.nlm.nih.gov/articles/{pmc}/"><u>{pmc}</u></link>)' if pmc else '')
        + ', reproduzido com a citação dos autores para uso educacional, sem fins comerciais. É uma extração '
          'automática: as figuras não estão incluídas, as tabelas aparecem em linha, separadas por “·”, e '
          'índices como o “1c” de HbA1c podem ter se perdido. Para a versão diagramada, abra o artigo pelo DOI.',
        ST['nota'])]], colWidths=[doc.width])
    aviso.setStyle(TableStyle([('BOX', (0, 0), (-1, -1), 0.5, PRETO),
                               ('LEFTPADDING', (0, 0), (-1, -1), 8), ('RIGHTPADDING', (0, 0), (-1, -1), 8),
                               ('TOPPADDING', (0, 0), (-1, -1), 6), ('BOTTOMPADDING', (0, 0), (-1, -1), 6)]))
    f += [Spacer(1, 10), aviso, Spacer(1, 4)]
    f += corpo(art.get('full_text') or '')

    def rodape(c, d):
        c.saveState()
        c.setFont('Gar', 8.5)
        c.setFillColor(PRETO)
        c.drawString(2.3 * cm, 1.2 * cm, citacao[:90])
        c.drawRightString(A4[0] - 2.3 * cm, 1.2 * cm, f'{d.page}')
        c.restoreState()

    doc.build(f, onFirstPage=rodape, onLaterPages=rodape)
    return arquivo


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--texto', required=True, help='JSON do get_full_text_article')
    ap.add_argument('--metadados', required=True, help='JSON do get_article_metadata')
    ap.add_argument('--doenca', nargs=3, action='append', required=True, metavar=('PMID', 'SLUG', 'NOME'))
    ap.add_argument('--saida', default='.')
    a = ap.parse_args()
    os.makedirs(a.saida, exist_ok=True)
    textos = {x['identifiers']['pmid']: x for x in json.load(open(a.texto, encoding='utf-8'))['articles']}
    metas = {x['identifiers']['pmid']: x for x in json.load(open(a.metadados, encoding='utf-8'))['articles']}
    for pmid, slug, nome in a.doenca:
        if pmid not in textos:
            raise SystemExit(f'PMID {pmid} não está no JSON de texto completo (não é de acesso aberto no PMC?).')
        print(gerar(textos[pmid], metas.get(pmid, {}), slug, nome, a.saida))


if __name__ == '__main__':
    main()
