#!/bin/sh
#@description: 补充额外iptables规则（来自netstat -tnp）
#@author: Fred
#@datetime: 2026-06-30

extra_blocks() {
  echo "开始配置额外 iptables 屏蔽规则..."
  
  # 1. 动态解析并屏蔽 stun.miwifi.com (NAT 穿透探测服务器)
  echo "正在解析 stun.miwifi.com..."
  local stun_ips
  stun_ips=$(nslookup stun.miwifi.com 2>/dev/null | awk '/Address/ {print $NF}' | grep -v '127.0.0.1' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')
  
  # 2. 屏蔽小米云端推送/长连接 IP (对应 6501/messagingagent 建立的 120.133.85.220:1886 连接)
  # ⚠️警告：屏蔽此 IP 后，手机端小米路由 App 的“远程管理”和“状态通知推送”将会失效。
  local push_ips="120.133.85.220"

  local target_ips=$(echo "$stun_ips $push_ips" | tr ' ' '\n' | sort -u | tr '\n' ' ')
  echo "合并后待处理的额外 IP 列表: $target_ips"

  for ip in $target_ips; do
    [ -z "$ip" ] && continue
    echo "----------------------------------------"
    echo "处理 IP: $ip"
    
    # 检查并清理已有规则
    if iptables -L OUTPUT -n 2>/dev/null | grep -F -q "$ip"; then
      echo "检测到 IP $ip 已有 iptables 规则，准备清理..."
      while iptables -D OUTPUT -d "$ip" -j REJECT 2>/dev/null; do
        :
      done
      echo "清理完成。"
    fi

    # 添加新的拒绝规则
    echo "正在添加规则拒绝发送到 $ip"
    if iptables -I OUTPUT -d "$ip" -j REJECT; then
      echo "成功添加拒绝 $ip 的规则。"
    else
      echo "添加拒绝 $ip 的规则失败，请确保具有 root 权限。"
    fi
  done

  echo "----------------------------------------"
  echo "额外规则配置完成！当前 OUTPUT 链中屏蔽规则如下："
  iptables -L OUTPUT -n 2>/dev/null | grep -E "REJECT" || echo "暂无匹配的 REJECT 规则。"
}