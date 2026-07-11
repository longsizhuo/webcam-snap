# 摄像头自拍脚本 (Windows / DirectShow) —— 单帧抓拍
# 用法: take_selfie.ps1 [-Output <路径>] [-Resolution 1280x720] [-Device "设备名"]
# Linux / macOS 请改用同目录的 take_selfie.sh
[CmdletBinding()]
param(
    [string]$Output = "",
    [string]$Resolution = "1280x720",
    [string]$Device = ""
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

# 检查 ffmpeg 是否已安装
$ff = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ff) {
    Write-Host "错误: 未找到 ffmpeg。" -ForegroundColor Red
    Write-Host "请先安装：winget install --id Gyan.FFmpeg （或 scoop install ffmpeg / choco install ffmpeg），然后重新打开终端。"
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
