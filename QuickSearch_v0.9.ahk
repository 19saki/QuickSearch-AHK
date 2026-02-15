#Requires AutoHotkey v2.0
#SingleInstance Force
SetTitleMatchMode "RegEx" 

; ==========================================
; 1. 全局配置与持久化加载
; ==========================================
Global g_CC_PressCount := 0
Global ConfigFile := A_ScriptDir . "\SearchToolConfig.ini"

; 尝试读取配置，若失败则使用默认值
DefaultDelay := "25"
DefaultFlash := "1"
try {
    DefaultDelay := IniRead(ConfigFile, "Settings", "Delay", "25")
    DefaultFlash := IniRead(ConfigFile, "Settings", "AutoFlash", "1")
}

A_IconTip := "时呓呓搜索助手`n------------------`n快捷键：Ctrl + Alt + S`n全搜索：双击 Ctrl + C`n任务结束后或按 Esc 可自动闪回"

TrayTip "时呓呓搜索助手已就绪", "双击 Ctrl+C 全搜索`nCtrl+Alt+S 菜单`n自动过滤长文本搜索", 1
SetTimer () => TrayTip(), -4000 

Global g_SearchManager := SearchController(DefaultDelay, DefaultFlash)

; ==========================================
; 2. 快捷键与双击逻辑
; ==========================================

^!s::g_SearchManager.Show()

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
    _flashCheck := unset
    _prevWin := 0 

    __New(initDelay, initFlash) {
        this.CreateGui(initDelay, initFlash)
    }

    CreateGui(initDelay, initFlash) {
        this._gui := Gui("+AlwaysOnTop -MaximizeBox +ToolWindow", "时呓呓搜索助手 v0.9")
        this._gui.SetFont("s9 cGray", "Microsoft YaHei")
        this._gui.Add("Text", "w260", "搜索内容 (可在此修改):")
        
        this._gui.SetFont("s10 cDefault Bold")
        this._edit := this._gui.Add("Edit", "w260 r2 -WantReturn vSearchText")
        
        this._gui.Add("Text", "w260 h2 0x10") 

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

        this._gui.SetFont("s8 cGray")
        this._delayTip := this._gui.Add("Text", "w260", "AI 站点加载等待: " . (initDelay/10) . " 秒")
        this._slider := this._gui.Add("Slider", "w260 Range10-80 ToolTipBottom", initDelay)
        this._slider.OnEvent("Change", (s, *) => this.UpdateDelay(s))

        this._gui.SetFont("s9 cDefault")
        this._flashCheck := this._gui.Add("Checkbox", "w260 h30 Checked" . initFlash, "任务结束后自动闪回原窗口")
        this._flashCheck.OnEvent("Click", (c, *) => IniWrite(c.Value, ConfigFile, "Settings", "AutoFlash"))

        this._gui.SetFont("s8 cSilver")
        this._gui.Add("Text", "w260 Center y+5", "Esc 隐藏菜单 | 搜索中按 Esc 立即停止")
        this._gui.OnEvent("Escape", (*) => this._gui.Hide())
    }

    UpdateDelay(s) {
        this._delayTip.Value := "AI 站点加载等待: " . Format("{:.1f}", s.Value/10) . " 秒"
        IniWrite(s.Value, ConfigFile, "Settings", "Delay")
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
            QuickTip("剪贴板为空")
            return
        }
        QuickTip("开始全搜索...")
        this.SearchAllFlow(text)
    }

    SearchAllFlow(text) {
        this.IsRunning := true
        this._stopFlag := false
        this._prevWin := WinExist("A")
        
        ; 默认引擎列表
        engines := ["Baidu", "DeepSeek", "GPT", "Gemini", "Bili"]
        
        ; --- Bilibili 与 Baidu 长度判断逻辑 ---
        if (StrLen(text) > 30) {
            ; 超过30字符通常是代码或段落，跳过非AI搜索引擎
            engines := ["DeepSeek", "GPT", "Gemini"]
            QuickTip("文本过长：已自动跳过百度与B站")
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
        
        if (this._flashCheck.Value) {
            this.FinalFlashBack()
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
            ; 单独点击B站按钮时也增加一个极长文本提示
            if (type = "Bili" && StrLen(val) > 500) {
                if MsgBox("内容过长（" StrLen(val) "字），B站可能无法处理。是否继续？", "提示", "YN") = "No"
                    return
            }
            this._prevWin := WinExist("A")
            this.RunEngine(type, val)
            if (this._flashCheck.Value) {
                SetTimer(() => this.FinalFlashBack(), -100)
            }
        }
    }

    Abort() {
        this._stopFlag := true
        if (this._flashCheck.Value) {
            this.FinalFlashBack()
        }
        this.IsRunning := false
    }

    FinalFlashBack() {
        if (this._prevWin && WinExist(this._prevWin)) {
            WinActivate(this._prevWin)
        }
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
    QuickTip("任务已停止")
}
#HotIf