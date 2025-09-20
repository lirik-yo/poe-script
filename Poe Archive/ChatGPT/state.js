const State = (function () {
  const internalState = {
    items: [],
    heroes: [],
    comparedItems: [],
    selectedHero: null,
    message: ''
  };

  function set(key, value) {
    if (internalState.hasOwnProperty(key)) {
      internalState[key] = value;
      Render.update(); // глобальный вызов на обновление интерфейса
    }
  }

  function get(key) {
    return internalState[key];
  }

  return {
    set,
    get,
    setComparedItems: ids => set('comparedItems', ids)
  };
})();