const memoryCache = new Map();
const MAX_CACHE_SIZE = 10000;

const NATIVE_HOST = 'com.selecttranslate.host';
let nativePort = null;
let isExtensionPaused = true;

let pdfPollingTabId = null;
let lastPdfSelection = '';

loadCacheFromStorage();
initializePauseState();

chrome.runtime.onSuspend?.addListener(async () => {
  const result = await chrome.storage.sync.get(['settings']);
  const settings = result.settings || {};
  settings.isPaused = true;
  await chrome.storage.sync.set({ settings });
});

self.addEventListener('beforeunload', async () => {
  const result = await chrome.storage.sync.get(['settings']);
  const settings = result.settings || {};
  settings.isPaused = true;
  await chrome.storage.sync.set({ settings });
});

async function loadCacheFromStorage() {
  try {
    const result = await chrome.storage.local.get(['translationCache']);
    if (result.translationCache) {
      const entries = Object.entries(result.translationCache);
      entries.forEach(([key, value]) => {
        memoryCache.set(key, value);
      });
    }
  } catch (e) {}
}

async function initializePauseState() {
  try {
    const result = await chrome.storage.sync.get(['settings']);
    const settings = result.settings || {
      targetLang: 'en',
      sourceLang: 'auto',
      autoTranslate: true,
      showPopup: true
    };

    settings.isPaused = true;
    await chrome.storage.sync.set({ settings });
    isExtensionPaused = true;

    await chrome.action.setBadgeText({ text: '⏸' });
    await chrome.action.setBadgeBackgroundColor({ color: '#ff9800' });
  } catch (e) {
    isExtensionPaused = true;
  }
}

setInterval(() => {
  if (!isExtensionPaused) {
    checkForPdfTab();
  }
}, 2000);

async function checkForPdfTab() {
  try {
    const tabs = await chrome.tabs.query({ active: true, currentWindow: true });
    if (tabs[0]) {
      const tab = tabs[0];
      const isPdf = tab.url?.toLowerCase().endsWith('.pdf') ||
                    tab.url?.includes('pdfjs') ||
                    tab.url?.includes('/pdf') ||
                    tab.title?.toLowerCase().includes('.pdf');

      if (isPdf && pdfPollingTabId !== tab.id) {
        pdfPollingTabId = tab.id;
        pollPdfSelection(tab.id);
      } else if (!isPdf && pdfPollingTabId === tab.id) {
        pdfPollingTabId = null;
      }
    }
  } catch (e) {}
}

async function pollPdfSelection(tabId) {
  if (pdfPollingTabId !== tabId) return;

  try {
    const settings = await chrome.storage.sync.get(['settings']);
    if (settings.settings?.isPaused) {
      setTimeout(() => pollPdfSelection(tabId), 1000);
      return;
    }

    const results = await chrome.scripting.executeScript({
      target: { tabId: tabId },
      func: () => {
        const selection = window.getSelection();
        return selection ? selection.toString().trim() : '';
      }
    });

    if (results && results[0] && results[0].result) {
      const text = results[0].result;

      if (text && text.length >= 2 && text.length < 5000 && text !== lastPdfSelection) {
        lastPdfSelection = text;
        translateAndSend(text, tabId);
      }
    }
  } catch (e) {}

  if (pdfPollingTabId === tabId) {
    setTimeout(() => pollPdfSelection(tabId), 500);
  }
}

function showTranslationPopup(original, translated, detectedLang) {
  const existing = document.getElementById('qt-injected-popup');
  if (existing) existing.remove();

  const popup = document.createElement('div');
  popup.id = 'qt-injected-popup';
  popup.style.cssText = `
    position: fixed;
    bottom: 20px;
    right: 20px;
    width: 350px;
    background: white;
    border-radius: 12px;
    box-shadow: 0 8px 32px rgba(0,0,0,0.2);
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    font-size: 14px;
    z-index: 2147483647;
    overflow: hidden;
  `;

  popup.innerHTML = `
    <div style="padding: 12px 15px; background: linear-gradient(135deg, #2196F3, #1976D2); color: white; display: flex; justify-content: space-between; align-items: center;">
      <span style="font-weight: 600;">🌐 Translation</span>
      <button id="qt-close-btn" style="background: rgba(255,255,255,0.2); border: none; color: white; width: 26px; height: 26px; border-radius: 6px; cursor: pointer;">✕</button>
    </div>
    <div style="padding: 12px 15px; color: #666; font-size: 13px; border-bottom: 1px solid #eee; max-height: 80px; overflow-y: auto;">${original.substring(0, 150)}${original.length > 150 ? '...' : ''}</div>
    <div style="text-align: center; color: #2196F3; padding: 5px;">↓</div>
    <div style="padding: 12px 15px; color: #2196F3; font-size: 15px; font-weight: 500;">${translated}</div>
    <div style="padding: 10px 15px; background: #fafafa; border-top: 1px solid #eee; display: flex; justify-content: space-between; align-items: center;">
      <button id="qt-copy-btn" style="background: #4CAF50; color: white; border: none; padding: 6px 14px; border-radius: 6px; cursor: pointer;">📋 Copy</button>
      <span style="font-size: 11px; color: #999;">${detectedLang || ''}</span>
    </div>
  `;

  document.body.appendChild(popup);

  document.getElementById('qt-close-btn').onclick = () => popup.remove();

  document.getElementById('qt-copy-btn').onclick = () => {
    navigator.clipboard.writeText(translated);
    document.getElementById('qt-copy-btn').textContent = '✓ Copied!';
  };

  setTimeout(() => popup.remove(), 30000);
}

function connectToNativeHost() {
  try {
    nativePort = chrome.runtime.connectNative(NATIVE_HOST);

    nativePort.onMessage.addListener(async (message) => {
      if (message.action === 'translate' && message.text) {
        const settings = await chrome.storage.sync.get(['settings']);
        const { sourceLang = 'auto', targetLang = 'en', isPaused = false } = settings.settings || {};

        if (isPaused) return;

        const result = await translateText(message.text, sourceLang, targetLang);

        if (result.success) {
          addToHistory({
            original: message.text,
            translated: result.translatedText,
            sourceLang: result.detectedLanguage || sourceLang,
            targetLang: targetLang,
            timestamp: Date.now()
          });

          const tabs = await chrome.tabs.query({ active: true, currentWindow: true });
          if (tabs[0]) {
            try {
              await chrome.tabs.sendMessage(tabs[0].id, {
                action: 'showTranslation',
                original: message.text,
                translated: result.translatedText,
                suggestions: result.suggestions,
                detectedLang: result.detectedLanguage,
                fromCache: result.fromCache
              });
            } catch (e) {
              try {
                await chrome.scripting.executeScript({
                  target: { tabId: tabs[0].id },
                  func: showTranslationPopup,
                  args: [message.text, result.translatedText, result.detectedLanguage]
                });
              } catch (e2) {
                chrome.action.setBadgeText({ text: '1' });
                chrome.action.setBadgeBackgroundColor({ color: '#4CAF50' });
                setTimeout(() => chrome.action.setBadgeText({ text: '' }), 3000);
              }
            }
          }
        }
      }
    });

    nativePort.onDisconnect.addListener(() => {
      nativePort = null;
      if (!isExtensionPaused) {
        setTimeout(connectToNativeHost, 5000);
      }
    });
  } catch (e) {}
}

chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: 'translate-selection',
    title: 'Translate "%s"',
    contexts: ['selection']
  });

  chrome.storage.sync.set({
    settings: {
      targetLang: 'en',
      sourceLang: 'auto',
      autoTranslate: true,
      isPaused: true,
      showPopup: true
    }
  });
});

chrome.contextMenus.onClicked.addListener(async (info, tab) => {
  if (info.menuItemId === 'translate-selection' && info.selectionText) {
    const settings = await chrome.storage.sync.get(['settings']);
    const { sourceLang = 'auto', targetLang = 'en' } = settings.settings || {};

    const result = await translateText(info.selectionText, sourceLang, targetLang);

    if (result.success) {
      chrome.tabs.sendMessage(tab.id, {
        action: 'showTranslation',
        original: info.selectionText,
        translated: result.translatedText,
        suggestions: result.suggestions,
        detectedLang: result.detectedLanguage,
        fromCache: result.fromCache
      });

      addToHistory({
        original: info.selectionText,
        translated: result.translatedText,
        sourceLang: result.detectedLanguage || sourceLang,
        targetLang: targetLang,
        timestamp: Date.now()
      });
    }
  }
});

chrome.commands.onCommand.addListener(async (command) => {
  if (command === 'translate-selection') {
    const tabs = await chrome.tabs.query({ active: true, currentWindow: true });
    if (tabs[0]) {
      chrome.tabs.sendMessage(tabs[0].id, { action: 'getSelection' });
    }
  } else if (command === 'toggle-pause') {
    const tabs = await chrome.tabs.query({ active: true, currentWindow: true });
    togglePause(tabs[0]?.id);
  }
});

chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === 'translate') {
    (async () => {
      const settings = await chrome.storage.sync.get(['settings']);
      const { sourceLang = 'auto', targetLang = 'en' } = settings.settings || {};

      const result = await translateText(request.text, sourceLang, targetLang);
      sendResponse(result);

      if (result.success) {
        addToHistory({
          original: request.text,
          translated: result.translatedText,
          sourceLang: result.detectedLanguage || sourceLang,
          targetLang: targetLang,
          timestamp: Date.now()
        });
      }
    })();
    return true;
  }

  if (request.action === 'getHistory') {
    chrome.storage.local.get(['history'], (result) => {
      sendResponse({ history: result.history || [] });
    });
    return true;
  }

  if (request.action === 'clearHistory') {
    chrome.storage.local.set({ history: [] }, () => {
      sendResponse({ success: true });
    });
    return true;
  }

  if (request.action === 'exportHistory') {
    chrome.storage.local.get(['history'], (result) => {
      sendResponse({ history: result.history || [] });
    });
    return true;
  }

  if (request.action === 'togglePause') {
    togglePause(sender.tab?.id).then(isPaused => {
      sendResponse({ isPaused });
    });
    return true;
  }

  if (request.action === 'getPauseState') {
    chrome.storage.sync.get(['settings'], (result) => {
      sendResponse({ isPaused: result.settings?.isPaused !== false });
    });
    return true;
  }

  if (request.action === 'checkNativeHost') {
    checkNativeHost().then(available => {
      sendResponse({ available });
    });
    return true;
  }
});

async function checkNativeHost() {
  return new Promise((resolve) => {
    try {
      const port = chrome.runtime.connectNative(NATIVE_HOST);

      port.onMessage.addListener((response) => {
        port.disconnect();
        resolve(response.success === true);
      });

      port.onDisconnect.addListener(() => {
        resolve(false);
      });

      port.postMessage({ action: 'ping' });

      setTimeout(() => {
        port.disconnect();
        resolve(false);
      }, 1000);
    } catch (e) {
      resolve(false);
    }
  });
}

async function togglePause(tabId) {
  const result = await chrome.storage.sync.get(['settings']);
  const settings = result.settings || {
    targetLang: 'en',
    sourceLang: 'auto',
    autoTranslate: true,
    isPaused: true,
    showPopup: true
  };

  settings.isPaused = !settings.isPaused;
  isExtensionPaused = settings.isPaused;
  await chrome.storage.sync.set({ settings });

  if (settings.isPaused) {
    if (nativePort) {
      nativePort.disconnect();
      nativePort = null;
    }
    pdfPollingTabId = null;
  } else {
    if (!nativePort) {
      connectToNativeHost();
    }
  }

  const tabs = await chrome.tabs.query({});
  tabs.forEach(tab => {
    chrome.tabs.sendMessage(tab.id, {
      action: 'pauseStateChanged',
      isPaused: settings.isPaused
    }).catch(() => {});
  });

  await chrome.action.setBadgeText({ text: settings.isPaused ? '⏸' : '' });
  await chrome.action.setBadgeBackgroundColor({ color: settings.isPaused ? '#ff9800' : '#4CAF50' });

  return settings.isPaused;
}

async function translateAndSend(text, tabId) {
  const settings = await chrome.storage.sync.get(['settings']);
  const { sourceLang = 'auto', targetLang = 'en' } = settings.settings || {};

  const result = await translateText(text, sourceLang, targetLang);

  if (result.success) {
    chrome.tabs.sendMessage(tabId, {
      action: 'showTranslation',
      original: text,
      translated: result.translatedText,
      suggestions: result.suggestions,
      detectedLang: result.detectedLanguage,
      fromCache: result.fromCache
    });

    addToHistory({
      original: text,
      translated: result.translatedText,
      sourceLang: result.detectedLanguage || sourceLang,
      targetLang: targetLang,
      timestamp: Date.now()
    });
  }
}

function getCacheKey(text, sourceLang, targetLang) {
  return `${sourceLang}:${targetLang}:${text.toLowerCase().trim()}`;
}

function getFromCache(text, sourceLang, targetLang) {
  const key = getCacheKey(text, sourceLang, targetLang);
  const cached = memoryCache.get(key);
  if (cached) {
    return cached;
  }
  return null;
}

async function saveToCache(text, sourceLang, targetLang, result) {
  const key = getCacheKey(text, sourceLang, targetLang);

  const cacheEntry = {
    translatedText: result.translatedText,
    detectedLanguage: result.detectedLanguage,
    suggestions: result.suggestions,
    timestamp: Date.now()
  };

  memoryCache.set(key, cacheEntry);

  if (memoryCache.size > MAX_CACHE_SIZE) {
    const entries = Array.from(memoryCache.entries());
    entries.sort((a, b) => a[1].timestamp - b[1].timestamp);
    const toRemove = entries.slice(0, entries.length - MAX_CACHE_SIZE);
    toRemove.forEach(([k]) => memoryCache.delete(k));
  }

  persistCacheThrottled();
}

let persistTimeout = null;
function persistCacheThrottled() {
  if (persistTimeout) return;

  persistTimeout = setTimeout(() => {
    persistCacheNow();
    persistTimeout = null;
  }, 2000);
}

function persistCacheNow() {
  try {
    const cacheObj = Object.fromEntries(memoryCache);
    chrome.storage.local.set({ translationCache: cacheObj });
  } catch (e) {}
}

async function translateText(text, sourceLang = 'auto', targetLang = 'en') {
  const cached = getFromCache(text, sourceLang, targetLang);
  if (cached) {
    return {
      success: true,
      translatedText: cached.translatedText,
      detectedLanguage: cached.detectedLanguage,
      suggestions: cached.suggestions || [],
      fromCache: true
    };
  }

  try {
    const url = `https://translate.googleapis.com/translate_a/single?client=gtx&sl=${sourceLang}&tl=${targetLang}&dt=t&dt=bd&dj=1&q=${encodeURIComponent(text)}`;

    const response = await fetch(url);
    const data = await response.json();

    let translatedText = '';
    if (data.sentences) {
      translatedText = data.sentences.map(s => s.trans || '').join('');
    }

    let suggestions = [];
    if (data.dict) {
      data.dict.forEach(entry => {
        if (entry.terms) {
          suggestions.push(...entry.terms.slice(0, 3));
        }
      });
      suggestions = [...new Set(suggestions)].slice(0, 5);
    }

    const result = {
      success: true,
      translatedText,
      detectedLanguage: data.src,
      suggestions,
      fromCache: false
    };

    await saveToCache(text, sourceLang, targetLang, result);

    return result;
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
}

async function addToHistory(item) {
  const result = await chrome.storage.local.get(['history']);
  let history = result.history || [];

  const isDuplicate = history.some(h =>
    h.original === item.original &&
    h.targetLang === item.targetLang &&
    (Date.now() - h.timestamp) < 5000
  );

  if (!isDuplicate) {
    history.unshift(item);
    if (history.length > 500) {
      history = history.slice(0, 500);
    }
    await chrome.storage.local.set({ history });
  }
}