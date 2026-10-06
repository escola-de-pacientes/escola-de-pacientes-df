// Revisão por doença — o comportamento das páginas /revisao/.
// Tudo aqui é melhoria: sem script, a página continua inteira (as janelas
// abrem pelo <details>, os painéis do aprofundamento aparecem um embaixo do
// outro, e nenhum bloco fica invisível).
(function () {
  var doc = document.documentElement;
  var calmo = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var raiz = document.querySelector('.rv');
  if (!raiz) return;
  var slug = raiz.getAttribute('data-revisao') || 'indice';
  doc.classList.add('rv-js');      // o que só faz sentido com script (o tutorial) aparece a partir daqui

  function guarda(chave, valor) { try { localStorage.setItem(chave, valor); } catch (e) {} }
  function le(chave) { try { return localStorage.getItem(chave); } catch (e) { return null; } }

  // ---------- entrada ao rolar ----------
  var aparecem = Array.prototype.slice.call(document.querySelectorAll('.rv-reveal'));
  if (!calmo && 'IntersectionObserver' in window) {
    doc.classList.add('rv-anim');
    var io = new IntersectionObserver(function (es) {
      es.forEach(function (e) { if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); } });
    }, { threshold: 0.08, rootMargin: '0px 0px -4% 0px' });
    aparecem.forEach(function (el, i) {
      el.style.transitionDelay = Math.min((i % 4) * 70, 210) + 'ms';
      io.observe(el);
    });
    // rede de segurança: nada fica escondido se o observador não disparar
    setTimeout(function () {
      aparecem.forEach(function (el) {
        var r = el.getBoundingClientRect();
        if (r.top < window.innerHeight) el.classList.add('in');
      });
    }, 900);
    setTimeout(function () { aparecem.forEach(function (el) { el.classList.add('in'); }); }, 6000);
  }

  // ---------- vídeo: o tocador só carrega no clique ----------
  document.addEventListener('click', function (ev) {
    var b = ev.target.closest && ev.target.closest('.rv-yt');
    if (!b) return;
    var id = b.getAttribute('data-yt');
    var f = document.createElement('iframe');
    f.className = 'rv-yt-frame';
    f.src = 'https://www.youtube-nocookie.com/embed/' + id + '?autoplay=1&rel=0';
    f.title = b.getAttribute('aria-label') || 'Vídeo';
    f.allow = 'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; fullscreen';
    f.allowFullscreen = true;
    b.parentNode.replaceChild(f, b);
  });

  // ---------- janelas: o PDF só carrega quando a janela abre ----------
  function carrega(det) {
    var f = det.querySelector('iframe[data-src]');
    if (f && !f.getAttribute('src')) f.setAttribute('src', f.getAttribute('data-src'));
  }
  Array.prototype.forEach.call(document.querySelectorAll('.rv-janela'), function (det) {
    if (det.open) carrega(det);
    det.addEventListener('toggle', function () { if (det.open) carrega(det); });
  });

  // ---------- abas do aprofundamento ----------
  Array.prototype.forEach.call(document.querySelectorAll('.rv-abas'), function (lista) {
    var etapa = lista.parentNode;
    var abas = Array.prototype.slice.call(lista.querySelectorAll('[role="tab"]'));
    etapa.classList.add('rv-abas-on');
    function escolhe(aba, foco) {
      abas.forEach(function (a) {
        var sel = a === aba;
        a.setAttribute('aria-selected', sel ? 'true' : 'false');
        a.tabIndex = sel ? 0 : -1;
        var painel = document.getElementById(a.getAttribute('aria-controls'));
        if (painel) painel.hidden = !sel;
        if (sel && painel) {
          var primeira = painel.querySelector('.rv-janela');
          if (primeira && primeira.open) carrega(primeira);
          painel.querySelectorAll('.rv-reveal').forEach(function (el) { el.classList.add('in'); });
        }
      });
      if (foco) aba.focus();
      // rola só a fileira de abas, nunca a página
      var alvo = aba.offsetLeft - (lista.clientWidth - aba.offsetWidth) / 2;
      if (lista.scrollWidth > lista.clientWidth) lista.scrollTo({ left: alvo, behavior: calmo ? 'auto' : 'smooth' });
    }
    abas.forEach(function (a, i) {
      a.addEventListener('click', function () { escolhe(a); });
      a.addEventListener('keydown', function (ev) {
        var j = ev.key === 'ArrowRight' ? i + 1 : ev.key === 'ArrowLeft' ? i - 1
              : ev.key === 'Home' ? 0 : ev.key === 'End' ? abas.length - 1 : null;
        if (j === null) return;
        ev.preventDefault();
        escolhe(abas[(j + abas.length) % abas.length], true);
      });
    });
    escolhe(abas[0]);
  });

  // ---------- trilha: etapa atual e barra de progresso ----------
  var trilha = document.querySelector('.rv-trilha');
  if (trilha) {
    var chips = Array.prototype.slice.call(trilha.querySelectorAll('a[data-alvo]'));
    var secoes = chips.map(function (c) { return document.querySelector(c.getAttribute('href')); });
    var barra = trilha.querySelector('.rv-progresso span');
    var corpo = document.querySelector('.rv-corpo');
    var pendente = false;
    function atualiza() {
      pendente = false;
      var linha = trilha.getBoundingClientRect().bottom + 40;
      var atual = -1;
      secoes.forEach(function (s, i) { if (s && s.getBoundingClientRect().top <= linha) atual = i; });
      chips.forEach(function (c, i) { c.classList.toggle('ativa', i === atual); });
      if (barra && corpo) {
        var r = corpo.getBoundingClientRect();
        var total = r.height - window.innerHeight * 0.6;
        var feito = Math.min(1, Math.max(0, (linha - r.top) / Math.max(total, 1)));
        barra.style.width = (feito * 100).toFixed(1) + '%';
      }
    }
    window.addEventListener('scroll', function () {
      if (!pendente) { pendente = true; requestAnimationFrame(atualiza); }
    }, { passive: true });
    window.addEventListener('resize', atualiza, { passive: true });
    atualiza();
  }

  // ---------- etapas concluídas (só neste navegador) ----------
  var botoes = Array.prototype.slice.call(document.querySelectorAll('.rv-concluir'));
  var aviso = document.querySelector('.rv-trilha-ok');
  function marca(btn, feito, anima) {
    var n = btn.getAttribute('data-etapa');
    btn.setAttribute('aria-pressed', feito ? 'true' : 'false');
    btn.querySelector('.rv-c-txt').textContent = feito ? 'Etapa ' + n + ' concluída' : 'Marcar etapa ' + n + ' como concluída';
    var chip = trilha && trilha.querySelector('a[data-alvo="' + n + '"]');
    if (chip) chip.classList.toggle('feita', feito);
    var todas = botoes.length && botoes.every(function (b) { return b.getAttribute('aria-pressed') === 'true'; });
    if (aviso) {
      aviso.textContent = todas ? 'Revisão concluída 🎉' : '';
      aviso.classList.toggle('mostra', !!todas);
    }
    if (anima && todas && !calmo) festa();
  }
  botoes.forEach(function (btn) {
    var chave = 'rv:' + slug + ':' + btn.getAttribute('data-etapa');
    marca(btn, le(chave) === '1', false);
    btn.addEventListener('click', function () {
      var feito = btn.getAttribute('aria-pressed') !== 'true';
      guarda(chave, feito ? '1' : '0');
      marca(btn, feito, true);
    });
  });

  // uma chuvinha curta de pontos na cor da doença, quando as três etapas fecham
  function festa() {
    var cor = getComputedStyle(document.body).getPropertyValue('--rv') || '#1a73e8';
    var cores = [cor.trim(), '#f9ab00', '#1a73e8', '#188038'];
    var box = document.createElement('div');
    box.setAttribute('aria-hidden', 'true');
    box.style.cssText = 'position:fixed;inset:0;pointer-events:none;z-index:90;overflow:hidden';
    for (var i = 0; i < 60; i++) {
      var p = document.createElement('span');
      var s = 6 + Math.random() * 7;
      p.style.cssText = 'position:absolute;top:-20px;left:' + (Math.random() * 100) + 'vw;width:' + s + 'px;height:' + s +
        'px;border-radius:' + (Math.random() < .5 ? '50%' : '2px') + ';background:' + cores[i % cores.length];
      p.animate([
        { transform: 'translate(0,0) rotate(0deg)', opacity: 1 },
        { transform: 'translate(' + (Math.random() * 160 - 80) + 'px,' + (window.innerHeight + 40) + 'px) rotate(' + (Math.random() * 720) + 'deg)', opacity: .9 }
      ], { duration: 1800 + Math.random() * 1400, easing: 'cubic-bezier(.2,.6,.4,1)', delay: Math.random() * 300, fill: 'forwards' });
      box.appendChild(p);
    }
    document.body.appendChild(box);
    setTimeout(function () { box.remove(); }, 3800);
  }

  // ---------- chegou do SimulaPacientes ----------
  // O Hub abre esta página com ?origem=simulapacientes. A faixa fica até o fim
  // da visita (sessionStorage), para não sumir quando a pessoa clica numa aba
  // e a página recarrega pelo botão de voltar.
  var faixa = document.querySelector('.rv-sim');
  if (faixa) {
    var q = new URLSearchParams(location.search);
    var veio = q.get('origem') === 'simulapacientes';
    try {
      if (veio) sessionStorage.setItem('rv:origem', 'simulapacientes');
      else veio = sessionStorage.getItem('rv:origem') === 'simulapacientes';
    } catch (e) {}
    if (veio) {
      faixa.hidden = false;
      // ?volta= só é aceito se apontar para o próprio SimulaPacientes —
      // qualquer outro endereço viraria um redirecionador aberto com a cara
      // da Escola.
      var volta = q.get('volta');
      if (volta) {
        try {
          var u = new URL(volta);
          if (u.protocol === 'https:' && /^(simulapacientes\.escoladepacientes\.com|hub-de-ll-ms\.vercel\.app)$/.test(u.hostname)) {
            faixa.querySelector('.rv-sim-volta').href = u.href;
          }
        } catch (e) {}
      }
    }
  }

  // ---------- tutorial guiado ----------
  // Os passos vêm do gerador (#rv-tour-passos): alvo, título e texto. Aqui só
  // se conduz: rolar até o alvo, acender ele (o resto da tela escurece) e
  // mostrar o cartão. Passo cujo alvo não existe é pulado. Esc fecha; setas
  // avançam e voltam; o foco volta para o botão que abriu.
  var fonte = document.getElementById('rv-tour-passos');
  if (fonte) {
    var passos = [];
    try { passos = JSON.parse(fonte.textContent); } catch (e) {}
    passos = passos.filter(function (p) { return document.querySelector(p.alvo); });
    var tela, luz, cartao, atual = 0, quemAbriu = null, alvoAtual = null;

    function montar() {
      tela = document.createElement('div');
      tela.className = 'rv-tour';
      tela.innerHTML =
        '<div class="rv-tour-luz" aria-hidden="true"></div>' +
        '<div class="rv-tour-cartao" role="dialog" aria-modal="true" aria-labelledby="rv-tour-t" aria-describedby="rv-tour-x" tabindex="-1">' +
          '<p class="rv-tour-conta"></p>' +
          '<h2 id="rv-tour-t"></h2><p id="rv-tour-x"></p>' +
          '<div class="rv-tour-pontos" aria-hidden="true"></div>' +
          '<div class="rv-tour-botoes">' +
            '<button type="button" class="rv-tour-sai">Sair do tutorial</button>' +
            '<span><button type="button" class="rv-tour-volta">Anterior</button>' +
            '<button type="button" class="rv-tour-vai">Próximo</button></span>' +
          '</div>' +
        '</div>';
      document.body.appendChild(tela);
      luz = tela.querySelector('.rv-tour-luz');
      cartao = tela.querySelector('.rv-tour-cartao');
      tela.querySelector('.rv-tour-sai').addEventListener('click', fechar);
      tela.querySelector('.rv-tour-volta').addEventListener('click', function () { ir(atual - 1); });
      tela.querySelector('.rv-tour-vai').addEventListener('click', function () {
        if (atual >= passos.length - 1) fechar(); else ir(atual + 1);
      });
      tela.addEventListener('click', function (ev) { if (ev.target === tela) fechar(); });
    }

    // altura do que fica preso no alto da tela (cabeçalho e trilha)
    function topoFixo() {
      var h = 0;
      ['header.site', '.rv-trilha'].forEach(function (sel) {
        var el = document.querySelector(sel);
        if (el) { var r = el.getBoundingClientRect(); if (r.top <= 1) h = Math.max(h, r.bottom); }
      });
      return h;
    }

    function posicionar() {
      if (!alvoAtual || !tela) return;
      var r = alvoAtual.getBoundingClientRect();
      var vh = window.innerHeight, vw = window.innerWidth, m = 8;
      var fixo = alvoAtual.closest('.rv-trilha, .rv-tour-fab, header.site') ? 0 : topoFixo();
      var topo = Math.max(r.top - m, fixo + 4);
      // alvo mais alto que a tela: acende só o começo dele e deixa espaço pro cartão
      var fundo = Math.min(r.bottom + m, topo + vh * 0.42, vh - 8);
      if (r.height + 2 * m < vh * 0.42) fundo = Math.min(r.bottom + m, vh - 8);
      var esq = Math.max(r.left - m, 6), dir = Math.min(r.right + m, vw - 6);
      luz.style.top = topo + 'px'; luz.style.left = esq + 'px';
      luz.style.width = Math.max(dir - esq, 0) + 'px'; luz.style.height = Math.max(fundo - topo, 0) + 'px';

      var c = cartao.getBoundingClientRect(), cw = c.width, ch = c.height, y, x;
      if (vw < 640) {
        // celular: o cartão ocupa a largura e fica na metade da tela oposta
        // à parte acesa, para nunca cobrir o que está sendo explicado
        var emBaixo = (topo + fundo) / 2 < vh / 2;
        cartao.classList.toggle('rv-tour-baixo', emBaixo);
        cartao.classList.toggle('rv-tour-cima', !emBaixo);
        cartao.style.top = ''; cartao.style.left = '';
        return;
      }
      cartao.classList.remove('rv-tour-baixo', 'rv-tour-cima');
      if (fundo + 14 + ch < vh) y = fundo + 14;
      else if (topo - 14 - ch > fixo) y = topo - 14 - ch;
      else y = vh - ch - 16;
      x = Math.min(Math.max(esq, 16), vw - cw - 16);
      cartao.style.top = y + 'px'; cartao.style.left = x + 'px';
    }

    function ir(n) {
      if (n < 0 || n >= passos.length) return;
      atual = n;
      var p = passos[n];
      alvoAtual = document.querySelector(p.alvo);
      tela.querySelector('.rv-tour-conta').textContent = 'Passo ' + (n + 1) + ' de ' + passos.length;
      tela.querySelector('#rv-tour-t').textContent = p.titulo;
      tela.querySelector('#rv-tour-x').textContent = p.texto;
      tela.querySelector('.rv-tour-pontos').innerHTML = passos.map(function (_, i) {
        return '<span' + (i === n ? ' class="ativo"' : i < n ? ' class="feito"' : '') + '></span>';
      }).join('');
      tela.querySelector('.rv-tour-volta').disabled = n === 0;
      tela.querySelector('.rv-tour-vai').textContent = n === passos.length - 1 ? 'Concluir' : 'Próximo';
      // o alvo pode estar escondido pela animação de entrada
      alvoAtual.classList.add('in');
      alvoAtual.querySelectorAll('.rv-reveal').forEach(function (el) { el.classList.add('in'); });
      var fixo = alvoAtual.closest('.rv-trilha, .rv-tour-fab, header.site');
      if (!fixo) {
        var r = alvoAtual.getBoundingClientRect();
        var alturaFixa = 64 + ((document.querySelector('.rv-trilha') || {}).offsetHeight || 0);
        var alvoY = window.scrollY + r.top - alturaFixa - 24;
        if (r.height < window.innerHeight * 0.4) alvoY = window.scrollY + r.top - window.innerHeight * 0.22;
        window.scrollTo({ top: Math.max(0, alvoY), behavior: calmo ? 'auto' : 'smooth' });
      }
      tela.classList.remove('rv-tour-troca'); void tela.offsetWidth; tela.classList.add('rv-tour-troca');
      posicionar();
      setTimeout(posicionar, calmo ? 0 : 450);
      setTimeout(posicionar, calmo ? 0 : 900);
      cartao.focus({ preventScroll: true });
    }

    function abrir(ev) {
      if (!passos.length) return;
      quemAbriu = ev && ev.currentTarget;
      if (!tela) montar();
      fecharConvite();
      tela.hidden = false;
      doc.classList.add('rv-tour-aberto');
      ir(0);
      window.addEventListener('scroll', posicionar, { passive: true });
      window.addEventListener('resize', posicionar, { passive: true });
      document.addEventListener('keydown', teclas);
    }

    function fechar() {
      if (!tela) return;
      tela.hidden = true;
      doc.classList.remove('rv-tour-aberto');
      window.removeEventListener('scroll', posicionar);
      window.removeEventListener('resize', posicionar);
      document.removeEventListener('keydown', teclas);
      guarda('rv:tutorial-visto', '1');
      if (quemAbriu && quemAbriu.focus) quemAbriu.focus({ preventScroll: true });
    }

    function teclas(ev) {
      if (ev.key === 'Escape') { ev.preventDefault(); fechar(); }
      else if (ev.key === 'ArrowRight') { ev.preventDefault(); if (atual < passos.length - 1) ir(atual + 1); }
      else if (ev.key === 'ArrowLeft') { ev.preventDefault(); ir(atual - 1); }
      else if (ev.key === 'Tab') {                       // o foco não sai do cartão
        var f = Array.prototype.filter.call(cartao.querySelectorAll('button'), function (b) { return !b.disabled; });
        if (!f.length) return;
        var i = f.indexOf(document.activeElement);
        if (ev.shiftKey && (i <= 0)) { ev.preventDefault(); f[f.length - 1].focus(); }
        else if (!ev.shiftKey && i === f.length - 1) { ev.preventDefault(); f[0].focus(); }
      }
    }

    // convite na primeira visita a qualquer revisão: um balão perto do botão
    // flutuante, que some sozinho. Não abre o tutorial por conta própria —
    // quem veio só buscar um PDF não pode ser interrompido.
    var convite = document.querySelector('.rv-tour-convite');
    var timerConvite;
    function fecharConvite() {
      if (!convite || convite.hidden) return;
      convite.hidden = true;
      clearTimeout(timerConvite);
      guarda('rv:tutorial-visto', '1');
    }
    if (convite && passos.length && le('rv:tutorial-visto') !== '1') {
      setTimeout(function () {
        convite.hidden = false;
        timerConvite = setTimeout(fecharConvite, 12000);
      }, 1400);
      convite.querySelector('.rv-convite-fecha').addEventListener('click', fecharConvite);
    }

    Array.prototype.forEach.call(document.querySelectorAll('.rv-tour-abre'), function (b) {
      b.addEventListener('click', abrir);
    });
  }
})();
