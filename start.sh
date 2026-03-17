#!/bin/bash

# CodePilot 后台启动脚本

APP_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="$APP_DIR/app.log"
PID_FILE="$APP_DIR/app.pid"

# 显示菜单
show_menu() {
  clear
  echo "========================================"
  echo "      CodePilot 管理菜单"
  echo "========================================"
  echo ""
  
  # 检查状态
  if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "  当前状态: 运行中 (PID: $(cat "$PID_FILE"))"
  else
    echo "  当前状态: 未运行"
  fi
  
  echo ""
  echo "  [1] 启动服务"
  echo "  [2] 停止服务"
  echo "  [3] 重启服务"
  echo "  [4] 查看实时日志"
  echo "  [5] 查看状态"
  echo "  [6] 查看日志 (最后50行)"
  echo "  [0] 退出"
  echo ""
  echo "========================================"
}

# 启动服务
do_start() {
  if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "服务已在运行 (PID: $(cat "$PID_FILE"))"
    return
  fi
  
  cd "$APP_DIR" || exit 1
  nohup npm run start > "$LOG_FILE" 2>&1 &
  echo $! > "$PID_FILE"
  echo "启动成功，PID: $!"
}

# 停止服务
do_stop() {
  # 先尝试停止 PID 文件中的进程
  if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
      kill "$PID" 2>/dev/null
      sleep 1
      # 如果进程还在，强制杀掉
      if kill -0 "$PID" 2>/dev/null; then
        kill -9 "$PID" 2>/dev/null
      fi
      echo "已停止 (PID: $PID)"
    else
      echo "进程不存在"
    fi
    rm -f "$PID_FILE"
  else
    echo "服务未运行"
  fi
  
  # 强制清理占用端口 3000 的进程
  if ss -tlnp 2>/dev/null | grep -q ":3000 "; then
    echo "清理残留进程..."
    fuser -k 3000/tcp 2>/dev/null
    sleep 1
    # 再次强制清理
    lsof -ti:3000 | xargs -r kill -9 2>/dev/null
  fi
}

# 查看状态
do_status() {
  if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "运行中 (PID: $(cat "$PID_FILE"))"
  else
    echo "未运行"
  fi
}

# 查看日志
do_log() {
  tail -f "$LOG_FILE"
}

# 菜单模式
menu_mode() {
  while true; do
    show_menu
    read -p "请选择操作 [0-6]: " choice
    
    case $choice in
      1)
        echo ""
        do_start
        read -p "按回车键继续..."
        ;;
      2)
        echo ""
        do_stop
        read -p "按回车键继续..."
        ;;
      3)
        echo ""
        do_stop
        sleep 1
        do_start
        read -p "按回车键继续..."
        ;;
      4)
        echo ""
        echo "按 Ctrl+C 退出日志查看"
        do_log
        ;;
      5)
        echo ""
        do_status
        read -p "按回车键继续..."
        ;;
      6)
        echo ""
        if [ -f "$LOG_FILE" ]; then
          tail -n 50 "$LOG_FILE"
        else
          echo "暂无日志文件"
        fi
        read -p "按回车键继续..."
        ;;
      0)
        echo ""
        echo "再见！"
        exit 0
        ;;
      *)
        echo ""
        echo "无效选项"
        read -p "按回车键继续..."
        ;;
    esac
  done
}

# 命令行模式
case "${1:-menu}" in
  start)
    do_start
    ;;
  stop)
    do_stop
    ;;
  restart)
    do_stop
    sleep 1
    do_start
    ;;
  status)
    do_status
    ;;
  log)
    do_log
    ;;
  menu)
    menu_mode
    ;;
  *)
    echo "用法: $0 {start|stop|restart|status|log|menu}"
    echo ""
    echo "  start  - 后台启动服务"
    echo "  stop   - 停止服务"
    echo "  restart- 重启服务"
    echo "  status - 查看运行状态"
    echo "  log    - 查看实时日志"
    echo "  menu   - 显示交互菜单（默认）"
    ;;
esac
