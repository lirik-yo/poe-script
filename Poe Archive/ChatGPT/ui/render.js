const Render = (function () {
  /**
   * Главная точка входа: вызывать при изменении данных
   */
  function redrawAll() {
    renderItemList();
    renderHeroList();
    renderStatusBar();
  }

  function renderItemList() {
    const container = DomCache.Instance.get('.item-list');
    if (!container) return;

    container.innerHTML = ''; // очистка

    const items = Cache.getItems(); // предполагаем, что кэш хранит нужное
    for (const item of items) {
      const div = document.createElement('div');
      div.className = 'item-entry';
      div.textContent = item.name;
      container.appendChild(div);
    }
  }

  function renderHeroList() {
    const container = DomCache.Instance.get('.hero-list');
    if (!container) return;

    container.innerHTML = '';

    const heroes = Cache.getHeroes();
    for (const hero of heroes) {
      const div = document.createElement('div');
      div.className = 'hero-entry';
      div.textContent = hero.name;
      container.appendChild(div);
    }
  }

  function renderStatusBar() {
    const bar = DomCache.Instance.get('.status-bar');
    if (!bar) return;

    bar.textContent = StatusBar.get(); // откуда брать текст
  }

  // Публичный интерфейс
  return {
    redrawAll,
    renderItemList,
    renderHeroList,
    renderStatusBar
  };
})();