#!/bin/bash
# 把自编的 PlayTools.framework 装进 PlayCover.app 与 ~/Library/Frameworks。
# 用法：scripts/install-into-playcover.sh [PlayTools.framework 路径]
# 默认用 build-artifacts 下最新一次云端编译的产物。PlayCover 升级后重跑即可。
# 旧文件只移入废纸篓，PlayCover.app 每次先整份备份到 backup/。
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
APP=/Applications/PlayCover.app
SYS_FW="$HOME/Library/Frameworks/PlayTools.framework"
SRC="${1:-$(ls -td "$REPO"/build-artifacts/*/PlayTools.framework 2>/dev/null | head -1)}"
TS=$(date +%Y%m%d-%H%M%S)

[ -d "$SRC" ] || { echo "找不到 PlayTools.framework：$SRC" >&2; exit 1; }
if pgrep -f "$APP/Contents/MacOS" >/dev/null || pgrep -x KiHan >/dev/null; then
    echo "请先退出 PlayCover 和游戏" >&2; exit 1
fi

WORK=$(mktemp -d)
ditto "$SRC" "$WORK/PlayTools.framework"
FW="$WORK/PlayTools.framework"
# Xcode 26 编出的产物依赖这个兼容库，系统和游戏里都没有，放进框架内部
mkdir -p "$FW/Versions/A/Frameworks"
cp "$APP/Contents/Frameworks/libswiftCompatibilitySpan.dylib" "$FW/Versions/A/Frameworks/"
codesign --force --sign - "$FW/Versions/A/PlugIns/AKInterface.bundle"
codesign --force --sign - "$FW"

ditto "$APP" "$REPO/backup/PlayCover.app-$TS"
mv "$APP/Contents/Frameworks/PlayTools.framework" "$HOME/.Trash/PlayCover-PlayTools-$TS"
ditto "$FW" "$APP/Contents/Frameworks/PlayTools.framework"
# 原签名的团队权限在本机签名下不可用，不保留
codesign --force --deep --sign - "$APP"

[ -d "$SYS_FW" ] && mv "$SYS_FW" "$HOME/.Trash/PlayTools.framework-$TS"
ditto "$FW" "$SYS_FW"
rm -r "$WORK"

codesign -v --deep --strict "$APP"
codesign -v --deep "$SYS_FW"
echo "已安装：$SRC"
echo "PlayCover.app 备份：$REPO/backup/PlayCover.app-$TS"
