async function getInfoItemFromTextArea(){
	const textItem = DomCache.Instance.get("#item-new-text");
	const text = textItem.value.trim();
	if (!text) return;

	try {
		const item = Item.fromText(text);
		console.log(item);
		await DB.saveItem(item);
		await render(); // или твой метод перерисовки
	} catch (err) {
		console.error("Ошибка при добавлении предмета:", err);
		StatusBar.showError("Не удалось распарсить предмет");
	}
}

document.getElementById("add-item-button").addEventListener("click", ()=>{LoadingBar.withLoading(getInfoItemFromTextArea);});