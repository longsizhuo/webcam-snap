# 摄像头自拍脚本 (Windows / DirectShow) —— 单帧抓拍
# 用法: take_selfie.ps1 [-Output <路径>] [-Resolution 1280x720] [-Device "设备名"]
# Linux / macOS 请改用同目录的 take_selfie.sh
[CmdletBinding()]
param(
    [string]$Output = "",
    [string]$Resolution = "1280x720",
    [string]$Device = "",
    # 找不到 ffmpeg 时自动安装（winget / scoop / choco）。面向零基础用户，装完自动继续拍照。
    [switch]$AutoInstall
)

# 注意：不使用 $ErrorActionPreference='Stop'。
# 在 Windows PowerShell 5.1 中，原生命令(ffmpeg)写到 stderr 的内容会被包装成 ErrorRecord，
# 配合 Stop 会导致脚本误判为失败。这里统一用 $LASTEXITCODE 判断成败，并把 stderr 重定向到临时文件。
$ErrorActionPreference = "Continue"

# 默认输出路径：系统临时目录 + 时间戳
if ([string]::IsNullOrWhiteSpace($Output)) {
    $ts = Get-Date -Format "yyyyMMdd_HHmmss"
    $Output = Join-Path $env:TEMP "selfie_$ts.jpg"
}

# 解析 ffmpeg 可执行文件。刚用 winget/choco 装完时，当前终端会话的 PATH 不会自动更新，
# 直接重跑还是会“找不到”。这里做自愈：先查 PATH -> 从注册表刷新 PATH -> 搜常见安装目录，
# 从而无需重开终端即可用上刚装好的 ffmpeg。
function Resolve-Ffmpeg {
    $cmd = Get-Command ffmpeg -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    # 1) 从注册表重新加载 PATH（机器级 + 用户级），应对“刚装完但没重开终端”
    $machine = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user    = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    $env:PATH = (@($machine, $user) | Where-Object { $_ }) -join ';'
    $cmd = Get-Command ffmpeg -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    # 2) 搜常见安装位置（winget / scoop / choco）
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\ffmpeg.exe'),
        (Join-Path $env:USERPROFILE 'scoop\shims\ffmpeg.exe'),
        (Join-Path $env:ProgramData 'chocolatey\bin\ffmpeg.exe')
    )
    $wingetPkgs = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
    if (Test-Path $wingetPkgs) {
        $candidates += Get-ChildItem $wingetPkgs -Recurse -Filter ffmpeg.exe -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty FullName
    }
    foreach ($c in $candidates) {
        if ($c -and (Test-Path $c)) {
            # 把它所在目录加到本会话 PATH，后续直接用 ffmpeg 即可
            $env:PATH = (Split-Path $c) + ';' + $env:PATH
            return $c
        }
    }
    return $null
}

# 自动安装 ffmpeg（依次尝试 winget / scoop / choco），面向零基础用户
function Install-Ffmpeg {
    Write-Host "未检测到 ffmpeg，正在尝试自动安装..." -ForegroundColor Cyan
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "使用 winget 安装 Gyan.FFmpeg（首次可能需要下载几十 MB，请稍候）..."
        # 明确指定 winget 源并接受协议，避免交互卡住；用户级安装，无需管理员
        winget install --id Gyan.FFmpeg -e --source winget `
            --accept-source-agreements --accept-package-agreements --disable-interactivity 2>&1 | Out-Null
        return
    }
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        Write-Host "使用 scoop 安装 ffmpeg..."
        scoop install ffmpeg 2>&1 | Out-Null
        return
    }
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "使用 choco 安装 ffmpeg..."
        choco install ffmpeg -y 2>&1 | Out-Null
        return
    }
    Write-Host "没有可用的包管理器（winget / scoop / choco），无法自动安装。" -ForegroundColor Yellow
}

$ffPath = Resolve-Ffmpeg
if (-not $ffPath -and $AutoInstall) {
    Install-Ffmpeg
    $ffPath = Resolve-Ffmpeg   # 装完再解析：自愈逻辑会刷新 PATH / 搜安装目录找到它
}
if (-not $ffPath) {
    Write-Host "错误: 未找到 ffmpeg。" -ForegroundColor Red
    Write-Host "自动安装：给本脚本加 -AutoInstall 参数即可让它自己装好并继续拍照。"
    Write-Host "手动安装：winget install --id Gyan.FFmpeg （或 scoop install ffmpeg / choco install ffmpeg）。"
    Write-Host "提示：装完直接重跑本脚本即可——脚本会自动从注册表刷新 PATH 并搜索常见安装目录，通常无需重开终端。"
    exit 1
}

# 运行 ffmpeg 的辅助函数：stderr 重定向到临时文件，返回 stderr 文本，避免 5.1 的 ErrorRecord 问题
function Invoke-Ffmpeg {
    param([string[]]$FfArgs)
    $errFile = [System.IO.Path]::GetTempFileName()
    try {
        & ffmpeg @FfArgs 2>$errFile | Out-Null
        return Get-Content -LiteralPath $errFile -Raw
    } finally {
        Remove-Item -LiteralPath $errFile -Force -ErrorAction SilentlyContinue
    }
}

# 未显式指定设备时，自动探测第一个视频设备
if ([string]::IsNullOrWhiteSpace($Device)) {
    Write-Host "正在探测摄像头设备..."
    $listing = Invoke-Ffmpeg @("-hide_banner", "-f", "dshow", "-list_devices", "true", "-i", "dummy")
    $videoNames = [System.Collections.Generic.List[string]]::new()
    foreach ($line in ($listing -split "`n")) {
        # 解析形如: [dshow @ ...] "HD Pro Webcam C920" (video)
        if ($line -match '"([^"]+)"\s*\(video\)') {
            $videoNames.Add($Matches[1])
        }
    }
    if ($videoNames.Count -eq 0) {
        Write-Host "错误: 未找到任何视频输入设备。" -ForegroundColor Red
        Write-Host "可运行以下命令查看：ffmpeg -f dshow -list_devices true -i dummy"
        exit 1
    }
    $Device = $videoNames[0]
    Write-Host "使用摄像头设备: $Device （共发现 $($videoNames.Count) 个）"
} else {
    Write-Host "使用指定摄像头设备: $Device"
}

Write-Host "输出文件: $Output"
Write-Host "分辨率: $Resolution"
Write-Host "正在拍照..."

# 拍照：跳过前 30 帧，等待自动曝光收敛
$stderr = Invoke-Ffmpeg @(
    "-y", "-loglevel", "error", "-f", "dshow", "-video_size", $Resolution,
    "-i", "video=$Device", "-vf", "select=gte(n\,30)", "-frames:v", "1",
    "-fps_mode", "passthrough", "-f", "image2", $Output
)

# 指定分辨率被设备拒绝时，回退到设备默认分辨率再试一次
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $Output)) {
    Write-Host "指定分辨率失败，回退到设备默认分辨率重试..." -ForegroundColor Yellow
    $stderr = Invoke-Ffmpeg @(
        "-y", "-loglevel", "error", "-f", "dshow",
        "-i", "video=$Device", "-frames:v", "1", "-f", "image2", $Output
    )
}

if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $Output)) {
    $sizeKB = (Get-Item -LiteralPath $Output).Length / 1KB
    Write-Host "拍照成功!" -ForegroundColor Green
    Write-Host "文件路径: $Output"
    Write-Host ("文件大小: {0:N1} KB" -f $sizeKB)
} else {
    Write-Host "拍照失败" -ForegroundColor Red
    if ($stderr) { Write-Host $stderr }
    exit 1
}
