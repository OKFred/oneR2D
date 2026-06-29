#@description: 补充额外iptables规则（来自netstat -tnp）
#@author: Fred
#@datetime: 2026-06-30

extra_blocks() {
  iptables -I OUTPUT -d "120.133.85.220" -j REJECT
  iptables -I OUTPUT -d "220.181.104.239" -j REJECT
  iptables -I OUTPUT -d "106.120.178.57" -j REJECT
  iptables -I OUTPUT -d "220.181.106.182" -j REJECT
  iptables -L OUTPUT -d "106.38.242.1" -j REJECT
}