# Página estática: os arquivos públicos são a única fonte de depoimentos.
package VersosConselhos;
use strict; use warnings; use utf8; use JSON::PP;
our @etapas = (
 ['primeiros-passos','Primeiros passos'], ['primeiros-pacientes','Primeiros pacientes'],
 ['ciclo-clinico','Ciclo clínico'], ['internato','Internato'], ['reta-final','Reta final'],
);
our %etapa = map { $_->[0] => $_->[1] } @etapas;
sub e { my $s = $_[0] // ''; $s =~ s/&/&amp;/g; $s =~ s/</&lt;/g; $s =~ s/>/&gt;/g; $s =~ s/"/&quot;/g; $s =~ s/'/&#39;/g; return $s; }
sub read_json { my ($path)=@_; open my $fh,'<:encoding(UTF-8)',$path or die "$path: $!"; local $/; my $s=<$fh>; close $fh; return JSON::PP->new->decode($s); }
sub date_label { my ($d)=@_; my @m=qw(janeiro fevereiro março abril maio junho julho agosto setembro outubro novembro dezembro); return $d unless $d =~ /^(\d{4})-(\d{2})$/; return "$m[$2-1] de $1"; }
sub paragraphs { return join '', map { '<p>'.e($_).'</p>' } @{$_[0]}; }
sub render {
 my ($root)=@_;
 my @records;
 for my $path (sort glob "$root/versos-e-conselhos/*.json") {
  my $r=read_json($path);
  for my $key (qw(id titulo autor turma data origem)) { die "$path: falta $key" unless defined $r->{$key} && !ref($r->{$key}); }
  die "$path: id inválido" unless $r->{id} =~ /^[a-z0-9]+(?:-[a-z0-9]+)*$/ && $path =~ /\/$r->{id}\.json$/;
  die "$path: data inválida" unless $r->{data} =~ /^\d{4}(?:-(?:0[1-9]|1[0-2]))?$/;
  for my $key (qw(etapas conselho pos_escritos indicacoes)) { die "$path: $key deve ser lista" unless ref($r->{$key}) eq 'ARRAY'; }
  die "$path: etapa inválida" if grep { !exists $etapa{$_} } @{$r->{etapas}};
  die "$path: registro vazio" unless @{$r->{conselho}} || @{$r->{pos_escritos}};
  die "$path: fonte inválida" if $r->{fonte} && $r->{fonte} !~ m{^https://[^\s"<>]+$};
  for my $ps (@{$r->{pos_escritos}}) { die "$path: pós-escrito inválido" unless ref($ps->{paragrafos}) eq 'ARRAY' && ($ps->{data}//'') =~ /^\d{4}-(?:0[1-9]|1[0-2])$/; }
  push @records,$r;
 }
 @records=sort { $b->{data} cmp $a->{data} || $a->{id} cmp $b->{id} } @records;
 my $config=read_json("$root/versos-e-conselhos-config.json");
 my $form=$config->{formulario_url}//'';
 die 'URL do formulário inválida' if $form && $form !~ m{^https://(?:docs\.google\.com/forms/|forms\.gle/)[A-Za-z0-9_/?=&.%-]+$};
 my $cta=$form ? '<a class="btn btn-primary" href="'.e($form).'" target="_blank" rel="noopener noreferrer">Deixar meu conselho <span aria-hidden="true">↗</span></a><p class="vc-small">Abre um formulário do Google em outra aba.</p>' : '<p>O envio de novos conselhos será disponibilizado aqui.</p>';
 my $help=$form ? 'Use o formulário acima e informe o link do conselho e o pedido.' : 'O formulário de contato está temporariamente indisponível.';
 my %turmas=map { $_->{turma}=>1 } @records;
 my $options=join '', map { '<option value="'.e($_).'">'.e($_).'</option>' } sort keys %turmas;
 my $stages=join '',map { '<option value="'.$_->[0].'">'.$_->[1].'</option>' } @etapas;
 my $cards='';
 for my $r (@records) {
  my ($id,$title,$author,$turma,$date)=map {e($_)} @{$r}{qw(id titulo autor turma data)};
  my $tags=join '',map { '<span>'.$etapa{$_}.'</span>' } @{$r->{etapas}};
  my $text=paragraphs($r->{conselho});
  for my $ps (@{$r->{pos_escritos}}) { $text.='<aside class="vc-post"><h4>Pós-escrito · '.e(date_label($ps->{data})).'</h4>'.paragraphs($ps->{paragrafos}).'</aside>'; }
  if (@{$r->{indicacoes}}) { $text.='<aside class="vc-works"><h4>Na companhia deste conselho</h4>'.paragraphs($r->{indicacoes}).'<p class="vc-small">Referências indicadas no acervo; não são letras ou poemas reproduzidos na íntegra.</p></aside>'; }
  my $origin=e($r->{origem});
  my $source=$r->{fonte} ? '<a href="'.e($r->{fonte}).'" target="_blank" rel="noopener noreferrer">Consultar acervo original ↗</a>' : '';
  my @all=(@{$r->{conselho}},map { @{$_->{paragrafos}} } @{$r->{pos_escritos}});
  my $excerpt=$all[0]//''; $excerpt=substr($excerpt,0,175).'…' if length($excerpt)>175;
  my $search=e(join ' ', $r->{titulo},$r->{autor},$r->{turma},@all,@{$r->{indicacoes}});
  my $stage=e(join ' ',@{$r->{etapas}});
  my $date_text=e(date_label($r->{data}));
  $cards.=<<HTML;
<article class="vc-card" id="$id" data-search="$search" data-etapas="$stage" data-turma="$turma">
 <p class="vc-meta">$turma <span aria-hidden="true">·</span> <time datetime="$date">$date_text</time></p>
 <h3>$title</h3><p class="vc-author">$author</p>
 <p class="vc-excerpt">@{[e($excerpt)]}</p>
 <div class="vc-tags" aria-label="Para quem está em">$tags</div>
 <details><summary>Ler conselho <span class="vc-sr">de $author</span></summary>
 <div class="vc-text">$text</div><p class="vc-small">$origin. $source</p>
 </details>
 <a class="vc-permalink" href="#$id">Link deste conselho<span class="vc-sr"> de $author</span></a>
</article>
HTML
 }
 my $count=scalar @records;
 return <<HTML;
<main id="conteudo" class="vc-page">
 <section class="vc-hero"><div class="wrap">
 <nav class="breadcrumb" aria-label="Caminho da página"><a href="../">Início</a><span>/</span><a href="../para-estudantes/">Estudantes</a><span>/</span><span>Versos e Conselhos</span></nav>
 <p class="vc-eyebrow">De estudantes para estudantes</p>
 <h1>Versos e<br><span>Conselhos</span></h1>
 <p class="vc-lead">Uma calçada de experiências deixadas por quem caminhou antes.</p>
 <p class="vc-intro">Cada turma deixa uma marca. Aqui, ela fica nas palavras: descobertas, músicas e conselhos de colegas que já passaram por etapas da sua graduação em Medicina.</p>
 <div class="vc-actions"><a class="btn btn-primary" href="#conselhos">Encontrar um conselho</a><a class="btn btn-ghost" href="#participar">Deixar minha contribuição</a></div>
 <ol class="vc-path" aria-label="Toda a caminhada da graduação"><li>Primeiros passos</li><li>Primeiros pacientes</li><li>Ciclo clínico</li><li>Internato</li><li>Reta final</li></ol>
 </div></section>
 <section class="vc-collection wrap" id="conselhos" aria-labelledby="vc-heading">
 <div class="vc-section-head"><div><p class="vc-eyebrow">Palavras que atravessam turmas</p><h2 id="vc-heading">Para o seu momento da caminhada</h2></div><p class="vc-intro">Comece por uma etapa ou deixe que um conselho encontre você.</p></div>
 <p class="vc-context">A coleção nasceu do acervo da Calçada, com registros de 2016 a 2019 do Internato de Medicina Social da UnB. Agora, o convite se abre a colegas de todas as etapas. Os conselhos podem acompanhar toda a graduação; os textos mantêm o contexto em que nasceram.</p>
 <form class="vc-filters" id="vc-filters" role="search" aria-label="Filtrar conselhos" hidden>
 <label class="vc-search">O que você procura?<input type="search" id="vc-search" placeholder="Palavra, colega ou tema" autocomplete="off"></label>
 <label>Etapa da graduação<select id="vc-stage"><option value="">Todas as etapas</option>$stages</select></label>
 <label>Turma<select id="vc-class"><option value="">Todas as turmas</option>$options</select></label>
 <button type="reset" class="btn btn-ghost">Limpar filtros</button>
 </form>
 <p class="vc-status" id="vc-status" role="status" aria-live="polite" aria-atomic="true">$count conselhos para explorar · mais recentes primeiro</p>
 <noscript><p>Todos os conselhos estão disponíveis abaixo. Abra “Ler conselho” para continuar a leitura.</p></noscript>
 <div class="vc-grid" id="vc-grid">$cards</div>
 <div class="vc-empty" id="vc-empty" hidden><h3>Nenhum conselho por aqui, ainda.</h3><p>Experimente outra palavra ou limpe os filtros para continuar a caminhada.</p></div>
 </section>
 <section id="participar" class="vc-participate"><div class="wrap vc-two"><div><p class="vc-eyebrow">A próxima marca pode ser sua</p><h2>O que você gostaria<br>de ter ouvido antes?</h2><p>Compartilhe algo da sua graduação que possa acompanhar quem vem depois. Pode ser um conselho, uma pequena história, um verso seu ou a indicação de uma música que marcou essa etapa.</p></div><div class="vc-invite"><h3>Deixe algumas palavras para um colega.</h3><p>Vale participar em qualquer etapa da graduação. Se você já se formou, volte à sua experiência de estudante e escreva para quem ainda está nesse caminho.</p>$cta<p class="vc-small">Não inclua dados que identifiquem pacientes ou outras pessoas. O envio não publica a mensagem automaticamente. A equipe seleciona e acrescenta as contribuições à página.</p></div></div></section>
 <section class="wrap vc-about" aria-labelledby="vc-about-title"><p class="vc-eyebrow">De onde vem esta calçada</p><h2 id="vc-about-title">Uma memória que continua caminhando</h2><p>A antiga Calçada de Versos e Conselhos reunia palavras de estudantes do Internato de Medicina Social para as turmas seguintes. A proposta permanece: colegas compartilhando aquilo que aprenderam pelo caminho. Agora, o convite alcança toda a graduação em Medicina.</p><details><summary>Sobre esta edição e correções</summary><p>Foram preservados os conselhos, as assinaturas, os anonimatos e os pós-escritos do acervo. Os títulos dos cartões e as classificações por etapa são editoriais. As datas indicam o registro original, não uma atualização das opiniões. São experiências pessoais, não orientações clínicas.</p><p>Esta seleção não reproduz blocos autônomos de letras, poemas ou citações de terceiros. Um registro composto apenas por uma citação não integra a coleção de conselhos. As referências culturais acompanham os textos quando identificadas na fonte.</p><p>Precisa corrigir ou retirar um registro? $help</p><p><a href="https://docs.google.com/document/d/1JWIgMxsG2Gp_-_bT9n1Od1Rp9TVvpgPe/preview" target="_blank" rel="noopener noreferrer">Consultar o acervo original · edição de maio de 2022 ↗</a></p></details></section>
</main>
HTML
}
1;
