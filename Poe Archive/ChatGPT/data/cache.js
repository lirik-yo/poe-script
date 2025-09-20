/**
 * Простая реализация кэш-хранилища в памяти.
 * Используется для хранения уже загруженных из IndexedDB данных,
 * чтобы избежать повторных операций чтения и повысить производительность.
 */

const Cache = (function () {
  const cacheData = {
    heroes: [],
    items: [],
  };

  /**
   * Устанавливает значение кэша для заданной категории
   * @param {string} type - категория ('heroes', 'items')
   * @param {Array} data - массив данных
   */
  function set(type, data) {
    if (!cacheData.hasOwnProperty(type)) {
      console.warn(`Unknown cache type: ${type}`);
      return;
    }

    cacheData[type] = data;
  }

  /**
   * Возвращает текущий кэш для категории
   * @param {string} type - категория
   * @returns {Array}
   */
  function get(type) {
    return cacheData[type] || [];
  }

  /**
   * Добавляет объект в кэш
   * @param {string} type - категория
   * @param {object} obj - объект для добавления
   */
  function add(type, obj) {
    if (!cacheData[type]) cacheData[type] = [];
    cacheData[type].push(obj);
  }

  /**
   * Удаляет объект по ID
   * @param {string} type - категория
   * @param {string|number} id - уникальный ID
   */
  function remove(type, id) {
    cacheData[type] = cacheData[type].filter((item) => item.id !== id);
  }

  /**
   * Очищает весь кэш
   */
  function clearAll() {
    for (const type in cacheData) {
      if (cacheData.hasOwnProperty(type)) {
        cacheData[type] = [];
      }
    }
  }

  return {
    set,
    get,
    add,
    remove,
    clearAll,
  };
})();
