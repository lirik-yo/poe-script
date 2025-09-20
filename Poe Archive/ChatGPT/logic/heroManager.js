// Хранилище всех героев
const HeroManager = (function () {
	const _heroes = new Map();			// id -> Hero
	let _activeHeroId = null;

	/**
	 * Асинхронно загружает героев из IndexedDB
	 */
	async function loadAll() {
		const heroData = await DB.getAllHeroes(); // предположим: возвращает массив
		heroData.forEach(data => {
			const hero = Hero.fromJSON(data);
			_heroes.set(hero.id, hero);
		});
		// по умолчанию активен первый
		if (_heroes.size > 0) {
			_activeHeroId = Array.from(_heroes.keys())[0];
		}
	}

	/**
	 * Добавляет героя и сохраняет
	 */
	async function addHero(hero) {
		if (_heroes.has(hero.id)) return false;

		_heroes.set(hero.id, hero);
		_activeHeroId = hero.id;
		await DB.saveHero(hero);
		triggerRender(); // глобальный вызов обновления
		return true;
	}

	/**
	 * Удаляет героя и обновляет состояние
	 */
	async function deleteHero(id) {
		if (!_heroes.has(id)) return false;

		_heroes.delete(id);
		await DB.deleteHero(id);

		if (_activeHeroId === id) {
			_activeHeroId = _heroes.size ? Array.from(_heroes.keys())[0] : null;
		}

		triggerRender();
		return true;
	}

	/**
	 * Устанавливает активного героя
	 */
	function setActiveHero(id) {
		if (_heroes.has(id)) {
			_activeHeroId = id;
			triggerRender();
		}
	}

	/**
	 * Возвращает активного героя
	 */
	function getActiveHero() {
		return _heroes.get(_activeHeroId) || null;
	}

	/**
	 * Получает героя по ID
	 */
	function getById(id) {
		return _heroes.get(id) || null;
	}

	/**
	 * Возвращает список всех героев
	 */
	function getAll() {
		return Array.from(_heroes.values());
	}

	return {
		loadAll,
		addHero,
		deleteHero,
		setActiveHero,
		getActiveHero,
		getById,
		getAll,
	};
})();
