const languages = [
  { code: 'auto', name: 'Auto-detect', flag: '🔍' },
  { code: 'en', name: 'English', flag: '🇬🇧' },
  { code: 'ka', name: 'Georgian', flag: '🇬🇪' },
  { code: 'ru', name: 'Russian', flag: '🇷🇺' },
  { code: 'es', name: 'Spanish', flag: '🇪🇸' },
  { code: 'fr', name: 'French', flag: '🇫🇷' },
  { code: 'de', name: 'German', flag: '🇩🇪' },
  { code: 'it', name: 'Italian', flag: '🇮🇹' },
  { code: 'pt', name: 'Portuguese', flag: '🇵🇹' },
  { code: 'zh-CN', name: 'Chinese (Simplified)', flag: '🇨🇳' },
  { code: 'zh-TW', name: 'Chinese (Traditional)', flag: '🇹🇼' },
  { code: 'ja', name: 'Japanese', flag: '🇯🇵' },
  { code: 'ko', name: 'Korean', flag: '🇰🇷' },
  { code: 'ar', name: 'Arabic', flag: '🇸🇦' },
  { code: 'hi', name: 'Hindi', flag: '🇮🇳' },
  { code: 'tr', name: 'Turkish', flag: '🇹🇷' },
  { code: 'pl', name: 'Polish', flag: '🇵🇱' },
  { code: 'nl', name: 'Dutch', flag: '🇳🇱' },
  { code: 'sv', name: 'Swedish', flag: '🇸🇪' },
  { code: 'da', name: 'Danish', flag: '🇩🇰' },
  { code: 'fi', name: 'Finnish', flag: '🇫🇮' },
  { code: 'no', name: 'Norwegian', flag: '🇳🇴' },
  { code: 'cs', name: 'Czech', flag: '🇨🇿' },
  { code: 'el', name: 'Greek', flag: '🇬🇷' },
  { code: 'he', name: 'Hebrew', flag: '🇮🇱' },
  { code: 'th', name: 'Thai', flag: '🇹🇭' },
  { code: 'vi', name: 'Vietnamese', flag: '🇻🇳' },
  { code: 'id', name: 'Indonesian', flag: '🇮🇩' },
  { code: 'uk', name: 'Ukrainian', flag: '🇺🇦' },
  { code: 'ro', name: 'Romanian', flag: '🇷🇴' },
  { code: 'hu', name: 'Hungarian', flag: '🇭🇺' },
  { code: 'bg', name: 'Bulgarian', flag: '🇧🇬' },
  { code: 'sk', name: 'Slovak', flag: '🇸🇰' },
  { code: 'hr', name: 'Croatian', flag: '🇭🇷' },
  { code: 'sr', name: 'Serbian', flag: '🇷🇸' },
  { code: 'sl', name: 'Slovenian', flag: '🇸🇮' },
  { code: 'et', name: 'Estonian', flag: '🇪🇪' },
  { code: 'lv', name: 'Latvian', flag: '🇱🇻' },
  { code: 'lt', name: 'Lithuanian', flag: '🇱🇹' }
];

const sourceLang = document.getElementById('sourceLang');
const targetLang = document.getElementById('targetLang');
const inputText = document.getElementById('inputText');
const outputText = document.getElementById('outputText');
const suggestions = document.getElementById('suggestions');
const translateBtn = document.getElementById('translateBtn');
const translateText = document.getElementById('translateText');
const pauseBtn = document.getElementById('pauseBtn');
const pauseIcon = document.getElementById('pauseIcon');
const pauseBanner = document.getElementById('pauseBanner');
const historyList = document.getElementById('historyList');
const historyCount = document.getElementById('historyCount');

let isPaused = false;

document.addEventListener('DOMContentLoaded', init);

async function init() {
  populateLanguages();
  
  await loadSettings();
  
  await loadHistory();
  
  translateBtn.addEventListener('click', translate);
  pauseBtn.addEventListener('click', togglePause);
  document.getElementById('swapBtn').addEventListener('click', swapLanguages);
  document.getElementById('nativeBtn').addEventListener('click', getNativeSelection);
  document.getElementById('clipboardBtn').addEventListener('click', pasteAndTranslate);
  document.getElementById('clearBtn').addEventListener('click', clear);
  document.getElementById('copyBtn').addEventListener('click', copy);
  document.getElementById('exportCsvBtn').addEventListener('click', exportCsv);
  document.getElementById('exportExcelBtn').addEventListener('click', exportExcel);
  document.getElementById('clearHistoryBtn').addEventListener('click', clearHistory);
  
  document.getElementById('autoTranslate').addEventListener('change', saveSettings);
  document.getElementById('showPopup').addEventListener('change', saveSettings);
  
  document.getElementById('clearCacheBtn').addEventListener('click', clearCache);
  
  loadCacheStats();
  
  sourceLang.addEventListener('change', saveSettings);
  targetLang.addEventListener('change', saveSettings);
  
  document.querySelectorAll('.tab').forEach(tab => {
    tab.addEventListener('click', () => switchTab(tab.dataset.tab));
  });
  
  inputText.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      translate();
    }
  });
  
  document.getElementById('donateLink').addEventListener('click', (e) => {
    e.preventDefault();
    chrome.tabs.create({ url: 'https://ko-fi.com/sososurguladze' });
  });
}

function populateLanguages() {
  sourceLang.innerHTML = languages.map(l =>
    `<option value="${l.code}">${l.flag} ${l.name}</option>`
  ).join('');
  
  targetLang.innerHTML = languages.slice(1).map(l =>
    `<option value="${l.code}">${l.flag} ${l.name}</option>`
  ).join('');
}

async function loadSettings() {
  const result = await chrome.storage.sync.get(['settings']);
  const settings = result.settings || {};
  
  sourceLang.value = settings.sourceLang || 'auto';
  targetLang.value = settings.targetLang || 'en';
  document.getElementById('autoTranslate').checked = settings.autoTranslate !== false;
  document.getElementById('showPopup').checked = settings.showPopup !== false;
  
  isPaused = settings.isPaused !== false;
  
  updatePauseUI();
}

async function saveSettings() {
  const settings = {
    sourceLang: sourceLang.value,
    targetLang: targetLang.value,
    autoTranslate: document.getElementById('autoTranslate').checked,
    showPopup: document.getElementById('showPopup').checked,
    isPaused: isPaused
  };
  await chrome.storage.sync.set({ settings });
}

async function togglePause() {
  await chrome.runtime.sendMessage({ action: 'togglePause' });
  
  const result = await chrome.storage.sync.get(['settings']);
  isPaused = result.settings?.isPaused !== false;
  updatePauseUI();
}

function updatePauseUI() {
  pauseIcon.textContent = isPaused ? '▶' : '⏸';
  pauseBtn.classList.toggle('paused', isPaused);
  pauseBtn.title = isPaused ? 'Resume (Ctrl+Shift+P)' : 'Pause (Ctrl+Shift+P)';
  pauseBanner.classList.toggle('hidden', !isPaused);
}

chrome.storage.onChanged.addListener((changes, area) => {
  if (area === 'sync' && changes.settings) {
    const newSettings = changes.settings.newValue || {};
    isPaused = newSettings.isPaused !== false;
    updatePauseUI();
  }
});

async function translate() {
  const text = inputText.value.trim();
  if (!text) return;
  
  translateBtn.disabled = true;
  translateText.textContent = '⏳ Translating...';
  suggestions.classList.add('hidden');
  
  try {
    const response = await chrome.runtime.sendMessage({
      action: 'translate',
      text: text,
      sourceLang: sourceLang.value,
      targetLang: targetLang.value
    });
    
    if (response.success) {
      outputText.textContent = response.translatedText;
      outputText.classList.remove('placeholder');
      
      if (response.suggestions?.length > 0) {
        suggestions.innerHTML = response.suggestions.map(s => 
          `<span class="sug-item">${escapeHtml(s)}</span>`
        ).join('');
        suggestions.classList.remove('hidden');
        
        suggestions.querySelectorAll('.sug-item').forEach(item => {
          item.addEventListener('click', () => {
            outputText.textContent = item.textContent;
          });
        });
      }
      
      chrome.runtime.sendMessage({
        action: 'addToHistory',
        item: {
          original: text,
          translated: response.translatedText,
          sourceLang: response.detectedLanguage || sourceLang.value,
          targetLang: targetLang.value,
          timestamp: Date.now()
        }
      });
      
      await loadHistory();
    } else {
      outputText.textContent = `Error: ${response.error}`;
      outputText.classList.add('placeholder');
    }
  } catch (error) {
    outputText.textContent = `Error: ${error.message}`;
    outputText.classList.add('placeholder');
  } finally {
    translateBtn.disabled = false;
    translateText.textContent = '🔄 Translate';
  }
}

function swapLanguages() {
  if (sourceLang.value === 'auto') return;
  
  const temp = sourceLang.value;
  sourceLang.value = targetLang.value;
  targetLang.value = temp;
  
  if (outputText.textContent && !outputText.classList.contains('placeholder')) {
    const tempText = inputText.value;
    inputText.value = outputText.textContent;
    outputText.textContent = tempText;
  }
  
  saveSettings();
}

async function pasteAndTranslate() {
  try {
    const text = await navigator.clipboard.readText();
    if (text && text.trim()) {
      inputText.value = text;
      await translate();
    }
  } catch (err) {
    outputText.textContent = 'Could not read clipboard. Please paste manually (Ctrl+V)';
    outputText.classList.add('placeholder');
  }
}

async function getNativeSelection() {
  const btn = document.getElementById('nativeBtn');
  btn.textContent = '⏳';
  btn.disabled = true;
  
  try {
    const response = await chrome.runtime.sendMessage({ action: 'getNativeSelection' });
    
    if (response.success && response.text) {
      inputText.value = response.text;
      translate();
    } else {
      alert('Could not get selection.\n\nMake sure:\n1. Native host is installed\n2. Text is selected in another app');
    }
  } catch (e) {
    alert('Native messaging not available.\n\nInstall the native host app first.');
  } finally {
    btn.textContent = '📥';
    btn.disabled = false;
  }
}

function clear() {
  inputText.value = '';
  outputText.textContent = 'Translation will appear here...';
  outputText.classList.add('placeholder');
  suggestions.classList.add('hidden');
}

async function copy() {
  const text = outputText.textContent;
  if (text && !outputText.classList.contains('placeholder')) {
    await navigator.clipboard.writeText(text);
    document.getElementById('copyBtn').textContent = '✓ Copied!';
    setTimeout(() => {
      document.getElementById('copyBtn').textContent = '📋 Copy';
    }, 1500);
  }
}

function switchTab(tabName) {
  document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
  document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');
  
  document.getElementById('settingsTab').classList.toggle('hidden', tabName !== 'settings');
  document.getElementById('historyTab').classList.toggle('hidden', tabName !== 'history');
  
  if (tabName === 'history') {
    loadHistory();
  }
}

async function loadHistory() {
  const response = await chrome.runtime.sendMessage({ action: 'getHistory' });
  const history = response.history || [];
  
  historyCount.textContent = `${history.length} items`;
  
  if (history.length === 0) {
    historyList.innerHTML = '<div class="history-empty">No translations yet</div>';
    return;
  }
  
  historyList.innerHTML = history.slice(0, 50).map(item => `
    <div class="history-item" data-original="${escapeAttr(item.original)}" data-translated="${escapeAttr(item.translated)}">
      <div class="history-time">${formatTime(item.timestamp)}</div>
      <div class="history-original">${escapeHtml(truncate(item.original, 50))}</div>
      <div class="history-translated">${escapeHtml(truncate(item.translated, 50))}</div>
    </div>
  `).join('');
  
  historyList.querySelectorAll('.history-item').forEach(item => {
    item.addEventListener('click', () => {
      inputText.value = item.dataset.original;
      outputText.textContent = item.dataset.translated;
      outputText.classList.remove('placeholder');
      switchTab('settings');
    });
  });
}

async function clearHistory() {
  if (confirm('Clear all translation history?')) {
    await chrome.runtime.sendMessage({ action: 'clearHistory' });
    await loadHistory();
  }
}

async function loadCacheStats() {
  const response = await chrome.runtime.sendMessage({ action: 'getCacheStats' });
  document.getElementById('cacheCount').textContent = response?.cacheSize || 0;
}

async function clearCache() {
  if (confirm('Clear translation cache?')) {
    await chrome.runtime.sendMessage({ action: 'clearCache' });
    await loadCacheStats();
  }
}

async function exportCsv() {
  const response = await chrome.runtime.sendMessage({ action: 'getHistory' });
  const history = response.history || [];
  
  if (history.length === 0) {
    alert('No history to export');
    return;
  }
  
  let csv = '\uFEFF';
  csv += 'Date,Time,Original,Translation,From,To\n';
  
  history.forEach(item => {
    const date = new Date(item.timestamp);
    csv += `${date.toLocaleDateString()},${date.toLocaleTimeString()},`;
    csv += `"${escapeCsv(item.original)}","${escapeCsv(item.translated)}",`;
    csv += `${item.sourceLang},${item.targetLang}\n`;
  });
  
  downloadFile(csv, `translations_${formatDate()}.csv`, 'text/csv');
}

async function exportExcel() {
  const response = await chrome.runtime.sendMessage({ action: 'getHistory' });
  const history = response.history || [];
  
  if (history.length === 0) {
    alert('No history to export');
    return;
  }
  
  const xlsx = createXlsx(history);
  downloadFile(xlsx, `translations_${formatDate()}.xlsx`, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
}

function createXlsx(history) {
  const files = {};
  
  files['[Content_Types].xml'] = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
  <Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>
</Types>`;

  files['_rels/.rels'] = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>`;

  files['xl/_rels/workbook.xml.rels'] = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>
</Relationships>`;

  files['xl/workbook.xml'] = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="Translations" sheetId="1" r:id="rId1"/>
  </sheets>
</workbook>`;

  files['xl/styles.xml'] = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="2">
    <font><sz val="11"/><name val="Calibri"/></font>
    <font><sz val="11"/><name val="Calibri"/><b/><color rgb="FFFFFFFF"/></font>
  </fonts>
  <fills count="3">
    <fill><patternFill patternType="none"/></fill>
    <fill><patternFill patternType="gray125"/></fill>
    <fill><patternFill patternType="solid"><fgColor rgb="FF4472C4"/></patternFill></fill>
  </fills>
  <borders count="1"><border/></borders>
  <cellStyleXfs count="1"><xf/></cellStyleXfs>
  <cellXfs count="2">
    <xf/>
    <xf fontId="1" fillId="2" applyFont="1" applyFill="1"/>
  </cellXfs>
</styleSheet>`;

  const strings = [];
  const stringIndex = {};
  
  function getStringIndex(str) {
    if (!(str in stringIndex)) {
      stringIndex[str] = strings.length;
      strings.push(str);
    }
    return stringIndex[str];
  }
  
  const headers = ['Date/Time', 'Original Text', 'Translation', 'From', 'To'];
  headers.forEach(h => getStringIndex(h));
  
  history.forEach(item => {
    getStringIndex(new Date(item.timestamp).toLocaleString());
    getStringIndex(item.original || '');
    getStringIndex(item.translated || '');
    getStringIndex(getLangName(item.sourceLang));
    getStringIndex(getLangName(item.targetLang));
  });
  
  files['xl/sharedStrings.xml'] = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="${strings.length}" uniqueCount="${strings.length}">
${strings.map(s => `  <si><t>${escapeXml(s)}</t></si>`).join('\n')}
</sst>`;

  let sheetData = '';
  
  sheetData += '<row r="1">';
  headers.forEach((h, i) => {
    const col = String.fromCharCode(65 + i);
    sheetData += `<c r="${col}1" t="s" s="1"><v>${getStringIndex(h)}</v></c>`;
  });
  sheetData += '</row>';
  
  history.forEach((item, rowIdx) => {
    const row = rowIdx + 2;
    const dateStr = new Date(item.timestamp).toLocaleString();
    sheetData += `<row r="${row}">`;
    sheetData += `<c r="A${row}" t="s"><v>${getStringIndex(dateStr)}</v></c>`;
    sheetData += `<c r="B${row}" t="s"><v>${getStringIndex(item.original || '')}</v></c>`;
    sheetData += `<c r="C${row}" t="s"><v>${getStringIndex(item.translated || '')}</v></c>`;
    sheetData += `<c r="D${row}" t="s"><v>${getStringIndex(getLangName(item.sourceLang))}</v></c>`;
    sheetData += `<c r="E${row}" t="s"><v>${getStringIndex(getLangName(item.targetLang))}</v></c>`;
    sheetData += '</row>';
  });
  
  files['xl/worksheets/sheet1.xml'] = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <cols>
    <col min="1" max="1" width="18" customWidth="1"/>
    <col min="2" max="2" width="40" customWidth="1"/>
    <col min="3" max="3" width="40" customWidth="1"/>
    <col min="4" max="4" width="15" customWidth="1"/>
    <col min="5" max="5" width="15" customWidth="1"/>
  </cols>
  <sheetData>${sheetData}</sheetData>
</worksheet>`;

  return createZip(files);
}

function createZip(files) {
  const entries = [];
  const centralDirectory = [];
  let offset = 0;
  
  for (const [filename, content] of Object.entries(files)) {
    const data = new TextEncoder().encode(content);
    const crc = crc32(data);
    
    const header = new Uint8Array(30 + filename.length);
    const view = new DataView(header.buffer);
    
    view.setUint32(0, 0x04034b50, true);
    view.setUint16(4, 20, true);
    view.setUint16(6, 0, true);
    view.setUint16(8, 0, true);
    view.setUint16(10, 0, true);
    view.setUint16(12, 0, true);
    view.setUint32(14, crc, true);
    view.setUint32(18, data.length, true);
    view.setUint32(22, data.length, true);
    view.setUint16(26, filename.length, true);
    view.setUint16(28, 0, true);
    
    new TextEncoder().encodeInto(filename, header.subarray(30));
    
    const cdEntry = new Uint8Array(46 + filename.length);
    const cdView = new DataView(cdEntry.buffer);
    
    cdView.setUint32(0, 0x02014b50, true);
    cdView.setUint16(4, 20, true);
    cdView.setUint16(6, 20, true);
    cdView.setUint16(8, 0, true);
    cdView.setUint16(10, 0, true);
    cdView.setUint16(12, 0, true);
    cdView.setUint16(14, 0, true);
    cdView.setUint32(16, crc, true);
    cdView.setUint32(20, data.length, true);
    cdView.setUint32(24, data.length, true);
    cdView.setUint16(28, filename.length, true);
    cdView.setUint16(30, 0, true);
    cdView.setUint16(32, 0, true);
    cdView.setUint16(34, 0, true);
    cdView.setUint16(36, 0, true);
    cdView.setUint32(38, 0, true);
    cdView.setUint32(42, offset, true);
    
    new TextEncoder().encodeInto(filename, cdEntry.subarray(46));
    
    entries.push(header, data);
    centralDirectory.push(cdEntry);
    offset += header.length + data.length;
  }
  
  const cdSize = centralDirectory.reduce((sum, e) => sum + e.length, 0);
  const eocd = new Uint8Array(22);
  const eocdView = new DataView(eocd.buffer);
  
  eocdView.setUint32(0, 0x06054b50, true);
  eocdView.setUint16(4, 0, true);
  eocdView.setUint16(6, 0, true);
  eocdView.setUint16(8, Object.keys(files).length, true);
  eocdView.setUint16(10, Object.keys(files).length, true);
  eocdView.setUint32(12, cdSize, true);
  eocdView.setUint32(16, offset, true);
  eocdView.setUint16(20, 0, true);
  
  const totalSize = offset + cdSize + 22;
  const result = new Uint8Array(totalSize);
  let pos = 0;
  
  for (const part of entries) {
    result.set(part, pos);
    pos += part.length;
  }
  for (const part of centralDirectory) {
    result.set(part, pos);
    pos += part.length;
  }
  result.set(eocd, pos);
  
  return result;
}

function crc32(data) {
  let crc = 0xFFFFFFFF;
  const table = new Uint32Array(256);
  
  for (let i = 0; i < 256; i++) {
    let c = i;
    for (let j = 0; j < 8; j++) {
      c = (c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
    }
    table[i] = c;
  }
  
  for (let i = 0; i < data.length; i++) {
    crc = table[(crc ^ data[i]) & 0xFF] ^ (crc >>> 8);
  }
  
  return (crc ^ 0xFFFFFFFF) >>> 0;
}

function downloadFile(content, filename, type) {
  let blob;
  if (content instanceof Uint8Array) {
    blob = new Blob([content], { type });
  } else {
    blob = new Blob([content], { type });
  }
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

function escapeAttr(text) {
  return text.replace(/"/g, '&quot;').replace(/'/g, '&#39;');
}

function escapeCsv(text) {
  return text.replace(/"/g, '""');
}

function escapeXml(text) {
  return text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function truncate(text, maxLength) {
  return text.length > maxLength ? text.substring(0, maxLength) + '...' : text;
}

function formatTime(timestamp) {
  const date = new Date(timestamp);
  const now = new Date();
  const diff = now - date;
  
  if (diff < 60000) return 'Just now';
  if (diff < 3600000) return `${Math.floor(diff / 60000)}m ago`;
  if (diff < 86400000) return `${Math.floor(diff / 3600000)}h ago`;
  return date.toLocaleDateString();
}

function formatDate() {
  return new Date().toISOString().slice(0, 10);
}

function getLangName(code) {
  return languages.find(l => l.code === code)?.name || code;
}
