// FocusGuard Popup

let siteLimits = {};
let currentModalDomain = null;
let selectedMinutes = 30;

document.addEventListener('DOMContentLoaded', () => {
  loadStats();
  loadBlockedSites();
  setupEventListeners();
  setupModal();
});

function loadStats() {
  chrome.runtime.sendMessage({ type: 'GET_STATS' }, (response) => {
    if (response) {
      if (response.stats) {
        document.getElementById('todayBypasses').textContent = response.stats.todayBypasses || 0;
        document.getElementById('weekBypasses').textContent = response.stats.weekBypasses || 0;
      }
      if (response.siteLimits) {
        siteLimits = response.siteLimits;
      }
    }
  });
}

function loadBlockedSites() {
  chrome.runtime.sendMessage({ type: 'GET_STATS' }, (response) => {
    const list = document.getElementById('blockedList');

    if (response && response.blockedSites && response.blockedSites.length > 0) {
      siteLimits = response.siteLimits || {};

      list.innerHTML = response.blockedSites.map(site => {
        const limit = siteLimits[site];
        const hasLimit = limit && limit.dailyMinutes;

        return `
          <div class="blocked-item">
            <div class="blocked-item-info">
              <span class="blocked-item-domain">${site}</span>
              ${hasLimit ? `
                <span class="blocked-item-limit">
                  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M11.99 2C6.47 2 2 6.48 2 12s4.47 10 9.99 10C17.52 22 22 17.52 22 12S17.52 2 11.99 2zM12 20c-4.42 0-8-3.58-8-8s3.58-8 8-8 8 3.58 8 8-3.58 8-8 8zm.5-13H11v6l5.25 3.15.75-1.23-4.5-2.67z"/>
                  </svg>
                  ${limit.dailyMinutes} min/day limit
                </span>
              ` : ''}
            </div>
            <div class="blocked-item-actions">
              <button class="limit-btn ${hasLimit ? 'active' : ''}" data-site="${site}" title="Set daily limit">
                ${hasLimit ? 'Edit' : 'Limit'}
              </button>
              <button data-site="${site}" class="remove-btn" title="Remove">&times;</button>
            </div>
          </div>
        `;
      }).join('');

      // Add remove handlers
      document.querySelectorAll('.remove-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
          const site = e.target.dataset.site;
          removeSite(site);
        });
      });

      // Add limit handlers
      document.querySelectorAll('.limit-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
          const site = e.target.dataset.site;
          openLimitModal(site);
        });
      });
    } else {
      list.innerHTML = '<div class="empty-state">No sites blocked</div>';
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

function setupModal() {
  const overlay = document.getElementById('modalOverlay');
  const cancelBtn = document.getElementById('modalCancel');
  const saveBtn = document.getElementById('modalSave');
  const removeBtn = document.getElementById('modalRemove');

  // Time preset selection
  document.querySelectorAll('.time-preset').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.time-preset').forEach(b => b.classList.remove('selected'));
      btn.classList.add('selected');
      selectedMinutes = parseInt(btn.dataset.minutes);
    });
  });

  // Cancel
  cancelBtn.addEventListener('click', closeModal);

  // Click outside to close
  overlay.addEventListener('click', (e) => {
    if (e.target === overlay) {
      closeModal();
    }
  });

  // Save limit
  saveBtn.addEventListener('click', () => {
    if (currentModalDomain && selectedMinutes > 0) {
      chrome.runtime.sendMessage({
        type: 'SET_TIME_LIMIT',
        domain: currentModalDomain,
        minutes: selectedMinutes
      }, () => {
        closeModal();
        loadBlockedSites();
      });
    }
  });

  // Remove limit
  removeBtn.addEventListener('click', () => {
    if (currentModalDomain) {
      chrome.runtime.sendMessage({
        type: 'REMOVE_TIME_LIMIT',
        domain: currentModalDomain
      }, () => {
        closeModal();
        loadBlockedSites();
      });
    }
  });
}

function openLimitModal(domain) {
  currentModalDomain = domain;
  document.getElementById('modalDomain').textContent = domain;

  // Check if there's an existing limit
  const existingLimit = siteLimits[domain];
  const removeBtn = document.getElementById('modalRemove');

  if (existingLimit && existingLimit.dailyMinutes) {
    // Pre-select the existing limit
    selectedMinutes = existingLimit.dailyMinutes;
    document.querySelectorAll('.time-preset').forEach(btn => {
      btn.classList.toggle('selected', parseInt(btn.dataset.minutes) === selectedMinutes);
    });
    removeBtn.style.display = 'block';
  } else {
    // Default to 30 minutes
    selectedMinutes = 30;
    document.querySelectorAll('.time-preset').forEach(btn => {
      btn.classList.toggle('selected', parseInt(btn.dataset.minutes) === 30);
    });
    removeBtn.style.display = 'none';
  }

  document.getElementById('modalOverlay').classList.add('show');
}

function closeModal() {
  document.getElementById('modalOverlay').classList.remove('show');
  currentModalDomain = null;
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
