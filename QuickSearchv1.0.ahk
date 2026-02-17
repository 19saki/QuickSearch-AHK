#Requires AutoHotkey v2.0
#SingleInstance Force
SetTitleMatchMode "RegEx"

; ==========================================
; 1. 全局状态
; ==========================================
Global g_CC_PressCount := 0

A_IconTip := "时呓呓搜索助手`n------------------`n快捷键：Ctrl + Alt + S`n全搜索：双击 Ctrl + C"

TrayTip "时呓呓搜索助手已就绪", "双击 Ctrl+C 全搜索`nCtrl+Alt+S 菜单`n自动过滤长文本搜索", 1
SetTimer () => TrayTip(), -4000

; 引擎默认勾选状态（内存中，不持久化）
Global DefaultChecks := Map(
    "Baidu",    1,
    "DeepSeek", 1,
    "Claude",   1,
    "GPT",      1,
    "Gemini",   1,
    "Bili",     1
)

Global g_SearchManager := SearchController(DefaultChecks)

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
    _gui      := unset
    _edit     := unset
    _slider   := unset
    _delayTip := unset
    _checks   := Map()

    __New(initChecks) {
        this.CreateGui(initChecks)
    }

    ; -----------------------------------------------
    ; GUI 构建
    ; -----------------------------------------------
    CreateGui(initChecks) {
        g := Gui("+AlwaysOnTop -MaximizeBox +ToolWindow", "时呓呓搜索助手 v1.0")
        g.SetFont("s9 cGray", "Microsoft YaHei")
        g.Add("Text", "w300", "搜索内容 (可在此修改):")

        ; 搜索框：r6 约为原来 r2 的三倍高
        g.SetFont("s10 cDefault Bold")
        this._edit := g.Add("Edit", "w300 r6 -WantReturn vSearchText")

        g.Add("Text", "w300 h2 0x10")

        ; ---- 引擎勾选区 ----
        g.SetFont("s9 w400 cGray")
        g.Add("Text", "w300", "勾选要执行的引擎：")

        engines := [
            ["Baidu",    "百度搜索"],
            ["DeepSeek", "DeepSeek"],
            ["Claude",   "Claude "],
            ["GPT",      "ChatGPT"],
            ["Gemini",   "Gemini"],
            ["Bili",     "哔哩哔哩"],
        ]

        g.SetFont("s10 w400 cDefault")
        for item in engines {
            key   := item[1]
            label := item[2]
            chk := g.Add("Checkbox", "w300 h26 Checked" . initChecks[key], label)
            this._checks[key] := chk
        }

        g.Add("Text", "w300 h2 0x10")

        ; ---- 执行按钮 ----
        g.SetFont("s11 w700 cDefault")
        g.Add("Button", "w300 h40 Default Left", "  执行勾选的引擎!!!").OnEvent("Click", (*) => this.ExecChecked())

        g.Add("Text", "w300 h2 0x10")

        ; ---- 延迟滑块（默认 40 = 4.0 秒，不持久化）----
        g.SetFont("s8 cGray")
        this._delayTip := g.Add("Text", "w300", "AI 站点加载等待: 4.0 秒")
        this._slider := g.Add("Slider", "w300 Range10-80 ToolTipBottom", 40)
        this._slider.OnEvent("Change", (s, *) => this.UpdateDelay(s))

        g.SetFont("s8 cSilver")
        g.Add("Text", "w300 Center y+8", "Esc 隐藏菜单 | 搜索中按 Esc 立即停止")
        g.OnEvent("Escape", (*) => g.Hide())

        this._gui := g
    }

    UpdateDelay(s) {
        this._delayTip.Value := "AI 站点加载等待: " . Format("{:.1f}", s.Value / 10) . " 秒"
    }

    ; -----------------------------------------------
    ; 获取当前勾选的引擎列表（固定顺序）
    ; -----------------------------------------------
    GetCheckedEngines() {
        order := ["Baidu", "DeepSeek", "Claude", "GPT", "Gemini", "Bili"]
        result := []
        for key in order {
            if (this._checks[key].Value) {
                result.Push(key)
            }
        }
        return result
    }

    ; -----------------------------------------------
    ; 显示 GUI
    ; -----------------------------------------------
    Show() {
        this._edit.Value := GetSelectedOrClipboard()
        this._gui.Show("Center")
    }

    ; -----------------------------------------------
    ; 双击 Ctrl+C 静默全搜索（仅执行勾选项）
    ; -----------------------------------------------
    HandleSilentSearchAll() {
        text := Trim(A_Clipboard)
        if (text == "") {
            QuickTip("剪贴板为空")
            return
        }
        engines := this.GetCheckedEngines()
        if (engines.Length = 0) {
            QuickTip("没有勾选任何引擎，请先打开菜单勾选")
            return
        }
        QuickTip("开始搜索（共 " . engines.Length . " 个引擎）...")
        this.SearchFlow(text, engines)
    }

    ; -----------------------------------------------
    ; 执行勾选项（按钮触发）
    ; -----------------------------------------------
    ExecChecked() {
        val := Trim(this._edit.Value)
        this._gui.Hide()
        if (val = "") {
            return
        }
        engines := this.GetCheckedEngines()
        if (engines.Length = 0) {
            QuickTip("没有勾选任何引擎")
            return
        }
        this.SearchFlow(val, engines)
    }

    ; -----------------------------------------------
    ; 核心搜索流程
    ; -----------------------------------------------
    SearchFlow(text, engines) {
        this.IsRunning := true
        this._stopFlag := false

        ; 文本过长时自动过滤非AI引擎
        filteredEngines := []
        skipped := []
        for engine in engines {
            if (StrLen(text) > 30 && (engine = "Baidu" || engine = "Bili")) {
                skipped.Push(engine)
            } else {
                filteredEngines.Push(engine)
            }
        }
        if (skipped.Length > 0) {
            skipNames := ""
            for s in skipped {
                skipNames .= s . " "
            }
            QuickTip("文本过长：已自动跳过 " . Trim(skipNames))
        }

        for engine in filteredEngines {
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

    ; -----------------------------------------------
    ; 中止任务
    ; -----------------------------------------------
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

    ; -----------------------------------------------
    ; 打开引擎并投递搜索内容
    ; -----------------------------------------------
    RunEngine(name, text) {
        static urls := Map(
            "Baidu",    "https://www.baidu.com/s?wd=",
            "Bili",     "https://search.bilibili.com/all?keyword=",
            "DeepSeek", "https://chat.deepseek.com/",
            "Claude",   "https://claude.ai/new",
            "GPT",      "https://chat.openai.com/",
            "Gemini",   "https://gemini.google.com/"
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
