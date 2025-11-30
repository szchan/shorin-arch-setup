#!/bin/bash

# ==============================================================================
# shorin-arch-setup Installer
# ==============================================================================

# 获取当前目录
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$BASE_DIR/scripts"

# 引入工具库以使用日志函数
source "$SCRIPTS_DIR/00-utils.sh"

# 检查 Root 权限
check_root

# 赋予所有脚本执行权限
chmod +x "$SCRIPTS_DIR"/*.sh

clear
echo -e "${BLUE}"
cat << "EOF"
   _____ __  __ ____  ____  _____ _   _ 
  / ____|  \/  |  _ \|  _ \|_   _| \ | |
 | (___ | \  / | |_) | |_) | | | |  \| |
  \___ \| |\/| |  _ <|  _ <  | | | . ` |
  ____) | |  | | |_) | |_) |_| |_| |\  |
 |_____/|_|  |_|____/|____/|_____|_| \_|
   Arch Linux Setup Script by Shorin
EOF
echo -e "${NC}"
log "欢迎使用自动化安装脚本。"
log "安装日志将输出到控制台。"
echo "----------------------------------------------------"

# 定义要运行的模块列表 (按顺序)
MODULES=(
    "01-base.sh"
)

# 循环执行模块
for module in "${MODULES[@]}"; do
    script_path="$SCRIPTS_DIR/$module"
    
    if [ -f "$script_path" ]; then
        # 执行脚本
        bash "$script_path"
        
        # 检查返回值，如果出错则中断
        if [ $? -ne 0 ]; then
            error "模块 $module 执行失败，安装中止！"
            exit 1
        fi
    else
        warn "找不到模块: $module"
    fi
done

echo "----------------------------------------------------"
success "所有选定的模块已执行完毕！"