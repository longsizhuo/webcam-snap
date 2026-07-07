#!/bin/bash
# 摄像头自拍脚本

set -e

OUTPUT_FILE="${1:-/tmp/selfie_$(date +%Y%m%d_%H%M%S).jpg}"
RESOLUTION="${2:-640x480}"

echo "正在拍照..."
echo "输出文件: $OUTPUT_FILE"
echo "分辨率: $RESOLUTION"

# 检查ffmpeg是否安装
if ! command -v ffmpeg &> /dev/null; then
    echo "错误: ffmpeg未安装"
    echo "请安装: sudo apt install ffmpeg 或 brew install ffmpeg"
    exit 1
fi

# 检查摄像头设备
if [ ! -e "/dev/video0" ]; then
    echo "警告: /dev/video0 不存在，尝试查找其他摄像头设备..."
    CAM_DEVICES=$(ls /dev/video* 2>/dev/null | head -1)
    if [ -z "$CAM_DEVICES" ]; then
        echo "错误: 未找到摄像头设备"
        exit 1
    fi
    CAMERA_DEVICE="$CAM_DEVICES"
else
    CAMERA_DEVICE="/dev/video0"
fi

echo "使用摄像头设备: $CAMERA_DEVICE"

# 拍照（跳过前30帧，等待自动曝光收敛）
ffmpeg -y -loglevel error \
    -f v4l2 \
    -video_size "$RESOLUTION" \
    -i "$CAMERA_DEVICE" \
    -vf "select=gte(n\,30)" -frames:v 1 -vsync 0 \
    -f image2 "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
    echo "拍照成功!"
    echo "文件大小: $(du -h "$OUTPUT_FILE" | cut -f1)"
    echo "图片信息: $(file "$OUTPUT_FILE")"
else
    echo "拍照失败"
    exit 1
fi