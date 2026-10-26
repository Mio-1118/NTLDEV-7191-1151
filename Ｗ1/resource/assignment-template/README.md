# 作業模板 / Assignment template

本模板供 NTLDEV 7191 與 NTLDEV 7192 課程報告及研究紀要使用，支援中英文。

We use this bilingual template for course reports and research notes in NTLDEV 7191 and NTLDEV 7192.

[PDF 預覽 / Preview PDF](https://github.com/davidycliao/NTLDEV-7191-1151/blob/main/%EF%BC%B71/resource/assignment-template/assignment-template-preview.pdf) · [下載完整 ZIP / Download ZIP](https://github.com/davidycliao/NTLDEV-7191-1151/raw/refs/heads/main/%EF%BC%B71/resource/assignment-template/assignment-template.zip)

## 1. 上傳 Overleaf / Upload to Overleaf

1. 下載上方的 `assignment-template.zip`，不需要先解壓縮。
   We download `assignment-template.zip` without extracting it.
2. 登入 [Overleaf](https://www.overleaf.com/)，在專案首頁選擇 **New project → Existing project (.zip)**；舊版介面可能顯示 **Upload project**。
   We sign in and select **New project → Existing project (.zip)**, or **Upload project** in the older interface.
3. 選取或拖入 ZIP，等待專案開啟。
   We select or drag in the ZIP and wait for the project to open.
4. 將專案名稱改為「課程代碼-姓名-學號」，例如 `NTLDEV7191-WangXiaoming-R12345678`（示例資料）。
   We rename the project as `CourseCode-Name-StudentID`; the example above uses fictional details.

ZIP 內的檔案結構如下；主檔位於最上層，請保留圖片資料夾的相對位置。

We keep the main document at the project root and preserve the image folder structure.

```text
main-template.tex
reference.bib
README.md
images/
  example-image.pdf
```

## 2. 選擇編譯器與主檔 / Select the compiler and main document

開啟專案的齒輪 **Settings**（或 **File → Settings**），進入 **Compiler** 分頁：

We open **Settings** using the gear icon (or **File → Settings**) and select **Compiler**.

| 設定 / Setting | 選項 / Value |
| --- | --- |
| Compiler | **XeLaTeX** |
| Main document | **main-template.tex** |

設定完成後按 **Recompile**。本模板使用 `fontspec` 與 `xeCJK` 處理中英文字體，因此請選 XeLaTeX；`fontspec` 的編譯器錯誤通常表示仍使用 pdfLaTeX。

We select **XeLaTeX** for the template's `fontspec` and `xeCJK` packages, then click **Recompile**. If a `fontspec` engine error appears, we check the compiler setting again.

文獻設定為 `biblatex` 的 `backend=biber`，文獻檔為 `reference.bib`。保留這項設定，並以重新編譯更新引用及文獻表。

We retain `backend=biber` and keep `reference.bib` in the project when updating citations and recompiling.

## 3. 修改姓名、學號與標題 / Edit personal details and the title

在 `main-template.tex` 中搜尋 `\author`，將原本這一行：

We search for `\author` in `main-template.tex` and replace this line:

```latex
\author{姓名 / Name\thanks{系所、學號與電子郵件。Department, student ID, and email.}}
```

改為自己的姓名、系所、學號與電子郵件。以下僅為示例：

We enter our name, department, student ID, and email. The following details are fictional:

```latex
\author{王小明 / Xiaoming Wang\thanks{國家發展研究所，R12345678，student@example.com}}
```

接著修改 `\title{...}` 中的報告標題，保留指令與大括號；`\date{\today}` 會顯示編譯當日日期，也可改成指定日期。

We edit the report title inside `\title{...}`, keeping the command and braces. We can retain `\date{\today}` for the compilation date or enter a fixed date.

## 4. 開始撰寫與檢查 / Write and check the report

將摘要與各節示範內容換成自己的研究，刪除不需要的示範與紅字提醒。文獻資料放在 `reference.bib`；圖片放在 `images/`，並同步修改 `\includegraphics` 的檔名。

We replace the sample abstract and sections with our research and remove unused examples and red reminders. We maintain references in `reference.bib`, place figures in `images/`, and update the filenames in `\includegraphics`.

重新編譯後，檢查 PDF 的姓名、學號、標題、圖片及文獻引用。若出現 `?` 或未定義的引用，先核對引用 key 是否與 `reference.bib` 一致，再重新編譯。

We recompile and check the PDF's name, student ID, title, figures, and citations. For undefined citations, we check the citation keys against `reference.bib` and recompile.

## 5. 引用指令範例 / Citation examples

`main-template.tex` 的「文獻引用指令與實例」提供七個指令的程式碼、實際輸出與句子範例：`\citet`、`\citep`、`\citet*`、`\citep*`、`\citeauthor`、`\citeyear` 與附頁碼的 `\citep[p.~12]{key}`。

We compare seven citation forms, including full author lists and page numbers, using code and actual output in the template's “Citation Commands and Examples” subsection.

模板已設定 `natbib=true`，使用 biblatex 的相容指令，繼續以 Biber 處理文獻。一般引用在三位以上作者時顯示 `et al.`，星號版本列出全部作者。`reference.bib` 中的 `smith2020` 是明確標註的虛構示範，正式報告請移除並替換為真實來源。

We retain biblatex and Biber with `natbib=true`. We use starred commands for full author lists and replace the fictional `smith2020` entry with a verified source before submission.

## 官方操作說明 / Official guides

- [上傳 ZIP / Uploading a project](https://docs.overleaf.com/managing-projects-and-files/uploading-a-project)
- [編譯器設定 / Selecting a compiler](https://docs.overleaf.com/getting-started/recompiling-your-project/selecting-a-tex-live-version-and-latex-compiler)
- [主檔設定 / The main document](https://docs.overleaf.com/getting-started/recompiling-your-project/the-main-document)
- [文獻設定 / Bibliography management with biblatex](https://www.overleaf.com/learn/latex/Bibliography_management_with_biblatex)

模板原始致謝 / Original template credit: adapted from Gui-Ping (Roy) Liang.
