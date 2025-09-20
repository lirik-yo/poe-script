class StatusBar {
  constructor(selector = '#status-bar') {
    this.container = document.querySelector(selector);
    if (!this.container) {
      throw new Error(`Status bar element ${selector} not found`);
    }

    this.timeout = null;
  }

  show(message, type = 'info', duration = 3000) {
    this.clear();
    this.container.textContent = message;
    this.container.className = `status ${type}`; // .status.info / .status.error и т.д.
    this.container.style.display = 'block';

    if (duration > 0) {
      this.timeout = setTimeout(() => this.hide(), duration);
    }
  }

  showLoading(message = 'Загрузка...') {
    this.show(message, 'loading', 0);
  }

  showError(message) {
    this.show(message, 'error');
  }

  showSuccess(message) {
    this.show(message, 'success');
  }

  hide() {
    this.clear();
    this.container.style.display = 'none';
  }

  clear() {
    clearTimeout(this.timeout);
    this.timeout = null;
    this.container.textContent = '';
    this.container.className = 'status';
  }
}
