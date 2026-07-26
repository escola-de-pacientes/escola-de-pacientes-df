// Confetes de boas-vindas 🎉 — leves, sem bibliotecas, respeitam
// prefers-reduced-motion e somem sozinhos após a queda.
(function () {
  var calmo = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var cores = ['#1a73e8', '#ea4335', '#fbbc04', '#34a853', '#12818f', '#a142f4', '#ff6d00', '#0d9488'];

  function soltar(n) {
    if (calmo) return;
    var box = document.createElement('div');
    box.className = 'confetti-box';
    box.setAttribute('aria-hidden', 'true');
    for (var i = 0; i < n; i++) {
      var p = document.createElement('span');
      p.className = 'confetti-piece';
      var w = 6 + Math.random() * 8;
      var fita = Math.random() < 0.22;                 // algumas fitas compridas
      var h = fita ? w * (2.2 + Math.random()) : w * (0.4 + Math.random() * 1.2);
      p.style.left = (Math.random() * 100) + 'vw';
      p.style.width = w + 'px';
      p.style.height = h + 'px';
      p.style.background = cores[Math.floor(Math.random() * cores.length)];
      p.style.borderRadius = Math.random() < 0.3 ? '50%' : '2px';
      p.style.setProperty('--dur', (2.6 + Math.random() * 2.8) + 's');
      p.style.setProperty('--delay', (Math.random() * 1.1) + 's');
      p.style.setProperty('--sway', ((Math.random() - 0.5) * 260) + 'px');
      p.style.setProperty('--spin', (1 + Math.random() * 3.4).toFixed(1) + 'turn');
      box.appendChild(p);
    }
    document.body.appendChild(box);
    setTimeout(function () { box.remove(); }, 7000);
  }

  function aoCarregar() { soltar(170); }
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', aoCarregar);
  } else {
    aoCarregar();
  }

  // botão "soltar de novo"
  var botao = document.getElementById('rc-festa');
  if (botao) {
    if (calmo) botao.hidden = true;                    // sem movimento, sem botão
    else botao.addEventListener('click', function () { soltar(200); });
  }

  // ---- checklist dos primeiros passos ----
  // Guardado só neste navegador: é para a pessoa se organizar, não é registro
  // do grupo. Por isso não vai para lugar nenhum nem depende de login.
  var caixas = Array.prototype.slice.call(document.querySelectorAll('.rc-passo input[data-passo]'));
  var contador = document.getElementById('rc-progresso');
  if (caixas.length && contador) {
    var CHAVE = 'epdf:primeiros-passos';
    var feitos = {};
    try { feitos = JSON.parse(localStorage.getItem(CHAVE) || '{}'); } catch (e) { feitos = {}; }

    var total = parseInt(contador.getAttribute('data-total'), 10) || caixas.length;
    var completouAgora = false;

    function pintar() {
      var n = caixas.filter(function (c) { return c.checked; }).length;
      contador.textContent = n === total
        ? 'Tudo pronto — bem-vindo(a) ao grupo!'
        : n + ' de ' + total + ' concluídos';
      if (n === total && !completouAgora) { completouAgora = true; soltar(200); }
      if (n < total) completouAgora = false;
    }

    caixas.forEach(function (c) {
      var id = c.getAttribute('data-passo');
      if (feitos[id]) c.checked = true;
      c.addEventListener('change', function () {
        feitos[id] = c.checked;
        try { localStorage.setItem(CHAVE, JSON.stringify(feitos)); } catch (e) {}
        pintar();
      });
    });
    pintar();
  }
})();
