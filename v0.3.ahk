; 快捷键：Ctrl + Alt + S
^!s::SearchAll()

; 核心逻辑：获取文本的通用函数
GetSelectedOrClipboard() {
    SavedClipboard := ClipboardAll() ; 备份原始剪贴板
    A_Clipboard := ""               ; 清空剪贴板以备检测
    
    Send "^c"                       ; 尝试复制选中文本
    if !ClipWait(0.3) {             ; 等待 0.3 秒，如果没有新内容被复制
        A_Clipboard := SavedClipboard ; 还原旧剪贴板内容
    }
    
    text := Trim(A_Clipboard)
    return text
}

SearchAll() {
    text := GetSelectedOrClipboard()
    if (text = "") {
        MsgBox "未发现可搜索的文本"
        return
    }

    ; 调用各个搜索引擎，直接传递获取到的 text
    SearchBaidu(text)
    SearchDeepSeek(text)
    Sleep 500
    SearchGPT(text)
    Sleep 500
    SearchGemini(text)
}

; --- 修改后的子函数（接受参数，避免重复读取剪贴板） ---

SearchBaidu(text) {
    urlText := StrReplace(StrReplace(text, "`r`n", " "), " ", "%20")
    Run "https://www.baidu.com/s?wd=" . urlText
}

SearchDeepSeek(text) {
    Run "https://chat.deepseek.com/"
    if WinWaitActive("DeepSeek", , 5) {
        Sleep 500
        A_Clipboard := text
        Send "^v{Enter}"
    }
}

SearchGPT(text) {
    Run "https://chat.openai.com/"
    if WinWaitActive("ChatGPT", , 5) {
        Sleep 1000
        A_Clipboard := text
        Send "^v{Enter}"
    }
}

SearchGemini(text) {
    Run "https://gemini.google.com/"
    if WinWaitActive("Gemini", , 5) {
        Sleep 4000 ; Gemini 加载稍慢
        A_Clipboard := text
        Send "^v{Enter}"
    }
}

; 快捷键：Ctrl + Alt + B
^!b:: {
    text := GetSelectedOrClipboard()
    if (text != "") {
        urlText := StrReplace(text, "`r`n", " ")
        Run "https://search.bilibili.com/all?keyword=" . urlText
    }
}

