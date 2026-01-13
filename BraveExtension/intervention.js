// FocusGuard Intervention Page

// Get URL parameters
const urlParams = new URLSearchParams(window.location.search);
const targetURL = urlParams.get('url');
const domain = urlParams.get('domain');
const todayBypasses = parseInt(urlParams.get('todayBypasses')) || 0;
const weekBypasses = parseInt(urlParams.get('weekBypasses')) || 0;

// Motivational messages based on bypass count
const messages = {
  low: [
    "Is this really how you want to spend your time?",
    "Your future self will thank you for staying focused.",
    "Every distraction is a choice. Choose wisely.",
    "What's one thing you could accomplish instead?",
    "Focus is a superpower. Use it."
  ],
  medium: [
    "You've already bypassed a few times today. Break the cycle.",
    "Imagine how productive you'd be without this distraction.",
    "Your goals won't achieve themselves.",
    "This is becoming a habit. Is it a good one?",
    "Time is the one resource you can't get back."
  ],
  high: [
    "This is getting out of hand. You know better.",
    "How much time have you wasted today already?",
    "Your bypasses are adding up. What's the cost?",
    "You set up FocusGuard for a reason. Remember why.",
    "Every bypass makes the next one easier. Stop the cycle now."
  ],
  critical: [
    "STOP. You've bypassed too many times today.",
    "This isn't who you want to be. Make a different choice.",
    "You're actively fighting against your own goals.",
    "Seriously? Again? You're better than this.",
    "The definition of insanity is doing the same thing and expecting different results."
  ]
};

// Initialize page
document.addEventListener('DOMContentLoaded', () => {
  // Set domain
  document.getElementById('domain').textContent = domain || 'this site';

  // Set bypass counts
  document.getElementById('todayBypasses').textContent = todayBypasses;
  document.getElementById('weekBypasses').textContent = weekBypasses;

  // Set motivational message based on bypass count
  setMotivationalMessage();

  // Add shake animation if high bypass count
  if (todayBypasses >= 5) {
    document.querySelector('.stats-container').classList.add('high-bypass-warning');
  }

  // Set up button handlers
  setupButtons();

  // Show streak info
  updateStreakInfo();
});

function setMotivationalMessage() {
  let messageList;

  if (todayBypasses >= 10) {
    messageList = messages.critical;
  } else if (todayBypasses >= 5) {
    messageList = messages.high;
  } else if (todayBypasses >= 2) {
    messageList = messages.medium;
  } else {
    messageList = messages.low;
  }

  const randomMessage = messageList[Math.floor(Math.random() * messageList.length)];
  document.getElementById('motivationalMessage').textContent = randomMessage;
}

function setupButtons() {
  // Block for 4 hours
  document.getElementById('blockBtn').addEventListener('click', () => {
    blockSite(4 * 60 * 60 * 1000); // 4 hours in ms
  });

  // Block rest of day
  document.getElementById('blockRestOfDay').addEventListener('click', () => {
    const now = new Date();
    const endOfDay = new Date(now);
    endOfDay.setHours(23, 59, 59, 999);
    const duration = endOfDay - now;
    blockSite(duration);
  });

  // Bypass (continue anyway)
  document.getElementById('bypassBtn').addEventListener('click', () => {
    bypassBlock();
  });
}

function blockSite(duration) {
  // Send message to background script
  chrome.runtime.sendMessage({
    type: 'BLOCK_NOW',
    domain: domain,
    duration: duration
  }, (response) => {
    if (response && response.success) {
      // Show confirmation
      showConfirmation('Block activated! Redirecting...');

      // Close tab or redirect to new tab page
      setTimeout(() => {
        chrome.tabs.getCurrent((tab) => {
          chrome.tabs.update(tab.id, { url: 'about:newtab' });
        });
      }, 1500);
    }
  });
}

function bypassBlock() {
  // Send bypass event to background
  chrome.runtime.sendMessage({
    type: 'BYPASS',
    url: targetURL,
    domain: domain
  }, (response) => {
    if (response && response.success) {
      // Redirect to original URL
      window.location.href = targetURL;
    }
  });
}

function showConfirmation(message) {
  const container = document.querySelector('.container');
  container.innerHTML = `
    <div class="shield-icon" style="color: #68d391;">
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">
        <path d="M12 2L4 5v6.09c0 5.05 3.41 9.76 8 10.91 4.59-1.15 8-5.86 8-10.91V5l-8-3zm-1 14.59l-3.29-3.3 1.41-1.41L11 13.76l4.88-4.88 1.41 1.41L11 16.59z"/>
      </svg>
    </div>
    <h1 style="color: #68d391;">Good choice!</h1>
    <p class="subtitle">${message}</p>
  `;
}

function updateStreakInfo() {
  const streakInfo = document.getElementById('streakInfo');

  if (todayBypasses === 0) {
    streakInfo.className = 'streak-info positive';
    streakInfo.textContent = "You haven't bypassed yet today. Keep it up!";
  } else if (todayBypasses < 3) {
    streakInfo.className = 'streak-info';
    streakInfo.textContent = `${todayBypasses} bypass${todayBypasses > 1 ? 'es' : ''} today. You can still turn this around.`;
  } else {
    streakInfo.className = 'streak-info negative';
    streakInfo.textContent = `${todayBypasses} bypasses today. Tomorrow is a fresh start.`;
  }
}
