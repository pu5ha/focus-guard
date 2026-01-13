// FocusGuard Popup

document.addEventListener('DOMContentLoaded', () => {
  loadStats();
  loadBlockedSites();
  setupEventListeners();
});

function loadStats() {
  chrome.runtime.sendMessage({ type: 'GET_STATS' }, (response) => {
    if (response && response.stats) {
      document.getElementById('todayBypasses').textContent = response.stats.todayBypasses || 0;
      document.getElementById('weekBypasses').textContent = response.stats.weekBypasses || 0;
    }
  });
}

function loadBlockedSites() {
  chrome.runtime.sendMessage({ type: 'GET_STATS' }, (response) => {
    const list = document.getElementById('blockedList');

    if (response && response.blockedSites && response.blockedSites.length > 0) {
      list.innerHTML = response.blockedSites.map(site => `
        <div class="blocked-item">
          <span>${site}</span>
          <button data-site="${site}" class="remove-btn" title="Remove">&times;</button>
        </div>
      `).join('');

      // Add remove handlers
      document.querySelectorAll('.remove-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
          const site = e.target.dataset.site;
          removeSite(site);
        });
      });
    } else {
      list.innerHTML = '<div class="empty-state">No sites blocked in extension</div>';
    }
  });
}

function setupEventListeners() {
  const input = document.getElementById('newSite');
  const addBtn = document.getElementById('addBtn');

  addBtn.addEventListener('click', () => {
    addSite(input.value);
  });

  input.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') {
      addSite(input.value);
    }
  });
}

function addSite(site) {
  if (!site || !site.trim()) return;

  const cleanSite = site.trim().toLowerCase()
    .replace('https://', '')
    .replace('http://', '')
    .replace('www.', '')
    .replace(/\/$/, '');

  chrome.runtime.sendMessage({
    type: 'ADD_BLOCK',
    domain: cleanSite
  }, () => {
    document.getElementById('newSite').value = '';
    loadBlockedSites();
  });
}

function removeSite(site) {
  chrome.runtime.sendMessage({
    type: 'REMOVE_BLOCK',
    domain: site
  }, () => {
    loadBlockedSites();
  });
}
