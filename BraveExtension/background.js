// FocusGuard Background Service Worker
// Intercepts navigation to blocked sites and shows intervention page

// Blocked sites list (synced from native app)
let blockedSites = ['x.com', 'twitter.com'];
let siteLimits = {}; // { 'x.com': { dailyMinutes: 15, usedMinutes: 0 } }

// Stats
let stats = {
  todayBypasses: 0,
  weekBypasses: 0,
  lastReset: new Date().toDateString()
};

// Bypassed tabs - tracks which tabs have been bypassed (resets on tab close)
let bypassedTabs = {}; // { tabId: { domain, bypassTime, lastReminder } }

// Time tracking
let activeTabTracking = {
  tabId: null,
  url: null,
  startTime: null
};

// Initialize
chrome.runtime.onInstalled.addListener(() => {
  console.log('FocusGuard extension installed');
  loadSettings();
  resetDailyStatsIfNeeded();
});

chrome.runtime.onStartup.addListener(() => {
  loadSettings();
  resetDailyStatsIfNeeded();
});

// Load settings from storage
async function loadSettings() {
  const data = await chrome.storage.local.get(['blockedSites', 'siteLimits', 'stats']);
  if (data.blockedSites) blockedSites = data.blockedSites;
  if (data.siteLimits) siteLimits = data.siteLimits;
  if (data.stats) stats = data.stats;
  console.log('Loaded settings:', { blockedSites, stats });
}

// Save settings
async function saveSettings() {
  await chrome.storage.local.set({ blockedSites, siteLimits, stats });
}

// Reset daily stats at midnight
function resetDailyStatsIfNeeded() {
  const today = new Date().toDateString();
  if (stats.lastReset !== today) {
    stats.weekBypasses += stats.todayBypasses;
    stats.todayBypasses = 0;
    stats.lastReset = today;

    // Reset weekly on Sunday
    if (new Date().getDay() === 0) {
      stats.weekBypasses = 0;
    }

    saveSettings();
  }
}

// Check if URL matches blocked sites
function isBlockedURL(url) {
  if (!url) return false;

  try {
    const hostname = new URL(url).hostname.toLowerCase();
    return blockedSites.some(site => {
      const cleanSite = site.toLowerCase().replace('www.', '');
      return hostname.includes(cleanSite) || hostname.replace('www.', '') === cleanSite;
    });
  } catch {
    return false;
  }
}

// Get domain from URL
function getDomain(url) {
  try {
    return new URL(url).hostname.replace('www.', '');
  } catch {
    return null;
  }
}

// Intercept navigation to blocked sites
chrome.webNavigation.onBeforeNavigate.addListener((details) => {
  // Only intercept main frame (not iframes)
  if (details.frameId !== 0) return;

  if (isBlockedURL(details.url)) {
    // Check if this tab has been bypassed
    if (bypassedTabs[details.tabId]) {
      console.log('Tab already bypassed, allowing:', details.url);
      return; // Allow navigation
    }

    console.log('Intercepting navigation to:', details.url);

    // Redirect to intervention page
    const interventionURL = chrome.runtime.getURL('intervention.html') +
      '?url=' + encodeURIComponent(details.url) +
      '&domain=' + encodeURIComponent(getDomain(details.url)) +
      '&todayBypasses=' + stats.todayBypasses +
      '&weekBypasses=' + stats.weekBypasses;

    chrome.tabs.update(details.tabId, { url: interventionURL });
  }
});

// Clean up bypassed tabs when tab is closed
chrome.tabs.onRemoved.addListener((tabId) => {
  if (bypassedTabs[tabId]) {
    console.log('Tab closed, removing bypass for tab:', tabId);
    delete bypassedTabs[tabId];
  }
});

// Also catch URL bar changes
chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (changeInfo.url && isBlockedURL(changeInfo.url)) {
    // Check if this tab has been bypassed
    if (bypassedTabs[tabId]) {
      console.log('Tab already bypassed, allowing URL change:', changeInfo.url);
      return;
    }

    console.log('Tab URL changed to blocked site:', changeInfo.url);

    // Check if already on intervention page
    if (changeInfo.url.includes('intervention.html')) return;

    const interventionURL = chrome.runtime.getURL('intervention.html') +
      '?url=' + encodeURIComponent(changeInfo.url) +
      '&domain=' + encodeURIComponent(getDomain(changeInfo.url)) +
      '&todayBypasses=' + stats.todayBypasses +
      '&weekBypasses=' + stats.weekBypasses;

    chrome.tabs.update(tabId, { url: interventionURL });
  }
});

// Time tracking - track active tab
chrome.tabs.onActivated.addListener(async (activeInfo) => {
  // Stop tracking previous tab
  stopTimeTracking();

  // Start tracking new tab
  const tab = await chrome.tabs.get(activeInfo.tabId);
  if (tab.url && isTrackedURL(tab.url)) {
    startTimeTracking(activeInfo.tabId, tab.url);
  }
});

// Track URL changes in active tab
chrome.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (!tab.active) return;

  if (changeInfo.url) {
    stopTimeTracking();
    if (isTrackedURL(changeInfo.url)) {
      startTimeTracking(tabId, changeInfo.url);
    }
  }
});

// Stop tracking when window loses focus
chrome.windows.onFocusChanged.addListener((windowId) => {
  if (windowId === chrome.windows.WINDOW_ID_NONE) {
    stopTimeTracking();
  }
});

function isTrackedURL(url) {
  // Track time on blocked sites (even if user bypassed)
  return isBlockedURL(url);
}

function startTimeTracking(tabId, url) {
  activeTabTracking = {
    tabId,
    url,
    startTime: Date.now()
  };
  console.log('Started tracking:', getDomain(url));
}

function stopTimeTracking() {
  if (activeTabTracking.startTime && activeTabTracking.url) {
    const duration = Math.round((Date.now() - activeTabTracking.startTime) / 1000);
    const domain = getDomain(activeTabTracking.url);

    if (duration > 5) { // Only log if more than 5 seconds
      logUsage(domain, duration);
      console.log(`Tracked ${duration}s on ${domain}`);
    }
  }

  activeTabTracking = { tabId: null, url: null, startTime: null };
}

async function logUsage(domain, seconds) {
  // Store usage data
  const data = await chrome.storage.local.get(['usage']);
  const usage = data.usage || {};
  const today = new Date().toDateString();

  if (!usage[today]) usage[today] = {};
  if (!usage[today][domain]) usage[today][domain] = 0;

  usage[today][domain] += seconds;

  await chrome.storage.local.set({ usage });

  // Try to send to native app
  sendToNativeApp({
    type: 'USAGE_UPDATE',
    payload: { domain, seconds, timestamp: new Date().toISOString() }
  });
}

// Message handling from intervention page and popup
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  console.log('Received message:', message);

  switch (message.type) {
    case 'BYPASS':
      // Get the tab ID from the sender
      const tabId = sender.tab ? sender.tab.id : null;
      handleBypass(message.url, message.domain, tabId);
      sendResponse({ success: true, tabId });
      break;

    case 'BLOCK_NOW':
      handleBlockNow(message.domain, message.duration);
      sendResponse({ success: true });
      break;

    case 'GET_STATS':
      sendResponse({ stats, blockedSites });
      break;

    case 'ADD_BLOCK':
      addBlockedSite(message.domain);
      sendResponse({ success: true });
      break;

    case 'REMOVE_BLOCK':
      removeBlockedSite(message.domain);
      sendResponse({ success: true });
      break;

    case 'GET_USAGE':
      getUsageStats().then(usage => sendResponse({ usage }));
      return true; // async response
  }
});

function handleBypass(url, domain, tabId) {
  stats.todayBypasses++;
  saveSettings();

  // Track this tab as bypassed
  // Set lastReminder to 25 seconds ago so first reminder shows in ~5 seconds
  bypassedTabs[tabId] = {
    domain,
    bypassTime: Date.now(),
    lastReminder: Date.now() - 25000
  };

  console.log('Bypass tracked for tab:', tabId, 'domain:', domain);

  console.log(`Bypass logged for ${domain} in tab ${tabId}. Today: ${stats.todayBypasses}`);

  // Send to native app
  sendToNativeApp({
    type: 'BYPASS_EVENT',
    payload: {
      domain,
      url,
      todayCount: stats.todayBypasses,
      timestamp: new Date().toISOString()
    }
  });
}

function handleBlockNow(domain, duration) {
  // Add to blocked list if not already
  if (!blockedSites.includes(domain)) {
    blockedSites.push(domain);
    saveSettings();
  }

  // Send to native app to activate hosts file block
  sendToNativeApp({
    type: 'ACTIVATE_BLOCK',
    payload: { domain, duration }
  });

  console.log(`Block activated for ${domain} for ${duration}ms`);
}

function addBlockedSite(domain) {
  const cleanDomain = domain.toLowerCase().replace('www.', '');
  if (!blockedSites.includes(cleanDomain)) {
    blockedSites.push(cleanDomain);
    saveSettings();
    console.log('Added blocked site:', cleanDomain);
  }
}

function removeBlockedSite(domain) {
  const cleanDomain = domain.toLowerCase().replace('www.', '');
  blockedSites = blockedSites.filter(site => site !== cleanDomain);
  saveSettings();
  console.log('Removed blocked site:', cleanDomain);
}

async function getUsageStats() {
  const data = await chrome.storage.local.get(['usage']);
  return data.usage || {};
}

// Native messaging to FocusGuard app
function sendToNativeApp(message) {
  try {
    chrome.runtime.sendNativeMessage('com.focusguard.app', message, (response) => {
      if (chrome.runtime.lastError) {
        console.log('Native messaging not connected:', chrome.runtime.lastError.message);
      } else {
        console.log('Native app response:', response);
      }
    });
  } catch (error) {
    console.log('Native messaging error:', error);
  }
}

// Listen for messages from native app
chrome.runtime.onMessageExternal.addListener((message, sender, sendResponse) => {
  console.log('Message from native app:', message);

  if (message.type === 'BLOCKS_UPDATED') {
    blockedSites = message.payload.blockedUrls || [];
    saveSettings();
  }
});

// Periodic sync with native app
chrome.alarms.create('syncWithApp', { periodInMinutes: 1 });

// Check reminders more frequently (every 30 seconds using delayInMinutes workaround)
chrome.alarms.create('checkReminders', { delayInMinutes: 0.5, periodInMinutes: 0.5 });

chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === 'syncWithApp') {
    resetDailyStatsIfNeeded();
    sendToNativeApp({ type: 'SYNC_REQUEST' });
  }
  if (alarm.name === 'checkReminders') {
    checkBypassedTabsForReminders();
  }
});

// Check bypassed tabs and send reminders every 3 minutes
const REMINDER_INTERVAL = 3 * 60 * 1000; // 3 minutes

function checkBypassedTabsForReminders() {
  const now = Date.now();
  const tabCount = Object.keys(bypassedTabs).length;
  console.log('Checking reminders. Bypassed tabs:', tabCount, bypassedTabs);

  if (tabCount === 0) return;

  Object.entries(bypassedTabs).forEach(async ([tabId, info]) => {
    const timeSinceLastReminder = now - info.lastReminder;

    if (timeSinceLastReminder >= REMINDER_INTERVAL) {
      // Time for a reminder!
      const minutesWasted = Math.round((now - info.bypassTime) / 60000);

      try {
        // Inject reminder into the tab
        await chrome.scripting.executeScript({
          target: { tabId: parseInt(tabId) },
          func: showReminder,
          args: [info.domain, minutesWasted, stats.todayBypasses]
        });

        // Update last reminder time
        bypassedTabs[tabId].lastReminder = now;
        console.log(`Reminder shown in tab ${tabId} for ${info.domain}`);
      } catch (error) {
        console.log('Could not show reminder in tab:', error.message);
        // Tab might be closed or navigated away
        delete bypassedTabs[tabId];
      }
    }
  });
}

// This function gets injected into the page to show reminder
function showReminder(domain, minutesWasted, todayBypasses) {
  // Remove existing reminder if any
  const existing = document.getElementById('focusguard-reminder');
  if (existing) existing.remove();

  // Create reminder overlay
  const reminder = document.createElement('div');
  reminder.id = 'focusguard-reminder';
  reminder.innerHTML = `
    <div style="
      position: fixed;
      top: 20px;
      right: 20px;
      background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
      color: white;
      padding: 20px 24px;
      border-radius: 16px;
      box-shadow: 0 10px 40px rgba(0,0,0,0.4);
      z-index: 2147483647;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      max-width: 320px;
      animation: slideIn 0.3s ease-out;
      border: 1px solid rgba(79, 172, 254, 0.3);
    ">
      <style>
        @keyframes slideIn {
          from { transform: translateX(100%); opacity: 0; }
          to { transform: translateX(0); opacity: 1; }
        }
      </style>
      <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 12px;">
        <div style="font-size: 24px;">🛡️</div>
        <div style="font-weight: 600; font-size: 16px;">FocusGuard Reminder</div>
        <button onclick="this.parentElement.parentElement.parentElement.remove()" style="
          margin-left: auto;
          background: none;
          border: none;
          color: #718096;
          font-size: 20px;
          cursor: pointer;
          padding: 0;
        ">&times;</button>
      </div>
      <div style="color: #fc8181; font-size: 14px; margin-bottom: 8px;">
        You've been on ${domain} for <strong>${minutesWasted} minutes</strong>
      </div>
      <div style="color: #a0aec0; font-size: 13px; margin-bottom: 16px;">
        Bypasses today: ${todayBypasses}
      </div>
      <div style="display: flex; gap: 8px;">
        <button onclick="window.location.href='about:newtab'; this.parentElement.parentElement.parentElement.remove();" style="
          flex: 1;
          padding: 10px 16px;
          background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
          border: none;
          border-radius: 8px;
          color: #1a1a2e;
          font-weight: 600;
          cursor: pointer;
          font-size: 13px;
        ">Leave Now</button>
        <button onclick="this.parentElement.parentElement.parentElement.remove()" style="
          padding: 10px 16px;
          background: rgba(255,255,255,0.1);
          border: 1px solid rgba(255,255,255,0.2);
          border-radius: 8px;
          color: white;
          cursor: pointer;
          font-size: 13px;
        ">Dismiss</button>
      </div>
    </div>
  `;

  document.body.appendChild(reminder);

  // Auto-dismiss after 30 seconds
  setTimeout(() => {
    const el = document.getElementById('focusguard-reminder');
    if (el) el.remove();
  }, 30000);
}

console.log('FocusGuard background script loaded');
