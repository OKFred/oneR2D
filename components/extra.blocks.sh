#@description: 补充额外iptables规则（来自netstat -tnp）
#@author: Fred
#@datetime: 2026-06-30

extra_blocks() {
  # block api.miwifi.com
  iptables -I OUTPUT -d "220.181.104.239" -j REJECT
  iptables -I OUTPUT -d "220.181.106.182" -j REJECT
  iptables -I OUTPUT -d "106.120.178.57" -j REJECT
  iptables -I OUTPUT -d "106.38.242.1" -j REJECT
  
  # block stun.miwifi.com
  iptables -I OUTPUT -d "111.206.174.2" -j REJECT
  iptables -I OUTPUT -d "111.206.174.3" -j REJECT
}