#!/bin/sh
#@description: 屏蔽小米路由API上报
#@author: Fred
#@datetime: 2026-06-29

block_miwifi_api() {
  local dryrun=0
  if [ "$1" = "dryrun" ] || [ "$1" = "--dryrun" ] || [ "$DRYRUN" = "1" ]; then
    dryrun=1
    echo "=== DRYRUN 模式运行：仅显示将要执行的命令，不会修改 iptables ==="
  fi

  echo "开始配置 iptables 屏蔽 api.miwifi.com..."
  
  # 待屏蔽的 IP 列表，包含 todo.md 中的静态 IP 及样例 IP
  local static_ips="106.120.178.57 220.181.104.239 220.181.106.182 106.38.242.1 203.0.113.10"
  local ips=""

  # 尝试动态解析域名
  echo "正在解析 api.miwifi.com..."
  local dynamic_ips
  dynamic_ips=$(nslookup api.miwifi.com 2>/dev/null | awk '/Address/ {print $NF}' | grep -v '127.0.0.1' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')
  
  if [ -n "$dynamic_ips" ]; then
    # 合并动态解析 of IP，并去重
    ips=$(echo "$static_ips $dynamic_ips" | tr ' ' '\n' | sort -u | tr '\n' ' ')
    echo "获取到动态 IP，合并后待处理的 IP 列表: $ips"
  else
    ips="$static_ips"
    echo "域名解析失败或未返回有效IPv4，使用静态备用 IP 列表: $ips"
  fi

  for ip in $ips; do
    [ -z "$ip" ] && continue
    echo "----------------------------------------"
    echo "处理 IP: $ip"
    
    # 检查是否已存在相关的 iptables 规则
    if iptables -L OUTPUT -n 2>/dev/null | grep -F -q "$ip"; then
      echo "检测到 IP $ip 已有 iptables 规则，准备清理..."
      # 循环删除所有重复的规则，防止多次添加产生冗余
      if [ "$dryrun" -eq 1 ]; then
        echo "[DRYRUN] 将执行：循环删除该 IP 的 iptables 规则"
      else
        while iptables -D OUTPUT -d "$ip" -j REJECT 2>/dev/null; do
          :
        done
        echo "清理完成。"
      fi
    fi

    # 添加新的拒绝规则
    if [ "$dryrun" -eq 1 ]; then
      echo "[DRYRUN] 将执行：iptables -I OUTPUT -d $ip -j REJECT"
    else
      echo "正在添加规则拒绝发送到 $ip"
      if iptables -I OUTPUT -d "$ip" -j REJECT; then
        echo "成功添加拒绝 $ip 的规则。"
      else
        echo "添加拒绝 $ip 的规则失败，请确保具有 root 权限。"
      fi
    fi
  done

  echo "----------------------------------------"
  echo "iptables 规则配置完成！当前 OUTPUT 链中屏蔽规则如下："
  if [ "$dryrun" -eq 1 ]; then
    echo "[DRYRUN] 模式下，当前规则未发生改变："
  fi
  iptables -L OUTPUT -n 2>/dev/null | grep -E "REJECT" || echo "暂无匹配的 REJECT 规则（可能未以 root 权限运行或尚无规则）。"
}

# 如果是直接运行脚本而不是 source 引入，则调用函数
if [ "${0##*/}" = "block_miwifi_api.sh" ]; then
  block_miwifi_api "$@"
fi
