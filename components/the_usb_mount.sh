#!/bin/sh
#@description:  U盘挂载：
#@author: Fred Zhang Qi
#@datetime: 2023-12-26

#dependencies--文件依赖
# none
my_usb_mount_path="/userdisk/data/TDDOWNLOAD/usb"
my_usb_mount_script=$my_usb_mount_path"/mountUSBtoSSD"

the_usb_mount() {
  echo "尝试开启读写权限"
  mount -o remount rw /
  echo "检查权限"
  if [ ! -w "/etc/rc.local" ]; then
    echo "权限不足，无法写入"
    exit 1
  fi
  echo "检查/dev/sdb1是否存在"
  if [ ! -e "/dev/sdb1" ]; then
    echo "U盘可能未插入"
    exit 1
  fi
  echo "创建挂载目录"
  mkdir -p $my_usb_mount_path
  echo "创建提示信息"
  echo "### 这是U盘挂载目录，不要删除" >$my_usb_mount_path"/readme.md"
  echo "### 这是U盘挂载目录，不要删除" >$my_usb_mount_path"/failed-to-mount-if-you-see-this"
  echo "创建挂载脚本"
  echo "#!/bin/sh /etc/rc.common

START=99
STOP=20
echo "good job";
sleep 10
mount /dev/sdb1 $my_usb_mount_path" >$my_usb_mount_script
  chmod 777 $my_usb_mount_script
  echo -p "是否需要开机自动挂载？(y/n)" need_auto_mount
  if [ $need_auto_mount == "y" ]; then
    echo "开机自动挂载"
    echo "# restore phy config
speed=\$(uci -q get xiaoqiang.common.WAN_SPEED)
[ -n \"\$speed\" ] && /usr/sbin/phyhelper swan \"\$speed\"

date
echo \"挂载usb\"
sh $my_usb_mount_script

exit 0" >/etc/rc.local
  else
    echo "不需要开机自动挂载。那就运行一次"
    sh $my_usb_mount_script
  fi
  echo "挂载完成，检查是否成功"
  echo $(df -h | grep $my_usb_mount_path)
  echo $(mount | grep $my_usb_mount_path)
  ls -la $my_usb_mount_path
}
