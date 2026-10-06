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
})();
