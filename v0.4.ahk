; 快捷键：Ctrl + Alt + S 唤起选择面板
^!s::ShowSearchMenu()

ShowSearchMenu() {
    global textToSearch := GetSelectedOrClipboard()
    if (textToSearch = "") {
        MsgBox "未发现可搜索的文本"
        return
    }

    ; 创建 GUI 窗口
    MyGui := Gui("+AlwaysOnTop", "搜索助手 - 请选择目标")
    MyGui.SetFont("s10", "Microsoft YaHei")
    
    ; 添加按钮
    MyGui.Add("Button", "w200", "1. 全部发动 (Baidu+AI)").OnEvent("Click", (*) => (MyGui.Destroy(), SearchAll(textToSearch)))
    MyGui.Add("Button", "w200", "2. 百度搜索").OnEvent("Click", (*) => (MyGui.Destroy(), SearchBaidu(textToSearch)))
    MyGui.Add("Button", "w200", "3. DeepSeek").OnEvent("Click", (*) => (MyGui.Destroy(), SearchDeepSeek(textToSearch)))
    MyGui.Add("Button", "w200", "4. ChatGPT").OnEvent("Click", (*) => (MyGui.Destroy(), SearchGPT(textToSearch)))
    MyGui.Add("Button", "w200", "5. Gemini").OnEvent("Click", (*) => (MyGui.Destroy(), SearchGemini(textToSearch)))
    MyGui.Add("Button", "w200", "6. Bilibili").OnEvent("Click", (*) => (MyGui.Destroy(), SearchBili(textToSearch)))
    
    MyGui.Show()
}

; --- 逻辑核心：获取文本 ---
GetSelectedOrClipboard() {
    SavedClipboard := ClipboardAll()
    A_Clipboard := ""
    Send "^c"
    if !ClipWait(0.3) {
        A_Clipboard := SavedClipboard
    }
    return Trim(A_Clipboard)
}

; --- 搜索函数库 ---

SearchAll(text) {
    SearchBaidu(text)
    SearchDeepSeek(text)
    Sleep 500
    SearchGPT(text)
    Sleep 500
    SearchGemini(text)
}

SearchBaidu(text) {
    Run "https://www.baidu.com/s?wd=" . StrReplace(text, " ", "%20")
}

SearchBili(text) {
    Run "https://search.bilibili.com/all?keyword=" . StrReplace(text, " ", "%20")
}

; AI 类函数：建议使用 URI 编码以防文本包含特殊字符
SearchDeepSeek(text) {
    Run "https://chat.deepseek.com/"
    if WinWaitActive("DeepSeek", , 8) {
        Sleep 800
        A_Clipboard := text
        Send "^v{Enter}"
    }
}

SearchGPT(text) {
    Run "https://chat.openai.com/"
    if WinWaitActive("ChatGPT", , 8) {
        Sleep 1000
        A_Clipboard := text
        Send "^v{Enter}"
    }
}

SearchGemini(text) {
    Run "https://gemini.google.com/"
    if WinWaitActive("Gemini", , 8) {
        Sleep 3000
        A_Clipboard := text
        Send "^v{Enter}"
    }
}