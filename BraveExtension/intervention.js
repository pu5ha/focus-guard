// FocusGuard Intervention Page

// Get URL parameters
const urlParams = new URLSearchParams(window.location.search);
const targetURL = urlParams.get('url');
const domain = urlParams.get('domain');
const todayBypasses = parseInt(urlParams.get('todayBypasses')) || 0;
const weekBypasses = parseInt(urlParams.get('weekBypasses')) || 0;
const reason = urlParams.get('reason') || 'blocked'; // 'blocked' or 'timelimit'
const limitMinutes = parseInt(urlParams.get('limitMinutes')) || 0;
const usedMinutes = parseInt(urlParams.get('usedMinutes')) || 0;

// Bypass phrases that escalate based on bypass count
const bypassPhrases = {
  low: "I am choosing to waste my time",
  medium: "I am actively choosing distraction over my goals",
  high: "I am sabotaging my own productivity again",
  critical: "I refuse to respect my own boundaries"
};

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

// Selected extra minutes for time limit bypass
let selectedExtraMinutes = 5;

// Initialize page
document.addEventListener('DOMContentLoaded', () => {
  // Set domain
  document.getElementById('domain').textContent = domain || 'this site';

  // Set bypass counts
  document.getElementById('todayBypasses').textContent = todayBypasses;
  document.getElementById('weekBypasses').textContent = weekBypasses;

  // Handle time limit vs blocked
  if (reason === 'timelimit') {
    setupTimeLimitMode();
  }

  // Set motivational message based on bypass count
  setMotivationalMessage();

  // Set bypass phrase based on bypass count
  setBypassPhrase();

  // Add shake animation if high bypass count
  if (todayBypasses >= 5) {
    document.querySelector('.content').classList.add('high-bypass-warning');
  }

  // Set up button handlers
  setupButtons();

  // Show streak info
  updateStreakInfo();
});

function setupTimeLimitMode() {
  // Update label
  const reasonLabel = document.getElementById('reasonLabel');
  reasonLabel.textContent = 'TIME LIMIT REACHED';
  reasonLabel.classList.add('time-limit');

  // Show time limit info
  const timeLimitInfo = document.getElementById('timeLimitInfo');
  timeLimitInfo.style.display = 'block';

  document.getElementById('timeUsed').textContent = usedMinutes;
  document.getElementById('timeLimit').textContent = limitMinutes;

  // Set progress bar
  const progress = Math.min(100, (usedMinutes / limitMinutes) * 100);
  document.getElementById('timeLimitProgress').style.width = progress + '%';
}

function getBypassLevel() {
  if (todayBypasses >= 10) return 'critical';
  if (todayBypasses >= 5) return 'high';
  if (todayBypasses >= 2) return 'medium';
  return 'low';
}

function setMotivationalMessage() {
  const level = getBypassLevel();
  const messageList = messages[level];
  const randomMessage = messageList[Math.floor(Math.random() * messageList.length)];
  document.getElementById('motivationalMessage').textContent = randomMessage;
}

function setBypassPhrase() {
  const level = getBypassLevel();
  const phrase = bypassPhrases[level];

  document.getElementById('bypassPhrase').textContent = phrase;
  document.getElementById('timeBypassPhrase').textContent = phrase;
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

  // Show bypass section
  document.getElementById('showBypassBtn').addEventListener('click', () => {
    document.getElementById('mainActions').style.display = 'none';

    if (reason === 'timelimit') {
      document.getElementById('timeBypassSection').style.display = 'block';
      document.getElementById('timeBypassInput').focus();
    } else {
      document.getElementById('bypassSection').style.display = 'block';
      document.getElementById('bypassInput').focus();
    }
  });

  // Cancel bypass
  document.getElementById('cancelBypassBtn').addEventListener('click', () => {
    document.getElementById('bypassSection').style.display = 'none';
    document.getElementById('mainActions').style.display = 'flex';
    document.getElementById('bypassInput').value = '';
  });

  // Cancel time bypass
  document.getElementById('cancelTimeBypassBtn').addEventListener('click', () => {
    document.getElementById('timeBypassSection').style.display = 'none';
    document.getElementById('mainActions').style.display = 'flex';
    document.getElementById('timeBypassInput').value = '';
  });

  // Bypass input validation
  const bypassInput = document.getElementById('bypassInput');
  const bypassBtn = document.getElementById('bypassBtn');
  const bypassPhrase = document.getElementById('bypassPhrase').textContent.toLowerCase();

  bypassInput.addEventListener('input', () => {
    const match = bypassInput.value.toLowerCase().trim() === bypassPhrase;
    bypassBtn.disabled = !match;

    if (match) {
      bypassInput.classList.add('match');
    } else {
      bypassInput.classList.remove('match');
    }
  });

  // Time bypass input validation
  const timeBypassInput = document.getElementById('timeBypassInput');
  const timeBypassBtn = document.getElementById('timeBypassBtn');
  const timeBypassPhrase = document.getElementById('timeBypassPhrase').textContent.toLowerCase();

  timeBypassInput.addEventListener('input', () => {
    const match = timeBypassInput.value.toLowerCase().trim() === timeBypassPhrase;
    timeBypassBtn.disabled = !match;

    if (match) {
      timeBypassInput.classList.add('match');
    } else {
      timeBypassInput.classList.remove('match');
    }
  });

  // Time option selection
  document.querySelectorAll('.time-option').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.time-option').forEach(b => b.classList.remove('selected'));
      btn.classList.add('selected');
      selectedExtraMinutes = parseInt(btn.dataset.minutes);
      document.getElementById('selectedMinutes').textContent = selectedExtraMinutes;
    });
  });

  // Bypass button (regular)
  bypassBtn.addEventListener('click', () => {
    bypassBlock();
  });

  // Time bypass button
  timeBypassBtn.addEventListener('click', () => {
    bypassTimeLimit();
  });

  // Allow Enter key to submit if phrase matches
  bypassInput.addEventListener('keypress', (e) => {
    if (e.key === 'Enter' && !bypassBtn.disabled) {
      bypassBlock();
    }
  });

  timeBypassInput.addEventListener('keypress', (e) => {
    if (e.key === 'Enter' && !timeBypassBtn.disabled) {
      bypassTimeLimit();
    }
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
        window.location.href = 'about:newtab';
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

function bypassTimeLimit() {
  // Send time limit bypass to background
  chrome.runtime.sendMessage({
    type: 'TIME_LIMIT_BYPASS',
    domain: domain,
    extraMinutes: selectedExtraMinutes
  }, (response) => {
    if (response && response.success) {
      // Redirect to original URL
      window.location.href = targetURL;
    }
  });
}

function showConfirmation(message) {
  const card = document.querySelector('.card');
  card.innerHTML = `
    <div class="header" style="background: linear-gradient(180deg, rgba(74, 222, 128, 0.15) 0%, var(--bg-surface, #141416) 100%);">
      <div class="shield-icon" style="animation: none; filter: drop-shadow(0 0 12px rgba(74, 222, 128, 0.5));">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" style="color: #4ade80;">
          <path d="M12 2L4 5v6.09c0 5.05 3.41 9.76 8 10.91 4.59-1.15 8-5.86 8-10.91V5l-8-3zm-1 14.59l-3.29-3.3 1.41-1.41L11 13.76l4.88-4.88 1.41 1.41L11 16.59z"/>
        </svg>
      </div>
      <div class="header-text">
        <h1 style="font-family: 'Cormorant Garamond', Georgia, serif;">Good Choice</h1>
        <p class="tagline">${message}</p>
      </div>
    </div>
    <div class="content" style="padding: 48px 32px;">
      <p class="motivational-message" style="color: #4ade80; margin-bottom: 0; font-size: 1.4rem;">
        You're taking control of your focus.
      </p>
    </div>
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
