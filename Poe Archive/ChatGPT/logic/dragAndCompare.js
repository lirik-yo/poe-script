const DragAndCompare = (function () {
  let draggedItem = null;

  function initDragAndDrop(containerSelector) {
    const container = document.querySelector(containerSelector);
    if (!container) return;

    container.addEventListener('dragstart', e => {
      draggedItem = e.target.closest('.item-card');
    });

    container.addEventListener('dragover', e => {
      e.preventDefault();
    });

    container.addEventListener('drop', e => {
      e.preventDefault();
      const dropTarget = e.target.closest('.item-card');
      if (draggedItem && dropTarget && draggedItem !== dropTarget) {
        // здесь вызов сравнения
        State.setComparedItems([draggedItem.dataset.id, dropTarget.dataset.id]);
      }
    });
  }

  return {
    initDragAndDrop
  };
})();