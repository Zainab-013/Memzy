// Mobile Navigation Menu Toggle
const mobileToggle = document.getElementById('mobile-toggle');
const navMenu = document.getElementById('nav-menu');

if (mobileToggle && navMenu) {
  mobileToggle.addEventListener('click', () => {
    navMenu.classList.toggle('active');
    mobileToggle.classList.toggle('open');
  });

  // Close menu when clicking nav links
  const navLinks = document.querySelectorAll('.nav-link');
  navLinks.forEach(link => {
    link.addEventListener('click', () => {
      navMenu.classList.remove('active');
      mobileToggle.classList.remove('open');
    });
  });
}

// Terms & Conditions Tab Switcher
function switchTab(event, tabId) {
  event.preventDefault();
  
  // Hide all tab panes
  const tabPanes = document.querySelectorAll('.tab-pane');
  tabPanes.forEach(pane => {
    pane.classList.remove('active');
  });
  
  // Deactivate all tab buttons
  const tabButtons = document.querySelectorAll('.tab-btn');
  tabButtons.forEach(btn => {
    btn.classList.remove('active');
  });
  
  // Show target tab pane
  const targetPane = document.getElementById(tabId);
  if (targetPane) {
    targetPane.classList.add('active');
  }
  
  // Activate clicked button
  event.currentTarget.classList.add('active');
}

// Interactive Reminder Parser Simulator
const simForm = document.getElementById('sim-form');
const simInput = document.getElementById('sim-input');
const simChatBox = document.getElementById('sim-chat-box');

if (simForm && simInput && simChatBox) {
  simForm.addEventListener('submit', (e) => {
    e.preventDefault();
    const text = simInput.value.trim();
    if (!text) return;
    
    // Add user chat bubble
    addChatBubble(text, 'user');
    simInput.value = '';
    
    // Auto scroll chat
    autoScrollChat();
    
    // Simulate thinking delay
    setTimeout(() => {
      const result = parseReminder(text);
      let responseText = '';
      
      if (result.hasTime) {
        responseText = `<strong class="text-pink">✓ Noted</strong><br>Reminder created for: <strong>${result.time}</strong><br><span style="opacity: 0.8; font-size: 0.85em;">Task: "${result.task}"</span>`;
      } else {
        responseText = `<strong class="text-pink">✓ Saved Note</strong><br>Saved as a note in this chat. (Tip: Try adding "remind me at 10 PM" to set alarms)`;
      }
      
      addChatBubble(responseText, 'system');
      autoScrollChat();
    }, 600);
  });
}

// Parse reminder using simple JS text analysis (NLP simulator)
function parseReminder(text) {
  const result = {
    hasTime: false,
    time: '',
    task: text
  };
  
  // Regex to detect common time patterns, e.g., "at 10:00 PM", "at 9 PM", "at 6am", "tomorrow at 5 PM", "10:30 PM"
  // Match "at XX:XX PM/AM", "at XX PM/AM", "at XX"
  const timeRegex = /(?:at\s+)?(\d{1,2}(?::\d{2})?\s*(?:pm|am|PM|AM))/i;
  const match = text.match(timeRegex);
  
  if (match) {
    result.hasTime = true;
    result.time = match[1];
    
    // Try to isolate the task (remove the timing part)
    let cleanedTask = text.replace(timeRegex, '');
    
    // Clean up reminder phrases
    const phrasesToClean = [
      /remind me to/i,
      /remind me at/i,
      /remind me/i,
      /\bremind\b/i
    ];
    
    phrasesToClean.forEach(regex => {
      cleanedTask = cleanedTask.replace(regex, '');
    });
    
    // Strip trailing punctuation and whitespace
    cleanedTask = cleanedTask.trim().replace(/[.,;!]+$/, '');
    
    if (cleanedTask) {
      result.task = cleanedTask;
    } else {
      result.task = "Untitled Reminder";
    }
  } else {
    // Check for phrases like "tomorrow", "tonight", "in 2 hours"
    if (/tomorrow/i.test(text)) {
      result.hasTime = true;
      result.time = 'Tomorrow (Default: 9:00 AM)';
      result.task = text.replace(/tomorrow/i, '').replace(/remind me to/i, '').trim();
    } else if (/tonight/i.test(text)) {
      result.hasTime = true;
      result.time = 'Tonight (Default: 8:00 PM)';
      result.task = text.replace(/tonight/i, '').replace(/remind me to/i, '').trim();
    }
  }
  
  // Final sanitation
  result.task = result.task.trim().replace(/[.,;!]+$/, '');
  
  return result;
}

// Create and append a chat bubble element
function addChatBubble(content, sender) {
  const bubble = document.createElement('div');
  bubble.className = `chat-bubble ${sender}`;
  
  const bubbleContent = document.createElement('div');
  bubbleContent.className = 'bubble-content';
  bubbleContent.innerHTML = content;
  
  const time = document.createElement('div');
  time.className = 'bubble-time';
  
  const now = new Date();
  let hours = now.getHours();
  const minutes = now.getMinutes().toString().padStart(2, '0');
  const ampm = hours >= 12 ? 'PM' : 'AM';
  hours = hours % 12;
  hours = hours ? hours : 12; // the hour '0' should be '12'
  time.textContent = `${hours}:${minutes} ${ampm}`;
  
  bubble.appendChild(bubbleContent);
  bubble.appendChild(time);
  
  simChatBox.appendChild(bubble);
}

// Auto scroll chat box
function autoScrollChat() {
  simChatBox.scrollTop = simChatBox.scrollHeight;
}
