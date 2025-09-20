class ItemManager {
	constructor() {
		this.items = new Map(); // ключ: id, значение: Item
		this._cache = new Map(); // для фильтрации и поиска
	}

	/**
	 * Загрузка всех предметов из IndexedDB
	 */
	async loadAll() {
		const data = await DB.getAllItems();
		data.forEach(itemData => {
			const item = Item.fromJSON(itemData);
			this.items.set(item.id, item);
		});
	}

	/**
	 * Добавление предмета (если такого ещё нет)
	 */
	async addItem(item) {
		if (this.items.has(item.id)) return false;

		this.items.set(item.id, item);
		await DB.saveItem(item);
		return true;
	}

	/**
	 * Удаление предмета по ID
	 */
	async deleteItem(id) {
		this.items.delete(id);
		await DB.deleteItem(id);
	}

	/**
	 * Получение предмета по ID
	 */
	getById(id) {
		return this.items.get(id) || null;
	}

	/**
	 * Получить все предметы указанного типа
	 */
	getByType(type) {
		return Array.from(this.items.values()).filter(item => item.type === type);
	}

	/**
	 * Фильтрация по свойству
	 * @param {string} prop — имя свойства
	 * @param {string} mode — has | min | max | range
	 * @param {number[]} value — значение/диапазон
	 */
	filterByProperty(prop, mode, value) {
		return Array.from(this.items.values()).filter(item => {
			const val = item.getNumeric(prop);
			if (val === null) return false;

			switch (mode) {
				case 'has': return item.hasProperty(prop);
				case 'min': return val >= value[0];
				case 'max': return val <= value[0];
				case 'range': return val >= value[0] && val <= value[1];
				default: return false;
			}
		});
	}

	/**
	 * Получить все уникальные свойства у предметов указанного типа
	 */
	collectKnownProperties(type) {
		const props = new Set();
		for (const item of this.items.values()) {
			if (type && item.type !== type) continue;
			Object.keys(item.properties).forEach(key => props.add(key));
		}
		return Array.from(props);
	}

	/**
	 * Очистить кеш фильтров
	 */
	clearCache() {
		this._cache.clear();
	}

	/**
	 * Вернуть все предметы в массиве
	 */
	getAllItems() {
		return Array.from(this.items.values());
	}
}
