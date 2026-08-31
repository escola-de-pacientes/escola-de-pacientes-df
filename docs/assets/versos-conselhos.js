/* Busca local e links permanentes. Nenhuma resposta ou dado é enviado. */
(function () {
  'use strict';
  const form = document.getElementById('vc-filters');
  if (!form) return;
  const cards = Array.from(document.querySelectorAll('.vc-card'));
  const search = document.getElementById('vc-search');
  const stage = document.getElementById('vc-stage');
  const turma = document.getElementById('vc-class');
  const status = document.getElementById('vc-status');
  const empty = document.getElementById('vc-empty');
  const normalize = text => text.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLocaleLowerCase('pt-BR');
  const texts = cards.map(card => normalize(card.dataset.search));
  function apply() {
    const words = normalize(search.value.trim()).split(/\s+/).filter(Boolean);
    let count = 0;
    cards.forEach((card, i) => {
      const visible = words.every(word => texts[i].includes(word)) &&
        (!stage.value || card.dataset.etapas.split(' ').includes(stage.value)) &&
        (!turma.value || card.dataset.turma === turma.value);
      card.hidden = !visible;
      if (visible) count++;
    });
    status.textContent = `${count} ${count === 1 ? 'conselho encontrado' : 'conselhos encontrados'} de ${cards.length} · mais recentes primeiro`;
    empty.hidden = count !== 0;
  }
  function revealLinkedCard() {
    // IDs são curados; não interpretamos o fragmento como seletor HTML.
    let id;
    try { id = decodeURIComponent(location.hash.slice(1)); } catch (_) { return; }
    const card = cards.find(item => item.id === id);
    if (!card) return;
    if (card.hidden) { form.reset(); apply(); }
    card.querySelector('details').open = true;
    requestAnimationFrame(() => card.scrollIntoView({block: 'start'}));
  }
  form.addEventListener('submit', event => { event.preventDefault(); apply(); });
  form.addEventListener('input', apply);
  form.addEventListener('change', apply);
  form.addEventListener('reset', () => { setTimeout(apply, 0); });
  document.querySelectorAll('.vc-permalink').forEach(link => {
    link.addEventListener('click', () => { link.closest('.vc-card').querySelector('details').open = true; });
  });
  window.addEventListener('hashchange', revealLinkedCard);
  form.hidden = false;
  apply();
  revealLinkedCard();
})();
