# Title Extractor (Batch File Lister)

A tiny Windows batch script that scans a folder, numbers every file in it, and writes the list to a plain text file. It's the sort of thing you reach for when you want a quick inventory of what's in a directory — for a spreadsheet, a backup manifest, a README, or just to see what got extracted from an archive.

No dependencies, no Python, no install. Just a `.bat` file you can double-click.

---

## Table of Contents

1. [What It Does](#what-it-does)
2. [Requirements](#requirements)
3. [Installation](#installation)
4. [Usage](#usage)
5. [Configuration](#configuration)
6. [Output Format](#output-format)
7. [How the Code Works](#how-the-code-works)
8. [Batch Scripting Crash Course](#batch-scripting-crash-course)
9. [Customization Recipes](#customization-recipes)
10. [Troubleshooting](#troubleshooting)
11. [Known Limitations](#known-limitations)
12. [Porting to Other Platforms](#porting-to-other-platforms)
13. [License](#license)

---

## What It Does

Given a target directory (default: the folder the script lives in), it:

1. **Creates or truncates** a text file called `results.txt`.
2. **Writes a header** identifying the directory being scanned.
3. **Enumerates every file** in that directory (non-recursive — subfolders are ignored).
4. **Numbers each file** (`1. filename.ext`, `2. otherfile.mkv`, …) and appends it to the output.
5. **Writes a total count** at the bottom.
6. **Prints a one-line summary** to the console so you know it finished.

Nothing is moved, renamed, deleted, or modified. It's purely read-only apart from creating the output file.

---

## Requirements

- **Windows** (any version with `cmd.exe` — XP through Windows 11).
- No admin rights, no installs, no external tools.

That's it. The script uses only built-in `cmd.exe` commands (`dir`, `echo`, `set`, `for`).

---

## Installation

1. Save the script as `title_extractor.bat` (or any name ending in `.bat`).
2. Put it in the folder you want to scan — **or** in a fixed location and edit `TARGET_DIR` (see [Configuration](#configuration)).
3. Double-click it, or run it from a terminal.

> **Heads up on Windows SmartScreen:** freshly-downloaded `.bat` files sometimes get flagged. If you see a warning, right-click the file → *Properties* → check *Unblock* → *OK*.

---

## Usage

### Option 1 — Double-click

Put `title_extractor.bat` in the folder you want to list, then double-click it. When it finishes, the console window closes immediately.

### Option 2 — Run from a terminal (recommended)

Open `cmd.exe`, `cd` into the target folder, and run:

```cmd
title_extractor.bat
```

The console shows `Done. N file(s) written to results.txt` and stays open until you close it manually.

### Option 3 — Run on a different folder

Edit `TARGET_DIR` inside the script (see [Configuration](#configuration)):

```bat
set "TARGET_DIR=D:\Videos\2024"
```

### Option 4 — Run from anywhere with an absolute path

```cmd
"C:\Tools\title_extractor.bat"
```

The script always operates on `TARGET_DIR`, no matter where you invoke it from.

---

## Configuration

Both options live at the top of the file, in the `Configuration` block:

```bat
REM Set the directory to scan (use "." for the current directory)
set "TARGET_DIR=."

REM Output file name
set "OUTPUT_FILE=results.txt"
```

| Variable | Default | Meaning |
|----------|---------|---------|
| `TARGET_DIR` | `.` (the current working directory) | The folder to list. Use `.` for "wherever the script is run from," or an absolute path like `D:\Videos`. |
| `OUTPUT_FILE` | `results.txt` | The file the list is written to. Relative paths land in the current directory. |

> **Quoting matters.** Both `set` lines wrap the value in quotes (`set "VAR=value"`). This makes `cmd.exe` treat everything between the quotes as a single value — even if it contains spaces. Don't remove them.

---

## Output Format

A sample `results.txt` looks like this:

```
File listing for: .
============================

1. 2024-01-15_meeting.mp4
2. 2024-01-16_interview.mkv
3. backup.zip
4. notes.txt
5. screenshot.png

Total files: 5
```

- **Header** — identifies the scanned directory.
- **Numbered list** — one file per line, prefix is `N. ` (number, dot, space).
- **Filler line** — a blank line before the summary.
- **Total** — count of files.

Files appear in the order `dir /b /a-d` returns them — which, on NTFS, is *usually* alphabetical but **not guaranteed**. If you need strict alphabetical order, see the [Sorting](#sorting-alphabetically) recipe.

---

## How the Code Works

Here's the full script again, annotated:

```bat
@echo off
setlocal enabledelayedexpansion
```

- `@echo off` — suppresses the "echoing" of every command to the console. Without this, the terminal would fill with noise.
- `setlocal enabledelayedexpansion` — turns on **delayed expansion**. Inside a `for` loop, `%VAR%` is expanded *once* at parse time (before the loop runs), so incrementing a counter with `set /a counter+=1` would never be visible via `%counter%`. With delayed expansion, `!counter!` re-evaluates each iteration. This is *the* classic batch gotcha.

```bat
REM ===== Configuration =====
set "TARGET_DIR=."
set "OUTPUT_FILE=results.txt"
```

- `REM` starts a comment.
- The quoted `set "VAR=value"` form prevents trailing spaces from becoming part of the value.

```bat
> "%OUTPUT_FILE%" echo File listing for: %TARGET_DIR%
>> "%OUTPUT_FILE%" echo ============================
>> "%OUTPUT_FILE%" echo.
```

- `>` **creates or truncates** the file. The first line uses `>` to start fresh; everything after uses `>>` to append.
- `echo.` (echo followed by a dot) prints a **blank line**. Plain `echo` would print `ECHO is on.`.

```bat
set /a counter=0
```

- `set /a` does arithmetic. Initializes the counter to zero.

```bat
for /f "delims=" %%F in ('dir /b /a-d "%TARGET_DIR%" 2^>nul') do (
    set /a counter+=1
    >> "%OUTPUT_FILE%" echo !counter!. %%F
)
```

This is the meat. Let's unpack it:

- **`for /f`** — iterate over the *output of a command* (as opposed to `for %%F in (*)` which iterates over files directly). Using `/f` gives us more control and lets us suppress errors.
- **`"delims="`** — sets the delimiter set to empty, so the entire line (including spaces) is captured in `%%F`. Without this, filenames with spaces would be split at the first space.
- **`'dir /b /a-d "%TARGET_DIR%" 2^>nul'`** — the command to run:
  - `/b` = bare format (no headers, no summary).
  - `/a-d` = attribute filter, **minus** directories. Only files.
  - `2^>nul` — redirect stderr to null. The `^` **escapes** the `>` from the outer `for` parser. Without `^`, `cmd.exe` would try to redirect the `for` command's own output and choke.
- **`set /a counter+=1`** — increment.
- **`>> "%OUTPUT_FILE%" echo !counter!. %%F`** — append `N. filename`. Note the **`!counter!`** (delayed expansion) vs **`%%F`** (loop variable). The `%` is doubled inside a batch file; at the interactive prompt you'd use `%F` single.

```bat
>> "%OUTPUT_FILE%" echo.
>> "%OUTPUT_FILE%" echo Total files: !counter!
```

- Blank line, then the grand total.

```bat
echo Done. !counter! file(s) written to %OUTPUT_FILE%
endlocal
```

- Console-friendly summary. Here `!counter!` works because delayed expansion is still active.
- `endlocal` restores the environment to what it was before `setlocal`. Good hygiene, especially if this script is called from another.

---

## Batch Scripting Crash Course

If you're new to `.bat`, these are the concepts this script exercises. Worth a five-minute read.

### Variables and expansion

```bat
set "NAME=World"
echo Hello, %NAME%
```

`%NAME%` is expanded **at parse time** — the entire line is expanded before execution. Inside a `for` loop, this means the value is frozen from *before* the loop started.

### Delayed expansion

```bat
setlocal enabledelayedexpansion
set "counter=0"
for %%F in (*) do (
    set /a counter+=1
    echo !counter!    REM correct — evaluated each iteration
)
```

`!VAR!` is expanded **at execution time**, which is what you need inside loops.

### Redirection

| Syntax | Effect |
|--------|--------|
| `> file` | Overwrite `file` |
| `>> file` | Append to `file` |
| `2> file` | Redirect stderr |
| `2>nul` | Discard stderr |
| `2>&1` | Send stderr to the same place as stdout |

### Escaping `>` inside `for /f`

Inside `for /f ('command')`, the `>` needs to be escaped as `^>` because the outer parser is already looking for redirections. This trips up nearly every batch author.

### Quoting

Always use `set "VAR=value"` and quote paths passed to commands. Filenames with spaces, parentheses, and `&` are the #1 source of batch bugs.

---

## Customization Recipes

### Scanning a different folder

Edit the config:

```bat
set "TARGET_DIR=D:\Videos"
```

### Recursive scan (include subfolders)

Swap `/b /a-d` for `/b /s /a-d`:

```bat
for /f "delims=" %%F in ('dir /b /s /a-d "%TARGET_DIR%" 2^>nul') do (
```

With `/s`, `dir` returns **full paths**, so you'll get lines like `D:\Videos\2024\clip.mp4`.

### Full paths instead of filenames

Even without `/s`, you can prefix the target directory:

```bat
>> "%OUTPUT_FILE%" echo !counter!. %TARGET_DIR%\%%F
```

### Sorting alphabetically

Pipe `dir` through `sort`:

```bat
for /f "delims=" %%F in ('dir /b /a-d "%TARGET_DIR%" 2^>nul ^| sort') do (
```

Note the escaped pipe `^|` — same reason as `^>`.

### Filtering by extension

Only list `.mp4` files:

```bat
for /f "delims=" %%F in ('dir /b /a-d "%TARGET_DIR%\*.mp4" 2^>nul') do (
```

Or multiple extensions using a wildcard sweep and a filter:

```bat
for /f "delims=" %%F in ('dir /b /a-d "%TARGET_DIR%" 2^>nul ^| findstr /i "\.mp4$ \.mkv$ \.avi$"') do (
```

### Including file sizes

`dir /b` strips metadata. To keep it, drop `/b` and parse columns — messy. Easier: use `forfiles` or `for %%F in (...) do`:

```bat
for %%F in ("%TARGET_DIR%\*") do (
    set /a counter+=1
    >> "%OUTPUT_FILE%" echo !counter!. %%~nxF  %%~zF bytes
)
```

`%%~zF` = size, `%%~nxF` = name + extension.

### Writing to a dated filename

```bat
for /f "tokens=1-3 delims=/-. " %%a in ("%date%") do (
    set "OUTPUT_FILE=listing_%%c-%%a-%%b.txt"
)
```

`%date%` format varies by locale; this is best-effort.

### Appending instead of overwriting

Change the very first redirection from `>` to `>>`:

```bat
>> "%OUTPUT_FILE%" echo File listing for: %TARGET_DIR%
```

But be aware: every subsequent run will append, and the file will grow without bound. Better to write to a dated file.

### Suppressing the console window (silent mode)

Save as `.vbs` and call the batch file:

```vbs
CreateObject("WScript.Shell").Run "title_extractor.bat", 0, True
```

Or save the `.bat` with a `.cmd` extension and launch via Task Scheduler with *Hidden* set.

### Scheduling a weekly run

1. Open **Task Scheduler** → *Create Basic Task*.
2. Trigger: *Weekly*.
3. Action: *Start a program* → point to `title_extractor.bat`.
4. Set *Start in* to the folder you want to scan (this sets the working directory so `.` resolves correctly).

---

## Troubleshooting

| Symptom | Cause & fix |
|---------|-------------|
| **Window flashes and disappears** | You double-clicked the file. It *did* run — check the folder for `results.txt`. To see output, open `cmd.exe` and run it from there. |
| **`results.txt` is empty** | The target folder has no files, or `TARGET_DIR` doesn't exist. A missing directory triggers the `2>nul` suppression — the script exits silently with 0 files. |
| **Filenames with `&`, `%`, `!` cause weird output** | Batch's expansion pass mangles these. `!` in particular is eaten by delayed expansion. Solutions: turn off `enabledelayedexpansion` and use a `call :sub` trick, or switch to PowerShell. |
| **Filenames with spaces get cut off** | Missing `"delims="`. Make sure it's present. |
| **Only some files listed** | They may be hidden or system files. `dir /a-d` includes them, but `dir /b /a-d` also includes them. If still missing, check subfolders — the script is non-recursive. |
| **Output shows `N. ` for every line** | Delayed expansion is off, or you're running from the interactive prompt with `%%F` instead of `%F`. |
| **Unicode / non-ASCII filenames show as `?`** | The console is in legacy code page 437/850. Run `chcp 65001` before the script, or use PowerShell (which handles UTF-8 natively). |
| **"The system cannot find the path specified"** | `TARGET_DIR` is wrong, or a drive isn't mounted. Verify with `dir "D:\Videos"` in a terminal. |
| **`ECHO is on.` appears instead of a blank line** | Use `echo.` (with the dot) for blank lines, not bare `echo`. |
| **File is locked, "access denied"** | Another program has `results.txt` open. Close it (Excel, Notepad, etc.) and re-run. |

### Debugging tip

Temporarily change `@echo off` to `@echo on` to see every command as it executes. It's noisy but reveals exactly which line misbehaves.

---

## Known Limitations

- **Windows only.** Batch is a Windows-shell language. No native support on macOS or Linux. See [Porting to Other Platforms](#porting-to-other-platforms).
- **Non-recursive by default.** Subfolders are ignored unless you add `/s`.
- **No sorting by default.** Output order reflects `dir`'s internal order, which is filesystem-dependent.
- **UTF-8 unfriendly.** Non-Latin filenames may render as `?` in the output on older Windows versions.
- **No file sizes, dates, or other metadata** — just names.
- **Fragile with special characters.** Filenames containing `!`, `%`, `&`, or `^` can break the output. This is a fundamental batch limitation, not a bug in this script.
- **No error recovery.** If the output file can't be written (disk full, permissions), the script fails silently because of `2>nul`.
- **Slow on huge directories.** `for /f` over `dir` output is line-buffered; tens of thousands of files can take a minute or two.
- **No dry-run or preview.** It just runs.

---

## Porting to Other Platforms

If you need the same functionality on macOS or Linux, or want to escape batch's quoting nightmares, here are equivalents.

### PowerShell (Windows — modern replacement)

```powershell
$target = "."
$out = "results.txt"
$files = Get-ChildItem -Path $target -File
"File listing for: $target" | Out-File $out
"=" * 28 | Out-File $out -Append
"" | Out-File $out -Append
$i = 1
$files | ForEach-Object {
    "$i. $($_.Name)" | Out-File $out -Append
    $i++
}
"" | Out-File $out -Append
"Total files: $($files.Count)" | Out-File $out -Append
Write-Host "Done. $($files.Count) file(s) written to $out"
```

PowerShell handles UTF-8, spaces, and special characters natively. If you have a choice, prefer it.

### Bash (macOS / Linux)

```bash
#!/usr/bin/env bash
TARGET_DIR="."
OUTPUT_FILE="results.txt"

{
  echo "File listing for: $TARGET_DIR"
  echo "============================"
  echo
  i=0
  for f in "$TARGET_DIR"/*; do
    [ -f "$f" ] || continue
    i=$((i+1))
    echo "$i. $(basename "$f")"
  done
  echo
  echo "Total files: $i"
} > "$OUTPUT_FILE"

echo "Done. $i file(s) written to $OUTPUT_FILE"
```

### Python (cross-platform)

```python
from pathlib import Path

target = Path(".")
out = Path("results.txt")

files = [f for f in target.iterdir() if f.is_file()]

with out.open("w", encoding="utf-8") as fh:
    fh.write(f"File listing for: {target}\n")
    fh.write("=" * 28 + "\n\n")
    for i, f in enumerate(files, 1):
        fh.write(f"{i}. {f.name}\n")
    fh.write(f"\nTotal files: {len(files)}\n")

print(f"Done. {len(files)} file(s) written to {out}")
```

Two lines of logic, three lines of I/O, no quoting rituals. If you find yourself fighting batch, this is the escape hatch.

---

## License

MIT License. Use, modify, and redistribute freely.

---

## Contributing

Pull requests / variants welcome for:

- A recursive-scan switch as an argument (`title_extractor.bat /s`).
- A dated-output variant.
- A PowerShell rewrite bundled alongside the batch version.
- A UTF-8-safe version that calls `chcp 65001` first.

For anything more ambitious than a one-line change, consider writing a PowerShell or Python version instead — batch has a hard ceiling on correctness with modern filenames.
