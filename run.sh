#!/bin/bash

# 当前脚本目录
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
echo "当前脚本目录: $SCRIPT_DIR"

# 如果当前目录存在 venv 虚拟目录，则激活虚拟环境
if [ -d $SCRIPT_DIR/venv ]; then
    source $SCRIPT_DIR/venv/bin/activate
fi

# 应用名称
app_name="comfyui"

create_systemd_service() {
    cat <<EOF | sudo tee /etc/systemd/system/${app_name}.service
[Unit]
Description=${app_name}
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/docker/${app_name}
ExecStart=/opt/docker/${app_name}/run.sh start service
Restart=on-failure
User=$(whoami)

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
}

enable_launch_start() {
    create_systemd_service
    sudo systemctl enable ${app_name}.service
    echo "${app_name} 服务已设置为开机启动。"
}

disable_launch_start() {
    sudo systemctl disable ${app_name}.service
    echo "${app_name} 服务已禁用开机启动。"
}

# 检查 ${app_name} 是否已经启动
is_app_running() {
    pgrep -f "${app_name}/main.py" > /dev/null 2>&1 
}

start() {
    if is_app_running; then
        echo "${app_name} 已经启动，跳过启动步骤。"
    else
        pushd "$SCRIPT_DIR" || { echo "目录不存在"; exit 1; }
        echo "当前脚本目录: $SCRIPT_DIR"


        if [[ "$2" == "service" ]]; then
            echo "启动 ${app_name}.service..."
            source "$SCRIPT_DIR/venv/bin/activate" || { echo "激活虚拟环境失败"; exit 1; }
            exec "$SCRIPT_DIR/venv/bin/python" "$SCRIPT_DIR/main.py" > ${app_name}.log 2>&1
            # while is_app_running; do
            #     sleep 1
            # done
        else
            nohup ./${app_name}.sh > ${app_name}.log 2>&1 &
        fi
        echo "${app_name} 启动中..."
        popd  # 返回原始目录
    fi
}

stop() {
    if is_app_running; then
        echo "停止 ${app_name} ..."
        pkill -f "${app_name}.sh"
        pkill -f "${app_name}"
        echo "${app_name}.sh 已停止。"
    else
        echo "${app_name} 未运行，无需停止。"
    fi
}

restart() {
    stop
    start
}

status() {
    if is_app_running; then
        echo "${app_name} 正在运行。"
    else
        echo "${app_name} 未运行。"
    fi
}

# 获取输入参数，默认是 start
ACTION="${1:-start}"


# 根据输入参数执行相应的操作
case $ACTION in
    start)
        start "$@"
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    enable_launch_start)
        enable_launch_start
        ;;
    disable_launch_start)
        disable_launch_start
        ;;
    *)
        echo "无效的参数: $1"
        echo "使用方法: $0 [start|stop|restart|status|enable_launch_start|disable_launch_start]"
        exit 1
        ;;
esac

