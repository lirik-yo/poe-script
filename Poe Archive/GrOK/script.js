let items = []; // Массив для хранения объектов { text, imageUrl }
let currentIndex = -1; // Текущий индекс в массиве

let heroes = [];  // Новый список heroes
let currentHeroIndex = -1; // Индекс текущего героя

let toDoTasks = [];  // Новый список ToDo

let maxId = -1;

let CanWearType = []; // Таблица: строки - ID героев, столбцы - типы предметов

let WearNow = []; // Таблица: строки - ID героев, столбцы - типы предметов, значения - массивы

let ItemOrder = []; // Таблица: строки - ID героев, столбцы - предметы, значения - числа

let keyWeaknessNeuron = '';

let weaknessNeuron = [];

let uselessItem = [];

function getNetCalc(heroId, itemId, net)
{
	const heroRow = ItemOrder.find(x=>x.heroId == heroId);
	if (heroRow){
		const valueOrder = heroRow[itemId];
		if (valueOrder)
			return Math.round(10000/valueOrder)*1.0/10000;
	}
	if (net == null)
		return 0;	
	const item = items.find(x => x.id == itemId);
	return calcNet(net, processNeuron(item.text));
}

function getNextId(){
	if (maxId == -1){
		const maxLocal = localStorage.getItem('maxId');
		if (maxLocal && maxLocal>-1) {
			maxId = maxLocal;
		}else{
			if (items.length>0 || heroes.length>0){
				maxId = Math.max(Math.max(...items.map(item=>item.id || 0)), Math.max(...heroes.map(item=>item.id || 0)));
			}else{
				maxId = 0;
			}
		}
	}
	return maxId++;
}

// Функция для получения элемента по ID
function findIndexById(array, id) {
    return array.findIndex(item => item.id == id);
}

// Функция для получения названия (третья строка текста)
function getItemTitle(item) {
    const lines = item.text.split('\n');
    return lines.length >= 3 ? lines[2].trim() : 'Без названия';
}

// Функция для получения названия героя
function getHeroTitle(heroItem) {
    return heroItem.name || 'Без названия';
}

function getItemLevel(item){
    const lines = item.text.split('\n');
	const regex = /Требуется: Уровень (\d+)/;
	for (const line of lines) {
		const regRes = regex.exec(line);
		if (regRes){
			return regRes[1];
		}
	}
	return 0;
}

// Функция для получения всех уникальных типов предметов
function getUniqueItemTypes() {
    const types = new Set(items.map(item => getItemType(item)));
    return Array.from(types);
}

function getItemType(item){
    const lines = item.text.split('\n');
	const regex = /Класс предмета: (.+)/;
	for (const line of lines) {
		const regRes = regex.exec(line);
		if (regRes){
			return regRes[1];
		}
	}
	return 'Не Известно';
}

// Функция для переключения на предмет заданного типа
function switchToItemByType(type) {
    if (!type || typeof type !== 'string') {
        console.log('Ошибка: тип предмета должен быть непустой строкой');
        return false;
    }

    const newIndex = items.findIndex(item => getItemType(item) === type);
    if (newIndex !== -1) {
        currentIndex = newIndex;
        updateUI();
		saveToLocalStorage('currentIndex');
        return true;
    } else {
        return false;
    }
}

// Функция для переключения на предмет заданного типа
function switchToItemByIndex(itemIndex) {
	const newIndex = items.findIndex(i => i.id === parseInt(itemIndex, 10));
	if (newIndex !== -1) {
		currentIndex = newIndex;
		updateUI(); // Обновляем весь интерфейс
		saveToLocalStorage('currentIndex');
	}
}

// Показать плашку загрузки
function showLoadingOverlay() {
    const overlay = document.getElementById('loadingOverlay');
    overlay.classList.remove('hidden');
}

// Скрыть плашку загрузки
function hideLoadingOverlay() {
    const overlay = document.getElementById('loadingOverlay');
    overlay.classList.add('hidden');
}

// Обновить прогресс-бар
function updateProgressBar(percent) {
    const progressBar = document.getElementById('progressBar');
    progressBar.style.width = `${percent}%`;
}

// Функция для инициализации или обновления таблицы CanWearType
function updateCanWearType() {
    const heroIds = heroes.map(hero => hero.id);
    const itemTypes = getUniqueItemTypes();

    // Создаём новую таблицу
    const newTable = heroIds.map(heroId => {
        const row = {};
        itemTypes.forEach(type => {
            // Сохраняем существующие значения, если они есть, иначе -1
            const existingHeroRow = CanWearType.find(r => r.heroId === heroId);
            row[type] = existingHeroRow && existingHeroRow[type] !== undefined ? existingHeroRow[type] : -1;
        });
        return { heroId, ...row };
    });

    CanWearType = newTable;
    saveToLocalStorage('CanWearType'); // Сохраняем обновлённую таблицу
}

function updateItemOrderSetNumeric()
{	
    const heroIds = heroes.map(hero => hero.id);
    const itemTypes = getUniqueItemTypes();
	heroIds.forEach((heroId)=>{
		const heroRow = ItemOrder.find(row => row.heroId === heroId);		
		itemTypes.forEach(typeName=>{
			const sortedValue = Object.keys(heroRow)
				.filter(k=> 
					heroRow[k]!=heroId 
					&& heroRow[k]
					&& getItemType(items.find(item => item.id == k)) == typeName
				).sort((a,b)=>
					Number(heroRow[a])-Number(heroRow[b])
				);//Получаем номера предметов по тому порядку, который уже был в данных
			sortedValue.forEach((k, i)=>heroRow[k] = (i+1)*10);
		});
	});
	saveToLocalStorage('ItemOrder');
}

function updateItemOrder(){
    const heroIds = heroes.map(hero => hero.id);
    const itemIds = items.map(item => item.id);
	
    // Создаём новую таблицу
    const newTable = heroIds.map(heroId => {
        const row = {};
        itemIds.forEach(item => {
            // Сохраняем существующие массивы, если они есть, иначе пустой массив
            const existingHeroRow = ItemOrder.find(r => r.heroId === heroId);
            row[item] = existingHeroRow && existingHeroRow[item] !== undefined ? existingHeroRow[item] : undefined;
			
        });
        return { heroId, ...row };
    });

    ItemOrder = newTable;
    saveToLocalStorage('ItemOrder'); // Сохраняем обновлённую таблицу
	
}

// Функция для инициализации или обновления таблицы WearNow
function updateWearNow() {
    const heroIds = heroes.map(hero => hero.id);
    const itemTypes = getUniqueItemTypes();

    // Создаём новую таблицу
    const newTable = heroIds.map(heroId => {
        const row = {};
        const existingHeroRow = WearNow.find(r => r.heroId === heroId);
        itemTypes.forEach(type => {
            // Сохраняем существующие массивы, если они есть, иначе пустой массив
            row[type] = existingHeroRow && existingHeroRow[type] !== undefined ? existingHeroRow[type].filter(num => items.findIndex(x => x.id == num)>=0) : [];
        });
        return { heroId, ...row };
    });

    WearNow = newTable;
    saveToLocalStorage('WearNow'); // Сохраняем обновлённую таблицу
}

// Обновляем интерфейс для героев
function updateHeroUI() {
    const heroNameInput = document.getElementById('heroName');
    const heroDescriptionInput = document.getElementById('heroDescription');
    const prevHeroBtn = document.getElementById('prevHeroBtn');
    const nextHeroBtn = document.getElementById('nextHeroBtn');
    const currentHeroTitle = document.getElementById('currentHeroTitle');
	const deleteHeroBtn = document.getElementById('deleteHeroBtn');
	const percentWear = document.getElementById('percentWear');
	const heroWearTable = document.getElementById('heroWearTable');

    if (heroes.length === 0) {
        heroNameInput.value = '';
        heroDescriptionInput.value = '';
        currentHeroTitle.textContent = 'Нет героев';
        prevHeroBtn.innerHTML = '<span class="arrow">←</span> Предыдущий';
        nextHeroBtn.innerHTML = 'Следующий <span class="arrow">→</span>';
        prevHeroBtn.disabled = true;
        nextHeroBtn.disabled = true;
		deleteHeroBtn.disabled = true;
		heroWearTable.innerHTML = ''; // Очищаем таблицу
    } else {
		const heroCurrent = heroes[currentHeroIndex];
        heroNameInput.value = heroes[currentHeroIndex].name || '';
        heroDescriptionInput.value = heroCurrent.description || '';
        currentHeroTitle.textContent = `${getHeroTitle(heroCurrent)}(${heroCurrent.level})`;
		currentHeroTitle.ondblclick = function(){changeHeroLevel();};
        prevHeroBtn.innerHTML = `<span class="arrow">←</span> ${getHeroTitle(heroes[(currentHeroIndex - 1 + heroes.length) % heroes.length])}`;
        nextHeroBtn.innerHTML = `${getHeroTitle(heroes[(currentHeroIndex + 1) % heroes.length])} <span class="arrow">→</span>`;
        prevHeroBtn.disabled = heroes.length <= 1;
        nextHeroBtn.disabled = heroes.length <= 1;
		deleteHeroBtn.disabled = false;
		
		// Заполняем таблицу CanWearType
        heroWearTable.innerHTML = '';
        const heroId = heroCurrent.id;
		let countWear = 0;
		let maxCountWear = 0;
        const heroWearNowRow = WearNow.find(row => row.heroId === heroId);
        const heroCanWearRow = CanWearType.find(row => row.heroId === heroId);
        if (heroCanWearRow) {
            const wearableTypes = Object.entries(heroCanWearRow)
                .filter(([type, value]) => type !== 'heroId' && value > 0);
                // .map(([type]) => type);

            wearableTypes.forEach(([type]) => {
				maxCountWear += heroCanWearRow[type];
                const tr = document.createElement('tr');
                const tdType = document.createElement('td');
                const tdItems = document.createElement('td');

                tdType.textContent = type;
				tdType.addEventListener('dblclick', ()=>{switchToItemByType(type);});
				
				// Заполняем второй столбец данными из WearNow
                if (heroWearNowRow && heroWearNowRow[type] && heroWearNowRow[type].length > 0) {
					countWear += heroWearNowRow[type].length;
					heroWearNowRow[type].forEach(itemId=>{
						const spanItem = document.createElement('span');
                        const item = items.find(i => i.id === itemId);
						spanItem.textContent = 	item ? getItemTitle(item) : `ID ${itemId} (не найден)`;
						
						addEventMouseMoveShowItemText(spanItem, item);
						spanItem.addEventListener('dblclick', ()=>{
							switchToItemByIndex(itemId);
						});
						tdItems.appendChild(spanItem);
					});
					
                    const itemTitles = heroWearNowRow[type]
                        .map(itemId => {
                            const item = items.find(i => i.id === itemId);
							return '';
							return item ? `<span ondblclick="switchToItemByIndex(${itemId})">${getItemTitle(item)}</span>` : `ID ${itemId} (не найден)`;
                        })
                        .join(', ');
						
						
                } else {
                    // tdWearNow.textContent = '—';
                }
				if (heroWearNowRow[type].length == heroCanWearRow[type]) tr.style.backgroundColor = 'lightgreen';
                tr.appendChild(tdType);
                tr.appendChild(tdItems); 
                heroWearTable.appendChild(tr);
            });
			
			const unidefineType = Object.entries(heroCanWearRow).find(([type, value])=>value<0);
			if (unidefineType){
				
                const tr = document.createElement('tr');
                const td = document.createElement('td');
                td.textContent = `Неопределён предел для: ${unidefineType[0]}`;
				td.addEventListener('dblclick', ()=>{switchToItemByType(unidefineType[0]);});
                td.colSpan = 2;
                tr.appendChild(td);
                heroWearTable.appendChild(tr);				
			}

            if (wearableTypes.length === 0) {
                const tr = document.createElement('tr');
                const td = document.createElement('td');
                td.textContent = 'Нет доступных типов';
                td.colSpan = 2;
                tr.appendChild(td);
                heroWearTable.appendChild(tr);
            }
			percentWear.textContent = `Одет на ${Math.round(100*countWear/maxCountWear)}%(${countWear}/${maxCountWear})`;
        } else {
            const tr = document.createElement('tr');
            const td = document.createElement('td');
            td.textContent = 'Данные CanWearType отсутствуют';
            td.colSpan = 2;
            tr.appendChild(td);
            heroWearTable.appendChild(tr);
			percentWear.textContent = 'Нет данных об одежде';
        }
    }
}

function getHeroesWearingItem(itemId) {
    return heroes
        .filter(hero => {
            const heroRow = WearNow.find(row => row.heroId === hero.id);
            if (!heroRow) return false;
            return Object.values(heroRow)
                .filter(Array.isArray)
                .some(itemArray => itemArray.includes(itemId));
        });
}

function getMaxItemLevelFromWearNow(heroId) {
    const heroRow = WearNow.find(row => row.heroId === heroId);
    if (!heroRow) return 0;

    return Object.values(heroRow)
        .filter(Array.isArray)
        .flat()
        .reduce((max, itemId) => {
            const item = items.find(i => i.id === itemId);
            return item ? Math.max(max, parseInt(getItemLevel(item), 10)) : max;
        }, 0);
}

function changeHeroLevel(currentType){
	const currentHero = heroes[currentHeroIndex];
	const newLevel = prompt(`Введите новый уровень для ${currentHero.name} (текущий: ${currentHero.level}):`, currentHero.level);
	if (newLevel !== null) { // Проверяем, что не нажата "Отмена"
		const parsedLevel = parseInt(newLevel, 10);
		const minimumItemLevel = getMaxItemLevelFromWearNow(currentHero.id);
		if (!isNaN(parsedLevel) && parsedLevel >= minimumItemLevel && parsedLevel <= 100) { // Проверяем, что число и >= 1
			currentHero.level = parsedLevel;
			saveToLocalStorage('heroes');
			updateHeroUI(); // Обновляем интерфейс
		} else {
			alert(`Пожалуйста, введите корректный уровень (целое число >= ${minimumItemLevel}).`);
		}
	}
}

// Функция для обновления интерфейса
function updateLists(item) {
	const text = item.text;
    const tableProperties = document.getElementById('tableProperties');
    const tableItems = document.getElementById('tableItems');
    tableProperties.innerHTML = '';
    tableItems.innerHTML = '';

    // Разбиваем текст на строки и добавляем каждую в таблицу tableProperties
    const lines = text.split('\n').filter((s)=>{
        const trimmedLine = s.trim();
		const isOnlyDashesOrEmpty = trimmedLine === '' || /^-+$/.test(trimmedLine);
		return !isOnlyDashesOrEmpty;
	});
	// text = lines.join('\n');
	const neuronResult = processNeuron(item.text); // Получаем результаты обработки нейронов
	const skipLines = neuronResult.successfulLines.concat([2]);
    lines.forEach((line, index) => {
		if (skipLines.includes(index)) return;
        // const trimmedLine = line.trim();
		// const isOnlyDashesOrEmpty = trimmedLine === '' || /^-+$/.test(trimmedLine);
        // if (!isOnlyDashesOrEmpty) { // Пропускаем пустые строки и строки только с '-'
            const tr = document.createElement('tr');
            const th = document.createElement('th');
            const td = document.createElement('td');
			
			// Проверяем, есть ли эта строка в failedLines
            // th.textContent = neuronResult.failedLines.includes(line) ? 'Необработано' : '';
            th.textContent = 'Необработано';
			
            td.textContent = line;
            tr.appendChild(th);
            tr.appendChild(td);
            tableProperties.appendChild(tr);
        // }
    });
	
	// Сортируем Object.entries по orderOut
	const sortedEntries = Object.entries(neuronResult.successfulNeuron)
	.filter(([neuronName])=>{
		const orderShow = neuronOrderShowMap.get(neuronName) ?? 0;
		return orderShow > 0;
	}).sort(([neuronNameA], [neuronNameB]) => {
		const orderA = neuronOrderShowMap.get(neuronNameA) ?? 0;
		const orderB = neuronOrderShowMap.get(neuronNameB) ?? 0;
		return orderA - orderB;
	});	
	
	
	// Добавляем строки для каждой выполненной функции
    for (const [neuronName, results] of sortedEntries) {
        const tr = document.createElement('tr');
        const th = document.createElement('th');
        const td = document.createElement('td');
        
        th.textContent = neuronName; // Название функции
		if (results.length>1){
			// Создаём маркированный список
			const ul = document.createElement('ul');
			results.forEach(result => {
				const li = document.createElement('li');
				li.textContent = `${result.result}`;
				ul.appendChild(li);
			});
			td.appendChild(ul);
		}else{
			td.textContent = `${results[0].result}`;
		}
        
        tr.appendChild(th);
        tr.appendChild(td);
        tableProperties.appendChild(tr);
    }

	const needType = getItemType(item);
	let wearType = null;
	let canWearType = -1;
	const heroId = heroes[currentHeroIndex].id;
	const heroRowWear = WearNow.find(row => row.heroId === heroId);
	if (heroRowWear && heroRowWear[needType]){
		wearType = heroRowWear[needType];
	}else{
		wearType = [];
	}
	const heroRowCanWear = CanWearType.find(row => row.heroId === heroId);		
	if (heroRowCanWear && heroRowCanWear[needType]){
		canWearType = heroRowCanWear[needType];
	}else{
		canWearType = -1;
	}
	const net = getOrCreateNet(needType, heroId);
	const trainingSet = collectTrainingSet(heroId);
	trainingNet(net, trainingSet, needType, heroId);
	const heroLevel = heroes[currentHeroIndex].level;
	const fullWear = wearType.length>=canWearType;
	const heroItemOrder = ItemOrder.find(row => row.heroId == heroId);
	
	const itemsHeroType = items
		.filter(checkItem=>getItemType(checkItem) == needType)
		.sort((item1,item2)=>getNetCalc(heroId, item2.id, net)-getNetCalc(heroId, item1.id, net));
		
	const keyWeakness = `${heroId}_${needType}`;
	if (keyWeakness != keyWeaknessNeuron){
		weaknessNeuron = analyzeWeakNeurons(itemsHeroType);
		keyWeaknessNeuron = keyWeakness;
		uselessItem = analyzeUselessItems(needType)
	}
		
	itemsHeroType.forEach(checkItem =>{
			const tr2 = document.createElement('tr');
			const th2Item = document.createElement('th');
			const td2Order = document.createElement('td');
			// const td2Value = document.createElement('td');
									
			th2Item.textContent = getItemTitle(checkItem);
			const netCalc = getNetCalc(heroId, checkItem.id, net);
			// td2Value.textContent = netCalc>0?netCalc:calcNet(net, processNeuron(checkItem.text));
			th2Item.dataset.id = checkItem.id; // ID уже есть	
			td2Order.textContent = heroItemOrder[checkItem.id] ? heroItemOrder[checkItem.id] : '';
			tr2.appendChild(th2Item);
			tr2.appendChild(td2Order);
			// tr2.appendChild(td2Value);
			tableItems.appendChild(tr2);
			
			th2Item.style.background = defineColorItem(checkItem, heroes[currentHeroIndex], wearType, canWearType);
			td2Order.style.background = defineColorItemOrder(item, checkItem, heroes[currentHeroIndex], wearType);

			addEventMouseMoveShowItemText(th2Item, checkItem);
			
			th2Item.addEventListener('click', ()=>{
				if (event.ctrlKey){
					const itemId = parseInt(th2Item.dataset.id, 10);
					const clickedItem = items.find(i => i.id === itemId);
					if (!clickedItem) return;
					if (heroes.length == 0) return;
					if (currentHeroIndex == -1) return;
					changeWearingItem(itemId, heroes[currentHeroIndex].id, needType);	
				}else if (event.shiftKey){
					const itemId = parseInt(th2Item.dataset.id, 10);
					const clickedItem = items.find(i => i.id === itemId);
					if (!clickedItem) return;
					navigator.clipboard.writeText(getItemTitle(clickedItem));
					window.getSelection().removeAllRanges()
				}					
			});
			
			// Добавляем обработчик двойного клика
            th2Item.addEventListener('dblclick', () => {
				switchToItemByIndex(th2Item.dataset.id);
            });
			
			td2Order.addEventListener('dblclick', () => {
				askItemOrder(th2Item.dataset.id, heroId, needType);
			});
		}
	);
}

function defineColorItemOrder(itemNow, checkedItem, hero, wearType){
	if (itemNow == checkedItem)
		return 'lightblue';
	if (wearType.includes(checkedItem.id))
		return 'lightgreen';
	if (weaknessNeuron.weakItems.has(checkedItem))
		return 'pink';
	if (uselessItem.includes(checkedItem))
		return 'lightgray';
	return 'white';
}

function defineColorItem(item, hero, wearType, canWearType){
	if (canWearType <= 0) return 'black'; //Не может носить
	if (wearType && wearType.includes(item.id))
		return 'lightgreen';	//Носит прямо сейчас
	const haveOtherWear = WearNow.some(x=>Object.values(x).filter(Array.isArray).some(itemArray => itemArray.includes(item.id)));	
	const levelOk = hero.level >= getItemLevel(item);
	
	if (haveOtherWear) return 'gray';	
	
	if (wearType.length>=canWearType){//Слоты уже заполнены
		return levelOk ? 'pink' : 'orange';
	}
	return levelOk ? 'white' : 'palegoldenrod';
}

function collectTrainingSet(heroId) {
    const results = [];
    
    items.forEach(checkItem => {
        const netCalcValue = getNetCalc(heroId, checkItem.id, null);
        if (netCalcValue !== 0) {
            const neuronResult = processNeuron(checkItem.text);
            const trainingSet = prepareTrainingSet(
                getItemTitle(checkItem),
                neuronResult,
                netCalcValue
            );
            results.push(trainingSet);
        }
    });
    
    return results;
}

function addEventMouseMoveShowItemText(element, item){
	// const text = item.text;
	const tooltip = document.getElementById('tooltip');
	element.addEventListener('mouseover', ()=>{
		showComparisonTooltip(item);
		tooltip.style.display = 'block';
	});
	
	element.addEventListener('mouseout', ()=>{
		tooltip.style.display = 'none';
	});
}

function showComparisonTooltip(hoveredItem) {
    const currentItem = items[currentIndex];
    const tooltip = document.getElementById('tooltip');
    const tooltipNameHoverItem = document.getElementById('tooltipNameHoverItem');
    const tooltipHoverItem = document.getElementById('tooltipHoverItem');
    const tableDifferenceProperty = document.getElementById('tableDifferenceProperty');
    const currentHero = heroes[currentHeroIndex];
    const heroId = currentHero ? currentHero.id : null;
    
    // Находим надетый предмет для текущего героя и типа наведённого предмета
    const typeItem = getItemType(hoveredItem);
	
	tooltipHoverItem.textContent = hoveredItem.text;
	tooltipNameHoverItem.textContent = getItemTitle(hoveredItem);
	
	const hoverEqCurrent = hoveredItem == currentItem;
	
	tableDifferenceProperty.innerHTML = '';
	
    let wornItemId = [];
    if (heroId && WearNow) {
        const wearRow = WearNow.find(row => row.heroId === heroId);
        if (wearRow && wearRow[typeItem] && wearRow[typeItem].length > 0) {
            wornItemId = wearRow[typeItem].filter(x=>x!=currentItem.id && x!=hoveredItem.id); // Берём все надетые предметы
        }
    }
	
	let wornItem = [];
	if (wornItemId.length > 0){
		wornItem = wornItemId.map(id => items.find(item => item.id === id));
	}
	const itemsByColumn = hoverEqCurrent ? [hoveredItem, ...wornItem] : [hoveredItem, currentItem, ...wornItem];
	
	if (itemsByColumn.length <= 1) return;
	
	const trCaption = document.createElement('tr');
	trCaption.appendChild(document.createElement('td'));
	
	if (hoverEqCurrent){
		const thHC = document.createElement('th');
		thHC.textContent = getItemTitle(hoveredItem);
		trCaption.appendChild(thHC);		
	}else{
		const thHover = document.createElement('th');
		thHover.textContent = getItemTitle(hoveredItem);
		trCaption.appendChild(thHover);
		const thCurrent = document.createElement('th');
		thCurrent.textContent = getItemTitle(currentItem);
		trCaption.appendChild(thCurrent);
	}
	
	wornItem.forEach(item=>{
		const thWorn = document.createElement('th');
		thWorn.textContent = getItemTitle(item);
		trCaption.appendChild(thWorn);
	});
	
	tableDifferenceProperty.appendChild(trCaption);
		
	
	const neuronPrepare = neurons.filter(x=>x.orderShow > 0).sort((a,b) => a.orderShow - b.orderShow);
	
	neuronPrepare.forEach(neuron =>{
		const valueNeuron = itemsByColumn.map(item => calcNeuronText(neuron, item.text));
		if (new Set(valueNeuron).size != 1){			
			const trValue = document.createElement('tr');
			const thValue = document.createElement('th');
			thValue.textContent = neuron.name;
			trValue.appendChild(thValue);
			
			const example = valueNeuron[0];//Что нейрон выдал на наведённом предмете
			const exampleValue = example || 0;//Какое значение надо использовать для нейрона на наведённом предмете
			valueNeuron.forEach(value =>{
				const tdValue = document.createElement('td');
				if (value === false){
					if (example === false){//И сравниваемое и текущее не содержит значений - ничего не стоит писать в таблицу
					}else{//Если сравниваемое пусто, а текущее нет - пишем с минус значение у текущего
						if (isFinite(example)){
							tdValue.textContent = `0 (${-example})`;
							tdValue.className = 'worse';						
						}else{
							tdValue.textContent = `Нет (${example})`;
							tdValue.className = 'worse';													
						}
					}
				}else{
					if (example === false){//Если сравниваемое есть, а текущее нет - пишем значение с плюсом
						tdValue.textContent = `+${value}`;
						tdValue.className = 'better';						
					}else if (example != value){//Есть оба значения, надо писать сравниваемое, но аккуратнее с разницей.
						const diffValue = value - example;
						if (isNaN(diffValue)){
							tdValue.textContent = `${value}`;
							tdValue.className = 'undefined';
						}else{
							const beatyDiffValue = Math.round(diffValue * 100) / 100;
							tdValue.textContent = value + ' (' + (diffValue>0?'+':'') + beatyDiffValue + ')';
							tdValue.className = diffValue>0 ? 'better' : 'worse';
						}
					}else{
						tdValue.textContent = `${value}`;
					}
				}				
				trValue.appendChild(tdValue);				
			});
			tableDifferenceProperty.appendChild(trValue);			
		}
	});
}

function askItemOrder(itemId, heroId, needType){
	const item = items[findIndexById(items, itemId)];
	const hero = heroes[findIndexById(heroes, heroId)];
	const heroRow = ItemOrder.find(row => row.heroId === heroId);
	if (!heroRow) return;
	let newValue = false;
	
	while (newValue = prompt(`Введите новый порядок для ${getItemTitle(item)} (герой ${getHeroTitle(hero)}). Важно - он должен отличаться от прошлых`, heroRow[itemId] || 0)){
		if (Object.keys(heroRow).some(k=> heroRow[k]!=heroId && heroRow[k] == newValue && getItemType(items.find(x=>x.id == k))==needType)) continue;
		heroRow[itemId] = newValue;
		saveToLocalStorage('ItemOrder');
		updateUI();
		break;
	}
}

function changeWearingItem(itemId, heroId, needType){
	const heroRow = WearNow.find(row => row.heroId === heroId);
	const heroRowCan = CanWearType.find(row => row.heroId === heroId);
	if (!heroRow) return;
	if (!heroRowCan) return;
	// const needType = getItemType(item);
	const hero = heroes[findIndexById(heroes, heroId)];
	const item = items[findIndexById(items, itemId)];
	const wearList = heroRow[needType];
	if (!wearList) return;
	const wearCanCount = heroRowCan[needType];
	const itemIndex = wearList.indexOf(itemId);
	if (itemIndex === -1) {		
		if (wearCanCount<=wearList.length) return;
		const haveOtherWear = getHeroesWearingItem(itemId);
		if (haveOtherWear.length>0){
			const yesChangeHero = confirm("Этот предмет одет на другого персонажа. Переключить на носящего предмет героя?");
			if (!yesChangeHero) return;
			const heroIndex = findIndexById(heroes, haveOtherWear[0].id);
			currentHeroIndex = heroIndex;
			updateUI();
			saveToLocalStorage('currentHeroIndex');
			return;
		}
		const levelItem = getItemLevel(item);
		// Добавляем ID, если его нет
		if (hero.level<levelItem) {
			const yesLevelUp = confirm("Уровень героя ниже уровня предмета. Поднять уровень героя?");
			if (!yesLevelUp) return;
			hero.level = levelItem;
			saveToLocalStorage('heroes');
		}
		wearList.push(itemId);
	} else {
		// Удаляем ID, если он есть
		wearList.splice(itemIndex, 1);
	}
	saveToLocalStorage('WearNow');
	updateUI(); // Обновляем интерфейс
}

// Функция для сохранения всех списков в localStorage (вызываем при изменениях)
function saveToLocalStorage(oneTable = null) {
	const savedData = {items, heroes, toDoTasks, maxId, CanWearType, WearNow, ItemOrder, currentIndex, currentHeroIndex};
	Object.keys(savedData).forEach( (key) =>{
		if (!oneTable || (key == oneTable))
			localStorage.setItem(key, JSON.stringify(savedData[key]));
	});
}

function updateItemUI(){
	const input = document.getElementById('inputText');
    const title = document.getElementById('currentTitle');
    const prevBtn = document.getElementById('prevBtn');
    const nextBtn = document.getElementById('nextBtn');
	const deleteBtn = document.getElementById('deleteBtn');
	const typeNameItem = document.getElementById('typeNameItem');
    // const displayImage = document.getElementById('displayImage');
    // const imageUrlInput = document.getElementById('imageUrl');

    if (items.length === 0) {
        input.value = '';
        title.textContent = 'Нет элементов';
        prevBtn.innerHTML = '<span class="arrow">←</span> Назад';
        nextBtn.innerHTML = 'Вперёд <span class="arrow">→</span>';
        prevBtn.disabled = true;
        nextBtn.disabled = true;
        deleteBtn.disabled = true;
		// displayImage.style.display = 'none';
        // imageUrlInput.value = '';
    } else {
		const currentItem = items[currentIndex];
		const currentType = getItemType(currentItem);
		
        input.value = currentItem.text;
        title.textContent = `${getItemTitle(currentItem)} (${getItemLevel(currentItem)})`;
		addEventMouseMoveShowItemText(title, currentItem);
        prevBtn.innerHTML = `<span class="arrow">←</span> ${getItemTitle(items[(currentIndex - 1 + items.length) % items.length])}`;
        nextBtn.innerHTML = `${getItemTitle(items[(currentIndex + 1) % items.length])} <span class="arrow">→</span>`;
        prevBtn.disabled = items.length <= 1;
        nextBtn.disabled = items.length <= 1;
        deleteBtn.disabled = false;
        updateLists(currentItem);
		
		// Получаем значение из CanWearType для текущего героя и типа
        let canWearValue = 'N/A'; // Значение по умолчанию, если данных нет
        if (heroes.length > 0 && currentHeroIndex !== -1) {
            const heroId = heroes[currentHeroIndex].id;
            const heroRow = CanWearType.find(row => row.heroId === heroId);
            if (heroRow && heroRow[currentType] !== undefined) {
                canWearValue = heroRow[currentType];
            }
        }
		// Получаем значение из WearNow для текущего героя и типа
        let wearNow = '-'; // Значение по умолчанию, если данных нет
        if (heroes.length > 0 && currentHeroIndex !== -1) {
            const heroId = heroes[currentHeroIndex].id;
            const heroRow = WearNow.find(row => row.heroId === heroId);
            if (heroRow && heroRow[currentType] !== undefined) {
                wearNow = heroRow[currentType].length;
            }
        }
		// Получаем список героев, которые могут носить этот тип
        const heroesWearingType = getHeroesWearingType(currentType);//.filter(hero=>hero!=heroes[currentHeroIndex]);
		const spanHeroesWearingType = heroesWearingType.map((hero)=>{
			return `<span class="hero-name-can-wear" data-hero-id="${hero.id}">${getHeroTitle(hero)}</span>`;
		});
        const heroesText = heroesWearingType.length > 0 
            ? `<span class="heroes-list">[${spanHeroesWearingType.join(', ')}]</span>` 
            : '[Никто]';
        typeNameItem.innerHTML = `${currentType} <span id="NumberCanWear">(${wearNow}/${canWearValue})</span> ${heroesText}`;
		typeNameItem.querySelector('#NumberCanWear').addEventListener('dblclick', ()=>{
			changeWearLimit(currentType, canWearValue);// Добавляем обработчик двойного щелчка
		});
		
        typeNameItem.querySelectorAll('.hero-name-can-wear').forEach(span => {
			span.addEventListener('dblclick', () => {				
				const heroIndex = findIndexById(heroes, span.dataset.heroId);
				if (heroIndex !== -1 && heroIndex != currentHeroIndex) {
					saveCurrentHero();
					currentHeroIndex = heroIndex;
					updateUI();
					saveToLocalStorage('currentHeroIndex');
				}
			});
		});
    }
}

function changeWearLimit(currentType, canWearValue){
	if (heroes.length === 0 || currentHeroIndex === -1) {
		alert('Выберите героя для редактирования CanWearType.');
		return;
	}
	const heroId = heroes[currentHeroIndex].id;
	const newValue = prompt(`Введите значение для ${currentType} (герой ${heroes[currentHeroIndex].name}):`, canWearValue);
	if (newValue !== null) { // Проверяем, что пользователь не нажал "Отмена"
		const parsedValue = parseInt(newValue, 10);
		if (!isNaN(parsedValue)) {
			const heroRow = CanWearType.find(row => row.heroId === heroId);
			if (heroRow) {
				heroRow[currentType] = parsedValue;
				saveToLocalStorage('CanWearType');
				updateUI(); // Обновляем интерфейс
			}
		} else {
			alert('Пожалуйста, введите корректное число.');
		}
	}
}

// Функция сохранения текущего героя перед переключением
function saveCurrentHero() {
    if (currentHeroIndex !== -1) {
        // const heroNameInput = document.getElementById('heroName');
        const heroDescriptionInput = document.getElementById('heroDescription');
        // heroes[currentHeroIndex].name = heroNameInput.value.trim();
        heroes[currentHeroIndex].description = heroDescriptionInput.value.trim();
        saveToLocalStorage('heroes'); // С сохраняем изменения в localStorage		
    }
}

// Функция добавления героя
function addHero() {
    const heroNameInput = document.getElementById('heroName');
    const heroDescriptionInput = document.getElementById('heroDescription');
    const name = heroNameInput.value.trim();
    const description = heroDescriptionInput.value.trim();

    if (name === '' && description === '') return; // Не добавляем пустые записи

    const newHero = { id:getNextId(), name:name, description:description, level: 1 };
    const existingIndex = heroes.findIndex(h => h.name === name && h.description === description);
    if (existingIndex !== -1) {
        currentHeroIndex = existingIndex;
		saveToLocalStorage('currentHeroIndex');
    } else {
        heroes.push(newHero);
        currentHeroIndex = heroes.length - 1;
		updateCanWearType(); // Обновляем таблицу при добавлении героя
		updateWearNow(); // Обновляем WearNow при добавлении героя
		updateItemOrder(); // Обновляем ItemOrder при добавлении героя
        saveToLocalStorage();
    }
    heroNameInput.value = '';
    heroDescriptionInput.value = '';
    updateUI();
}

// Функция для обновления интерфейса
function updateUI() {
    updateItemUI();
	updateHeroUI(); // Обновляем UI героев
}

// Загрузка данных из localStorage при старте
window.onload = function() {
    const savedItems = localStorage.getItem('items');
    if (savedItems) {
        items = JSON.parse(savedItems);
		if (items.length == 0){
			currentIndex = -1;
		}else{		
			const savedCurrentIndex = localStorage.getItem('currentIndex');
			if (savedCurrentIndex) {
				currentIndex = JSON.parse(savedCurrentIndex);
			}
			if (currentIndex >= items.length)
				currentIndex = items.length - 1;
		}
    }	
    const savedHeroes = localStorage.getItem('heroes');
    if (savedHeroes) {
        heroes = JSON.parse(savedHeroes);
		heroes.forEach((hero)=>{if (hero.level == undefined) hero.level=1;});// Устанавливаем уровень 1 по умолчанию
		currentHeroIndex = heroes.length > 0 ? 0 : -1;		
		if (heroes.length == 0){
			currentHeroIndex = -1;
		}else{		
			const savedCurrentHeroIndex = localStorage.getItem('currentHeroIndex');
			if (savedCurrentHeroIndex) {
				currentHeroIndex = JSON.parse(savedCurrentHeroIndex);
			}
			if (currentHeroIndex >= heroes.length)
				currentHeroIndex = heroes.length - 1;
		}
    }
    const savedToDoTasks = localStorage.getItem('toDoTasks');
    if (savedToDoTasks) {
        toDoTasks = JSON.parse(savedToDoTasks);
		toDoTasks.forEach((x, i)=>console.log(i, x));
		console.log('Напиши для добавки задачи: addTask("qqq")');
		console.log('Напиши для удаления задачи: removeTask(qqq)');
    }
	const savedCanWearType = localStorage.getItem('CanWearType');
    if (savedCanWearType) {
        CanWearType = JSON.parse(savedCanWearType);
    }
	const savedWearNow = localStorage.getItem('WearNow');
    if (savedWearNow) {
        WearNow = JSON.parse(savedWearNow);
    }
	const savedItemOrder = localStorage.getItem('ItemOrder');
    if (savedItemOrder) {
        ItemOrder = JSON.parse(savedItemOrder);
    }
	updateId();
	updateCanWearType(); // Обновляем таблицу после загрузки данных
	updateWearNow(); // Обновляем WearNow после загрузки данных
	updateItemOrder(); // Обновляем ItemOrder после загрузки данных
	updateItemOrderSetNumeric();
	removeDuplicates();
	
    updateUI();
};

function updateId(){
	items.forEach((x)=>{
		if (!x.id) x.id = getNextId();
	});
	heroes.forEach((x)=>{
		if (!x.id) x.id = getNextId();
	});
}

// Функция удаления дублей из items по полю text
function removeDuplicates() {
    const seen = new Set(); // Для отслеживания уникальных text
    const uniqueItems = [];

    // Проходим по массиву items с конца, чтобы сохранить последние вхождения (можно изменить порядок)
    for (let i = items.length - 1; i >= 0; i--) {
        const item = items[i];
        if (!seen.has(item.text)) {
            seen.add(item.text);			
			cleanItem(item);//Убираем лишние пробелы, прочерки			
            uniqueItems.unshift(item); // Добавляем в начало, чтобы сохранить порядок
        }
    }

    // Обновляем items
    items = uniqueItems;
    currentIndex = Math.max(Math.min(currentIndex, items.length - 1), 0);
    saveToLocalStorage('items');
    saveToLocalStorage('currentIndex');
    updateUI();

    console.log('Дубли удалены. Надо научиться зачищать те предметы, которые плохи для всех. И писать об этом.');
}

function cleanItem(item){	
	item.text = cleanTextItem(item.text);
}

function cleanTextItem(text){
	const lines = text.split('\n').filter((s)=>{
		const trimmedLine = s.trim();
		const isOnlyDashesOrEmpty = trimmedLine === '' || /^-+$/.test(trimmedLine);
		return !isOnlyDashesOrEmpty;
	});
	return lines.join('\n');
}

function getNextUndefined(){	
	showLoadingOverlay();
	// updateProgressBar(0);
	let foundIndex = -1;
	for (let i = 0; i < items.length; i++){
		const item = items[i];
        const neuronResult = processNeuron(item.text);
		if (neuronResult.failedLines.length > 1){
			//Название всегда будет непонятным.    
			foundIndex = i;
			break;
		}
		console.log(Math.round(100*i/items.length));
		// await updateProgressBar(Math.round(100*i/items.length));
	}

    if (foundIndex !== -1) {
        currentIndex = foundIndex;
        updateUI();
		saveToLocalStorage('currentIndex');
	}else{
		document.getElementById('NextUndefined').style.display = 'none';
	}
	hideLoadingOverlay();
}

function getHeroesWearingType(itemType) {
    return heroes
        .filter(hero => {
            const heroRow = CanWearType.find(row => row.heroId === hero.id);
            return heroRow && heroRow[itemType] != 0;
        });
}

// Функция загрузки предметов из файла
function loadItemsFromFile() {
    const fileInput = document.getElementById('fileInput');
    const file = fileInput.files[0];
    if (!file) {
        alert('Пожалуйста, выберите файл.');
        return;
    }

    const reader = new FileReader();
    
    reader.onload = function(event) {
        const content = event.target.result;
        try {
            if (file.name.endsWith('.json')) {
                // Обработка JSON-файла
                const parsedItems = JSON.parse(content);
                if (Array.isArray(parsedItems)) {
                    parsedItems.forEach(item => {
						var newItem = '';
                        if (typeof item === 'string') {
							newItem = item;
                        } else if (item.text) {
							newItem = item.text;
                        }
						
						const existingIndex = items.findIndex(x=>x.text==newItem);
						if (existingIndex == -1) {
							cleanItem(item);
							items.push({ id:getNextId(), text: newItem, imageUrl: ''});
						}
                    });
                } else {
                    throw new Error('JSON должен содержать массив предметов.');
                }
            } 
            currentIndex = items.length > 0 ? items.length - 1 : -1;
			updateCanWearType(); // Обновляем таблицу после загрузки предметов
			updateWearNow(); // Обновляем WearNow после загрузки предметов
			updateItemOrder(); // Обновляем ItemOrder после загрузки предметов
            saveToLocalStorage();
            updateUI();
        } catch (error) {
            alert('Ошибка при обработке файла: ' + error.message);
            console.error('Ошибка:', error);
        }
    };

    reader.onerror = function() {
        alert('Ошибка чтения файла.');
        console.error('Ошибка чтения файла:', reader.error);
    };

    // Читаем файл как текст
    reader.readAsText(file);
	
	document.getElementById('fileInput').value = ''; // Очищаем поле файла
}

// Функция добавления задачи в список todo
function addTask(task) {
    if (typeof task !== 'string' || task.trim() === '') return; // Проверяем, что задача — непустая строка
    toDoTasks.push(task.trim());
    saveToLocalStorage('toDoTasks'); // Сохраняем изменения в localStorage
}

// Функция удаления задачи из списка todo по индексу
function removeTask(index) {
    if (typeof index !== 'number' || index < 0 || index >= todo.length) return; // Проверяем валидность индекса
    toDoTasks.splice(index, 1); // Удаляем элемент по индексу
    saveToLocalStorage('toDoTasks'); // Сохраняем изменения в localStorage
}

function addToList() {
    const input = document.getElementById('inputText');
    const text = cleanTextItem(input.value.trim());	
    if (text === '') return;

    const existingIndex = items.findIndex(item => item.text === text);
    if (existingIndex !== -1) {
        currentIndex = existingIndex;
        updateUI();		
    } else {
        items.push({ id:getNextId(), text: text, imageUrl: '' }); // Новый объект с пустым URL
        currentIndex = items.length - 1;		
		updateCanWearType(); // Обновляем таблицу при добавлении предмета
		updateWearNow(); // Обновляем WearNow при добавлении предмета
		updateItemOrder(); //Обновляем ItemOrder при добавлении предмета
        saveToLocalStorage('items');
		saveToLocalStorage('maxId');
        input.value = '';
        updateUI();
    }
	saveToLocalStorage('currentIndex');
}

// Функция загрузки изображения
function loadImage() {
    const imageUrlInput = document.getElementById('imageUrl');
    const url = imageUrlInput.value.trim();
    if (url && currentIndex !== -1) {
        items[currentIndex].imageUrl = url;
        saveToLocalStorage('items');
        updateUI();
    }
}

// Функция очистки изображения
function clearImage() {
    if (items.length === 0) return;
    const confirmation = confirm(`Вы уверены, что хотите удалить картинку для "${getItemTitle(items[currentIndex])}"?`);
    if (confirmation) {
        items[currentIndex].imageUrl = '';
        saveToLocalStorage('items');
        updateUI();
    }
}

// Функция удаления текущего элемента
function deleteCurrentItem() {
    if (items.length === 0) return;
	const currentItem = items[currentIndex];
	const currentType = getItemType(currentItem); // Сохраняем тип удаляемого предмета
	const currentItemTitle = getItemTitle(currentItem);
	const heroesWearing = getHeroesWearingItem(currentItem.id);
	const currentHero = heroes[currentHeroIndex];
	if (weaknessNeuron.weakItems.has(currentItem)){
		const yesDeleteWeakNeuronItem = confirm("Этот предмет нужен для материала работы нейронной сети. Вы уверены, что хотите его убрать?");
		if (!yesDeleteWeakNeuronItem) return;
	}
	if (heroesWearing.length > 0){
		if (heroesWearing.includes(currentHero)){
			alert('Эта вещь носится текущим героем. Вы не можете её удалить.');
			return;
		}
		const yesChangeHero = confirm("Этот предмет не может быть удалён, так как одет на другого персонажа. Переключить на носящего предмет героя?");
		if (!yesChangeHero) return;
		const heroIndex = findIndexById(heroes, heroesWearing[0].id);
		currentHeroIndex = heroIndex;
		updateUI();
		saveToLocalStorage('currentHeroIndex');
		return;	
	}
    const confirmation = confirm(`Вы уверены, что хотите удалить "${currentItemTitle}"?`);
    if (confirmation) {
        items.splice(currentIndex, 1);
        if (items.length === 0) {
            currentIndex = -1;
        } else{
			const newIndex = items.findIndex(item => getItemType(item) == currentType);
			if (newIndex == -1){
				currentIndex = Math.min(curentIndex, items.length -1);
			}else{
				currentIndex = newIndex;
			}
			// if (currentIndex >= items.length) {
            // currentIndex = items.length - 1;
        }
		updateCanWearType(); // Обновляем таблицу при удалении предмета
		updateWearNow(); // Обновляем WearNow при удалении предмета
		updateItemOrder(); // Обновление ItemOrder при удаление предмета
        saveToLocalStorage('items');
        saveToLocalStorage('currentIndex');
        updateUI();
    }
}

function analyzeUselessItems(itemType){
	const usefulItems = new Set();
	const maxTopItem = Math.round(heroes.length * 1.4);
	const maxLowerItem = 3;
	
	const itemsTypeUnsorted = items
		.filter(checkItem=>getItemType(checkItem) == itemType);//Если у нас всего предметов меньше границы, то у нас нет слишком слабых предметов
		
	if (itemsTypeUnsorted.length <= maxTopItem) return [];
	
	for (const hero of heroes){
		if (usefulItems.length == itemsTypeUnsorted.length) break;//Все предметы в том или ином виде нужны - нечего объявлять бесполезным
		const heroId = hero.id;//heroes[currentHeroIndex].id;//
        const heroCanWearRow = CanWearType.find(row => row.heroId === heroId)[itemType]; 
		if (heroCanWearRow<=0)
			continue;//Нет смысла проверять на герое, который не пользуется этим типом предмета.
		const heroWearNow = WearNow.find(row => row.heroId === heroId)[itemType];
		const net = getOrCreateNet(itemType, heroId);
		const lowBorderHeroNetValue =  heroWearNow.length>0 ? Math.min(...heroWearNow.map(itemId=>getNetCalc(heroId, itemId, net))): 1;
								
		const itemsHeroTypeSorted =	itemsTypeUnsorted.sort((item1,item2)=>getNetCalc(heroId, item2.id, net)-getNetCalc(heroId, item1.id, net));
		let border = -1;
		for(let i = 0;  i<itemsHeroTypeSorted.length; i++){
			if (border>=0 && (i > border + maxLowerItem))
				break;
			let item = itemsHeroTypeSorted[i];
			usefulItems.add(item);
			if (getNetCalc(heroId, itemsHeroTypeSorted[i].id, net)==lowBorderHeroNetValue)
				border = i;
		}
	}
	return itemsTypeUnsorted.filter(item => !usefulItems.has(item));
		// let indexLowBorder = Math.max(0, maxTopItem - maxLowerItem);
		// for(;indexLowBorder<items.length;
		// const indexLowBorder = itemsHeroTypeSorted.findIndex(
		// itemsHeroTypeSorted.forEach((item, index)=>{
		// }); 
		// const 
		
		
	// const net = getOrCreateNet(needType, heroId);
	// const trainingSet = collectTrainingSet(heroId);
	// trainingNet(net, trainingSet, needType, heroId);
	// const heroLevel = heroes[currentHeroIndex].level;
	// const fullWear = wearType.length>=canWearType;
	// const heroItemOrder = ItemOrder.find(row => row.heroId == heroId);
	
	// const itemsHeroType = items
		// .filter(checkItem=>getItemType(checkItem) == needType)
		// .sort((item1,item2)=>getNetCalc(heroId, item2.id, net)-getNetCalc(heroId, item1.id, net));
	// }
}

// Функция удаления текущего героя
function deleteCurrentHero() {
    if (heroes.length === 0) return;

    const confirmation = confirm(`Вы уверены, что хотите удалить героя "${getHeroTitle(heroes[currentHeroIndex])}"?`);
    if (confirmation) {
        heroes.splice(currentHeroIndex, 1);
        if (heroes.length === 0) {
            currentHeroIndex = -1;
        } else if (currentHeroIndex >= heroes.length) {
            currentHeroIndex = heroes.length - 1;
        }
		updateCanWearType(); // Обновляем таблицу при удалении героя
		updateWearNow(); // Обновляем WearNow при удалении героя
		updateItemOrder(); //Обновляем порядок предметов при удалении героя
        saveToLocalStorage('heroes');
        saveToLocalStorage('currentHeroIndex');
        updateUI();
    }
}

// Обработка удаления
document.getElementById('NextUndefined').addEventListener('click', getNextUndefined);

// Привязываем обработчик к кнопке удаления
document.getElementById('deleteHeroBtn').addEventListener('click', deleteCurrentHero);

// Обработка Enter
document.getElementById('inputText').addEventListener('keydown', function(e) {
    if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        addToList();
    }
});

// Навигация назад по кругу
document.getElementById('prevBtn').addEventListener('click', function() {
    if (items.length > 0) {
        currentIndex = (currentIndex - 1 + items.length) % items.length;
        updateUI();		
		saveToLocalStorage('currentIndex');
    }
});

// Навигация вперёд по кругу
document.getElementById('nextBtn').addEventListener('click', function() {
    if (items.length > 0) {
        currentIndex = (currentIndex + 1) % items.length;
        updateUI();		
		saveToLocalStorage('currentIndex');
    }
});

// Навигация по героям
document.getElementById('prevHeroBtn').addEventListener('click', function() {
    if (heroes.length > 0) {
		saveCurrentHero(); // Сохраняем текущего героя перед переключением
        currentHeroIndex = (currentHeroIndex - 1 + heroes.length) % heroes.length;
        updateUI();
		saveToLocalStorage('currentHeroIndex');
    }
});

document.getElementById('nextHeroBtn').addEventListener('click', function() {
    if (heroes.length > 0) {
		saveCurrentHero(); // Сохраняем текущего героя перед переключением
        currentHeroIndex = (currentHeroIndex + 1) % heroes.length;
        updateUI();
		saveToLocalStorage('currentHeroIndex');
    }
});

// Обработка удаления
document.getElementById('deleteBtn').addEventListener('click', deleteCurrentItem);

// Обработка удаления картинки
// document.getElementById('deleteImg').addEventListener('click', clearImage);

// Сохранение при закрытии окна
window.addEventListener('beforeunload', function() {
    saveCurrentHero(); // Сохраняем текущего героя перед закрытием
});