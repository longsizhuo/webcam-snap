#!/usr/bin/env bash
# 摄像头自拍脚本 (Linux / macOS) —— 单帧抓拍
# 用法: take_selfie.sh [输出路径] [分辨率] [--auto-install]
# Windows 请改用同目录的 take_selfie.ps1
set -euo pipefail

OS="$(uname -s)"
AUTO_INSTALL=0
POS=()
# 解析参数：--auto-install 可放在任意位置，其余按位置解析（输出路径、分辨率）
for a in "$@"; do
    case "$a" in
        --auto-install) AUTO_INSTALL=1 ;;
        *) POS+=("$a") ;;
    esac
done
OUTPUT_FILE="${POS[0]:-${TMPDIR:-/tmp}/selfie_$(date +%Y%m%d_%H%M%S).jpg}"
RESOLUTION="${POS[1]:-1280x720}"

# 自动安装 ffmpeg（面向零基础用户）。macOS 用 brew；Linux 仅在 sudo 免密(-n)时自动装，
# 否则给出手动命令——避免非交互环境卡在密码输入上。
install_ffmpeg() {
    echo "未检测到 ffmpeg，正在尝试自动安装..." >&2
    case "$OS" in
        Darwin)
            if command -v brew >/dev/null 2>&1; then brew install ffmpeg || true
            else echo "未找到 Homebrew，请手动运行: brew install ffmpeg" >&2; fi
            ;;
        Linux)
            if command -v apt-get >/dev/null 2>&1; then
                sudo -n apt-get install -y ffmpeg >/dev/null 2>&1 \
                    || echo "需要 sudo 权限，请手动运行: sudo apt install ffmpeg" >&2
            elif command -v dnf >/dev/null 2>&1; then
                sudo -n dnf install -y ffmpeg >/dev/null 2>&1 \
                    || echo "需要 sudo 权限，请手动运行: sudo dnf install ffmpeg" >&2
            else
                echo "未识别的包管理器，请手动安装 ffmpeg" >&2
            fi
            ;;
    esac
}

# 检查 ffmpeg；缺失且带 --auto-install 时自动装一次
if ! command -v ffmpeg >/dev/null 2>&1 && [ "$AUTO_INSTALL" = "1" ]; then
    install_ffmpeg
fi
if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "错误: 未找到 ffmpeg" >&2
    echo "自动安装：给脚本加 --auto-install 参数。" >&2
    case "$OS" in
        Darwin) echo "手动安装: brew install ffmpeg" >&2 ;;
        *)      echo "手动安装: sudo apt install ffmpeg  (Debian/Ubuntu) 或 sudo dnf install ffmpeg (Fedora)" >&2 ;;
    esac
    exit 1
fi

echo "系统: $OS"
echo "输出文件: $OUTPUT_FILE"
echo "分辨率: $RESOLUTION"
echo "正在拍照..."

case "$OS" in
  Darwin)
    # macOS: AVFoundation 后端，设备用序号；默认第 0 个视频设备，可用环境变量 CAMERA_INDEX 覆盖
    # 列设备: ffmpeg -f avfoundation -list_devices true -i ""
    DEVICE_INDEX="${CAMERA_INDEX:-0}"
    echo "使用摄像头(AVFoundation)设备序号: $DEVICE_INDEX"
    # 跳过前 30 帧，等待自动曝光收敛
    if ! ffmpeg -y -loglevel error -f avfoundation -framerate 30 \
            -video_size "$RESOLUTION" -i "$DEVICE_INDEX" \
            -vf "select=gte(n\,30)" -frames:v 1 -vsync 0 \
            -f image2 "$OUTPUT_FILE" 2>/dev/null; then
        echo "指定分辨率失败，回退到设备默认参数重试..." >&2
        ffmpeg -y -loglevel error -f avfoundation -i "$DEVICE_INDEX" \
            -frames:v 1 -f image2 "$OUTPUT_FILE"
    fi
    ;;
  Linux)
    # Linux: V4L2 后端，设备为 /dev/video*
    if [ -e "/dev/video0" ]; then
        CAMERA_DEVICE="/dev/video0"
    else
        echo "警告: /dev/video0 不存在，查找其他摄像头设备..." >&2
        CAMERA_DEVICE="$(ls /dev/video* 2>/dev/null | head -1 || true)"
        if [ -z "$CAMERA_DEVICE" ]; then
            echo "错误: 未找到摄像头设备 (/dev/video*)" >&2
            exit 1
        fi
    fi
    echo "使用摄像头(V4L2)设备: $CAMERA_DEVICE"
    if ! ffmpeg -y -loglevel error -f v4l2 -video_size "$RESOLUTION" \
            -i "$CAMERA_DEVICE" -vf "select=gte(n\,30)" -frames:v 1 -vsync 0 \
            -f image2 "$OUTPUT_FILE" 2>/dev/null; then
        echo "指定分辨率失败，回退到设备默认参数重试..." >&2
        ffmpeg -y -loglevel error -f v4l2 -i "$CAMERA_DEVICE" \
            -frames:v 1 -f image2 "$OUTPUT_FILE"
    fi
    ;;
  *)
    echo "错误: 不支持的系统 '$OS'。Windows 请使用同目录的 take_selfie.ps1" >&2
    exit 1
    ;;
esac

# -s 判断文件存在且非空
if [ -s "$OUTPUT_FILE" ]; then
    echo "拍照成功!"
    echo "文件路径: $OUTPUT_FILE"
    echo "文件大小: $(du -h "$OUTPUT_FILE" | cut -f1)"
else
    echo "拍照失败" >&2
    exit 1
fi
