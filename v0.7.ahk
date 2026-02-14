#Requires AutoHotkey v2.0
#SingleInstance Force

; ==========================================
; 1. 全局配置与启动提示
; ==========================================
Global g_CC_PressCount := 0

; 托盘悬停提示
A_IconTip := "时呓呓搜索助手`n------------------`n快捷键：Ctrl + Alt + S`n全搜索：双击 Ctrl + C"

; 启动气泡
TrayTip "搜索助手已就绪", "🚀 双击 Ctrl+C 触发全引擎搜索`n⌨️ Ctrl+Alt+S 呼出手动菜单", 1
SetTimer () => TrayTip(), -4000 

; ==========================================
; 2. 快捷键触发逻辑
; ==========================================

; 呼出 UI 菜单
^!s::ShowSearchMenu()

; 双击 Ctrl+C 触发静默全搜索
~^c:: {
    Global g_CC_PressCount
    g_CC_PressCount += 1
    
    if (g_CC_PressCount = 1) {
        SetTimer(ResetCCCount, -400) 
    } else if (g_CC_PressCount = 2) {
        SetTimer(ResetCCCount, 0)
        g_CC_PressCount := 0
        Sleep(150)
        HandleSilentSearchAll()
    }
}

ResetCCCount() {
    global g_CC_PressCount := 0
}

HandleSilentSearchAll() {
    text := Trim(A_Clipboard)
    if (text == "") {
        QuickTip("❌ 剪贴板为空")
        return
    }
    QuickTip("🚀 启动全引擎搜索...")
    SearchAll(text)
}

QuickTip(msg) {
    ToolTip(msg)
    SetTimer(() => ToolTip(), -2000)
}

; ==========================================
; 3. 精致版 UI 菜单 (带编辑框)
; ==========================================

ShowSearchMenu() {
    ; 获取初始文本
    textToSearch := GetSelectedOrClipboard()
    
    static MyGui := unset
    if IsSet(MyGui) && MyGui
        MyGui.Destroy()

    ; 创建 GUI
    MyGui := Gui("+AlwaysOnTop -MaximizeBox +ToolWindow", "时呓呓搜索助手")
    
    ; --- 头部：编辑区 ---
    MyGui.SetFont("s9 cGray", "Microsoft YaHei")
    MyGui.Add("Text", "w260", "搜索内容 (可在此修改):")
    
    MyGui.SetFont("s10 cDefault Bold")
    EditBox := MyGui.Add("Edit", "w260 r2 -WantReturn vSearchText", textToSearch)
    
    ; 分割线
    MyGui.Add("Text", "w260 h2 0x10") 

    ; --- 按钮区 (左对齐 + 移除 Emoji) ---
    btnW := 260
    btnH := 38
    ; Left 为左对齐选项；按钮文字前加了两个空格以保证视觉美观
    padding := "  " 
    
    MyGui.SetFont("s11 w700") 
    MyGui.Add("Button", "w" btnW " h" btnH " Default Left", padding "(&1) 全部发动").OnEvent("Click", (*) => (SearchAll(EditBox.Value), MyGui.Destroy()))
    
    MyGui.SetFont("s10 w400")
    MyGui.Add("Button", "w" btnW " h" btnH " Left", padding "(&2) 百度一下").OnEvent("Click", (*) => (SearchBaidu(EditBox.Value), MyGui.Destroy()))
    MyGui.Add("Button", "w" btnW " h" btnH " Left", padding "(&3) DeepSeek").OnEvent("Click", (*) => (SearchDeepSeek(EditBox.Value), MyGui.Destroy()))
    MyGui.Add("Button", "w" btnW " h" btnH " Left", padding "(&4) ChatGPT").OnEvent("Click", (*) => (SearchGPT(EditBox.Value), MyGui.Destroy()))
    MyGui.Add("Button", "w" btnW " h" btnH " Left", padding "(&5) Gemini").OnEvent("Click", (*) => (SearchGemini(EditBox.Value), MyGui.Destroy()))
    MyGui.Add("Button", "w" btnW " h" btnH " Left", padding "(&6) Bilibili").OnEvent("Click", (*) => (SearchBili(EditBox.Value), MyGui.Destroy()))

    ; --- 底部 ---
    MyGui.SetFont("s8 cSilver")
    MyGui.Add("Text", "w260 Center y+10", "Enter 搜索 · Esc 退出 · 1-6 快捷键")

    MyGui.OnEvent("Escape", (*) => MyGui.Destroy())
    MyGui.Show("Center")
}

; ==========================================
; 4. 核心功能函数
; ==========================================

GetSelectedOrClipboard() {
    saved := A_Clipboard
    A_Clipboard := ""
    Send "^c"
    if !ClipWait(0.3)
        return Trim(saved)
    text := Trim(A_Clipboard)
    A_Clipboard := saved 
    return text
}

SearchAll(text) {
    if (text == "") {
        return
    }
    SearchBaidu(text)
    Sleep 300
    SearchDeepSeek(text)
    Sleep 300
    SearchGPT(text)
    Sleep 300
    SearchGemini(text)
}

SearchBaidu(text) => Run("https://www.baidu.com/s?wd=" . UrlEncodeUTF8(text))
SearchBili(text) => Run("https://search.bilibili.com/all?keyword=" . UrlEncodeUTF8(text))

SearchDeepSeek(text) {
    Run "https://chat.deepseek.com/"
    if WinWaitActive("ahk_exe chrome.exe", , 3) || WinWaitActive("ahk_exe msedge.exe", , 3) {
        Sleep 3000
        SendAndWait(text)
    }
}

SearchGPT(text) {
    Run "https://chat.openai.com/"
    Sleep 4000
    SendAndWait(text)
}

SearchGemini(text) {
    Run "https://gemini.google.com/"
    Sleep 4000
    SendAndWait(text)
}

SendAndWait(text) {
    saved := A_Clipboard
    A_Clipboard := text
    if ClipWait(1) {
        Send "^v"
        Sleep 200
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