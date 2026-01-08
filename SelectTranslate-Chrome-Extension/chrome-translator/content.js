let isPaused = true;
let popup = null;
let selectionTimeout = null;
let lastTranslatedText = '';
let isDragging = false;
let dragOffset = { x: 0, y: 0 };

let savedPosition = null;

init();

async function init() {
  try {
    const response = await chrome.runtime.sendMessage({ action: 'getPauseState' });
    isPaused = response?.isPaused !== false;
  } catch (e) {
    isPaused = true;
  }
  
  try {
    const stored = await chrome.storage.local.get(['popupPosition']);
    if (stored.popupPosition) {
      savedPosition = stored.popupPosition;
    }
  } catch (e) {
  }
  
  document.addEventListener('mouseup', onMouseUp);
  document.addEventListener('keydown', onKeyDown);
  
  chrome.runtime.onMessage.addListener(handleMessage);
  
  chrome.storage.onChanged.addListener((changes, area) => {
    if (area === 'sync' && changes.settings) {
      isPaused = changes.settings.newValue?.isPaused || false;
    }
  });
  
  document.addEventListener('mousemove', onDragMove);
  document.addEventListener('mouseup', onDragEnd);
}

function onMouseUp(e) {
  if (popup && popup.contains(e.target)) return;
  
  if (isDragging) return;
  
  if (selectionTimeout) clearTimeout(selectionTimeout);
  
  selectionTimeout = setTimeout(() => {
    const selection = window.getSelection();
    const text = selection?.toString()?.trim();
    
    if (text && text.length >= 2 && text.length < 5000 && !isPaused) {
      let rect = null;
      try {
        if (selection.rangeCount > 0) {
          rect = selection.getRangeAt(0).getBoundingClientRect();
        }
      } catch (e) {
      }
      
      translateSelection(text, rect);
    }
  }, 300);
}

function handleMessage(request, sender, sendResponse) {
  if (request.action === 'showTranslation') {
    showPopup(request.original, request.translated, request.suggestions, request.detectedLang, null, request.fromCache);
  }
  
  if (request.action === 'getSelection') {
    const text = window.getSelection()?.toString()?.trim();
    sendResponse({ text });
  }
  
  if (request.action === 'pauseStateChanged') {
    isPaused = request.isPaused;
    showPauseIndicator(isPaused);
  }
}

function onKeyDown(e) {
  if (e.key === 'Escape' && popup) {
    hidePopup();
  }
}

async function translateSelection(text, rect) {
  if (text === lastTranslatedText) return;
  lastTranslatedText = text;
  
  const result = await chrome.storage.sync.get(['settings']);
  const settings = result.settings || {};
  
  const autoTranslate = settings.autoTranslate !== false;
  
  if (!autoTranslate || isPaused) return;
  
  try {
    const response = await chrome.runtime.sendMessage({
      action: 'translate',
      text: text,
      sourceLang: settings.sourceLang || 'auto',
      targetLang: settings.targetLang || 'en'
    });
    
    if (response && response.success) {
      showPopup(text, response.translatedText, response.suggestions, response.detectedLanguage, rect, response.fromCache);
      
      chrome.runtime.sendMessage({
        action: 'addToHistory',
        item: {
          original: text,
          translated: response.translatedText,
          sourceLang: response.detectedLanguage || settings.sourceLang,
          targetLang: settings.targetLang || 'en',
          timestamp: Date.now()
        }
      });
    }
  } catch (e) {
  }
}

function showPopup(original, translated, suggestions = [], detectedLang = '', rect = null, fromCache = false) {
  if (popup) {
    popup.remove();
    popup = null;
  }
  
  popup = document.createElement('div');
  popup.className = 'qt-popup';
  popup.innerHTML = `
    <div class="qt-header" data-draggable="true">
      <span class="qt-title">🌐 Translation ${fromCache ? '<span class="qt-cached">⚡</span>' : ''}</span>
      <div class="qt-buttons">
        <button class="qt-btn qt-reset" title="Reset position">↺</button>
        <button class="qt-btn qt-pin" title="Pin (keep open)">📌</button>
        <button class="qt-btn qt-close" title="Close (Esc)">✕</button>
      </div>
    </div>
    <div class="qt-original">${escapeHtml(truncate(original, 150))}</div>
    <div class="qt-arrow">↓</div>
    <div class="qt-translated">${escapeHtml(translated)}</div>
    ${suggestions.length > 0 ? `
      <div class="qt-suggestions">
        <span class="qt-sug-label">💡</span>
        ${suggestions.map(s => `<span class="qt-sug-item">${escapeHtml(s)}</span>`).join('')}
      </div>
    ` : ''}
    <div class="qt-footer">
      <button class="qt-copy-btn">📋 Copy</button>
      ${detectedLang ? `<span class="qt-lang">${detectedLang}</span>` : ''}
    </div>
  `;
  
  document.body.appendChild(popup);
  
  positionPopup(rect);
  
  setupPopupEvents(translated, rect);
}

function positionPopup(rect) {
  if (!popup) return;
  
  const padding = 20;
  const popupWidth = 350;
  const popupHeight = popup.offsetHeight || 220;
  let x, y;
  
  if (savedPosition) {
    x = savedPosition.x;
    y = savedPosition.y;
  } else if (rect && rect.width > 0 && rect.height > 0) {
    x = rect.right + padding;
    y = rect.top;
    
    if (x + popupWidth > window.innerWidth - padding) {
      x = rect.left - popupWidth - padding;
    }
    
    if (x < padding) {
      x = Math.max(padding, rect.left);
      y = rect.bottom + padding;
    }
  } else {
    x = window.innerWidth - popupWidth - padding;
    y = window.innerHeight - popupHeight - padding;
  }
  
  x = Math.max(padding, Math.min(x, window.innerWidth - popupWidth - padding));
  y = Math.max(padding, Math.min(y, window.innerHeight - popupHeight - padding));
  
  popup.style.position = 'fixed';
  popup.style.left = `${x}px`;
  popup.style.top = `${y}px`;
}

function setupPopupEvents(translated, rect) {
  if (!popup) return;
  
  popup.querySelector('.qt-close').addEventListener('click', (e) => {
    e.stopPropagation();
    hidePopup();
  });
  
  popup.querySelector('.qt-pin').addEventListener('click', (e) => {
    e.stopPropagation();
    togglePin();
  });
  
  popup.querySelector('.qt-reset').addEventListener('click', (e) => {
    e.stopPropagation();
    savedPosition = null;
    chrome.storage.local.remove('popupPosition');
    positionPopup(rect);
  });
  
  popup.querySelector('.qt-copy-btn').addEventListener('click', (e) => {
    e.stopPropagation();
    navigator.clipboard.writeText(translated);
    const btn = popup.querySelector('.qt-copy-btn');
    btn.textContent = '✓ Copied!';
    setTimeout(() => {
      if (popup && btn) btn.textContent = '📋 Copy';
    }, 1500);
  });
  
  popup.querySelectorAll('.qt-sug-item').forEach(item => {
    item.addEventListener('click', (e) => {
      e.stopPropagation();
      popup.querySelector('.qt-translated').textContent = item.textContent;
    });
  });
  
  popup.addEventListener('click', (e) => {
    e.stopPropagation();
  });
  
  popup.addEventListener('wheel', (e) => {
    e.stopPropagation();
  }, { passive: true });
  
  const header = popup.querySelector('.qt-header');
  header.style.cursor = 'grab';
  
  header.addEventListener('mousedown', (e) => {
    if (e.target.closest('.qt-btn')) return;
    
    isDragging = true;
    dragOffset.x = e.clientX - popup.offsetLeft;
    dragOffset.y = e.clientY - popup.offsetTop;
    
    header.style.cursor = 'grabbing';
    popup.style.userSelect = 'none';
    
    e.preventDefault();
    e.stopPropagation();
  });
}

function onDragMove(e) {
  if (!isDragging || !popup) return;
  
  const x = e.clientX - dragOffset.x;
  const y = e.clientY - dragOffset.y;
  
  const maxX = window.innerWidth - popup.offsetWidth - 10;
  const maxY = window.innerHeight - popup.offsetHeight - 10;
  
  popup.style.left = `${Math.max(10, Math.min(x, maxX))}px`;
  popup.style.top = `${Math.max(10, Math.min(y, maxY))}px`;
}

function onDragEnd() {
  if (!isDragging) return;
  
  isDragging = false;
  
  if (popup) {
    const header = popup.querySelector('.qt-header');
    if (header) header.style.cursor = 'grab';
    popup.style.userSelect = '';
    
    savedPosition = {
      x: popup.offsetLeft,
      y: popup.offsetTop
    };
    
    try {
      chrome.storage.local.set({ popupPosition: savedPosition });
    } catch (e) {
    }
  }
}

function hidePopup() {
  if (popup) {
    popup.classList.add('qt-hiding');
    const popupToRemove = popup;
    popup = null;
    
    setTimeout(() => {
      popupToRemove.remove();
    }, 150);
  }
  
  isDragging = false;
  lastTranslatedText = '';
}

function togglePin() {
  if (!popup) return;
  
  const isPinned = popup.classList.toggle('qt-pinned');
  const pinBtn = popup.querySelector('.qt-pin');
  pinBtn.textContent = isPinned ? '📍' : '📌';
  pinBtn.title = isPinned ? 'Unpin' : 'Pin (keep open)';
}

function showPauseIndicator(paused) {
  document.querySelector('.qt-pause-indicator')?.remove();
  
  if (paused) {
    const indicator = document.createElement('div');
    indicator.className = 'qt-pause-indicator';
    indicator.textContent = '⏸ Translation Paused';
    document.body.appendChild(indicator);
    
    setTimeout(() => indicator.classList.add('qt-show'), 10);
    setTimeout(() => {
      indicator.classList.remove('qt-show');
      setTimeout(() => indicator.remove(), 300);
    }, 2000);
  }
}

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

function truncate(text, maxLength) {
  return text.length > maxLength ? text.substring(0, maxLength) + '...' : text;
}
