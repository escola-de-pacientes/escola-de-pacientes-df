#!/usr/bin/perl
# Gerador do site estático da Escola de Pacientes.
# Lê build/content/*.md (páginas) e build/content2/*.md (subpáginas, nome com "__"),
# aplica o manifesto de categorias e escreve o site pronto em docs/.
use strict; use warnings; use utf8;
use open ':std', ':encoding(UTF-8)';
use File::Path qw(make_path);
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use URI::Escape qw(uri_unescape);
use Digest::MD5 qw(md5_hex);
use Encode qw(encode_utf8 decode_utf8);
use JSON::PP;                # núcleo do Perl desde a 5.14 -- nada a instalar

my $ROOT   = dirname(__FILE__);
my $OUT    = "$ROOT/../docs";
my $SITE   = 'Escola de Pacientes';
my $SITE_URL = 'https://escoladepacientes.com';

# ---------------- manifesto ----------------
my (%page, @order);          # slug -> {title, cat, group}
open my $mf, '<:encoding(UTF-8)', "$ROOT/manifest.txt" or die $!;
while (<$mf>) {
    chomp; next if /^\s*#/ or /^\s*$/;
    my ($slug, $title, $cat, $group) = split /\|/;
    $page{$slug} = { title => $title, cat => $cat, group => $group // '' };
    push @order, $slug;
}
close $mf;

my %cat_label = (
    sobre         => 'A Escola',
    ensino        => 'Ensino UnB',
    pratica       => 'Simulações e Testes',
    temas         => 'Temas Clínicos',
    pacientes     => 'Educação em Saúde',
    profissionais => 'Profissionais e Gestão',
    ciencia       => 'Ciência',
    noticias      => 'Notícias e Mídia',
    projetos      => 'Projetos e Produtos',
    publicos      => 'Comece por aqui',
);
my @group_order = ('Doenças crônicas', 'Saúde da mulher e pré-natal', 'Saúde mental e bem-estar',
                   'Infecções e urgências', 'Outros temas');

# ---------------- páginas escritas em HTML ----------------
# Algumas páginas não passam pelo conversor de markdown: elas têm retrato,
# linha do tempo, grade de nomes ou ilustração de interface desenhada em CSS,
# e nada disso sai de "# título" e "- item". O corpo de cada uma vive num
# arquivo .html aqui em build/, e o gerador o encaixa no mesmo shell das
# outras (cabeçalho, rodapé, meta tags).
#
# Este registro é a fonte única: dele saem a geração, a liberação do link
# interno em clean_url, a entrada na busca e a linha no índice A–Z. Antes cada
# página dessas era um bloco copiado, e as três primeiras ficaram fora do A–Z
# sem ninguém notar — é o tipo de esquecimento que uma lista só não deixa
# acontecer de novo.
#
# REGRAS AO EDITAR OS ARQUIVOS .html DESTA LISTA. Elas ficam aqui, e não lá
# dentro, porque comentário de HTML é publicado junto com a página.
#
# 1. simula-pacientes.html é PÚBLICA e os pacientes digitais são material de
#    prova. Nenhum exemplo pode citar um caso pelo nome, pela queixa ou pelo
#    diagnóstico: quem lesse a página antes de atender chegaria à consulta com
#    a resposta na mão. O paciente e o código de turma da ilustração são
#    inventados de propósito, e devem continuar sendo.
# 2. Ela é escrita para quem NÃO é da casa: frase curta, palavra do dia a dia
#    e todo termo técnico explicado na primeira vez em que aparece.
# 3. Não se escreve nada sobre quem custeia as inteligências artificiais.
#    Decisão da coordenação, tomada em 16/08/2026.
my @PAGINAS_HTML = (
    { slug => 'versos-e-conselhos', arquivo => 'versos-e-conselhos.html', tema => '',
      titulo => 'Versos e Conselhos', busca => 'Versos e Conselhos — da graduação para a graduação',
      secao => 'Ensino UnB', desc => 'Conselhos de estudantes para estudantes de Medicina. Palavras, músicas e aprendizados das turmas anteriores para acompanhar toda a graduação.' },
    { slug => 'nucleo-ep', arquivo => 'nucleo-ep.html', tema => 'theme-nucleo',
      titulo => 'Núcleo EP — o sistema do grupo de pesquisa',
      busca  => 'Núcleo EP — sistema do grupo de pesquisa', secao => 'A Escola',
      desc   => 'O Núcleo EP é o sistema onde a Escola de Pacientes organiza projetos, prazos, responsáveis e as oportunidades acadêmicas do grupo de pesquisa. Acesso restrito aos integrantes.' },

    { slug => 'simula-pacientes', arquivo => 'simula-pacientes.html', tema => 'theme-simula',
      titulo => 'SimulaPacientes — pacientes digitais com IA',
      busca  => 'SimulaPacientes — pacientes digitais com IA', secao => 'Simulações e Testes',
      desc   => 'O SimulaPacientes é a plataforma de pacientes digitais da Escola de Pacientes: você escolhe o caso e a inteligência artificial, conduz a consulta simulada por escrito e recebe um retorno, item por item, sobre a própria conduta clínica.' },

    { slug => 'dr-estevao-rolim', arquivo => 'dr-estevao-rolim.html', tema => '',
      titulo => 'Dr. Estêvão Cubas Rolim',
      busca  => 'Dr. Estêvão Cubas Rolim — trajetória e produção', secao => 'A Escola',
      desc   => 'Prof. Dr. Estêvão Cubas Rolim: professor de Medicina da UnB, médico da Estratégia Saúde da Família na SES-DF, doutor em Saúde Coletiva e coordenador da Escola de Pacientes desde 2016.' },

    { slug => 'radar-de-congressos', arquivo => 'radar-de-congressos.html', tema => 'theme-radar',
      titulo => 'Radar de Congressos',
      busca  => 'Radar de Congressos — a que congresso dá para submeter', secao => 'Projetos e Produtos',
      desc   => 'O Radar de Congressos varre as chamadas abertas, cruza cada congresso com as janelas do Edital FAPDF Participa e a rubrica de pontos, e devolve um veredito: dá para submeter, não dá, ou dá no limite.' },

    { slug => 'plano-de-aula-dcnt-geral-e-obesidade', arquivo => 'plano-de-aula-dcnt-geral-e-obesidade.html', tema => '',
      titulo => 'Plano de aula — DCNT geral e obesidade',
      busca  => 'Plano de aula — DCNT geral e obesidade', secao => 'Ensino UnB',
      desc   => 'Plano da aula de doenças crônicas e obesidade: os momentos do encontro, as duas rodadas de simulação e o treino de prescrição em folha em branco.' },

    { slug => 'plano-de-aula-hipertensao', arquivo => 'plano-de-aula-hipertensao.html', tema => '',
      titulo => 'Plano de aula — Hipertensão',
      busca  => 'Plano de aula — Hipertensão', secao => 'Ensino UnB',
      desc   => 'Plano da aula de hipertensão arterial: os momentos do encontro, as duas rodadas de simulação e o treino de estratificação de risco e prescrição em folha em branco.' },

    { slug => 'plano-de-aula-diabetes-aula-1', arquivo => 'plano-de-aula-diabetes-aula-1.html', tema => '',
      titulo => 'Plano de aula — Diabetes: DM aula 1',
      busca  => 'Plano de aula — Diabetes: DM aula 1', secao => 'Ensino UnB',
      desc   => 'Plano da primeira aula de diabetes: a revisão de hipertensão que abre o encontro, e a aula do conceito ao diagnóstico, tipos e complicações.' },

    { slug => 'plano-de-aula-diabetes-aula-2', arquivo => 'plano-de-aula-diabetes-aula-2.html', tema => '',
      titulo => 'Plano de aula — Diabetes: DM aula 2',
      busca  => 'Plano de aula — Diabetes: DM aula 2', secao => 'Ensino UnB',
      desc   => 'Plano da segunda aula de diabetes: tratamento, medicamentos orais, insulina e a receita montada passo a passo.' },

    { slug => 'plano-de-aula-insuficiencia-cardiaca', arquivo => 'plano-de-aula-insuficiencia-cardiaca.html', tema => '',
      titulo => 'Plano de aula — Insuficiência Cardíaca',
      busca  => 'Plano de aula — Insuficiência Cardíaca', secao => 'Ensino UnB',
      desc   => 'Plano da aula que fecha a sequência das doenças crônicas: conceito, classificação, diagnóstico, tratamento e atualizações.' },

    { slug => 'equipe', arquivo => 'equipe.html', tema => '',
      titulo => 'Equipe e Grupo de Pesquisa',
      busca  => 'Equipe e Grupo de Pesquisa', secao => 'A Escola',
      desc   => 'O grupo de pesquisa da Escola de Pacientes, com coordenação estudantil: quem coordena hoje, quem participa e todos os estudantes que já passaram pelo grupo desde 2016.' },
);
my %PAGINA_HTML = map { $_->{slug} => $_ } @PAGINAS_HTML;

# menu principal curado — vitrine, não inventário
my @NAV = (
    { label => 'A Escola', items => [
        ['boas-vindas', 'Boas-vindas'],
        ['dr-estevao-rolim', 'Dr. Estêvão Rolim'],
        ['coluna-do-estevao', 'Coluna do Estêvão'],
        ['equipe', 'Equipe e Grupo de Pesquisa'],
        ['feedback-ex-integrantes', 'Feedback de ex-integrantes'],
        ['nucleo-ep', 'Núcleo EP — sistema do grupo'],
        ['premios', 'Prêmios e Reconhecimentos'],
        ['reportagens', 'Na Mídia'],
        ['historia-da-medicina', 'História da Medicina'],
        ['planejamento-estrategico', 'Planejamento Estratégico'],
        ['diagnostico-situacional', 'Diagnóstico Situacional'],
        ['painel-de-bordo', 'Painel de Bordo'],
        ['agenda-2030-ods-3-saude', 'Agenda 2030 — ODS 3'],
    ]},
    { label => 'Projetos e Produtos', items => [
        ['receita-simples', 'Receita Simples'],
        ['simula-pacientes', 'SimulaPacientes — pacientes digitais'],
        ['radar-de-congressos', 'Radar de Congressos'],
        ['prescreva-um-livro', 'Prescreva um Livro'],
        ['escola-saudavel', 'Escola Saudável'],
        ['youtube', 'Canal no YouTube'],
        ['instagram', 'Instagram — Luz, Câmera, Saúde'],
        ['impressos-de-educacao-em-saude', 'Materiais Educativos'],
    ]},
    { label => 'Comece por aqui', items => [
        ['para-pacientes', '<span class="msym">diversity_3</span> Pacientes e Comunidade'],
        ['para-estudantes', '<span class="msym">school</span> Estudantes'],
        ['para-pesquisadores', '<span class="msym">science</span> Pesquisadores'],
        ['para-profissionais', '<span class="msym">stethoscope</span> Profissionais e Gestores'],
    ]},
    { label => 'Ciência', items => [
        ['publicacoes', 'Publicações'],
        ['congressos', 'Congressos'],
        ['icase-2026', 'ICASE 2026'],
        ['ciencia-banco-de-citacoes', 'Banco de Citações'],
        ['cbpr-pesquisa-participativa-baseada-na-comunidade', 'Pesquisa Participativa (CBPR)'],
        ['rayyan-revisao-de-literatura', 'Rayyan — Revisão de Literatura'],
        ['ciencia-onde-buscar-referencias', 'Onde Buscar Referências'],
        ['ciencia-qualis-saude-coletiva', 'Qualis Saúde Coletiva'],
    ]},
    { label => 'Acervo', items => [
        ['temas', 'Temas Clínicos'],
        ['az', 'Índice A–Z (todas as páginas)'],
        ['testes', 'Testes'],
        ['noticias', 'Notícias'],
    ]},
);

# ---------------- conteúdo ----------------
my %content;                 # path (ex.: "hipertensao" ou "testes/teste-x") -> md
for my $f (glob "$ROOT/content/*.md") {
    my ($slug) = $f =~ m{([^/\\]+)\.md$};
    next if $slug eq 'home';
    open my $fh, '<:encoding(UTF-8)', $f or die $!;
    local $/; $content{$slug} = <$fh>;
}
for my $f (glob "$ROOT/content2/*.md") {
    my ($name) = $f =~ m{([^/\\]+)\.md$};
    (my $path = $name) =~ s/__/\//g;
    open my $fh, '<:encoding(UTF-8)', $f or die $!;
    local $/; $content{$path} = <$fh>;
}

# ---------------- Coluna do Estêvão ----------------
# Área autoral do coordenador: textos pessoais, reflexões, memórias e
# posicionamentos. Cada texto é uma subpágina de coluna-do-estevao/ e o
# próprio arquivo carrega a apresentação, em duas linhas logo abaixo do
# título:
#
#     # Título do texto
#     DATA: 2026-08-22
#     CHAMADA: uma frase curta, que aparece na listagem
#
# As duas linhas saem do corpo antes de ele virar HTML — são apresentação,
# não texto do autor. PARA PUBLICAR UM TEXTO NOVO BASTA CRIAR O ARQUIVO em
# build/content2/coluna-do-estevao__<slug>.md: a listagem se reordena
# sozinha, do mais recente para o mais antigo, e o texto do topo passa a
# aparecer na página inicial. Nada aqui precisa ser editado de novo.
my $COLUNA = 'coluna-do-estevao';
my %coluna_meta;                     # path -> {data => 'AAAA-MM-DD', chamada => '...'}
for my $path (grep { m{^\Q$COLUNA\E/} } keys %content) {
    my $md = $content{$path};
    my %m;
    $md =~ s{^[ \t]*(DATA|CHAMADA)[ \t]*:[ \t]*(\S.*?)[ \t]*$}{ $m{lc $1} = $2; '' }gme;
    $content{$path} = $md;
    $coluna_meta{$path} = { data => $m{data} // '', chamada => $m{chamada} // '' };
}

my @MESES = qw(janeiro fevereiro março abril maio junho julho agosto setembro outubro novembro dezembro);

sub data_extenso {
    my ($iso) = @_;
    return '' unless defined $iso && $iso =~ /^(\d{4})-(\d{2})-(\d{2})$/;
    my ($ano, $mes, $dia) = ($1, $2 + 0, $3 + 0);
    return '' if $mes < 1 || $mes > 12;
    return "$dia de $MESES[$mes - 1] de $ano";
}

# textos da coluna, do mais recente para o mais antigo (sem data vai para o fim)
sub coluna_posts {
    return sort {
        ($coluna_meta{$b}{data} || '') cmp ($coluna_meta{$a}{data} || '')
            || lc(title_of($a)) cmp lc(title_of($b))
    } keys %coluna_meta;
}

# listagem cronológica na página principal da coluna
sub coluna_lista_html {
    my ($p) = @_;
    my @posts = coluna_posts();
    unless (@posts) {
        return qq{<h2 id="textos">Textos</h2>\n}
             . qq{<p class="nota">A coluna acabou de ser aberta e o primeiro texto entra aqui assim que for publicado. Daí em diante, o mais recente fica sempre no topo.</p>};
    }
    my $n = scalar @posts;
    my $itens = '';
    for my $path (@posts) {
        my $m     = $coluna_meta{$path};
        my $t     = esc(title_of($path));
        my $data  = data_extenso($m->{data});
        my $tempo = $data ? qq{<time class="cl-data" datetime="$m->{data}">$data</time>} : '';
        my $cham  = $m->{chamada} ? qq{<p class="cl-chamada">@{[esc($m->{chamada})]}</p>} : '';
        $itens .= qq{<li><a class="cl-card" href="$p$path/">$tempo<h3>$t</h3>$cham}
                . qq{<span class="cl-go">Ler o texto <span aria-hidden="true">&#8594;</span></span></a></li>\n};
    }
    my $rot = $n == 1 ? '1 texto publicado' : "$n textos publicados";
    return qq{<h2 id="textos">Textos</h2>\n}
         . qq{<p class="cl-contagem">$rot — do mais recente para o mais antigo.</p>\n}
         . qq{<ol class="coluna-lista">\n$itens</ol>};
}

# assinatura e navegação no pé de cada texto
sub coluna_rodape_html {
    my ($p, $path) = @_;
    my @posts = coluna_posts();
    my ($i) = grep { $posts[$_] eq $path } 0 .. $#posts;
    my @viz;
    if (defined $i) {
        my $novo  = $i > 0        ? $posts[$i - 1] : undef;   # a lista vai do mais recente ao mais antigo
        my $velho = $i < $#posts  ? $posts[$i + 1] : undef;
        push @viz, qq{<a class="cl-viz" href="$p$novo/"><small>Texto mais recente</small><b>@{[esc(title_of($novo))]}</b></a>} if $novo;
        push @viz, qq{<a class="cl-viz" href="$p$velho/"><small>Texto anterior</small><b>@{[esc(title_of($velho))]}</b></a>} if $velho;
    }
    my $nav = @viz ? qq{<nav class="cl-vizinhos" aria-label="Outros textos da coluna">\n} . join("\n", @viz) . qq{\n</nav>\n} : '';
    return <<HTML;
<div class="cl-assina">
<p class="cl-sub"><a href="$p$COLUNA/">Coluna do Estêvão</a><span class="sep">·</span><a href="${p}dr-estevao-rolim/">Página do autor</a></p>
</div>
$nav
HTML
}

# chamada do texto mais recente, para a página inicial (vazia se não houver texto)
sub coluna_home_html {
    my @posts = coluna_posts();
    return '' unless @posts;
    my $path  = $posts[0];
    my $m     = $coluna_meta{$path};
    my $t     = esc(title_of($path));
    my $data  = data_extenso($m->{data});
    my $tempo = $data ? qq{<time datetime="$m->{data}">$data</time>} : '';
    my $cham  = $m->{chamada} ? qq{<p>@{[esc($m->{chamada})]}</p>} : '';
    return <<HTML;
<div class="cl-home">
<p class="cl-home-selo"><span class="msym" aria-hidden="true">edit_note</span>Coluna do Estêvão</p>
<h3><a href="$path/">$t</a></h3>
$tempo
$cham
<p class="cl-home-acoes"><a class="btn btn-ghost" href="$path/">Ler o texto</a> <a class="btn btn-ghost" href="$COLUNA/">Ver a coluna</a></p>
</div>
HTML
}

# filhos por página-mãe
my %children;
for my $path (sort keys %content) {
    next unless $path =~ m{^([^/]+)/(.+)$};
    push @{ $children{$1} }, $path;
}

# título de uma página (manifesto > h1 do conteúdo > slug)
sub title_of {
    my ($path) = @_;
    return $page{$path}{title} if $page{$path} && $page{$path}{title};
    if (defined $content{$path} && $content{$path} =~ /^#\s+(.+?)\s*$/m) {
        my $t = $1; $t =~ s/<[^>]+>//g;
        return $t if length $t;
    }
    my $t = (split m{/}, $path)[-1];
    $t =~ s/-/ /g; return ucfirst $t;
}

# ---------------- versão dos arquivos de estilo e script ----------------
# O navegador guarda assets/style.css em cache. Sem nada que diferencie uma
# versão da outra, quem já visitou o site continua vendo o CSS velho depois
# de uma atualização — e a página quebra, porque o HTML é novo e o estilo não.
# Solução: cada arquivo ganha ?v=<resumo do próprio conteúdo>. Muda o
# conteúdo, muda o endereço, o navegador baixa de novo. Não mudou nada, o
# endereço é o mesmo e o cache continua valendo (e o docs/ não fica sujo de
# diferença a cada geração).
my %ASSET_VER;

sub asset_ver {
    my ($name) = @_;
    return $ASSET_VER{$name} if exists $ASSET_VER{$name};
    my $src = "$ROOT/assets/$name";
    my $v = 'x';
    if (open my $fh, '<:raw', $src) {
        local $/; $v = substr(md5_hex(scalar <$fh>), 0, 8); close $fh;
    }
    return $ASSET_VER{$name} = $v;
}

# carimba a versão em todo assets/*.css e assets/*.js citado no HTML
sub versionar {
    my ($html) = @_;
    $html =~ s{(assets/)([\w.\-]+\.(?:css|js))(?=["'])}{$1 . $2 . '?v=' . asset_ver($2)}ge;
    return $html;
}

# ---------------- helpers HTML ----------------
sub esc { my $s = shift; $s =~ s/&/&amp;/g; $s =~ s/</&lt;/g; $s =~ s/>/&gt;/g; $s }

sub clean_url {
    my ($u, $p) = @_;
    # desembrulha redirecionador do Google
    if ($u =~ m{^https?://www\.google\.com/url\?q=([^&]+)}) {
        $u = uri_unescape($1);
    }
    # links internos do site antigo -> páginas novas
    $u =~ s{^https?://(?:www\.)?escoladepacientes\.com}{};
    if ($u =~ m{^/}) {
        (my $path = $u) =~ s{^/}{}; $path =~ s{[#?].*$}{};
        $path =~ s{/$}{};
        if ($path eq '' or $path eq 'home') { return $p eq '' ? './' : $p; }
        # As chaves de %content vêm de readdir, que entrega o nome do arquivo em
        # BYTES; $path vem do markdown, lido com camada UTF-8, e portanto em
        # CARACTERES. Para slug sem acento os dois são idênticos e a comparação
        # funciona; com acento ela falhava calada, e onze páginas que existem
        # aqui — as do banco de citações, o teste do Revalida — eram mandadas
        # para o site antigo, que não as tem. Comparar também a forma
        # codificada resolve sem mexer em como os arquivos são lidos.
        my $chave = encode_utf8($path);
        return "$p$path/" if exists $content{$path}     or exists $PAGINA_HTML{$path}
                          or exists $content{$chave}    or exists $PAGINA_HTML{$chave}
                          or $path eq 'temas' or $path eq 'az';
        return "http://www.escoladepacientes.com/$path";   # não migrada: aponta pro antigo
    }
    return $u;
}

# Os nomes de arquivo vindos do glob chegam em BYTES, e o HTML é escrito em
# camada UTF-8: escrever esses bytes direto os codifica de novo, e o link sai
# com "Ã§Ã£o" no lugar de "ção" — endereço que não existe no disco. É o mesmo
# descompasso descrito lá em cima, no link_href, resolvido do mesmo jeito: no
# ponto de uso, sem mexer em como os arquivos são lidos. Idempotente, porque a
# mesma função recebe títulos que já vêm em caracteres, do manifesto.
sub em_caracteres {
    my ($s) = @_;
    return $s if !defined $s or utf8::is_utf8($s);
    my $c = eval { decode_utf8($s, Encode::FB_CROAK()) };
    return defined $c ? $c : $s;
}

sub embed_html {
    my ($label, $url) = @_;
    $label =~ s/^(?:Drive|Document|Presentation|Spreadsheet|YouTube Video)\s*,\s*//i;
    my $l = esc($label);
    if ($url =~ m{youtube\.com/embed/([\w-]+)}) {
        my $src = "https://www.youtube.com/embed/$1";
        return qq{<figure class="embed embed-video"><iframe src="$src" title="$l" loading="lazy" allowfullscreen></iframe>}
             . ($l ? qq{<figcaption class="embed-caption"><span>$l</span><a href="https://www.youtube.com/watch?v=$1" target="_blank" rel="noopener">Ver no YouTube ↗</a></figcaption>} : '')
             . qq{</figure>};
    }
    # Podcast do Spotify. O endereço que se copia do aplicativo é o da página
    # (/show/ID, às vezes com "?si=" de rastreio); o tocador mora em
    # /embed/show/ID. A conversão fica aqui para que o arquivo de conteúdo
    # continue guardando o endereço que a pessoa copiou, e não um segundo
    # formato que ninguém sabe de cor.
    if ($url =~ m{open\.spotify\.com/(?:embed/)?(show|episode|playlist|album)/([\w-]+)}) {
        my ($kind, $id) = ($1, $2);
        my $view = "https://open.spotify.com/$kind/$id";
        return qq{<figure class="embed embed-audio"><iframe src="https://open.spotify.com/embed/$kind/$id" title="$l" loading="lazy" allow="clipboard-write; encrypted-media; picture-in-picture" allowfullscreen></iframe><figcaption class="embed-caption"><span>$l</span><a href="$view" target="_blank" rel="noopener">Abrir no Spotify ↗</a></figcaption></figure>};
    }
    if ($url =~ m{drive\.google\.com/file/d/([\w-]+)}) {
        my $view = "https://drive.google.com/file/d/$1/view";
        return qq{<figure class="embed embed-doc"><iframe src="https://drive.google.com/file/d/$1/preview" title="$l" loading="lazy"></iframe><figcaption class="embed-caption"><span>$l</span><a href="$view" target="_blank" rel="noopener">Abrir no Drive ↗</a></figcaption></figure>};
    }
    if ($url =~ m{drive\.google\.com/embeddedfolderview\?id=([\w-]+)}) {
        my $view = "https://drive.google.com/drive/folders/$1";
        my $cap = $l || 'Pasta de arquivos';
        return qq{<figure class="embed embed-folder"><iframe src="https://drive.google.com/embeddedfolderview?id=$1#list" title="$cap" loading="lazy"></iframe><figcaption class="embed-caption"><span>$cap</span><a href="$view" target="_blank" rel="noopener">Abrir a pasta ↗</a></figcaption></figure>};
    }
    if ($url =~ m{docs\.google\.com/(document|presentation|spreadsheets)/d/([\w-]+)}) {
        my ($kind, $id) = ($1, $2);
        my $src  = $kind eq 'presentation' ? "https://docs.google.com/presentation/d/$id/embed" : "https://docs.google.com/$kind/d/$id/preview";
        my $view = "https://docs.google.com/$kind/d/$id/edit";
        return qq{<figure class="embed embed-doc"><iframe src="$src" title="$l" loading="lazy"></iframe><figcaption class="embed-caption"><span>$l</span><a href="$view" target="_blank" rel="noopener">Abrir o documento ↗</a></figcaption></figure>};
    }
    if ($url =~ m{docs\.google\.com/forms|forms\.gle}) {
        return qq{<a class="link-card" href="$url" target="_blank" rel="noopener"><span class="lc-ico"><span class="msym">assignment</span></span><span class="lc-body"><b>$l</b><small>formulário</small></span><span class="lc-arrow">→</span></a>};
    }
    # iframe genérico só com link
    return qq{<p><a href="$url" target="_blank" rel="noopener">$l ↗</a></p>};
}

# chave canônica de um embed (dedupe por conteúdo, não por URL literal)
sub embed_key {
    my ($u) = @_;
    return "yt:$1" if $u =~ m{youtube\.com/embed/([\w-]+)};
    return "sp:$1:$2" if $u =~ m{open\.spotify\.com/(?:embed/)?(show|episode|playlist|album)/([\w-]+)};
    return "dr:$1" if $u =~ m{drive\.google\.com/file/d/([\w-]+)};
    return "fo:$1" if $u =~ m{embeddedfolderview\?id=([\w-]+)};
    return "dc:$1" if $u =~ m{docs\.google\.com/\w+/d/([\w-]+)};
    (my $k = $u) =~ s/\?.*$//;
    return $k;
}

sub host_of {
    my ($u) = @_;
    return '' unless $u =~ m{^https?://([^/]+)};
    (my $h = $1) =~ s/^www\.//;
    return $h;
}

sub link_icon {
    my ($u) = @_;
    return 'assignment' if $u =~ m{forms\.gle|docs\.google\.com/forms};
    return 'play_circle' if $u =~ m{youtube\.com|youtu\.be|globoplay|tvbrasil|video};
    return 'podcasts' if $u =~ m{spotify\.com|deezer\.com|podcast};
    return 'photo_camera' if $u =~ m{instagram\.com};
    return 'smart_toy' if $u =~ m{chatgpt\.com|chat\.openai|g\.co/gemini|gemini\.google};
    return 'description' if $u =~ m{drive\.google|docs\.google|\.pdf};
    return 'link';
}

# linha composta apenas por um link (ou rótulo + link) -> card clicável
sub link_card_html {
    my ($l, $p) = @_;
    my ($label, $text, $url);
    if    ($l =~ /^\[([^\]]+)\]\((\S+)\)\s*[-–—:.]?\s*$/)                     { ($text, $url) = ($1, $2); }
    elsif ($l =~ /^([^\[\]]{2,200}?)\s*[:\-–—]\s*\[([^\]]*)\]\((\S+)\)\s*$/) { ($label, $text, $url) = ($1, $2, $3); }
    elsif ($l =~ /^([^\[\]]{2,200}?)\s*[:\-–—]\s*(https?:\/\/\S+)\s*$/)      { ($label, $url) = ($1, $2); $text = ''; }
    else { return; }
    my $href = clean_url($url, $p);
    my $ext = $href =~ m{^https?://} ? ' target="_blank" rel="noopener"' : '';
    # escolhe o melhor título disponível (evita URLs cruas e "clique aqui")
    my $title = (defined $text && $text ne '' && $text !~ m{^https?://}) ? $text : (defined $label ? $label : '');
    $title = host_of($url) if $title eq '' or $title =~ m{^https?://};
    $title = $label if defined $label && $title =~ /^(clique aqui|aqui|link|acesse|ver)\.?$/i;
    $title =~ s/\s+/ /g; $title =~ s/^\s+|\s+$//g;
    $title = host_of($url) || 'Abrir link' if $title eq '';
    $title = substr($title, 0, 110) . '…' if length($title) > 112;
    my $sub  = $href =~ m{^https?://} ? host_of($href) : 'página do site';
    my $icon = $href =~ m{^https?://} ? link_icon($href) : 'description';
    return qq{<a class="link-card" href="$href"$ext><span class="lc-ico"><span class="msym">$icon</span></span><span class="lc-body"><b>@{[esc($title)]}</b><small>$sub</small></span><span class="lc-arrow">→</span></a>};
}

sub inline_fmt {
    my ($line, $p) = @_;
    $line = esc($line);
    # negrito com **dois** asteriscos. Só o par duplo: asterisco solto aparece
    # no acervo como curinga de arquivo (*.pdf) e marca de nota de rodapé, e
    # itálico de um asterisco só quebraria essas páginas. Crase também fica de
    # fora — é usada como apóstrofo em centenas de títulos (STUDENT`S).
    $line =~ s{\*\*(?=\S)(.+?)(?<=\S)\*\*}{<strong>$1</strong>}g;
    $line =~ s{\[([^\]\[]*)\]\(([^)\s]+)\)}{
        my ($t, $u) = ($1, $2); $u = clean_url($u, $p);
        my $ext = $u =~ m{^https?://} ? ' target="_blank" rel="noopener"' : '';
        $t =~ s/^\s+|\s+$//g;
        $t eq '' ? '' : qq{<a href="$u"$ext>$t</a>};
    }ge;
    # A pontuação que fecha a frase não faz parte do endereço. Sem esta
    # separação, "Disponível em: https://exemplo.org/artigo." vira um link
    # terminado em ponto — e o ponto acompanha o endereço até o servidor, que
    # devolve erro. É o formato de toda referência bibliográfica do site.
    $line =~ s{(?<!["'=>])(https?://[^\s<>"')]+)}{
        my $orig = $1;
        my $fim = '';
        $fim = $1 if $orig =~ s/([.,;:!?]+)$//;
        my $u = clean_url($orig, $p);
        my $ext = $u =~ m{^https?://} ? ' target="_blank" rel="noopener"' : '';
        qq{<a href="$u"$ext>$orig</a>} . $fim;
    }ge;
    return $line;
}

# ---------------- QR de cada página ----------------
# Toda página termina com o QR que aponta para ela mesma. O motivo é de sala de
# aula e de corredor: mostrar a tela do celular para a pessoa do lado é mais
# rápido do que ditar um endereço, e quem recebe sai com a página inteira, não
# com um print.
#
# O PNG é gerado no build, ao lado do index.html da própria página — por isso o
# src é só "qr.png", sem caminho. Não existe arquivo versionado em build/: quem
# publica é o GitHub, e o workflow instala o qrencode antes de rodar o gerador.
# Sem qrencode na máquina, a página sai sem a figura em vez de sair quebrada —
# mesmo trato das fotos do carrossel e dos prints do Núcleo EP.
my $QRENCODE = do { my $w = `which qrencode 2>/dev/null` // ''; chomp $w; $w };
sub qr_figure_html {
    my ($url, $dir) = @_;
    return '' unless $QRENCODE && $url && $dir;
    make_path($dir) unless -d $dir;
    my $png = "$dir/qr.png";
    system($QRENCODE, '-o', $png, '-s', '8', '-m', '2', '-l', 'M', '--', $url) == 0
        or return '';
    my ($w, $h) = png_size($png);
    my $dim = ($w && $h) ? qq{ width="$w" height="$h"} : '';
    return qq{<div class="wrap"><figure class="qr-pagina">}
         . qq{<img src="qr.png" alt="QR code que abre esta página"$dim decoding="async" loading="lazy">}
         . qq{<figcaption>Aponte a câmera para abrir esta página</figcaption>}
         . qq{</figure></div>};
}

# largura e altura de um PNG, lidas do cabeçalho IHDR
sub png_size {
    my ($f) = @_;
    open my $fh, '<:raw', $f or return ();
    read $fh, my $buf, 24; close $fh;
    return () unless length($buf) == 24 && substr($buf, 12, 4) eq 'IHDR';
    return unpack 'N2', substr($buf, 16, 8);
}

# ---------------- índice das seções ----------------
# Âncora estável de um título de seção.
#
# Espelha o `slugify` de assets/toc.js DE PROPÓSITO: o sumário lateral só cria
# `id` onde ainda não existe, então, se os dois discordassem, o índice do topo e
# o sumário apontariam para lugares diferentes na mesma página.
sub slug_secao {
    my ($s) = @_;
    $s = lc $s;
    $s =~ tr/áàâãäéèêëíìîïóòôõöúùûüçñ/aaaaaeeeeiiiiooooouuuucn/;
    $s =~ s/[^a-z0-9]+/-/g;
    $s =~ s/^-+|-+$//g;
    $s = substr($s, 0, 60);
    return $s eq '' ? 'sec' : $s;
}

# O índice do topo: só os nomes das seções, clicáveis.
#
# O que existia antes era uma lista explicando o que cada seção É -- "Slides -
# Apresentações resumidas com os principais conceitos da aula" --, trinta linhas
# antes do primeiro material, descrevendo seções que estavam logo abaixo com o
# nome delas. Aqui o índice não explica nada: diz o que a página tem e leva até lá.
#
# Sai dos próprios `##` da página, e não de uma lista escrita à mão: seção nova
# entra no índice sozinha, e seção renomeada não deixa atalho apontando para o
# nome antigo.
sub indice_html {
    my ($secoes) = @_;
    return '' unless @$secoes;
    my $h = qq{<nav class="indice-secoes" aria-label="Seções desta página">\n};
    for my $s (@$secoes) {
        $h .= qq{<a href="#$s->{slug}">} . esc($s->{titulo}) . qq{</a>\n};
    }
    return $h . '</nav>';
}

# md simplificado -> HTML
sub md_to_html {
    my ($md, $p) = @_;
    my @lines = split /\n/, $md;
    my (@html, $inlist, $ingrid, $last_embed_label, %seen, %eseen, %cseen);
    my $title_key = '';
    my $first_h1 = 0;
    my $close_blocks = sub {
        push @html, '</ul>'  and $inlist = 0 if $inlist;
        push @html, '</div>' and $ingrid = 0 if $ingrid;
    };
    my $dup = sub {
        my ($t) = @_;
        (my $k = lc $t) =~ s/\W+//g;
        return 0 if length($k) < 40;
        return $seen{$k}++ ? 1 : 0;
    };

    # As seções são levantadas ANTES de gerar o corpo: o índice fica no topo e
    # precisa saber o que vem depois dele. Os slugs entram numa fila POR TÍTULO
    # em vez de num contador de posição -- o laço de baixo pula linha (embed,
    # legenda repetida, título da página) e um contador sairia de sincronia sem
    # dar sinal, mandando o atalho para a seção errada.
    my (@secoes, %fila, %slug_usado);
    for my $bruta (@lines) {
        (my $t = $bruta) =~ s/^\s+|\s+$//g;
        next unless $t =~ /^##\s+(.+)/;
        $t = $1;
        my $base = slug_secao($t);
        my ($slug, $n) = ($base, 2);
        $slug = $base . '-' . $n++ while $slug_usado{$slug};
        $slug_usado{$slug} = 1;
        push @secoes, { titulo => $t, slug => $slug };
        push @{ $fila{$t} }, $slug;
    }
    for (my $i = 0; $i <= $#lines; $i++) {
        my $l = $lines[$i];
        $l =~ s/^\s+|\s+$//g;
        next if $l eq '' or $l eq '.' or $l =~ /^\.+$/;
        next if $l =~ /^\[IMAGEM:/;
        # "-" sozinho: item de lista cujo texto vem na próxima linha
        if ($l eq '-') { next; }
        # primeira h1 = título da página (já no hero)
        if ($l =~ /^#\s+(.+)/ && !$first_h1) {
            $first_h1 = 1;
            ($title_key = lc $1) =~ s/\W+//g;
            next;
        }
        # não repete o título da página como texto do corpo
        if ($title_key) {
            (my $tk = lc $l) =~ s/\W+//g;
            next if $tk eq $title_key;
        }

        # embed
        if ($l =~ /^\[EMBED:\s*(.*?)\]\((\S+)\)$/) {
            my ($label, $url) = ($1, $2);
            next if $eseen{ embed_key($url) }++;
            $close_blocks->();
            # rótulo genérico: usa a próxima linha curta como legenda
            if ($label =~ /^(?:Drive Folder|Drive)?$/i) {
                for (my $j = $i + 1; $j <= $#lines && $j <= $i + 2; $j++) {
                    my $nx = $lines[$j]; $nx =~ s/^\s+|\s+$//g;
                    next if $nx eq '';
                    if (length($nx) <= 80 && $nx !~ /https?:/ && $nx !~ /^\[/ && $nx !~ /^#/) {
                        ($label = $nx) =~ s/\s*[-–—:]\s*$//;
                        $i = $j;
                    }
                    last;
                }
            }
            push @html, embed_html($label, $url);
            $last_embed_label = $label; $last_embed_label =~ s/^(?:Drive|Document|Presentation|Spreadsheet|YouTube Video)\s*,\s*//i;
            next;
        }
        # legenda repetida logo após o embed
        if (defined $last_embed_label && length($l) > 3) {
            my ($a, $b) = (lc $l, lc $last_embed_label);
            if (index($b, $a) >= 0 or index($a, $b) >= 0) { $last_embed_label = undef; next; }
        }
        $last_embed_label = undef;

        # [INDICE]: o índice de atalhos, montado a partir dos `##` desta página
        if ($l eq '[INDICE]') { $close_blocks->(); push @html, indice_html(\@secoes) if @secoes; next; }

        # Os dois marcadores abaixo pertencem à página pública da avaliação
        # dos ex-integrantes. O primeiro desenha indicadores, gráficos e
        # tendências; o segundo contém SOMENTE as citações literais e fica no
        # fim da página. Assim, retirar os depoimentos não toca nos dados.
        if ($l eq '[FEEDBACK-EX-INTEGRANTES]') {
            $close_blocks->();
            push @html, feedback_ex_integrantes_html();
            next;
        }
        if ($l eq '[DEPOIMENTOS-EX-INTEGRANTES]') {
            $close_blocks->();
            push @html, depoimentos_ex_integrantes_html();
            next;
        }

        # [SIMULAPACIENTES]: o botão grande para a plataforma atual.
        #
        # É o MESMO botão da página inicial (`landing.html`), e é de propósito:
        # a página de simulações antigas precisa mandar quem chegou nela para o
        # lugar certo, e um link igual aos outros trinta e oito da página não
        # manda ninguém a lugar nenhum. Reaproveitar o botão da home é o que
        # faz os dois pontos de entrada parecerem o mesmo convite.
        # [SIMULACOES-EM-NUMEROS]: as tabelas do espelho público.
        #
        # Nenhum número é digitado nesta página. Eles vêm de
        # build/assets/dados-simulacoes.json, que uma Action busca do Hub e
        # comita -- o mesmo arranjo dos prêmios, que saem de vitrine-dados.md.
        # Se o arquivo não existir, a página diz isso em vez de mostrar zero.
        if ($l eq '[SIMULACOES-EM-NUMEROS]') {
            $close_blocks->();
            push @html, numeros_das_simulacoes_html($p);
            next;
        }

        if ($l eq '[SIMULAPACIENTES]') {
            $close_blocks->();
            my $href = clean_url('/simula-pacientes', $p);
            push @html,
                '<div class="hero-cta"><a class="cta-simula" href="' . $href . '">'
              . '<span class="cta-simula-l"><span class="msym">smart_toy</span>'
              . '<b>SimulaPacientes</b></span>'
              . '<span class="cta-simula-sub">atenda um paciente digital</span>'
              . '</a></div>';
            next;
        }

        if ($l =~ /^##\s+(.+)/)  {
            $close_blocks->();
            my $t = $1;
            my $slug = ($fila{$t} && @{ $fila{$t} }) ? shift @{ $fila{$t} } : slug_secao($t);
            push @html, qq{<h2 id="$slug">} . inline_fmt($t, $p) . '</h2>';
            next;
        }
        if ($l =~ /^###+\s+(.+)/){ $close_blocks->(); push @html, '<h3>' . inline_fmt($1, $p) . '</h3>'; next; }

        # "> texto" vira um aviso destacado (dica, ressalva, atenção)
        if ($l =~ /^>\s?(.+)/) {
            $close_blocks->();
            push @html, '<p class="nota">' . inline_fmt($1, $p) . '</p>';
            next;
        }

        # item de lista (item que é só um link vira card)
        if ($l =~ /^-\s+(.+)/) {
            my $item = $1;
            my $icard = link_card_html($item, $p);
            if ($icard) {
                my ($h) = $icard =~ /href="([^"]+)"/;
                next if $dup->($item) or $cseen{$h}++;
                push @html, '</ul>' and $inlist = 0 if $inlist;
                if (!$ingrid) { push @html, '<div class="link-grid">'; $ingrid = 1; }
                push @html, $icard;
                next;
            }
            push @html, '</div>' and $ingrid = 0 if $ingrid;
            next if $dup->($item);
            push @html, '<ul>' unless $inlist; $inlist = 1;
            push @html, '<li>' . inline_fmt($item, $p) . '</li>';
            next;
        }

        # linha que é apenas um link (ou rótulo + link) -> card clicável
        my $card = link_card_html($l, $p);
        if ($card) {
            my ($h) = $card =~ /href="([^"]+)"/;
            next if $dup->($l) or $cseen{$h}++;
            push @html, '</ul>' and $inlist = 0 if $inlist;
            if (!$ingrid) { push @html, '<div class="link-grid">'; $ingrid = 1; }
            push @html, $card;
            next;
        }
        $close_blocks->();

        # linha toda em maiúsculas = subtítulo visual
        my $letters = () = $l =~ /\p{L}/g;
        if ($letters >= 4 && length($l) <= 90 && $l !~ /https?:/ && $l !~ /\p{Ll}/ && $l =~ /\p{Lu}/) {
            push @html, '<h3>' . inline_fmt($l, $p) . '</h3>';
            next;
        }
        next if $dup->($l);
        push @html, '<p>' . inline_fmt($l, $p) . '</p>';
    }
    push @html, '</ul>' if $inlist;
    push @html, '</div>' if $ingrid;
    # remove subtítulo órfão apenas no fim da página (sem nada depois dele);
    # um h3 seguido de outro h3 é um título de grupo legítimo e é mantido
    pop @html while @html && $html[-1] =~ /^<h3>/;
    return join "\n", @html;
}

# ---------------- feedback público dos ex-integrantes ----------------
#
# A planilha original não atravessa o site. O arquivo abaixo é uma fotografia
# curada e contém apenas os campos que a página pode publicar. Indicadores,
# gráficos e citações leem a MESMA fonte; não há número duplicado no HTML.
sub dados_dos_ex_integrantes {
    my $arq = "$ROOT/assets/feedback-ex-integrantes.json";
    return undef unless -e $arq;
    open my $fh, '<:raw', $arq or return undef;
    local $/; my $bruto = <$fh>; close $fh;
    my $d = eval { JSON::PP->new->utf8->decode($bruto) };
    return $d;
}

sub feedback_ex_integrantes_html {
    my $d = dados_dos_ex_integrantes();
    return q{<p class="nota">Os dados agregados ainda não foram publicados nesta versão do site.</p>}
        unless $d && ref $d eq 'HASH';

    my $n = 0 + ($d->{avaliacoes} // 0);
    my $e = $d->{escalaExperiencia} || {};
    my $media = 0 + ($e->{media} // 0);
    my $media_br = "$media"; $media_br =~ s/\./,/;
    my $max = 0 + ($e->{notaMaximaPercentual} // 0);
    $max = 0 if $max < 0; $max = 100 if $max > 100;
    my $outras = 100 - $max;
    my $motivo = esc($d->{principalMotivoSaida} // 'Não informado');

    my @out;
    push @out, qq{<div class="fx-kpis" aria-label="Indicadores principais">}
      . qq{<div class="fx-kpi"><span class="msym" aria-hidden="true">groups</span><b>$n</b><small>ex-integrantes avaliaram</small></div>}
      . qq{<div class="fx-kpi"><span class="msym" aria-hidden="true">star</span><b>$max%</b><small>deram a nota máxima</small></div>}
      . qq{<div class="fx-kpi"><span class="msym" aria-hidden="true">monitoring</span><b>$media_br / 5</b><small>avaliação média</small></div>}
      . qq{</div>};

    push @out, qq{<div class="fx-painel">}
      . qq{<figure class="fx-grafico"><figcaption><h3>Avaliação da experiência</h3>}
      . qq{<p>Concentração das respostas no topo da escala.</p></figcaption>}
      . qq{<div class="fx-grafico-corpo">}
      . qq{<div class="fx-anel" style="--fx-max: $max%" role="img" }
      . qq{aria-label="$max% das avaliações deram a nota máxima; $outras% deram outras notas.">}
      . qq{<span><b>$max%</b><small>nota máxima</small></span></div>}
      . qq{<ul class="fx-legenda"><li><i class="fx-cor-max"></i><b>Nota máxima</b><span>$max%</span></li>}
      . qq{<li><i class="fx-cor-outras"></i><b>Outras notas</b><span>$outras%</span></li></ul>}
      . qq{</div></figure>}
      . qq{<div class="fx-motivo"><span class="msym" aria-hidden="true">event_busy</span>}
      . qq{<small>Principal motivo de saída</small><b>$motivo</b>}
      . qq{<p>A saída aparece associada à conciliação da agenda acadêmica, não à avaliação global da experiência.</p></div>}
      . qq{</div>};

    push @out, q{<h3>Tendências observadas</h3><div class="fx-tendencias">}
      . qq{<div><span class="msym" aria-hidden="true">trending_up</span><b>Experiência muito positiva</b><p>Média de $media_br em 5 e $max% de notas máximas.</p></div>}
      . q{<div><span class="msym" aria-hidden="true">school</span><b>Mentoria e oportunidades andam juntas</b><p>Orientação, organização e oportunidades científicas aparecem na faixa mais alta da síntese.</p></div>}
      . q{<div><span class="msym" aria-hidden="true">balance</span><b>Permanência depende da carga acadêmica</b><p>O principal motivo de saída foi a dificuldade de conciliar o grupo com outras atividades.</p></div>}
      . q{</div>};

    my $fortes = $d->{pontosFortes};
    if ($fortes && ref $fortes eq 'ARRAY' && @$fortes) {
        my @linhas;
        for my $p (@$fortes) {
            my $cat = esc($p->{categoria} // '');
            my $freq = lc($p->{frequencia} // '');
            my ($rot, $largura) = $freq eq 'alta' ? ('Alta', '100%')
                                : $freq eq 'moderada' ? ('Moderada', '66.666%')
                                : ('Baixa', '33.333%');
            push @linhas, qq{<li><span class="fx-forca-rotulo">$cat</span>}
              . qq{<span class="fx-forca-trilho" aria-hidden="true"><i style="--fx-largura:$largura"></i></span>}
              . qq{<b>$rot</b></li>};
        }
        push @out, q{<div class="fx-secao"><h3>Pontos fortes identificados</h3>}
          . q{<p class="fx-ajuda">Síntese qualitativa das menções — os níveis não representam percentuais.</p>}
          . q{<ul class="fx-forcas">} . join('', @linhas) . q{</ul></div>};
    }

    my $melhorias = $d->{melhorias};
    if ($melhorias && ref $melhorias eq 'ARRAY' && @$melhorias) {
        my @itens;
        my @icones = qw(mark_chat_unread task_alt person_pin account_tree);
        for my $i (0 .. $#$melhorias) {
            my $t = esc($melhorias->[$i] // '');
            my $icone = $icones[$i] // 'tune';
            push @itens, qq{<li><span class="msym" aria-hidden="true">$icone</span><span>$t</span></li>};
        }
        push @out, q{<div class="fx-secao"><h3>Oportunidades de melhoria</h3>}
          . q{<ul class="fx-melhorias">} . join('', @itens) . q{</ul></div>};
    }

    my $ciclo = $d->{ciclo};
    if ($ciclo && ref $ciclo eq 'ARRAY' && @$ciclo) {
        my @etapas;
        for my $i (0 .. $#$ciclo) {
            my $t = esc($ciclo->[$i] // '');
            push @etapas, qq{<li><span>} . ($i + 1) . qq{</span><b>$t</b></li>};
        }
        push @out, q{<div class="fx-secao"><h3>Ciclo de melhoria</h3>}
          . q{<ol class="fx-ciclo">} . join('', @etapas) . q{</ol></div>};
    }

    if (my $m = $d->{metodologia}) {
        push @out, q{<h3>Como estes resultados foram preparados</h3><p class="nota">}
          . esc($m) . q{</p>};
    }
    if (my $data = $d->{atualizadoEm}) {
        push @out, q{<p class="nota">Síntese atualizada em } . esc($data) . q{.</p>};
    }

    return join("\n", @out);
}

# O bloco literal é deliberadamente uma função e um marcador separados.
# Para removê-lo, basta apagar a seção final do markdown OU esvaziar
# depoimentosIlustrativos no JSON; indicadores e gráficos permanecem iguais.
sub depoimentos_ex_integrantes_html {
    my $d = dados_dos_ex_integrantes();
    return '' unless $d && ref $d eq 'HASH';
    my $falas = $d->{depoimentosIlustrativos};
    return '' unless $falas && ref $falas eq 'ARRAY' && @$falas;

    my @cards = map {
        my $t = esc($_ // '');
        qq{<blockquote><p>&ldquo;$t&rdquo;</p></blockquote>}
    } @$falas;

    return q{<p class="fx-ajuda">Trechos literais apresentados sem atribuição pessoal, apenas como ilustração qualitativa dos resultados.</p>}
         . q{<div class="fx-depoimentos" data-conteudo-opcional="depoimentos">}
         . join('', @cards) . q{</div>};
}

# ---------------- navegação ----------------
# ---------------- o espelho público de dados das simulações ----------------
#
# ============== ESTA PÁGINA NÃO CALCULA NADA ==============
# O que decide o que pode ser publicado é `src/lib/dados-publicos.ts`, no
# repositório do Hub: piso de dez simulações, denominador suprimido junto com o
# percentual, e supressão complementar quando esconder uma célula só permitiria
# deduzi-la por subtração.
#
# Aqui só se DESENHA o que já veio protegido. É por isso que este arquivo não
# tem nenhum `if` sobre tamanho de amostra: repetir a regra em Perl criaria uma
# segunda implementação da mesma proteção, e duas implementações divergem -- é
# o defeito que o Hub persegue no próprio código.
#
# Célula suprimida chega com `suprimida: true`, `percentual: null` e
# `denominador: null`. A tabela mostra um traço e o motivo. Nunca há um número
# escondido aqui para não ser exibido: ele não veio.
# ==========================================================
sub dados_das_simulacoes {
    my $arq = "$ROOT/assets/dados-simulacoes.json";
    return undef unless -e $arq;
    open my $fh, '<:raw', $arq or return undef;
    local $/; my $bruto = <$fh>; close $fh;
    my $d = eval { JSON::PP->new->utf8->decode($bruto) };
    return $d;
}

sub num_br {
    my $n = shift;
    return '—' unless defined $n;
    1 while $n =~ s/^(\d+)(\d{3})/$1.$2/;
    return $n;
}

# Uma tabela por bloco. `%opt`: rotulo da primeira coluna e se há percentual.
sub tabela_de_celulas {
    my ($titulo, $celulas, %opt) = @_;
    return '' unless $celulas && @$celulas;
    my $col = $opt{coluna} || 'Recorte';
    my $pct = $opt{percentual} // 1;

    my @linhas;
    for my $c (@$celulas) {
        my $rot = esc($c->{rotulo} // '');
        if ($c->{suprimida}) {
            my $motivo = ($c->{motivo} // '') eq 'complementar'
                ? 'protegido junto com outro'
                : 'menos de 10 simulações';
            push @linhas,
                qq{<tr><td>$rot</td>}
              . ($pct ? qq{<td>—</td>} : '')
              . qq{<td class="num-suprimido">— <span>$motivo</span></td></tr>};
            next;
        }
        my $p = defined $c->{percentual} ? $c->{percentual} . '%' : '—';
        my $n = num_br($c->{denominador});
        push @linhas,
            qq{<tr><td>$rot</td>}
          . ($pct ? qq{<td>$p</td>} : '')
          . qq{<td>$n</td></tr>};
    }

    my $th_pct = $pct ? '<th>Cobertura</th>' : '';
    return qq{<div class="g-tabela numeros-bloco"><h3>} . esc($titulo) . qq{</h3>}
         . qq{<table><thead><tr><th>} . esc($col) . qq{</th>$th_pct<th>Simulações</th></tr></thead>}
         . qq{<tbody>} . join('', @linhas) . qq{</tbody></table></div>};
}

# ---------------- a composição das origens, em rosca ----------------
#
# ============== POR QUE SIMULAPACIENTES VEM PRIMEIRO ==============
# A ordem das linhas é APRESENTAÇÃO, não dado. O Hub manda as origens na ordem
# em que a Escola as usou -- impressas, formulários, ChatGPT, Gems,
# SimulaPacientes -- e nessa ordem a única origem viva, a que ainda cresce
# todo dia, cai na última linha, depois de quatro que não mudam mais.
#
# Ela sobe para a primeira. As outras mantêm entre si a ordem que veio do Hub.
# Nenhum número se move junto: cada linha continua com o rótulo e o
# denominador que o Hub publicou.
sub composicao_ordenada {
    my ($celulas) = @_;
    return [] unless $celulas && ref $celulas eq 'ARRAY';
    my $eh_sp = sub { ($_[0]->{rotulo} // '') =~ /simula\s*pacientes/i };
    return [ (grep { $eh_sp->($_) } @$celulas), (grep { !$eh_sp->($_) } @$celulas) ];
}

sub pct_br {
    my ($v) = @_;
    my $s = sprintf('%.1f', $v);
    $s =~ s/\./,/;
    return "$s%";
}

# ============== AS CORES DA ROSCA ==============
# Cinco lugares fixos (`--pz-1` a `--pz-5` no style.css), na ordem em que as
# fatias entram no anel, mais um cinza (`--pz-6`) para a cauda. A ordem não é
# enfeite: ela foi escolhida para que duas fatias VIZINHAS continuem
# distinguíveis por quem não enxerga cor como a maioria -- e é por vizinhança
# que uma rosca é lida, porque cada fatia só encosta em duas outras.
#
# Por isso o lugar da cor acompanha a POSIÇÃO no anel, e não o rótulo: mudar a
# ordem sem mudar as cores desfaria exatamente a propriedade que foi verificada.
# O SimulaPacientes, que é a fatia que o leitor vem procurar, fica sempre na
# primeira posição -- e portanto sempre no azul da casa.
#
# Acima de cinco origens a cauda vira "Outras origens", no cinza. Inventar uma
# sexta cor produziria um tom que ninguém separa dos outros cinco; a tabela ao
# lado continua nomeando cada origem, uma a uma, então nada se perde.
sub pizza_fatias {
    my ($celulas) = @_;
    my (@plot, @fora);
    for my $c (@$celulas) {
        if ($c->{suprimida} || !defined $c->{denominador}) { push @fora, $c; next; }
        push @plot, { %$c };
    }
    if (@plot > 5) {
        my @cauda = splice @plot, 5;
        my $soma = 0; $soma += $_->{denominador} for @cauda;
        push @plot, { rotulo => 'Outras origens', denominador => $soma, slot => 6,
                      cauda => \@cauda };
    }
    my $i = 0;
    $_->{slot} //= ++$i for @plot;
    return (\@plot, \@fora);
}

# A rosca e a tabela são a MESMA figura: a tabela é a versão em texto do que o
# anel mostra, e fica visível, não escondida num `details`. Quem lê cor vê a
# proporção de relance; quem precisa do número exato tem o número exato ao
# lado, na mesma linha da chave colorida.
sub grafico_pizza_composicao_html {
    my ($celulas, $titulo) = @_;
    return '' unless $celulas && @$celulas;

    my ($plot, $fora) = pizza_fatias($celulas);

    # Uma fatia só não é parte-todo: é um número. Nesse caso a tabela de sempre
    # já diz tudo o que há para dizer.
    return tabela_de_celulas($titulo, $celulas, coluna => 'Origem', percentual => 0)
        if @$plot < 2;

    my $total = 0; $total += $_->{denominador} for @$plot;
    return tabela_de_celulas($titulo, $celulas, coluna => 'Origem', percentual => 0)
        unless $total > 0;

    my $CIRC = 439.82;   # 2 · π · 70, o raio do anel no viewBox
    my $VAO  = 3;        # o vão que separa duas fatias, na cor do fundo

    my $pos = 0;
    my (@arcos, @linhas, @alt);
    for my $c (@$plot) {
        my $slot  = $c->{slot};
        my $frac  = $c->{denominador} / $total;
        my $arco  = $frac * $CIRC;
        my $traco = $arco - $VAO; $traco = 0.6 if $traco < 0.6;
        my $off   = -$pos;
        $pos += $arco;

        my $rot = esc($c->{rotulo} // '');
        my $n   = num_br($c->{denominador});
        my $pct = pct_br($frac * 100);

        push @arcos, sprintf(
            q{<circle class="pz-fatia" style="--pz: var(--pz-%d)" cx="100" cy="100" r="70" }
          . q{stroke-dasharray="%.2f %.2f" stroke-dashoffset="%.2f">}
          . q{<title>%s: %s simulações, %s do total</title></circle>},
            $slot, $traco, $CIRC - $traco, $off, $rot, $n, $pct);

        push @linhas,
            qq{<tr><td><span class="pz-rot"><span class="pz-chave" style="--pz: var(--pz-$slot)" aria-hidden="true"></span>$rot</span></td>}
          . qq{<td>$pct</td><td>$n</td></tr>};

        # A cauda é uma fatia só no anel, mas continua sendo várias origens na
        # tabela: cada uma com o seu nome e o seu número, recuadas sob ela.
        # Somar origens para caber na paleta é decisão de desenho -- deixar de
        # dizer quais elas são seria outra coisa.
        for my $f (@{ $c->{cauda} || [] }) {
            push @linhas,
                qq{<tr class="pz-cauda"><td><span class="pz-rot"><span class="pz-chave" style="--pz: var(--pz-$slot)" aria-hidden="true"></span>}
              . esc($f->{rotulo} // '') . qq{</span></td><td>}
              . pct_br($f->{denominador} / $total * 100)
              . qq{</td><td>@{[ num_br($f->{denominador}) ]}</td></tr>};
        }

        push @alt, "$rot, $pct";
    }

    # Recorte protegido não vira fatia: ele não tem número. Continua na tabela,
    # dizendo por que não tem.
    for my $c (@$fora) {
        my $rot = esc($c->{rotulo} // '');
        my $motivo = ($c->{motivo} // '') eq 'complementar'
            ? 'protegido junto com outro'
            : 'menos de 10 simulações';
        push @linhas,
            qq{<tr><td><span class="pz-rot"><span class="pz-chave pz-chave-vazia" aria-hidden="true"></span>$rot</span></td>}
          . qq{<td>—</td><td class="num-suprimido">— <span>$motivo</span></td></tr>};
    }

    my $nota = @$fora
        ? ' ' . (@$fora == 1 ? 'Uma origem ficou' : scalar(@$fora) . ' origens ficaram')
          . ' fora do anel, por ser recorte protegido — a tabela diz quais.'
        : '';

    my $t     = esc($titulo);
    my $arcos = join "\n", @arcos;
    my $trs   = join "\n", @linhas;
    my $lbl   = esc(join '; ', @alt);
    my $tot   = num_br($total);

    # ============== POR QUE ISTO NÃO É UM CARTÃO ==============
    # O `.grafico` do site é vidro: fundo translúcido, borda, sombra. Ele existe
    # para a vitrine da home, onde tudo é cartão. Aqui não: esta página é um
    # documento, e todo bloco vizinho -- competência, condição, grupo -- é um
    # rótulo em caixa alta com um traço e uma tabela sem moldura. Um cartão no
    # meio disso não parece um gráfico da página; parece um gráfico colado nela.
    #
    # Então a figura usa o MESMO `h3` dos outros blocos (que ganha o traço e a
    # caixa alta de `article.content h3` sozinho) e a mesma tabela sem moldura.
    # O que a rosca acrescenta é a cor -- não uma caixa.
    return <<HTML;
<figure class="pz-figura numeros-bloco">
<h3>$t</h3>
<p class="numeros-sub">Quanto cada origem representa dos $tot atendimentos simulados.$nota</p>
<div class="pz-corpo">
<svg class="pz-svg" viewBox="0 0 200 200" role="img" aria-label="Rosca das origens: $lbl.">
<g transform="rotate(-90 100 100)">
$arcos
</g>
<text class="pz-centro-n" x="100" y="97">$tot</text>
<text class="pz-centro-l" x="100" y="118">simulações</text>
</svg>
<div class="g-tabela pz-tabela">
<table>
<thead><tr><th scope="col">Origem</th><th scope="col">Do total</th><th scope="col">Simulações</th></tr></thead>
<tbody>
$trs
</tbody>
</table>
</div>
</div>
</figure>
HTML
}

# ---------------- a evolução do SimulaPacientes ----------------
#
# ============== POR QUE SEMANA NÃO É DECISÃO DESTA PÁGINA ==============
# Agrupar por semana é mais fino do que agrupar por mês, e "mais fino" aqui não
# é detalhe de desenho: a própria página promete, em "O que estes números são",
# que o tempo aparece só em mês -- porque dia e hora, numa turma que simula na
# noite de terça, diriam quem estava na sala. Semana anda na direção disso.
#
# Então esta função NÃO fatia mês em semana. Ela desenha a série temporal que o
# Hub tiver publicado: usa `porSemana` se ela existir no espelho, e `porMes` se
# não. Enquanto o Hub mandar só meses, é mês que aparece -- e o dia em que a
# semana for uma decisão tomada lá (com o mesmo piso de dez, com a supressão
# complementar, e com o texto da metodologia atualizado junto), o gráfico passa
# a ser semanal sozinho, sem tocar neste arquivo.
sub serie_temporal_das_simulacoes {
    my ($d) = @_;
    for my $chave (qw(porSemana porMes)) {
        my $serie = $d->{$chave};
        next unless $serie && ref $serie eq 'ARRAY' && @$serie;
        # Um ponto só não é evolução: é um número, e a tabela já o mostra.
        my $publicados = grep { !$_->{suprimida} && defined $_->{denominador} } @$serie;
        next if $publicados < 2;
        return ($chave, $serie);
    }
    return ();
}

sub rotulo_periodo {
    my ($r) = @_;
    my @MES = qw(jan fev mar abr mai jun jul ago set out nov dez);
    if ($r =~ /^(\d{4})-W(\d{1,2})$/i)  { return 'sem. ' . (0 + $2) . '/' . substr($1, 2, 2); }
    if ($r =~ /^(\d{4})-(\d{2})$/ && $2 >= 1 && $2 <= 12) {
        return $MES[$2 - 1] . '/' . substr($1, 2, 2);
    }
    return $r;
}

sub grafico_evolucao_html {
    my ($d, $no_hub) = @_;
    my ($chave, $serie) = serie_temporal_das_simulacoes($d);
    return '' unless $chave;

    my $por = $chave eq 'porSemana' ? 'semana' : 'mês';
    my $max = 1;
    my $soma = 0;
    for my $p (@$serie) {
        next if $p->{suprimida} || !defined $p->{denominador};
        $max  = $p->{denominador} if $p->{denominador} > $max;
        $soma += $p->{denominador};
    }

    my (@colunas, @linhas);
    for my $p (@$serie) {
        my $bruto = $p->{rotulo} // '';
        my $rot   = esc(rotulo_periodo($bruto));
        my $orig  = esc($bruto);

        if ($p->{suprimida}) {
            my $motivo = ($p->{motivo} // '') eq 'complementar'
                ? 'protegido junto com outro recorte'
                : 'menos de 10 simulações';
            push @colunas,
                qq{<div class="g-col g-col-prot" data-v="prot" tabindex="0" role="listitem" }
              . qq{aria-label="$rot: recorte protegido, $motivo">}
              . qq{<span class="g-tip">Recorte protegido: $motivo</span>}
              . qq{<span class="g-val" aria-hidden="true">—</span>}
              . qq{<div class="g-bar"></div>}
              . qq{<span class="g-ano" aria-hidden="true">$rot</span></div>};
            push @linhas,
                qq{<tr><td>$orig</td><td class="num-suprimido">— <span>$motivo</span></td></tr>};
            next;
        }

        my $n   = $p->{denominador} // 0;
        my $h   = sprintf('%.1f', $n / $max * 100);
        my $sim = $n == 1 ? '1 simulação' : "$n simulações";
        my $cob = defined $p->{percentual}
            ? "<span>Cobertura de avaliação: $p->{percentual}%</span>" : '';
        push @colunas,
            qq{<div class="g-col" data-v="$n" tabindex="0" role="listitem" aria-label="$rot: $sim">}
          . qq{<span class="g-tip"><b>$rot</b>$cob</span>}
          . qq{<span class="g-val" aria-hidden="true">$n</span>}
          . qq{<div class="g-bar" style="--h:$h%"></div>}
          . qq{<span class="g-ano" aria-hidden="true">$rot</span></div>};
        push @linhas, qq{<tr><td>$orig</td><td>@{[ num_br($n) ]}</td></tr>};
    }

    # O espelho publica o recorte por período só das simulações que passaram
    # pela avaliação por competência -- que são menos do que o total do
    # SimulaPacientes. Dizer "simulações por mês" sem dizer isso faria o leitor
    # somar as colunas e achar que o total da página está errado.
    my $ressalva = (defined $no_hub && $soma && $soma != $no_hub)
        ? " As colunas somam @{[ num_br($soma) ]} das @{[ num_br($no_hub) ]} simulações do SimulaPacientes:"
          . ' o recorte por período cobre as que passaram pela avaliação por competência.'
        : '';

    my $colunas = join "\n", @colunas;
    my $trs     = join "\n", @linhas;
    my $cab     = $por eq 'semana' ? 'Semana' : 'Mês';

    # Mesma decisão da rosca: rótulo em caixa alta e traço, como os blocos
    # vizinhos, em vez do cartão de vidro da vitrine.
    return <<HTML;
<figure class="numeros-bloco evo-figura">
<h3>Evolução do SimulaPacientes</h3>
<p class="numeros-sub">Simulações por $por, desde a entrada do SimulaPacientes.$ressalva</p>
<div class="g-plot" role="list" aria-label="Simulações do SimulaPacientes por $por">
$colunas
</div>
<details class="g-tabela">
<summary>Ver a série completa em texto</summary>
<table>
<thead><tr><th scope="col">$cab</th><th scope="col">Simulações</th></tr></thead>
<tbody>
$trs
</tbody>
</table>
</details>
</figure>
HTML
}

sub numeros_das_simulacoes_html {
    my ($p) = @_;
    $p = '' unless defined $p;
    my $d = dados_das_simulacoes();

    # Sem o arquivo, a página DIZ que não tem número -- e não mostra zero.
    # "Não consegui ler" e "não houve" são coisas diferentes, e um número
    # institucional errado é lido como fato.
    return q{<p class="nota">Os números ainda não foram publicados nesta versão do site. }
         . q{Eles são atualizados automaticamente a partir do SimulaPacientes.</p>}
      unless $d && ref $d eq 'HASH';

    my $t = $d->{totais} || {};
    my $hist = num_br($t->{baseHistorica});
    my $hub  = defined $t->{noHub} ? num_br($t->{noHub}) : 'menos de 10';
    my $soma = defined $t->{soma}  ? num_br($t->{soma})  : undef;

    my @out;
    push @out, qq{<div class="numeros-topo">};
    push @out, qq{<p class="numeros-grande">} . (defined $soma ? $soma : $hist) . q{</p>};
    push @out, defined $soma
        ? q{<p class="numeros-legenda">atendimentos simulados desde 2016</p>}
        : q{<p class="numeros-legenda">atendimentos simulados até a chegada do SimulaPacientes</p>};
    push @out, qq{</div>};

    push @out, qq{<p>Deste total, <strong>$hist</strong> vêm da base histórica, }
             . qq{apurada em 18/08/2026 — simulações impressas, em formulários e em }
             . qq{assistentes anteriores. O SimulaPacientes contribui com <strong>$hub</strong>.</p>};

    push @out, grafico_pizza_composicao_html(
        composicao_ordenada($t->{composicao}), 'De onde vêm as simulações');
    push @out, tabela_de_celulas('Por competência',       $d->{porCompetencia}, coluna => 'Competência');
    push @out, tabela_de_celulas('Por condição clínica',  $d->{porCondicao},    coluna => 'Condição');
    push @out, tabela_de_celulas('Por grupo clínico',     $d->{porGrupo},       coluna => 'Grupo');

    # A evolução vira gráfico quando há série para desenhar; enquanto houver um
    # período só, a tabela de sempre continua no lugar dela.
    my ($chave_evo) = serie_temporal_das_simulacoes($d);
    my $evolucao = grafico_evolucao_html($d, $t->{noHub});
    push @out, $evolucao if $evolucao;
    push @out, tabela_de_celulas('Mês a mês', $d->{porMes}, coluna => 'Mês')
        unless $evolucao && $chave_evo eq 'porMes';

    push @out, tabela_de_celulas('O que mais escapa',     $d->{condutasQueMaisEscapam},
        coluna => 'Conduta esperada');

    if (my $s = $d->{suprimidas}) {
        if (ref $s eq 'ARRAY' && @$s) {
            my @itens = map { '<li>' . esc($_->{bloco}) . ': ' . $_->{quantas} . '</li>' } @$s;
            push @out, q{<h3>O que ficou de fora, e quanto</h3>}
                     . q{<p>Recortes pequenos não são publicados. Estes blocos esconderam células:</p>}
                     . '<ul>' . join('', @itens) . '</ul>';
        }
    }

    if (my $m = $d->{metodologia}) {
        push @out, q{<h3>Como estes números são apurados</h3><p class="nota">} . esc($m) . q{</p>};
    }

    if (my $g = $d->{geradoEm}) {
        my ($dia) = $g =~ /^(\d{4}-\d{2}-\d{2})/;
        push @out, q{<p class="nota">Atualizado em } . esc($dia // $g)
                 . qq{. <a href="${p}assets/dados-simulacoes.json">Baixar os dados em JSON</a>.</p>};
    }

    return join("\n", grep { length } @out);
}

sub nav_html {
    my ($p, $current_cat) = @_;
    my $h = qq{<ul>\n};
    my $cur = (!defined $current_cat || $current_cat eq 'inicio') ? ' aria-current="page"' : '';
    my $home = $p eq '' ? './' : $p;
    $h .= qq{<li><a href="$home"$cur>Início</a></li>\n};
    for my $sec (@NAV) {
        my ($first_slug) = @{ $sec->{items}[0] };
        my $active = defined $current_cat && grep { $_->[0] eq $current_cat } @{ $sec->{items} };
        my $cc = $active ? ' aria-current="page"' : '';
        $h .= qq{<li><a href="$p$first_slug/"$cc>$sec->{label} <span class="caret">▾</span></a>\n<div class="dropdown">\n};
        for my $it (@{ $sec->{items} }) {
            my ($slug, $label) = @$it;
            $h .= qq{<a href="$p$slug/">$label</a>\n};
        }
        $h .= qq{</div>\n</li>\n};
    }
    $h .= qq{</ul>};
    return $h;
}

sub header_html {
    my ($p, $cat) = @_;
    my $home = $p eq '' ? './' : $p;
    my $nav = nav_html($p, $cat);
    return <<HTML;
<a class="skip-link" href="#conteudo">Pular para o conteúdo</a>
<header class="site">
<div class="header-inner">
<a class="brand" href="$home">
<img class="brand-mark" src="${p}assets/img/logo.png" alt="Logo da Escola de Pacientes">
<span class="brand-name"><strong>Escola de Pacientes</strong></span>
</a>
<input type="checkbox" id="nav-toggle" aria-hidden="true">
<label class="nav-toggle" for="nav-toggle" aria-label="Abrir menu"><span></span><span></span><span></span></label>
<nav class="main" aria-label="Navegação principal">
$nav
<a class="btn-simula" href="https://escoladepacientes.com/simula-pacientes/" title="SimulaPacientes — pacientes digitais com inteligência artificial">
<span class="msym" aria-hidden="true">smart_toy</span>
<span class="btn-simula-txt">SimulaPacientes</span>
</a>
<a class="btn-nucleo" href="https://adm-epdf.vercel.app" target="_blank" rel="noopener" title="Núcleo EP — sistema de gestão do grupo (acesso restrito aos integrantes)">
<svg viewBox="0 0 32 32" fill="none" aria-hidden="true" focusable="false"><rect x="2.8" y="2.8" width="26.4" height="26.4" rx="8" stroke="currentColor" stroke-width="3"/><path d="M9.6 16.4 L14 20.8 L22.8 11.2" stroke="currentColor" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round"/></svg>
<span class="btn-nucleo-txt">Núcleo EP</span>
</a>
<button class="theme-toggle" id="theme-toggle" aria-label="Alternar tema" title="Tema claro/escuro"><span class="msym">dark_mode</span></button>
<div class="searchbox">
<input id="busca" type="search" placeholder="Buscar página…" aria-label="Buscar páginas do site" autocomplete="off" data-root="$p">
<div id="busca-resultados" class="search-results" role="listbox"></div>
</div>
</nav>
</div>
</header>
HTML
}

sub footer_html {
    my ($p) = @_;
    my $y = (localtime)[5] + 1900;
    return <<HTML;
<footer class="site">
<div class="wrap">
<div class="cols">
<div>
<h4>Escola de Pacientes</h4>
<p>Grupo de atividades acadêmicas coordenado pelo Prof. Dr. Estêvão Cubas Rolim, em atividade desde 2016 no Distrito Federal. Reúne formação em saúde, educação permanente, produção científica e integração ensino-serviço-comunidade, junto à Universidade de Brasília (UnB) e à Secretaria de Estado de Saúde do DF (SES-DF).</p>
</div>
<div>
<h4>Comece por aqui</h4>
<ul>
<li><a href="${p}para-pacientes/">Pacientes e comunidade</a></li>
<li><a href="${p}para-estudantes/">Estudantes</a></li>
<li><a href="${p}para-pesquisadores/">Pesquisadores</a></li>
<li><a href="${p}para-profissionais/">Profissionais e gestores</a></li>
<li><a href="${p}az/">Acervo completo (A–Z)</a></li>
</ul>
</div>
<div>
<h4>Ciência</h4>
<ul>
<li><a href="${p}publicacoes/">Publicações</a></li>
<li><a href="${p}congressos/">Congressos</a></li>
<li><a href="${p}ciencia-banco-de-citacoes/">Banco de citações</a></li>
<li><a href="${p}premios/">Prêmios</a></li>
</ul>
</div>
<div>
<h4>Recursos</h4>
<ul>
<li><a href="https://www.youtube.com/channel/UCMiHRdmhduWggK_c-UYEbLQ" target="_blank" rel="noopener">Canal no YouTube</a></li>
<li><a href="https://www.instagram.com/unidosnobem_estar" target="_blank" rel="noopener">Instagram</a></li>
<li><a href="https://bit.ly/2BM7eVp" target="_blank" rel="noopener">Pasta de orientações</a></li>
<li><a href="https://bit.ly/30gwCfu" target="_blank" rel="noopener">Pasta de atendimento</a></li>
<li><a href="http://lattes.cnpq.br/3012202638503151" target="_blank" rel="noopener">Currículo Lattes</a></li>
<li><a href="https://orcid.org/0000-0001-7220-6276" target="_blank" rel="noopener">ORCID</a></li>
</ul>
</div>
</div>
<div class="fineprint">
<span>© 2016–$y Escola de Pacientes · Universidade de Brasília · SES-DF</span>
<span><a href="http://www.escoladepacientes.com" target="_blank" rel="noopener">Versão anterior do site</a></span>
</div>
</div>
</footer>
HTML
}

sub page_shell {
    my (%a) = @_;
    my $head_extra = $a{head_extra} // '';
    my $body_class = $a{body_class} ? qq{ class="$a{body_class}"} : '';
    my $canon = $a{canon} // $SITE_URL;
    # o 404 é a única página que não ganha QR: ninguém divulga um endereço que
    # não existe
    my $qr = qr_figure_html($a{qr_url}, $a{qr_dir});
    my $ogimg = "$SITE_URL/assets/img/og-card-v2.jpg";
    return <<HTML;
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<script>(function(){try{var t=localStorage.getItem('tema');if(t==='dark'||t==='light'){document.documentElement.setAttribute('data-theme',t);}}catch(e){}})();</script>
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$a{title}</title>
<meta name="description" content="$a{desc}">
<link rel="canonical" href="$canon">
<meta property="og:type" content="website">
<meta property="og:site_name" content="$SITE">
<meta property="og:title" content="$a{title}">
<meta property="og:description" content="$a{desc}">
<meta property="og:url" content="$canon">
<meta property="og:image" content="$ogimg">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta property="og:locale" content="pt_BR">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="$a{title}">
<meta name="twitter:description" content="$a{desc}">
<meta name="twitter:image" content="$ogimg">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Google+Sans:ital,wght\@0,400;0,500;0,700;1,400&family=Google+Sans+Text:ital,wght\@0,400;0,500;0,700;1,400&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:opsz,wght,FILL,GRAD\@20..48,100..700,0..1,-50..200&display=swap">
<link rel="stylesheet" href="$a{p}assets/style.css">
<link rel="icon" href="$a{p}assets/img/logo.png">
$head_extra
</head>
<body$body_class>
$a{header}
$a{body}
$qr
$a{footer}
<script src="$a{p}assets/search-index.js" defer></script>
<script src="$a{p}assets/search.js" defer></script>
<script src="$a{p}assets/reveal.js" defer></script>
<script src="$a{p}assets/theme.js" defer></script>
<script src="$a{p}assets/toc.js" defer></script>
<script src="$a{p}assets/brilho.js" defer></script>
</body>
</html>
HTML
}

sub write_file {
    my ($path, $data) = @_;
    $data = versionar($data) if $path =~ /\.html$/;
    make_path(dirname($path));
    open my $fh, '>:encoding(UTF-8)', $path or die "$path: $!";
    print $fh $data; close $fh;
}

# ---------------- índice de busca ----------------
# Gerado antes das páginas: elas citam este arquivo, e a citação precisa já
# carregar a versão certa dele.
{
    my @entries;
    push @entries, { t => 'Temas Clínicos (índice)', p => 'temas', c => 'Temas Clínicos' };
    push @entries, { t => $_->{busca}, p => $_->{slug}, c => $_->{secao} } for @PAGINAS_HTML;
    for my $path (sort keys %content) {
        my ($top) = split m{/}, $path;
        my $cat = $page{$top} ? $cat_label{ $page{$top}{cat} } // '' : '';
        # os textos da coluna aparecem na busca sob o nome dela, não sob "A Escola"
        $cat = 'Coluna do Estêvão' if $path =~ m{^\Q$COLUNA\E/};
        my $t = title_of($path);
        push @entries, { t => $t, p => $path, c => $cat };
    }
    my $json = join ",\n", map {
        my %e = %$_;
        for (values %e) { s/\\/\\\\/g; s/"/\\"/g; }
        qq{{"t":"$e{t}","p":"$e{p}","c":"$e{c}"}}
    } @entries;
    my $js = "window.SEARCH_INDEX = [\n$json\n];\n";
    # este arquivo não existe em build/assets/, então a versão sai do que
    # acabou de ser montado aqui
    $ASSET_VER{'search-index.js'} = substr(md5_hex(encode_utf8($js)), 0, 8);
    write_file("$OUT/assets/search-index.js", $js);
}

# ---------------- páginas de conteúdo ----------------
my $n = 0;
for my $path (sort keys %content) {
    my $depth = () = $path =~ m{/}g;
    my $p = '../' x ($depth + 1);
    my $title = title_of($path);
    my ($top) = split m{/}, $path;
    my $cat = $page{$top} ? $page{$top}{cat} : '';
    my $catlabel = $cat_label{$cat} // '';

    my $body_html = md_to_html($content{$path}, $p);

    # recepção festiva no topo da página de boas-vindas
    if ($path eq 'boas-vindas') {
        $body_html = recepcao_html() . $body_html;
    }

    # retrato do coordenador na página de apresentação
    if ($path eq 'dr-estevao-rolim') {
        $body_html = qq{<figure class="portrait"><img src="${p}assets/img/dr-estevao.jpg" alt="Foto do Prof. Dr. Estêvão Cubas Rolim"><figcaption>Prof. Dr. Estêvão Cubas Rolim</figcaption></figure>\n} . $body_html;
    }

    # a coluna tem listagem própria, cronológica — não o índice alfabético
    if ($path eq $COLUNA) {
        $body_html .= "\n" . coluna_lista_html($p);
    }

    # apresentação de cada texto da coluna: data e chamada no alto, assinatura no pé
    if (my $cm = $coluna_meta{$path}) {
        my $data  = data_extenso($cm->{data});
        my $topo  = qq{<p class="cl-kicker"><a href="$p$COLUNA/">Coluna do Estêvão</a>};
        $topo    .= qq{<span class="sep">·</span><time datetime="$cm->{data}">$data</time>} if $data;
        $topo    .= qq{</p>};
        $topo    .= qq{<p class="cl-lead">@{[esc($cm->{chamada})]}</p>} if $cm->{chamada};
        $body_html = qq{<div class="coluna-topo">$topo</div>\n} . $body_html . coluna_rodape_html($p, $path);
    }

    # lista de subpáginas ao final da página-mãe
    if ($children{$path} && $path ne $COLUNA) {
        my @kids = @{ $children{$path} };
        my $count = scalar @kids;
        my $items = join "\n", map {
            my $t    = esc(em_caracteres(title_of($_)));
            my $slug = em_caracteres($_);
            qq{<li data-t="\L$t\E"><a href="$p$slug/">$t</a></li>}
        } sort { lc(title_of($a)) cmp lc(title_of($b)) } @kids;
        my $filter = '';
        my $script = '';
        if ($count > 30) {
            $filter = qq{<div class="filterbox"><input id="filtro" type="search" placeholder="Filtrar por autor, ano ou palavra-chave…" aria-label="Filtrar itens"><p class="filter-count" id="filtro-n">$count itens</p></div>};
            $script = <<'JS';
<script>
const inp = document.getElementById('filtro');
const itens = [...document.querySelectorAll('.childlist li')];
const nEl = document.getElementById('filtro-n');
inp.addEventListener('input', () => {
  const q = inp.value.trim().toLowerCase();
  let n = 0;
  itens.forEach(li => { const v = !q || li.dataset.t.includes(q); li.style.display = v ? '' : 'none'; if (v) n++; });
  nEl.textContent = n + (n === 1 ? ' item' : ' itens');
});
</script>
JS
        }
        $body_html .= qq{\n<h2 id="indice">Índice de páginas ($count)</h2>\n$filter\n<ul class="childlist">\n$items\n</ul>\n$script};
    }

    my $crumb = qq{<a href="$p">Início</a><span class="sep">›</span>};
    if ($depth > 0) {
        my $ptitle = esc(title_of($top));
        $crumb .= qq{<a href="$p$top/">$ptitle</a><span class="sep">›</span>};
    } elsif ($catlabel) {
        $crumb .= qq{<span>$catlabel</span><span class="sep">›</span>};
    }
    $crumb .= '<span>' . esc($title) . '</span>';

    my $body = <<HTML;
<div class="page-hero"><div class="wrap-narrow">
<nav class="breadcrumb" aria-label="Localização">$crumb</nav>
<h1>@{[esc($title)]}</h1>
</div></div>
<article class="content" id="conteudo"><div class="wrap-narrow">
$body_html
</div></article>
HTML

    # tema de cor por página
    my %tema = (
        'para-pacientes'     => 'theme-verde',
        'para-estudantes'    => 'theme-azul',
        'para-pesquisadores' => 'theme-roxo',
        'para-profissionais' => 'theme-laranja',
        'boas-vindas'        => 'theme-teal',
    );
    # a coluna inteira — página principal e cada texto — usa o mesmo tom quente
    my $tema_pagina = ($path eq $COLUNA || $coluna_meta{$path}) ? 'theme-coluna' : ($tema{$path} // '');
    # confetes de boas-vindas 🎉
    my $extra = $path eq 'boas-vindas'
        ? qq{<script src="${p}assets/confetti.js" defer></script>}
        : '';

    write_file("$OUT/$path/index.html", page_shell(
        qr_url => "$SITE_URL/$path/",
        qr_dir => "$OUT/$path",
        title  => esc($title) . " — $SITE",
        desc   => esc($title) . " — material da $SITE: educação em saúde, educação permanente e formação em saúde.",
        p      => $p,
        canon  => "$SITE_URL/$path/",
        header => header_html($p, $top),
        body   => $body,
        footer => footer_html($p),
        body_class => $tema_pagina,
        head_extra => $extra,
    ));
    $n++;
}

# ---------------- índice de temas clínicos ----------------
{
    my $p = '../';
    my $groups_html = '';
    for my $g (@group_order) {
        my @slugs = grep { $page{$_}{cat} eq 'temas' && $page{$_}{group} eq $g } @order;
        next unless @slugs;
        my $items = join "\n", map { qq{<a href="$p$_/">$page{$_}{title}</a>} }
                    sort { lc($page{$a}{title}) cmp lc($page{$b}{title}) } @slugs;
        $groups_html .= qq{<div class="topic-group"><h2>$g</h2><div class="topic-grid">\n$items\n</div></div>\n};
    }
    my $body = <<HTML;
<div class="page-hero"><div class="wrap">
<nav class="breadcrumb" aria-label="Localização"><a href="$p">Início</a><span class="sep">›</span><span>Temas Clínicos</span></nav>
<h1>Temas Clínicos</h1>
</div></div>
<article class="content" id="conteudo"><div class="wrap">
<p class="section-lead">Materiais de orientação, referência e educação em saúde organizados por área. Cada tema reúne impressos para pacientes, documentos técnicos e material de referência para estudo.</p>
$groups_html
</div></article>
HTML
    write_file("$OUT/temas/index.html", page_shell(
        qr_url => "$SITE_URL/temas/",
        qr_dir => "$OUT/temas",
        title  => "Temas Clínicos — $SITE",
        desc   => "Índice de temas clínicos da $SITE, organizados por área.",
        p      => $p,
        header => header_html($p, 'temas'),
        body   => $body,
        footer => footer_html($p),
    ));
    $n++;
}

# ---------------- índice A–Z do acervo completo ----------------
{
    my $p = '../';
    # agrupa páginas de topo por inicial; subpáginas ficam com a mãe
    my %by_letter;
    for my $slug (grep { !m{/} } keys %content, keys %PAGINA_HTML) {
        my $t = $PAGINA_HTML{$slug} ? $PAGINA_HTML{$slug}{titulo} : title_of($slug);
        my $letter = uc substr($t =~ s/^\s+//r, 0, 1);
        $letter = '#' unless $letter =~ /\p{L}/;
        $letter =~ tr/ÁÀÂÃÉÊÍÓÔÕÚÇ/AAAAEEIOOOUC/;
        push @{ $by_letter{$letter} }, [$slug, $t];
    }
    my $list = '';
    for my $l (sort keys %by_letter) {
        my @items = sort { lc($a->[1]) cmp lc($b->[1]) } @{ $by_letter{$l} };
        $list .= qq{<div class="topic-group"><h2 id="letra-$l">$l</h2><div class="topic-grid">\n};
        for my $it (@items) {
            my ($slug, $t) = @$it;
            my $nf = $children{$slug} ? scalar(@{ $children{$slug} }) : 0;
            my $extra = $nf ? ' <small>(' . $nf . ($nf == 1 ? ' subpágina' : ' subpáginas') . ')</small>' : '';
            $list .= qq{<a href="$p$slug/">@{[esc($t)]}$extra</a>\n};
        }
        $list .= qq{</div></div>\n};
    }
    my $letters_nav = join ' · ', map { qq{<a href="#letra-$_">$_</a>} } sort keys %by_letter;
    my $total = scalar(keys %content) + scalar(keys %PAGINA_HTML);
    my $body = <<HTML;
<div class="page-hero"><div class="wrap">
<nav class="breadcrumb" aria-label="Localização"><a href="$p">Início</a><span class="sep">›</span><span>Acervo</span><span class="sep">›</span><span>Índice A–Z</span></nav>
<h1>Acervo completo — Índice A–Z</h1>
</div></div>
<article class="content" id="conteudo"><div class="wrap">
<p class="section-lead">Todas as $total páginas do acervo da Escola de Pacientes. Use a busca no topo do site ou navegue por letra: $letters_nav</p>
$list
</div></article>
HTML
    write_file("$OUT/az/index.html", page_shell(
        qr_url => "$SITE_URL/az/",
        qr_dir => "$OUT/az",
        title  => "Índice A–Z — $SITE",
        desc   => "Índice completo de todas as páginas do acervo da $SITE.",
        p      => $p,
        header => header_html($p, 'az'),
        body   => $body,
        footer => footer_html($p),
    ));
    $n++;
}

# ---------------- recepção da página de boas-vindas ----------------
# Bloco festivo que abre a página. A ideia é que quem chega sinta que entrou
# em algum lugar, antes de encarar o conteúdo operacional que vem depois.
sub recepcao_html {
    # os passos vêm do checklist de entrada que já existe no conteúdo da página
    my @passos = (
        ['orcid',     'fingerprint',  'ORCID',            'Seu identificador acadêmico, para sempre'],
        ['lattes',    'article',      'Lattes',           'O currículo oficial brasileiro'],
        ['scholar',   'school',       'Google Scholar',   'A vitrine pública da sua produção'],
        ['drive',     'folder_open',  'Google Drive',     'Onde ficam os materiais do grupo'],
        ['nucleo',    'hub',          'Núcleo EP',        'Peça seu acesso à coordenação'],
    );
    my $total = scalar @passos;
    my $itens = '';
    for my $p (@passos) {
        my ($id, $ico, $nome, $desc) = @$p;
        $itens .= qq{<li><label class="rc-passo">}
                . qq{<input type="checkbox" data-passo="$id">}
                . qq{<span class="rc-check" aria-hidden="true"></span>}
                . qq{<span class="rc-ico"><span class="msym">$ico</span></span>}
                . qq{<span class="rc-txt"><b>@{[esc($nome)]}</b><small>@{[esc($desc)]}</small></span>}
                . qq{</label></li>\n};
    }

    # a trajetória é a mesma que o sistema do grupo acompanha
    my @etapas = (
        ['waving_hand',   'Boas-vindas',       'Você está aqui'],
        ['menu_book',     'Treinamento',       'Método científico e as ferramentas do grupo'],
        ['rocket_launch', 'Primeira atividade','Sua entrada de fato em um projeto'],
        ['workspace_premium', 'Primeiro artigo', 'A publicação que leva o seu nome'],
    );
    my $trilha = '';
    for my $i (0 .. $#etapas) {
        my ($ico, $nome, $desc) = @{ $etapas[$i] };
        my $agora = $i == 0 ? ' rc-agora' : '';
        $trilha .= qq{<li class="rc-etapa$agora">}
                 . qq{<span class="rc-etapa-ico"><span class="msym">$ico</span></span>}
                 . qq{<b>@{[esc($nome)]}</b><small>@{[esc($desc)]}</small>}
                 . qq{</li>\n};
    }

    return <<HTML;
<section class="recepcao" aria-labelledby="rc-titulo">
<div class="rc-topo">
<p class="rc-kicker">Que bom que você chegou</p>
<h2 id="rc-titulo">Seja muito bem-vindo(a) à<br>Escola de Pacientes</h2>
<p class="rc-lead">A partir de hoje você faz parte de um grupo que, desde 2016, leva educação em saúde para dentro do SUS — e que já publicou 42 trabalhos, recebeu 12 reconhecimentos e realizou 34.026 atendimentos. Nada disso aconteceu sem gente nova chegando. Agora é a sua vez.</p>
<button type="button" class="rc-festa" id="rc-festa">Soltar os confetes de novo</button>
</div>

<div class="rc-grade">
<div class="rc-bloco">
<h3>Seus primeiros passos</h3>
<p class="rc-nota">Marque conforme for concluindo — fica salvo neste navegador, só para você se organizar.</p>
<ul class="rc-passos">
$itens</ul>
<p class="rc-progresso" id="rc-progresso" data-total="$total" aria-live="polite">0 de $total concluídos</p>
</div>

<div class="rc-bloco">
<h3>Por onde você vai passar</h3>
<p class="rc-nota">O caminho que todo integrante percorre no grupo.</p>
<ol class="rc-trilha">
$trilha</ol>
</div>
</div>
</section>
HTML
}

# ---------------- gráfico: prêmios e reconhecimentos por ano ----------------
# Os números saem da seção PREMIOS de vitrine-dados.md — a mesma lista que
# alimenta a página de prêmios. Cadastrou um prêmio novo lá, o gráfico muda
# sozinho. Nenhum número é digitado à mão aqui.
sub premios_por_ano {
    open my $fh, '<:encoding(UTF-8)', "$ROOT/vitrine-dados.md" or return ();
    local $/; my $txt = <$fh>; close $fh;
    my ($bloco) = $txt =~ /^##\s+PREMIOS\s*$(.*?)^##\s/ms;
    return () unless $bloco;
    my %por_ano;
    for my $l (split /\n/, $bloco) {
        next unless $l =~ /^-\s*(\d{4})\s*\|\s*([^|]+?)\s*(?:\|.*)?$/;
        push @{ $por_ano{$1} }, $2;
    }
    return %por_ano;
}

sub grafico_premios_html {
    my %ano = premios_por_ano();
    return '' unless %ano;

    my $ini = 2016;                                   # criação da Escola de Pacientes
    my @anos_todos = sort { $a <=> $b } keys %ano;
    my $fim = $anos_todos[-1];
    return '' if $fim < $ini;

    my $antes = 0; $antes += scalar @{ $ano{$_} } for grep { $_ <  $ini } @anos_todos;
    my $desde = 0; $desde += scalar @{ $ano{$_} } for grep { $_ >= $ini } @anos_todos;

    my $max = 1;
    for my $a ($ini .. $fim) {
        my $n = $ano{$a} ? scalar @{ $ano{$a} } : 0;
        $max = $n if $n > $max;
    }

    my $colunas = '';
    for my $a ($ini .. $fim) {
        my @p = $ano{$a} ? @{ $ano{$a} } : ();
        my $n = scalar @p;
        my $h = sprintf('%.1f', $n / $max * 100);
        my $rot = $n == 1 ? '1 prêmio' : "$n prêmios";
        my $tip = $n
            ? join('', map { '<b>' . esc($_) . '</b>' } @p)
            : '<span>Nenhum prêmio registrado neste ano</span>';
        $colunas .= qq{<div class="g-col" data-v="$n" tabindex="0" role="listitem" aria-label="$a: $rot">}
                  . qq{<span class="g-tip">$tip</span>}
                  . qq{<span class="g-val" aria-hidden="true">$n</span>}
                  . qq{<div class="g-bar" style="--h:$h%"></div>}
                  . qq{<span class="g-ano" aria-hidden="true">$a</span>}
                  . qq{</div>\n};
    }

    my $linhas = '';
    for my $a (reverse @anos_todos) {
        for my $p (@{ $ano{$a} }) {
            $linhas .= qq{<tr><td>$a</td><td>@{[esc($p)]}</td></tr>\n};
        }
    }

    my @anos_antes = grep { $_ < $ini } @anos_todos;
    my $nota = $antes
        ? qq{ Outros $antes, de @{[ join(' e ', @anos_antes) ]}, são anteriores ao grupo e ficam fora do gráfico — a lista completa está abaixo.}
        : '';

    return <<HTML;
<figure class="grafico">
<figcaption>
<p class="g-titulo">Prêmios e reconhecimentos por ano</p>
<p class="g-sub">Os $desde reconhecimentos recebidos desde a criação da Escola, em 2016.$nota</p>
</figcaption>
<div class="g-plot" role="list" aria-label="Prêmios por ano, de $ini a $fim">
$colunas</div>
<details class="g-tabela">
<summary>Ver a lista completa em texto</summary>
<table>
<thead><tr><th scope="col">Ano</th><th scope="col">Reconhecimento</th></tr></thead>
<tbody>
$linhas</tbody>
</table>
</details>
</figure>
HTML
}

# ---------------- carrossel de fotos da página inicial ----------------
# Cada foto só entra se o arquivo existir em build/assets/img/. Enquanto
# nenhuma delas estiver na pasta, a home mostra a foto estática de sempre
# (unb-campus.jpg) — o site nunca fica sem imagem.
my @HERO_SLIDES = (
    ['unb-icc-jardim.jpg',
     'Jardim entre as alas do Instituto Central de Ciências da UnB, com uma palmeira ao centro e as colunas de concreto dos dois lados, sob céu azul',
     'Jardim entre as alas do Instituto Central de Ciências (ICC) — Campus Darcy Ribeiro, UnB · Foto: Júlio Minasi / Secom UnB'],
    ['unb-fs-fm.jpg',
     'Estudantes conversando e caminhando na entrada do prédio da Faculdade de Saúde e da Faculdade de Medicina da UnB, ao entardecer',
     'Entrada da Faculdade de Saúde e da Faculdade de Medicina (FS–FM) — Campus Darcy Ribeiro, UnB · Foto: Beto Monteiro / Secom UnB'],
    ['unb-primaveras.jpg',
     'Primaveras cor-de-rosa floridas no canteiro que acompanha o corredor do Instituto Central de Ciências',
     'Primaveras em flor ao longo do corredor do ICC — Campus Darcy Ribeiro, UnB · Foto: Secom UnB'],
    ['unb-estudo.jpg',
     'Estudante sentada em um banco de concreto no jardim do campus, escrevendo em um caderno apoiado no colo',
     'Estudo no jardim do ICC — Campus Darcy Ribeiro, UnB · Foto: Secom UnB'],
    ['unb-jardim-interno.jpg',
     'Jardineiro cuidando dos canteiros floridos do jardim entre as alas do Instituto Central de Ciências',
     'Cuidado diário dos jardins do ICC — Campus Darcy Ribeiro, UnB · Foto: Secom UnB'],
);

# foto usada enquanto o carrossel não tiver imagens
my @HERO_FALLBACK = ('unb-campus.jpg',
    'Corredor do Instituto Central de Ciências (Minhocão) no Campus Darcy Ribeiro da UnB',
    'Instituto Central de Ciências (ICC) — Campus Darcy Ribeiro, Universidade de Brasília · Foto: Beto Monteiro / Secom UnB');

sub hero_figure_html {
    my ($file, $alt, $cap, $eager) = @_;
    my ($base, $ext) = $file =~ /^(.*)\.([^.]+)$/;

    # Se existirem variantes foto-800.jpg / -1400 / -2000, o navegador escolhe
    # a menor que serve para a tela dele: no celular baixa ~100 KB em vez de
    # ~560 KB. Sem variantes, usa o arquivo único — quem acrescentar uma foto
    # nova não precisa gerar tamanho nenhum.
    my @larguras = grep { -e "$ROOT/assets/img/$base-$_.$ext" } (800, 1400, 2000);
    my $srcset = @larguras
        ? ' srcset="' . join(', ', map { "assets/img/$base-$_.$ext ${_}w" } @larguras) . '" sizes="100vw"'
        : '';

    # A primeira foto carrega de imediato. As outras só quando o carrossel vai
    # mostrá-las (o carousel.js troca data-src por src). Sem JavaScript, só a
    # primeira aparece de qualquer forma, então nada se perde.
    my $fonte = $eager
        ? qq{ src="assets/img/$file"$srcset fetchpriority="high"}
        : do { (my $s = $srcset) =~ s/ srcset=/ data-srcset=/; qq{ data-src="assets/img/$file"$s} };

    return qq{<img$fonte alt="@{[esc($alt)]}" decoding="async">\n}
         . qq{<figcaption>@{[esc($cap)]}</figcaption>};
}

sub hero_carousel_html {
    my @have = grep { -e "$ROOT/assets/img/$_->[0]" } @HERO_SLIDES;
    @have = (\@HERO_FALLBACK) unless @have;
    my $total = scalar @have;

    # uma foto só: figura estática, sem controles nem script
    if ($total == 1) {
        my ($f, $alt, $cap) = @{ $have[0] };
        return qq{<figure class="hero-banner">\n} . hero_figure_html($f, $alt, $cap, 1) . qq{\n</figure>};
    }

    my ($slides, $dots) = ('', '');
    for my $i (0 .. $#have) {
        my ($f, $alt, $cap) = @{ $have[$i] };
        my $num = $i + 1;
        my $on  = $i == 0;
        $slides .= qq{<figure class="hc-slide@{[ $on ? ' is-active' : '' ]}" role="group" }
                 . qq{aria-roledescription="slide" aria-label="Foto $num de $total"}
                 . qq{@{[ $on ? '' : ' aria-hidden="true"' ]}>\n}
                 . hero_figure_html($f, $alt, $cap, $on) . qq{\n</figure>\n};
        $dots .= qq{<button type="button" class="hc-dot@{[ $on ? ' is-on' : '' ]}" data-i="$i" }
               . qq{aria-label="Mostrar a foto $num de $total"@{[ $on ? ' aria-current="true"' : '' ]}></button>\n};
    }

    return <<HTML;
<section class="hero-carousel" aria-roledescription="carrossel" aria-label="Fotos do Campus Darcy Ribeiro da UnB" data-intervalo="6500">
<div class="hc-viewport">
$slides</div>
<button type="button" class="hc-nav hc-prev" aria-label="Foto anterior"><span class="msym">chevron_left</span></button>
<button type="button" class="hc-nav hc-next" aria-label="Próxima foto"><span class="msym">chevron_right</span></button>
<button type="button" class="hc-play" aria-label="Pausar a troca automática de fotos" aria-pressed="false"><span class="msym">pause</span></button>
<div class="hc-dots" role="group" aria-label="Escolher a foto">
$dots</div>
<p class="hc-live" aria-live="polite" aria-atomic="true"></p>
</section>
HTML
}

# ---------------- páginas escritas em HTML ----------------
# Uma passada só sobre @PAGINAS_HTML (declarado lá em cima, junto do @NAV).
# Capturas de tela do Núcleo EP são opcionais: cada figura só entra no site se
# o arquivo existir em build/assets/img/. Para publicar um print, salve o PNG
# com um dos nomes abaixo nessa pasta e rode o gerador de novo — nada mais.
my @NUCLEO_SHOTS = (
    ['nucleo-minha-area.png', 'Minha área de trabalho — o que está sob a responsabilidade de cada integrante'],
    ['nucleo-dashboard.png',  'Dashboard — os indicadores do grupo e o próximo passo de cada projeto'],
    ['nucleo-cronograma.png', 'Cronograma — demandas e oportunidades acadêmicas na mesma linha do tempo'],
    ['nucleo-projetos.png',   'Projetos — agrupados por situação, com os que precisam de atenção no topo'],
);
for my $pg (@PAGINAS_HTML) {
    my $p = '../';
    open my $fh, '<:encoding(UTF-8)', "$ROOT/$pg->{arquivo}" or die "$pg->{arquivo}: $!";
    local $/; my $body = <$fh>; close $fh;

    if ($pg->{slug} eq 'nucleo-ep') {
        my @figs = map {
            my ($file, $cap) = @$_;
            my $c = esc($cap);
            qq{<figure class="shot"><img src="${p}assets/img/$file" alt="$c" loading="lazy"><figcaption>$c</figcaption></figure>};
        } grep { -e "$ROOT/assets/img/$_->[0]" } @NUCLEO_SHOTS;
        my $shots = @figs
            ? qq{<h2>O sistema por dentro</h2>\n}
              . qq{<p class="section-lead">Telas do Núcleo EP em uso pelo grupo.</p>\n}
              . qq{<div class="shot-grid">\n} . join("\n", @figs) . qq{\n</div>}
            : '';
        $body =~ s/\{\{SHOTS\}\}/$shots/;
    }

    if ($pg->{slug} eq 'versos-e-conselhos') {
        my $module = abs_path("$ROOT/versos-conselhos.pl");
        require $module;
        my $versos = VersosConselhos::render($ROOT);
        $body =~ s/\{\{VERSOS_CONSELHOS\}\}/$versos/;
    }
    $body =~ s/\{\{P\}\}/$p/g;

    write_file("$OUT/$pg->{slug}/index.html", page_shell(
        qr_url => "$SITE_URL/$pg->{slug}/",
        qr_dir => "$OUT/$pg->{slug}",
        title  => "$pg->{titulo} — $SITE",
        desc   => $pg->{desc},
        p      => $p,
        canon  => "$SITE_URL/$pg->{slug}/",
        header => header_html($p, $pg->{slug}),
        body   => $body,
        footer => footer_html($p),
        body_class => $pg->{tema},
        head_extra => $pg->{slug} eq 'versos-e-conselhos'
          ? qq{<link rel="stylesheet" href="${p}assets/versos-conselhos.css"><script src="${p}assets/versos-conselhos.js" defer></script>} : '',
    ));
    $n++;
}

# ---------------- landing page ----------------
{
    open my $fh, '<:encoding(UTF-8)', "$ROOT/landing.html" or die $!;
    local $/; my $tpl = <$fh>; close $fh;
    my $header = header_html('', 'inicio');
    my $footer = footer_html('');
    my $carrossel = hero_carousel_html();
    my $grafico   = grafico_premios_html();
    my $coluna    = coluna_home_html();
    $tpl =~ s/\{\{HEADER\}\}/$header/;
    $tpl =~ s/\{\{FOOTER\}\}/$footer/;
    $tpl =~ s/\{\{HERO_CARROSSEL\}\}/$carrossel/;
    $tpl =~ s/\{\{GRAFICO_PREMIOS\}\}/$grafico/;
    $tpl =~ s/\{\{COLUNA_HOME\}\}/$coluna/;
    write_file("$OUT/index.html", $tpl);
    $n++;
}

# ---------------- assets ----------------
sub copy_raw {
    my ($src, $dst) = @_;
    make_path(dirname($dst));
    open my $in,  '<:raw', $src or die "$src: $!";
    open my $out, '>:raw', $dst or die "$dst: $!";
    local $/; print {$out} <$in>;
    close $in; close $out;
}
for my $a (glob "$ROOT/assets/*") {
    next if -d $a;
    my ($name) = $a =~ m{([^/\\]+)$};
    copy_raw($a, "$OUT/assets/$name");
}
for my $a (glob "$ROOT/assets/img/*") {
    my ($name) = $a =~ m{([^/\\]+)$};
    copy_raw($a, "$OUT/assets/img/$name");
}

# ---------------- extras ----------------
write_file("$OUT/.nojekyll", '');
write_file("$OUT/404.html", page_shell(
    title  => "Página não encontrada — $SITE",
    desc   => "Página não encontrada.",
    p      => '/escola-de-pacientes-df/',
    header => header_html('/escola-de-pacientes-df/', ''),
    body   => qq{<div class="page-hero"><div class="wrap-narrow"><h1>Página não encontrada</h1></div></div><article class="content" id="conteudo"><div class="wrap-narrow"><p>O endereço acessado não existe neste site. <a href="/escola-de-pacientes-df/">Voltar ao início</a>.</p></div></article>},
    footer => footer_html('/escola-de-pacientes-df/'),
));

print "OK: $n páginas geradas em docs/\n";
