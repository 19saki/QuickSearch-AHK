^!b::Search("https://search.bilibili.com/all?keyword=")
^!c::SearchGPT()
^!d::SearchDeepSeek()

Search(baseUrl) {
    if !ClipWait(0.5)
        return
    text := A_Clipboard
    if (text = "")
        return
    text := StrReplace(text, "`r`n", " ")
    Run baseUrl . UriEncode(text)
}

SearchGPT() {
    if !ClipWait(0.5)
        return
    text := A_Clipboard
    if (text = "")
        return
    text := StrReplace(text, "`r`n", " ")

    Run "https://chat.openai.com/?q=" . UriEncode(text)
    WinWaitActive "ChatGPT", , 5
    Sleep 2000
    Send "{Enter}"
}


SearchDeepSeek() {
    if !ClipWait(0.5)
        return
    text := A_Clipboard
    if (text = "")
        return

    Run "https://chat.deepseek.com/"
    WinWaitActive "DeepSeek", , 5
    Sleep 500

    A_Clipboard := text
    Send "^v"
    Sleep 100
    Send "{Enter}"
}

UriEncode(str) {
    out := ""
    for char in StrSplit(str) {
        code := Ord(char)
        if (code >= 0x30 && code <= 0x39)
         || (code >= 0x41 && code <= 0x5A)
         || (code >= 0x61 && code <= 0x7A)
        {
            out .= char
        }
        else if (char = " ") {
            out .= "%20"
        }
        else {
            out .= "%" . Format("{:02X}", code)
        }
    }
    return out
} 