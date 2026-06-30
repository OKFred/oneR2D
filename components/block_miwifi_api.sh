#!/bin/sh
#@description: 屏蔽小米路由上报与额外规则整合版
#@author: Fred
#@datetime: 2026-06-30

# 解析指定域名的 IPv4 地址
_resolve_domain_ips() {
  local domain="$1"
  nslookup "$domain" 2>/dev/null | awk '/Address/ {print $NF}' | grep -v '127.0.0.1' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | tr '\n' ' '
}

# 解析并获取所有需要屏蔽的 IP（包括 api.miwifi.com, stun.miwifi.com, 消息推送 IP 和 GitHub CDN IP）
_get_all_target_ips() {
  local api_ips stun_ips push_ips github_ips
  
  # 解析 api.miwifi.com 与 stun.miwifi.com
  api_ips=$(_resolve_domain_ips "api.miwifi.com")
  stun_ips=$(_resolve_domain_ips "stun.miwifi.com")
  
  # 消息推送连接 IP (对应 6501/messagingagent 建立的连接)
  push_ips="120.133.85.220"
  
  # GitHub CDN 静态 IP (针对类似 cdn-185-199-110-133.github.com 等域名，其 IP 已经固定写在域名中，无需动态 DNS 解析)
  github_ips="185.199.108.133 185.199.109.133 185.199.110.133 185.199.111.133"
  
  # 合并、去重
  echo "$api_ips $stun_ips $push_ips $github_ips" | tr ' ' '\n' | sort -u | tr '\n' ' '
}

block_miwifi_api() {
  local dryrun=0
  if [ "$1" = "dryrun" ] || [ "$1" = "--dryrun" ] || [ "$DRYRUN" = "1" ]; then
    dryrun=1
    echo "=== DRYRUN 模式运行：仅显示将要执行的命令，不会修改 iptables ==="
  fi

  echo "开始配置 iptables 屏蔽小米路由上报及探测服务..."
  
  local ips
  ips=$(_get_all_target_ips)
  
  if [ -z "$(echo "$ips" | tr -d ' ')" ]; then
    echo "错误：未能解析到任何有效 IP 地址，配置中止。"
    return 1
  fi

  echo "获取到待屏蔽的完整 IP 列表: $ips"

  for ip in $ips; do
    [ -z "$ip" ] && continue
    echo "----------------------------------------"
    echo "处理 IP: $ip"
    
    # 检查并清理已有规则
    if iptables -L OUTPUT -n 2>/dev/null | grep -F -q "$ip"; then
      echo "检测到 IP $ip 已有 iptables 规则，准备清理..."
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
  iptables -L OUTPUT -n 2>/dev/null | grep -E "REJECT" || echo "暂无匹配的 REJECT 规则。"
}

# 打印生成的 iptables 规则，方便用户复制到 /etc/rc.local
show_block_rules() {
  echo "=================================================="
  echo " 提示：解析域名并生成适用于 /etc/rc.local 的命令："
  echo "=================================================="
  
  local api_ips stun_ips github_ips

  echo "# 1. 屏蔽 api.miwifi.com"
  api_ips=$(_resolve_domain_ips "api.miwifi.com")
  for ip in $api_ips; do
    [ -n "$ip" ] && echo "iptables -I OUTPUT -d $ip -j REJECT"
  done
  
  echo "# 2. 屏蔽 stun.miwifi.com"
  stun_ips=$(_resolve_domain_ips "stun.miwifi.com")
  for ip in $stun_ips; do
    [ -n "$ip" ] && echo "iptables -I OUTPUT -d $ip -j REJECT"
  done
  
  echo "# 3. 屏蔽消息推送长连接 (messagingagent)"
  echo "iptables -I OUTPUT -d 120.133.85.220 -j REJECT"
  
  echo "# 4. 屏蔽 GitHub CDN 域名 (类似 cdn-185-199-110-133.github.com)"
  github_ips="185.199.108.133 185.199.109.133 185.199.110.133 185.199.111.133"
  for ip in $github_ips; do
    [ -n "$ip" ] && echo "iptables -I OUTPUT -d $ip -j REJECT"
  done
  
  echo "=================================================="
}

# 如果是直接运行脚本而不是 source 引入，则调用函数
if [ "${0##*/}" = "block_miwifi_api.sh" ]; then
  if [ "$1" = "show" ] || [ "$1" = "list" ] || [ "$1" = "rules" ]; then
    show_block_rules
  else
    block_miwifi_api "$@"
  fi
fi
