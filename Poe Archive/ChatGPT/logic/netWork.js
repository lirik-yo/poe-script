const NetWork = (function () {
  async function fetchJsonFile(url) {
    try {
      const response = await fetch(url);
      if (!response.ok) throw new Error('Ошибка при загрузке: ' + url);
      return await response.json();
    } catch (error) {
      StatusBar.showError(error.message);
      return null;
    }
  }

  return {
    fetchJsonFile
  };
})();