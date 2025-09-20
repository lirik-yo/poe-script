(function(){
	async function renderNeuronSummary() {
		const currentType = State.CurrentItem?.type;
		const summaryNeuron = await getNeuronAnalysisSummary(currentType);

		const blockAllParsed = DomCache.Instance.get("#text-all-parsed");
		const blockHaveNoParsed = DomCache.Instance.get("#text-have-no-parsed");

		const trNotParsedCurrent = DomCache.Instance.get("#neuron-not-parsed-type-tr");
		const tdNotParsedCurrentCount = DomCache.Instance.get("#neuron-not-parsed-current-type-count");
		const tdNotParsedCurrentExample = DomCache.Instance.get("#neuron-not-parsed-current-type-example");
		
		const trNotParsedAll = DomCache.Instance.get("#neuron-not-parsed-all-tr");
		const tdNotParsedAllCount = DomCache.Instance.get("#neuron-not-parsed-all-type-count");
		const tdNotParsedAllExample = DomCache.Instance.get("#neuron-not-parsed-all-type-example");
		
		
			// badTotalCount,
			// badCurrentTypeCount,
			// firstBadLineGlobal,
			// firstItemGlobal,
			// firstBadLineCurrentType,
			// firstItemCurrentType
		
		tdNotParsedCurrentCount.textContent = `${summaryNeuron.badCurrentTypeCount}`;
		tdNotParsedCurrentExample.textContent = `${summaryNeuron.firstBadLineCurrentType}`;
		tdNotParsedAllCount.textContent = `${summaryNeuron.badTotalCount}`;
		tdNotParsedAllExample.textContent = `${summaryNeuron.firstBadLineGlobal}`;
		
		// const element = DomCache.Instance.get(`[data-i18n="${key}"]`);
		
		// const container = document.getElementById("tab-nav-neurons");
		// container.innerText = `Нераспознанных строк: ${summary.badCurrentTypeCount} (в текущем типе) / ${summary.badTotalCount} (всего)`;

		// 👇 При необходимости — сохранить в window для отладки
		// window.__NeuronDebugInfo = summary;
		
						// <span id="text-all-parsed" data-i18n="NEURON_ALL_TEXT_PARSED" title="ToDo:при обработке/подсчёте нейронов надо учесть что text-all-parsed, text-have-no-parsed одновременно не видны"></span>
				// <div id="text-have-no-parsed" title="ToDo:поработай над css, чтобы эта штука выглядела хорошо.">
					// <span data-i18n="NEURON_NOT_PARSED"></span>
					// <table>
						// <tr id="neuron-not-parsed-type-tr" title="ToDo:эта строку отображать только в случае, если есть в текущем типе не обработанные">
							// <th data-i18n="NEURON_NOT_PARSED_CURRENT_TYPE"></th>
							// <td id="neuron-not-parsed-current-type-count"></td>
							// <td id="neuron-not-parsed-current-type-example"></td>
						// </tr>
						// <tr id="neuron-not-parsed-all-tr" title="ToDo:эта строку отображать только в случае, если есть вне текущего типа не обработанные">
							// <th data-i18n="NEURON_NOT_PARSED_ALL_TYPE"></th>
							// <td id="neuron-not-parsed-all-type-count"></td>
							// <td id="neuron-not-parsed-all-type-example"></td>
						// </tr>
					// </table>
				// </div>
	}

	window.renderNeuronSummary = renderNeuronSummary;
})();

document.addEventListener('DOMContentLoaded', () => {
	LoadingBar.withLoading(()=>renderNeuronSummary());
});