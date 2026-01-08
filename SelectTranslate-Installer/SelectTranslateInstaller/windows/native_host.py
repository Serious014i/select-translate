#!/usr/bin/env python3

import sys
import json
import struct
import threading
import time
import platform

PLATFORM = platform.system()

def get_clipboard():
    if PLATFORM == 'Windows':
        return _get_clipboard_windows()
    elif PLATFORM == 'Darwin':
        return _get_clipboard_mac()
    else:
        return _get_clipboard_linux()

def _get_clipboard_windows():
    try:
        import subprocess
        result = subprocess.run(
            ['powershell', '-command', 'Get-Clipboard'],
            capture_output=True, text=True, timeout=2,
            creationflags=subprocess.CREATE_NO_WINDOW
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except:
        pass
    
    try:
        import ctypes
        CF_UNICODETEXT = 13
        
        for _ in range(3):
            if ctypes.windll.user32.OpenClipboard(0):
                try:
                    handle = ctypes.windll.user32.GetClipboardData(CF_UNICODETEXT)
                    if handle:
                        ctypes.windll.kernel32.GlobalLock.restype = ctypes.c_wchar_p
                        text = ctypes.windll.kernel32.GlobalLock(handle)
                        if text:
                            result = str(text)
                            ctypes.windll.kernel32.GlobalUnlock(handle)
                            return result
                finally:
                    ctypes.windll.user32.CloseClipboard()
            time.sleep(0.02)
    except:
        pass
    
    return ""

def _get_clipboard_mac():
    try:
        import subprocess
        result = subprocess.run(['pbpaste'], capture_output=True, text=True, timeout=2)
        return result.stdout
    except:
        return ""

def _get_clipboard_linux():
    import subprocess
    try:
        result = subprocess.run(['xclip', '-selection', 'clipboard', '-o'], 
                               capture_output=True, text=True, timeout=1)
        return result.stdout
    except:
        try:
            result = subprocess.run(['xsel', '--clipboard', '--output'], 
                                   capture_output=True, text=True, timeout=1)
            return result.stdout
        except:
            return ""

def set_clipboard(text):
    if not text:
        return
    if PLATFORM == 'Windows':
        _set_clipboard_windows(text)
    elif PLATFORM == 'Darwin':
        _set_clipboard_mac(text)
    else:
        _set_clipboard_linux(text)

def _set_clipboard_windows(text):
    try:
        import subprocess
        escaped = text.replace("'", "''")
        subprocess.run(
            ['powershell', '-command', f"Set-Clipboard -Value '{escaped}'"],
            capture_output=True, timeout=2,
            creationflags=subprocess.CREATE_NO_WINDOW
        )
        return
    except:
        pass
    
    try:
        import ctypes
        CF_UNICODETEXT = 13
        GMEM_MOVEABLE = 0x0002
        
        for _ in range(3):
            if ctypes.windll.user32.OpenClipboard(0):
                try:
                    ctypes.windll.user32.EmptyClipboard()
                    data = (text + '\0').encode('utf-16-le')
                    hGlobal = ctypes.windll.kernel32.GlobalAlloc(GMEM_MOVEABLE, len(data))
                    if hGlobal:
                        ctypes.windll.kernel32.GlobalLock.restype = ctypes.c_void_p
                        ptr = ctypes.windll.kernel32.GlobalLock(hGlobal)
                        if ptr:
                            ctypes.memmove(ptr, data, len(data))
                            ctypes.windll.kernel32.GlobalUnlock(hGlobal)
                            ctypes.windll.user32.SetClipboardData(CF_UNICODETEXT, hGlobal)
                finally:
                    ctypes.windll.user32.CloseClipboard()
                return
            time.sleep(0.02)
    except:
        pass

def _set_clipboard_mac(text):
    try:
        import subprocess
        subprocess.run(['pbcopy'], input=text.encode('utf-8'), check=True, timeout=2)
    except:
        pass

def _set_clipboard_linux(text):
    import subprocess
    try:
        subprocess.run(['xclip', '-selection', 'clipboard'], 
                      input=text.encode('utf-8'), check=True, timeout=1)
    except:
        try:
            subprocess.run(['xsel', '--clipboard', '--input'], 
                          input=text.encode('utf-8'), check=True, timeout=1)
        except:
            pass

def clear_clipboard():
    set_clipboard("")

def simulate_copy():
    try:
        if PLATFORM == 'Windows':
            import ctypes
            
            VK_CONTROL = 0x11
            VK_C = 0x43
            KEYEVENTF_KEYUP = 0x0002
            
            ctypes.windll.user32.keybd_event(VK_CONTROL, 0, 0, 0)
            ctypes.windll.user32.keybd_event(VK_C, 0, 0, 0)
            time.sleep(0.05)
            ctypes.windll.user32.keybd_event(VK_C, 0, KEYEVENTF_KEYUP, 0)
            ctypes.windll.user32.keybd_event(VK_CONTROL, 0, KEYEVENTF_KEYUP, 0)
            
        elif PLATFORM == 'Darwin':
            import subprocess
            subprocess.run(['osascript', '-e', 
                          'tell application "System Events" to keystroke "c" using command down'],
                          capture_output=True, timeout=1)
            
        else:
            import subprocess
            try:
                subprocess.run(['xdotool', 'key', 'ctrl+c'], capture_output=True, timeout=1)
            except:
                subprocess.run(['ydotool', 'key', '29:1', '46:1', '46:0', '29:0'], 
                              capture_output=True, timeout=1)
    except Exception as e:
        log(f"Simulate copy error: {e}")
    
    time.sleep(0.15)

class MouseMonitor:
    def __init__(self, on_selection_callback):
        self.callback = on_selection_callback
        self.running = True
        self.last_selection = ""
        self.last_time = 0
        
    def start(self):
        if PLATFORM == 'Windows':
            self._start_windows()
        else:
            self._start_pynput()
    
    def _start_windows(self):
        import ctypes
        from ctypes import wintypes, CFUNCTYPE, POINTER
        
        WH_MOUSE_LL = 14
        WM_LBUTTONUP = 0x0202
        
        HOOKPROC = CFUNCTYPE(ctypes.c_long, ctypes.c_int, wintypes.WPARAM, wintypes.LPARAM)
        
        def mouse_callback(nCode, wParam, lParam):
            if nCode >= 0 and wParam == WM_LBUTTONUP:
                threading.Thread(target=self._check_selection, daemon=True).start()
            return ctypes.windll.user32.CallNextHookEx(None, nCode, wParam, lParam)
        
        self._hook_callback = HOOKPROC(mouse_callback)
        
        hModule = ctypes.windll.kernel32.GetModuleHandleW(None)
        
        hook = ctypes.windll.user32.SetWindowsHookExW(
            WH_MOUSE_LL, 
            self._hook_callback,
            hModule,
            0
        )
        
        if not hook:
            error_code = ctypes.windll.kernel32.GetLastError()
            log(f"✗ Failed to install mouse hook (Error: {error_code})")
            log("")
            log("Possible causes:")
            log("  1. Not running as Administrator")
            log("  2. Antivirus blocking the hook")
            log("  3. Another program using the hook")
            log("")
            log("Falling back to pynput method...")
            log("")
            self._start_pynput()
            return
        
        log("✓ Mouse hook installed (Windows native)")
        log("")
        
        msg = wintypes.MSG()
        while self.running:
            result = ctypes.windll.user32.GetMessageW(ctypes.byref(msg), None, 0, 0)
            if result == 0 or result == -1:
                break
            ctypes.windll.user32.TranslateMessage(ctypes.byref(msg))
            ctypes.windll.user32.DispatchMessageW(ctypes.byref(msg))
        
        ctypes.windll.user32.UnhookWindowsHookEx(hook)
    
    def _start_pynput(self):
        try:
            from pynput import mouse
            
            self._mouse_pressed_pos = None
            self._mouse_pressed_time = None
            self._last_click_time = 0
            self._click_count = 0
            
            def on_click(x, y, button, pressed):
                if button != mouse.Button.left:
                    return self.running
                
                current_time = time.time()
                
                if pressed:
                    self._mouse_pressed_pos = (x, y)
                    self._mouse_pressed_time = current_time
                    
                    if current_time - self._last_click_time < 0.5:
                        self._click_count += 1
                    else:
                        self._click_count = 1
                    self._last_click_time = current_time
                    
                else:
                    should_check = False
                    
                    if self._mouse_pressed_pos and self._mouse_pressed_time:
                        dx = abs(x - self._mouse_pressed_pos[0])
                        dy = abs(y - self._mouse_pressed_pos[1])
                        duration = current_time - self._mouse_pressed_time
                        
                        is_drag = (dx > 20 or dy > 20) and duration > 0.15 and duration < 10
                        
                        is_double_click = self._click_count >= 2 and dx < 10 and dy < 10
                        
                        is_triple_click = self._click_count >= 3 and dx < 10 and dy < 10
                        
                        should_check = is_drag or is_double_click or is_triple_click
                    
                    if should_check:
                        delay = 0.1 if self._click_count >= 2 else 0
                        threading.Timer(delay, self._check_selection).start()
                    
                    self._mouse_pressed_pos = None
                    self._mouse_pressed_time = None
                
                return self.running
            
            log("✓ Mouse listener started")
            
            listener = mouse.Listener(on_click=on_click)
            listener.start()
            
            while self.running:
                time.sleep(0.1)
                if not listener.is_alive():
                    listener = mouse.Listener(on_click=on_click)
                    listener.start()
                
        except ImportError as e:
            log(f"⚠ pynput not installed: {e}")
            self._start_polling()
        except Exception as e:
            log(f"⚠ pynput error: {e}")
            self._start_polling()
    
    def _start_polling(self):
        log("✓ Clipboard polling started")
        last_clipboard = get_clipboard()
        
        while self.running:
            time.sleep(0.5)
            current = get_clipboard()
            if current and current != last_clipboard and len(current) >= 2:
                last_clipboard = current
                self._on_new_selection(current)
    
    def _check_selection(self):
        time.sleep(0.25)
        
        if self._is_chrome_focused():
            return
        
        original = get_clipboard()
        clear_clipboard()
        time.sleep(0.05)
        
        simulate_copy()
        time.sleep(0.15)
        
        selected = get_clipboard()
        
        if original and original != selected:
            threading.Thread(target=lambda: (time.sleep(0.5), set_clipboard(original)), daemon=True).start()
        
        if selected and len(selected) >= 2 and len(selected) < 5000:
            self._on_new_selection(selected)
    
    def _on_new_selection(self, text):
        now = time.time()
        if text == self.last_selection and (now - self.last_time) < 3:
            return
        
        self.last_selection = text
        self.last_time = now
        
        preview = text[:50] + "..." if len(text) > 50 else text
        preview = preview.replace('\n', ' ')
        log(f"[Selection] {preview}")
        
        self.callback(text)
    
    def _is_chrome_focused(self):
        try:
            if PLATFORM == 'Windows':
                import ctypes
                from ctypes import create_unicode_buffer
                
                hwnd = ctypes.windll.user32.GetForegroundWindow()
                
                length = ctypes.windll.user32.GetWindowTextLengthW(hwnd) + 1
                buffer = create_unicode_buffer(length)
                ctypes.windll.user32.GetWindowTextW(hwnd, buffer, length)
                title = buffer.value
                
                pid = ctypes.c_ulong()
                ctypes.windll.user32.GetWindowThreadProcessId(hwnd, ctypes.byref(pid))
                
                process_name = ""
                try:
                    PROCESS_QUERY_LIMITED_INFORMATION = 0x1000
                    handle = ctypes.windll.kernel32.OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, False, pid.value)
                    if handle:
                        exe_path = create_unicode_buffer(260)
                        size = ctypes.c_ulong(260)
                        ctypes.windll.kernel32.QueryFullProcessImageNameW(handle, 0, exe_path, ctypes.byref(size))
                        ctypes.windll.kernel32.CloseHandle(handle)
                        process_name = exe_path.value
                except:
                    pass
                
                process_lower = process_name.lower()
                
                skip_apps = [
                    'explorer.exe',
                    'taskmgr.exe',
                    'mmc.exe',
                    'devenv.exe',
                    'code.exe',
                    'cmd.exe',
                    'powershell.exe',
                    'windowsterminal.exe',
                    'slack.exe',
                    'teams.exe',
                    'discord.exe',
                    'outlook.exe',
                ]
                
                for app in skip_apps:
                    if app in process_lower:
                        return True
                
                is_browser = 'chrome.exe' in process_lower or 'msedge.exe' in process_lower
                
                title_lower = title.lower()
                is_pdf = '.pdf' in title_lower
                
                if is_browser and is_pdf:
                    return False
                
                return is_browser
                
            elif PLATFORM == 'Darwin':
                import subprocess
                result = subprocess.run(
                    ['osascript', '-e', 'tell application "System Events" to get name of first process whose frontmost is true'],
                    capture_output=True, text=True, timeout=1
                )
                app = result.stdout.strip().lower()
                return 'chrome' in app or 'edge' in app
                
            else:
                import subprocess
                result = subprocess.run(['xdotool', 'getactivewindow', 'getwindowname'],
                                       capture_output=True, text=True, timeout=1)
                title = result.stdout.strip().lower()
                return 'chrome' in title or 'chromium' in title or 'edge' in title
        except:
            return False
    
    def stop(self):
        self.running = False

def send_native_message(message):
    try:
        encoded = json.dumps(message).encode('utf-8')
        sys.stdout.buffer.write(struct.pack('I', len(encoded)))
        sys.stdout.buffer.write(encoded)
        sys.stdout.buffer.flush()
    except Exception as e:
        log(f"Send error: {e}")

def read_native_message():
    try:
        length_bytes = sys.stdin.buffer.read(4)
        if not length_bytes:
            return None
        length = struct.unpack('I', length_bytes)[0]
        message = sys.stdin.buffer.read(length).decode('utf-8')
        return json.loads(message)
    except:
        return None

def listen_for_messages():
    global is_paused, should_exit
    
    while True:
        message = read_native_message()
        if message is None:
            log("[Chrome disconnected - exiting]")
            should_exit = True
            import os
            os._exit(0)
        
        action = message.get('action', '')
        
        if action == 'ping':
            send_native_message({'success': True, 'status': 'running', 'platform': PLATFORM})
        elif action == 'pause':
            is_paused = True
            log("[Command] Paused")
            send_native_message({'success': True, 'paused': True})
        elif action == 'resume':
            is_paused = False
            log("[Command] Resumed")
            send_native_message({'success': True, 'paused': False})

def log(message):
    print(message, file=sys.stderr, flush=True)

is_paused = False
is_native_host = False
should_exit = False

def on_selection(text):
    if is_paused:
        return
    
    if is_native_host:
        send_native_message({'action': 'translate', 'text': text})
    else:
        log(f"[Would translate] {text[:50]}...")

def main():
    global is_native_host
    
    if '--test' in sys.argv:
        log("Test mode: Python and imports OK")
        sys.exit(0)
    
    is_native_host = len(sys.argv) > 1 and sys.argv[1].startswith('chrome-extension://')
    
    log("=" * 50)
    log("SelectTranslate Native Host")
    log(f"Platform: {PLATFORM}")
    log(f"Python: {sys.version.split()[0]}")
    log(f"Mode: {'Native Messaging' if is_native_host else 'Standalone (Test)'}")
    log("=" * 50)
    log("")
    
    try:
        if PLATFORM == 'Windows':
            import ctypes
            log("ctypes: OK")
        else:
            from pynput import mouse
            log("pynput: OK")
    except ImportError as e:
        log(f"Import error: {e}")
        log("Please install: pip install pynput")
        sys.exit(1)
    
    if is_native_host:
        msg_thread = threading.Thread(target=listen_for_messages, daemon=True)
        msg_thread.start()
        log("Native messaging listener started")
    
    log("")
    log("Listening for text selections...")
    log("Select text in any app to test.")
    log("")
    
    monitor = MouseMonitor(on_selection)
    
    try:
        monitor.start()
    except KeyboardInterrupt:
        log("\nShutting down...")
        monitor.stop()
    except Exception as e:
        log(f"Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == '__main__':
    main()
