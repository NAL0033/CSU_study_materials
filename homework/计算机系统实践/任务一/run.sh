#!/bin/bash
# ============================================================
# run.sh — MIPS 计算器 Linux 启动脚本
# 用法: ./run.sh [Mars.jar 路径]
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAIN_FILE="$SCRIPT_DIR/main.asm"

# ---- 查找 Mars.jar ----
if [ -n "$1" ]; then
    MARS_JAR="$1"
elif [ -f "$SCRIPT_DIR/Mars.jar" ]; then
    MARS_JAR="$SCRIPT_DIR/Mars.jar"
elif [ -f "$SCRIPT_DIR/Mars4_5.jar" ]; then
    MARS_JAR="$SCRIPT_DIR/Mars4_5.jar"
elif command -v mars &>/dev/null; then
    MARS_JAR="mars"
else
    # 尝试常见路径
    for jar in Mars.jar Mars4_5.jar Mars_4_5.jar; do
        if [ -f "$HOME/$jar" ]; then
            MARS_JAR="$HOME/$jar"
            break
        fi
    done
fi

if [ -z "$MARS_JAR" ]; then
    echo "错误: 找不到 Mars.jar！"
    echo "请将 Mars.jar 放到项目目录，或指定路径："
    echo "  ./run.sh /path/to/Mars.jar"
    echo ""
    echo "MARS 下载地址: https://courses.missouristate.edu/KenVollmar/MARS/"
    exit 1
fi

# ---- 检查 Java ----
if ! command -v java &>/dev/null; then
    echo "错误: 未找到 Java 运行环境，请安装 JRE 8+"
    exit 1
fi

# ---- 检查主文件 ----
if [ ! -f "$MAIN_FILE" ]; then
    echo "错误: 找不到 $MAIN_FILE"
    exit 1
fi

# ---- 运行 MARS ----
echo "启动 MIPS 计算器..."
echo "主文件: $MAIN_FILE"
echo "Mars JAR: $MARS_JAR"
echo ""

java -jar "$MARS_JAR" "$MAIN_FILE"
