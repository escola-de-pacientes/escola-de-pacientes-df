// Carrossel de fotos do topo da página inicial.
// Sem biblioteca: troca por transparência, avanço automático que o visitante
// pode pausar, setas, bolinhas, teclado e arrastar com o dedo.
// Se o JavaScript não carregar, a primeira foto continua visível.
(function () {
  var root = document.querySelector('.hero-carousel');
  if (!root) return;

  var slides = Array.prototype.slice.call(root.querySelectorAll('.hc-slide'));
  var dots   = Array.prototype.slice.call(root.querySelectorAll('.hc-dot'));
  if (slides.length < 2) return;

  var live    = root.querySelector('.hc-live');
  var btnPrev = root.querySelector('.hc-prev');
  var btnNext = root.querySelector('.hc-next');
  var btnPlay = root.querySelector('.hc-play');
  var icoPlay = btnPlay ? btnPlay.querySelector('.msym') : null;

  var calmo = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var intervalo = parseInt(root.getAttribute('data-intervalo'), 10) || 6500;

  var atual = 0;
  var timer = null;
  var pausadoPeloVisitante = calmo;   // quem pediu menos movimento já começa parado

  function mostrar(i, anunciar) {
    atual = (i + slides.length) % slides.length;
    slides.forEach(function (s, k) {
      var on = k === atual;
      s.classList.toggle('is-active', on);
      if (on) s.removeAttribute('aria-hidden');
      else s.setAttribute('aria-hidden', 'true');
    });
    dots.forEach(function (d, k) {
      var on = k === atual;
      d.classList.toggle('is-on', on);
      if (on) d.setAttribute('aria-current', 'true');
      else d.removeAttribute('aria-current');
    });
    if (anunciar && live) live.textContent = 'Foto ' + (atual + 1) + ' de ' + slides.length;
  }

  // ---- avanço automático ----
  // Só a vontade do visitante e a aba oculta valem aqui. Passar o mouse por
  // cima ou entrar com o teclado é tratado pelos eventos lá embaixo — se
  // entrasse nesta conta, apertar "retomar" nunca religava o carrossel,
  // porque o próprio botão de play conta como foco dentro dele.
  function podeRodar() { return !pausadoPeloVisitante && !document.hidden; }
  function parar() { if (timer) { clearInterval(timer); timer = null; } }
  function rodar() {
    parar();
    if (!podeRodar()) return;
    timer = setInterval(function () {
      if (podeRodar()) mostrar(atual + 1, false); else parar();
    }, intervalo);
  }

  function atualizarBotaoPlay() {
    if (!btnPlay) return;
    btnPlay.setAttribute('aria-pressed', pausadoPeloVisitante ? 'true' : 'false');
    btnPlay.setAttribute('aria-label', pausadoPeloVisitante
      ? 'Retomar a troca automática de fotos'
      : 'Pausar a troca automática de fotos');
    if (icoPlay) icoPlay.textContent = pausadoPeloVisitante ? 'play_arrow' : 'pause';
  }

  // ---- controles ----
  if (btnPrev) btnPrev.addEventListener('click', function () { mostrar(atual - 1, true); rodar(); });
  if (btnNext) btnNext.addEventListener('click', function () { mostrar(atual + 1, true); rodar(); });
  dots.forEach(function (d) {
    d.addEventListener('click', function () { mostrar(parseInt(d.getAttribute('data-i'), 10), true); rodar(); });
  });
  if (btnPlay) {
    btnPlay.addEventListener('click', function () {
      pausadoPeloVisitante = !pausadoPeloVisitante;
      atualizarBotaoPlay();
      if (pausadoPeloVisitante) parar(); else rodar();
    });
  }

  // teclado: setas quando o carrossel está em foco
  root.addEventListener('keydown', function (ev) {
    if (ev.key === 'ArrowLeft')  { ev.preventDefault(); mostrar(atual - 1, true); rodar(); }
    if (ev.key === 'ArrowRight') { ev.preventDefault(); mostrar(atual + 1, true); rodar(); }
  });

  // não corre enquanto o mouse está em cima, com foco dentro, ou na aba oculta
  ['mouseenter', 'focusin'].forEach(function (e) { root.addEventListener(e, parar); });
  ['mouseleave', 'focusout'].forEach(function (e) { root.addEventListener(e, rodar); });
  document.addEventListener('visibilitychange', function () { document.hidden ? parar() : rodar(); });

  // arrastar com o dedo
  var x0 = null;
  root.addEventListener('pointerdown', function (ev) { x0 = ev.clientX; }, { passive: true });
  root.addEventListener('pointerup', function (ev) {
    if (x0 === null) return;
    var d = ev.clientX - x0;
    x0 = null;
    if (Math.abs(d) < 45) return;
    mostrar(atual + (d < 0 ? 1 : -1), true);
    rodar();
  }, { passive: true });

  atualizarBotaoPlay();
  mostrar(0, false);
  rodar();
})();
