// Três detalhes de acabamento, todos opcionais: se este arquivo não carregar,
// a página continua completa e legível.
//   1. o realce de luz dos cartões acompanha o ponteiro
//   2. barra de progresso de leitura nas páginas de conteúdo
//   3. o cabeçalho ganha vidro mais denso depois que a página rola
(function () {
  var calmo = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  // ---- 1. luz que segue o ponteiro ----
  // Só no computador: em tela de toque não há ponteiro pairando, e o padrão
  // do CSS (luz no alto, ao centro) já resolve.
  if (window.matchMedia && window.matchMedia('(hover: hover) and (pointer: fine)').matches) {
    var alvos = '.card, .portal, .stat, .award, .media-card, .book-card';
    var pendente = false, ultimo = null;

    document.addEventListener('pointermove', function (ev) {
      var el = ev.target.closest ? ev.target.closest(alvos) : null;
      if (!el) return;
      ultimo = { el: el, x: ev.clientX, y: ev.clientY };
      if (pendente) return;
      pendente = true;
      requestAnimationFrame(function () {
        pendente = false;
        if (!ultimo) return;
        var r = ultimo.el.getBoundingClientRect();
        if (!r.width || !r.height) return;
        ultimo.el.style.setProperty('--mx', ((ultimo.x - r.left) / r.width * 100).toFixed(1) + '%');
        ultimo.el.style.setProperty('--my', ((ultimo.y - r.top) / r.height * 100).toFixed(1) + '%');
      });
    }, { passive: true });
  }

  // ---- 2. progresso de leitura ----
  var artigo = document.querySelector('article.content');
  if (artigo) {
    var barra = document.createElement('div');
    barra.className = 'leitura';
    barra.setAttribute('aria-hidden', 'true');   // é enfeite: o leitor de tela ignora
    document.body.appendChild(barra);

    var tick = false;
    function medir() {
      tick = false;
      var topo = artigo.offsetTop;
      var vao = artigo.offsetHeight - window.innerHeight;
      if (vao <= 0) { barra.style.width = '0'; return; }
      var pct = (window.scrollY - topo) / vao;
      pct = pct < 0 ? 0 : (pct > 1 ? 1 : pct);
      barra.style.width = (pct * 100).toFixed(2) + '%';
    }
    function agenda() { if (!tick) { tick = true; requestAnimationFrame(medir); } }
    window.addEventListener('scroll', agenda, { passive: true });
    window.addEventListener('resize', agenda, { passive: true });
    medir();
  }

  // ---- 3. cabeçalho mais denso ao rolar ----
  var cab = document.querySelector('header.site');
  if (cab) {
    var tick2 = false;
    function estado() {
      tick2 = false;
      cab.classList.toggle('rolado', window.scrollY > 24);
    }
    window.addEventListener('scroll', function () {
      if (!tick2) { tick2 = true; requestAnimationFrame(estado); }
    }, { passive: true });
    estado();
  }

  // ---- 4. barras do gráfico crescem quando entram na tela ----
  var plot = document.querySelector('.g-plot');
  if (plot && !calmo && 'IntersectionObserver' in window) {
    var barras = Array.prototype.slice.call(plot.querySelectorAll('.g-bar'));
    barras.forEach(function (b, i) {
      b.dataset.h = b.style.getPropertyValue('--h');
      b.style.setProperty('--h', '0%');
      b.style.transitionDelay = (i * 55) + 'ms';
    });
    var io = new IntersectionObserver(function (ent) {
      ent.forEach(function (e) {
        if (!e.isIntersecting) return;
        barras.forEach(function (b) { b.style.setProperty('--h', b.dataset.h); });
        io.disconnect();
      });
    }, { threshold: 0.3 });
    io.observe(plot);
    // rede de segurança: se o observador não disparar, mostra assim mesmo
    setTimeout(function () {
      barras.forEach(function (b) { b.style.setProperty('--h', b.dataset.h); });
    }, 2500);
  }
})();
