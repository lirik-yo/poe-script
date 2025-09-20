const FilterLogic = (function () {
  let currentFilter = {};

  /**
   * Применяет фильтрацию к списку предметов
   * @param {Array} items - список всех предметов
   * @returns {Array} - отфильтрованные предметы
   */
  function applyFilter(items) {
    return items.filter(item => {
      // Пример: фильтрация по типу и уровню
      if (currentFilter.type && item.type !== currentFilter.type) return false;
      if (currentFilter.minLevel && item.level < currentFilter.minLevel) return false;
      if (currentFilter.maxLevel && item.level > currentFilter.maxLevel) return false;
      return true;
    });
  }

  /**
   * Устанавливает активные параметры фильтрации
   * @param {Object} filter - объект с параметрами фильтрации
   */
  function setFilter(filter) {
    currentFilter = { ...filter };
  }

  /**
   * Сбрасывает фильтр до пустого состояния
   */
  function resetFilter() {
    currentFilter = {};
  }

  function getCurrentFilter() {
    return { ...currentFilter };
  }

  return {
    applyFilter,
    setFilter,
    resetFilter,
    getCurrentFilter
  };
})();