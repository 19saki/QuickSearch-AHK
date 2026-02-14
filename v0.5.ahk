^!s::ShowSearchMenu()

ShowSearchMenu() {
    global textToSearch := GetSelectedOrClipboard()
    if (textToSearch = "") {
        MsgBox "未发现可搜索的文本"
        return
    }

    static MyGui
    if IsSet(MyGui) && MyGui
        MyGui.Destroy()

    MyGui := Gui("+AlwaysOnTop", "时呓呓搜索")
    MyGui.SetFont("s10", "Microsoft YaHei")

    MyGui.Add("Button", "w220 Default", "1. 全部发动").OnEvent("Click", (*) => (MyGui.Destroy(), SearchAll(textToSearch)))
    MyGui.Add("Button", "w220", "2. 百度").OnEvent("Click", (*) => (MyGui.Destroy(), SearchBaidu(textToSearch)))
    MyGui.Add("Button", "w220", "3. DeepSeek").OnEvent("Click", (*) => (MyGui.Destroy(), SearchDeepSeek(textToSearch)))
    MyGui.Add("Button", "w220", "4. ChatGPT").OnEvent("Click", (*) => (MyGui.Destroy(), SearchGPT(textToSearch)))
    MyGui.Add("Button", "w220", "5. Gemini").OnEvent("Click", (*) => (MyGui.Destroy(), SearchGemini(textToSearch)))
    MyGui.Add("Button", "w220", "6. Bilibili").OnEvent("Click", (*) => (MyGui.Destroy(), SearchBili(textToSearch)))

    MyGui.OnEvent("Escape", (*) => MyGui.Destroy())
    MyGui.Show()
}

GetSelectedOrClipboard() {
    saved := A_Clipboard
    A_Clipboard := ""
    Send "^c"
    if !ClipWait(0.3)
        A_Clipboard := saved
    text := Trim(A_Clipboard)
    A_Clipboard := saved
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

SearchBaidu(text) {
    Run "https://www.baidu.com/s?wd=" . UrlEncodeUTF8(text)
}

SearchBili(text) {
    Run "https://search.bilibili.com/all?keyword=" . UrlEncodeUTF8(text)
}

; === AI 串行发送，固定延时版本 ===

SearchDeepSeek(text) {
    Run "https://chat.deepseek.com/"
    Sleep 4000  ; 等待页面加载
    SendAndWait(text)
}

SearchGPT(text) {
    Run "https://chat.openai.com/"
    Sleep 5000  ; 等待页面加载
    SendAndWait(text)
}

SearchGemini(text) {
    Run "https://gemini.google.com/"
    Sleep 6000  ; 等待页面加载
    SendAndWait(text)
}

SendAndWait(text) {
    saved := A_Clipboard
    A_Clipboard := text
    ClipWait 1
    Send "^v"
    Sleep 50
    Send "{Enter}"
    Sleep 500
    A_Clipboard := saved
}

; === UTF-8 编码，用于百度/B站等 ===

UrlEncodeUTF8(str) {
    size := StrPut(str, "UTF-8")
    buf := Buffer(size)
    StrPut(str, buf, "UTF-8")

    out := ""
    Loop size - 1 {
        byte := NumGet(buf, A_Index - 1, "UChar")
        if (byte >= 0x30 && byte <= 0x39)
         || (byte >= 0x41 && byte <= 0x5A)
         || (byte >= 0x61 && byte <= 0x7A)
         || (byte = 0x2D || byte = 0x2E || byte = 0x5F || byte = 0x7E)
            out .= Chr(byte)
        else
            out .= "%" . Format("{:02X}", byte)
    }
    return out
}
