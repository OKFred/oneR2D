#!/bin/sh
#@description: 菜单化显示工具箱列表
#@author: Fred Zhang Qi
#@datetime: 2023-12-26

#文件依赖
#⚠️import--需要引入包含函数的文件
source ./components/the_usb_mount.sh

menu_title() {
  #clear
  date
  echo "执行需要管理员权限。请注意"
  echo "*********************"
  echo "*****   工具箱   *****"
}

menu_back() {
  echo
  echo -n "按任意键返回."
  read
}

main() {
  while (true); do
    menu_title
    echo "01. 配置SSH访问"
    echo "02. 安装基础工具[米盒子]等"
    echo "03. 挂载U盘"
    echo "08. 更多"
    echo "09. 关于"
    echo "00. 退出"
    echo
    echo -n "请输入你的选择："
    read the_user_choice
    case "$the_user_choice" in
    01 | 1) echo "不然这脚本是怎么运行的？" ;;
    02 | 2) echo "自己网上搜资源" ;;
    03 | 3) the_usb_mount ;;
    08 | 8) echo '敬请期待' ;;
    09 | 9) nano readme.md ;;
    00 | 0) exit 1 ;;
    u) echo "???" ;;
    *) echo "输入有误，请重新输入！" && menu_back ;;
    esac
    echo
  done
}

clear
main
