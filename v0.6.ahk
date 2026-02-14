#Requires AutoHotkey v2.0
#SingleInstance Force

; ==========================================
; 全局变量与配置
; ==========================================
Global g_CC_PressCount := 0

A_IconTip := "时呓呓搜搜`n------------------`n选中文本后:`n呼出菜单：Ctrl + Alt + S`n全搜索：双击 Ctrl + C"


TrayTip "时呓呓搜搜已就绪", " 双击 Ctrl+C 触发全引擎搜索`n Ctrl+Alt+S 呼出手动菜单", 1

SetTimer () => TrayTip(), -4000

^!s::ShowSearchMenu()

~^c:: {
    Global g_CC_PressCount
    g_CC_PressCount += 1
    
    if (g_CC_PressCount = 1) {
        SetTimer(ResetCCCount, -400) ; 400ms 内等待第二次按键
    } else if (g_CC_PressCount = 2) {
        SetTimer(ResetCCCount, 0)    ; 取消重置计时器
        g_CC_PressCount := 0
        Sleep(150)                   ; 给系统一点时间完成第二次复制动作
        HandleSilentSearchAll()
    }
}

ResetCCCount() {
    Global g_CC_PressCount := 0
}

; 静默全搜索处理
HandleSilentSearchAll() {
    text := Trim(A_Clipboard)
    if (text == "") {
        QuickTip("❌ 剪贴板为空")
        return
    }
    QuickTip("🚀 启动全引擎搜索...")
    SearchAll(text)
}

; 轻量化提示窗
QuickTip(msg) {
    ToolTip(msg)
    SetTimer(() => ToolTip(), -2000)
}

; ------------------------------------------
; 3. UI 菜单逻辑 (优化了快捷键索引)
; ------------------------------------------
; ------------------------------------------
; 3. 优化后的 UI 菜单 (精致版)
; ------------------------------------------
ShowSearchMenu() {
    textToSearch := GetSelectedOrClipboard()
    
    if (textToSearch = "") {
        QuickTip("🔍 未发现可搜索的文本")
        return
    }

    ; 限制显示长度，避免 UI 过宽
    displayStr := StrLen(textToSearch) > 20 ? SubStr(textToSearch, 1, 20) . "..." : textToSearch

    static MyGui := unset
    if IsSet(MyGui) && MyGui
        MyGui.Destroy()

    ; 创建 GUI：+LastFound 提高响应，-MaximizeBox 禁用最大化
    MyGui := Gui("+AlwaysOnTop -MaximizeBox +ToolWindow", "时呓呓搜索助手")
    MyGui.SetFont("s11", "Microsoft YaHei") ; 稍微加大字体

    ; --- 头部：显示当前搜索内容 ---
    MyGui.SetFont("s9 cGray")
    MyGui.Add("Text", "w240 Center", "当前搜索内容:")
    MyGui.SetFont("s10 cDefault Bold")
    MyGui.Add("Text", "w240 Center xp y+5", '"' . displayStr . '"')
    
    ; 分割线
    MyGui.Add("Text", "w240 h2 0x10") ; SS_ETCHEDHORZ 效果

    ; --- 按钮区：增加高度和图标 ---
    MyGui.SetFont("s10 w400", "Microsoft YaHei")
    
    ; 定义通用按钮宽度和高度
    btnW := 240
    btnH := 36

    MyGui.Add("Button", "w" btnW " h" btnH " Default", " (&1) 全部发动").OnEvent("Click", (*) => (MyGui.Destroy(), SearchAll(textToSearch)))
    
    MyGui.SetFont("s10 w400") ; 恢复正常字重
    MyGui.Add("Button", "w" btnW " h" btnH, " (&2) 百度一下").OnEvent("Click", (*) => (MyGui.Destroy(), SearchBaidu(textToSearch)))
    MyGui.Add("Button", "w" btnW " h" btnH, " (&3) DeepSeek").OnEvent("Click", (*) => (MyGui.Destroy(), SearchDeepSeek(textToSearch)))
    MyGui.Add("Button", "w" btnW " h" btnH, " (&4) ChatGPT").OnEvent("Click", (*) => (MyGui.Destroy(), SearchGPT(textToSearch)))
    MyGui.Add("Button", "w" btnW " h" btnH, " (&5) Gemini").OnEvent("Click", (*) => (MyGui.Destroy(), SearchGemini(textToSearch)))
    MyGui.Add("Button", "w" btnW " h" btnH, " (&6) Bilibili").OnEvent("Click", (*) => (MyGui.Destroy(), SearchBili(textToSearch)))

; --- 底部：版权或小贴士 ---
    MyGui.SetFont("s8 cSilver") 
    MyGui.Add("Text", "w240 Center y+10", "Esc 退出 · 1-6 快捷键")
    MyGui.Show("Center")
}
; ------------------------------------------
; 4. 核心搜索函数库
; ------------------------------------------

GetSelectedOrClipboard() {
    saved := A_Clipboard
    A_Clipboard := ""
    Send "^c"
    if !ClipWait(0.3)
        return Trim(saved) ; 如果没选中，就用剪贴板原有的
    text := Trim(A_Clipboard)
    A_Clipboard := saved ; 还原剪贴板
    return text
}

SearchAll(text) {
    SearchBaidu(text)
    Sleep 500
    SearchDeepSeek(text)
    Sleep 500
    SearchGPT(text)
    Sleep 500
    SearchGemini(text)
}

SearchBaidu(text) => Run("https://www.baidu.com/s?wd=" . UrlEncodeUTF8(text))
SearchBili(text) => Run("https://search.bilibili.com/all?keyword=" . UrlEncodeUTF8(text))

; AI 逻辑
SearchDeepSeek(text) {
    Run "https://chat.deepseek.com/"
    if WinWaitActive("ahk_exe chrome.exe", , 3) || WinWaitActive("ahk_exe msedge.exe", , 3) {
        Sleep 3500 ; 略微缩短等待
        SendAndWait(text)
    }
}

SearchGPT(text) {
    Run "https://chat.openai.com/"
    Sleep 5000
    SendAndWait(text)
}

SearchGemini(text) {
    Run "https://gemini.google.com/"
    Sleep 5000
    SendAndWait(text)
}

SendAndWait(text) {
    saved := A_Clipboard
    A_Clipboard := text
    if ClipWait(1) {
        Send "^v"
        Sleep 100
        Send "{Enter}"
    }
    Sleep 500
    A_Clipboard := saved
}

UrlEncodeUTF8(str) {
    size := StrPut(str, "UTF-8")
    buf := Buffer(size)
    StrPut(str, buf, "UTF-8")
    out := ""
    Loop size - 1 {
        byte := NumGet(buf, A_Index - 1, "UChar")
        if (byte >= 0x30 && byte <= 0x39) || (byte >= 0x41 && byte <= 0x5A) || (byte >= 0x61 && byte <= 0x7A) || InStr("-._~", Chr(byte))
            out .= Chr(byte)
        else
            out .= "%" . Format("{:02X}", byte)
    }
    return out
} 