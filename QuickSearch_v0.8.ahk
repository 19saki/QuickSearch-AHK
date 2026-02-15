#Requires AutoHotkey v2.0
#SingleInstance Force
SetTitleMatchMode "RegEx" 

; ==========================================
; 1. 全局配置与启动提示
; ==========================================
Global g_CC_PressCount := 0

; 托盘悬停提示 (加入 Esc 中止说明)
A_IconTip := "时呓呓搜索助手`n------------------`n快捷键：Ctrl + Alt + S`n全搜索：双击 Ctrl + C`n任务进行中按 Esc 可立即停止"

; 启动气泡
TrayTip "时呓呓搜索助手已就绪", "双击 Ctrl+C 触发全引擎搜索`nCtrl+Alt+S 呼出手动菜单`n搜索过程中按 Esc 可强行中止任务", 1
SetTimer () => TrayTip(), -4000 

; 初始化控制器
Global g_SearchManager := SearchController()

; ==========================================
; 2. 快捷键触发逻辑
; ==========================================

^!s::g_SearchManager.Show()

; 双击 Ctrl+C 触发
~^c:: {
    Global g_CC_PressCount
    g_CC_PressCount += 1
    
    if (g_CC_PressCount = 1) {
        SetTimer(ResetCCCount, -400) 
    } else if (g_CC_PressCount = 2) {
        SetTimer(ResetCCCount, 0)
        g_CC_PressCount := 0
        Sleep(150)
        g_SearchManager.HandleSilentSearchAll()
    }
}

ResetCCCount() {
    Global g_CC_PressCount := 0
}

; ==========================================
; 3. 核心控制器类
; ==========================================
class SearchController {
    IsRunning := false
    _stopFlag := false
    _gui := unset
    _edit := unset
    _slider := unset
    _delayTip := unset

    __New() {
        this.CreateGui()
    }

    CreateGui() {
        this._gui := Gui("+AlwaysOnTop -MaximizeBox +ToolWindow", "时呓呓搜索助手 v1.1")
        this._gui.SetFont("s9 cGray", "Microsoft YaHei")
        this._gui.Add("Text", "w260", "搜索内容 (可在此修改):")
        
        this._gui.SetFont("s10 cDefault Bold")
        this._edit := this._gui.Add("Edit", "w260 r2 -WantReturn vSearchText")
        
        this._gui.Add("Text", "w260 h2 0x10") 

        ; --- 按钮区 ---
        btnW := 260, btnH := 38, p := "  "
        this._gui.SetFont("s11 w700")
        this._gui.Add("Button", "w" btnW " h" btnH " Default Left", p "(&1) 全部发动").OnEvent("Click", (*) => this.ExecAll())
        
        this._gui.SetFont("s10 w400")
        this.AddEngineBtn("(&2) 百度一下", "Baidu")
        this.AddEngineBtn("(&3) DeepSeek", "DeepSeek")
        this.AddEngineBtn("(&4) ChatGPT", "GPT")
        this.AddEngineBtn("(&5) Gemini", "Gemini")
        this.AddEngineBtn("(&6) Bilibili", "Bili")

        this._gui.Add("Text", "w260 h2 0x10") 

        ; --- 延迟调节滑块 ---
        this._gui.SetFont("s8 cGray")
        this._delayTip := this._gui.Add("Text", "w260", "AI 站点加载等待: 2.5 秒")
        this._slider := this._gui.Add("Slider", "w260 Range10-80 ToolTipBottom", 25)
        this._slider.OnEvent("Change", (s, *) => (this._delayTip.Value := "AI 站点加载等待: " . Format("{:.1f}", s.Value/10) . " 秒"))

        this._gui.SetFont("s8 cSilver")
        this._gui.Add("Text", "w260 Center y+10", "Esc 隐藏菜单 | 搜索时按 Esc 强行中止")
        this._gui.OnEvent("Escape", (*) => this._gui.Hide())
    }

    AddEngineBtn(label, type) {
        this._gui.Add("Button", "w260 h38 Left", "  " label).OnEvent("Click", (*) => this.ExecSingle(type))
    }

    Show() {
        this._edit.Value := GetSelectedOrClipboard()
        this._gui.Show("Center")
    }

    HandleSilentSearchAll() {
        text := Trim(A_Clipboard)
        if (text == "") {
            QuickTip("Clipboard is empty")
            return
        }
        QuickTip("Starting search...")
        this.SearchAllFlow(text)
    }

    ; --- 核心搜索流 ---
    SearchAllFlow(text) {
        this.IsRunning := true
        this._stopFlag := false
        
        engines := ["Baidu", "DeepSeek", "GPT", "Gemini"]
        
        ; 文本长度校验：大于 30 字符跳过百度
        if (StrLen(text) > 30) {
            engines := ["DeepSeek", "GPT", "Gemini"]
            QuickTip("Long text: skipping Baidu")
        }

        for engine in engines {
            if (this._stopFlag) {
                break
            }
            this.RunEngine(engine, text)
            if (!this.InterruptibleSleep(600)) {
                break
            }
        }
        this.IsRunning := false
    }

    ExecAll() {
        val := this._edit.Value
        this._gui.Hide()
        if (val != "") {
            this.SearchAllFlow(val)
        }
    }

    ExecSingle(type) {
        val := this._edit.Value
        this._gui.Hide()
        if (val != "") {
            this.RunEngine(type, val)
        }
    }

    Abort() {
        this._stopFlag := true
        this.IsRunning := false
    }

    InterruptibleSleep(ms) {
        start := A_TickCount
        while (A_TickCount - start < ms) {
            if (this._stopFlag) {
                return false
            }
            Sleep 10
        }
        return true
    }

    RunEngine(name, text) {
        static urls := Map(
            "Baidu", "https://www.baidu.com/s?wd=",
            "Bili",  "https://search.bilibili.com/all?keyword=",
            "DeepSeek", "https://chat.deepseek.com/",
            "GPT", "https://chat.openai.com/",
            "Gemini", "https://gemini.google.com/"
        )
        
        if (name = "Baidu" || name = "Bili") {
            Run(urls[name] . UrlEncodeUTF8(text))
        } else {
            Run(urls[name])
            if WinWaitActive("ahk_exe i)(msedge.exe|chrome.exe|firefox.exe|browser.exe)", , 8) {
                currentDelay := this._slider.Value * 100
                if (!this.InterruptibleSleep(currentDelay)) {
                    return
                }
                if (!this._stopFlag) {
                    this.SendAndWait(text)
                }
            }
        }
    }

    SendAndWait(text) {
        saved := A_Clipboard
        A_Clipboard := text
        if ClipWait(2) {
            Send "^a"
            Sleep 150
            Send "^v"
            Sleep 300
            Send "{Enter}"
        }
        SetTimer(() => (A_Clipboard := saved), -1000)
    }
}

; ==========================================
; 4. 工具函数
; ==========================================

GetSelectedOrClipboard() {
    saved := A_Clipboard
    A_Clipboard := ""
    Send "^c"
    if !ClipWait(0.2) {
        return Trim(saved)
    }
    text := Trim(A_Clipboard)
    A_Clipboard := saved 
    return text
}

QuickTip(msg) {
    ToolTip(msg)
    SetTimer(() => ToolTip(), -2000)
}

UrlEncodeUTF8(str) {
    size := StrPut(str, "UTF-8")
    buf := Buffer(size)
    StrPut(str, buf, "UTF-8")
    out := ""
    Loop size - 1 {
        byte := NumGet(buf, A_Index - 1, "UChar")
        if (byte >= 0x30 && byte <= 0x39) || (byte >= 0x41 && byte <= 0x5A) || (byte >= 0x61 && byte <= 0x7A) || InStr("-._~", Chr(byte)) {
            out .= Chr(byte)
        } else {
            out .= "%" . Format("{:02X}", byte)
        }
    }
    return out
}

#HotIf g_SearchManager.IsRunning
Esc:: {
    g_SearchManager.Abort()
    QuickTip("Task stopped")
}
#HotIf