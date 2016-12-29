---
layout: post
title: 管理服务
---

列出所有服务：

{% highlight shell %}
[root@localhost ~]# systemctl list-units --type=service
  UNIT                               LOAD   ACTIVE SUB     DESCRIPTION
  auditd.service                     loaded active running Security Auditing Service
  crond.service                      loaded active running Command Scheduler
  dbus.service                       loaded active running D-Bus System Message Bus
  firewalld.service                  loaded active running firewalld - dynamic firewall daemon
  getty@tty1.service                 loaded active running Getty on tty1
● kdump.service                      loaded failed failed  Crash recovery kernel arming
  kmod-static-nodes.service          loaded active exited  Create list of required static device nodes for the curren
  lvm2-lvmetad.service               loaded active running LVM2 metadata daemon
  lvm2-monitor.service               loaded active exited  Monitoring of LVM2 mirrors, snapshots etc. using dmeventd 
  lvm2-pvscan@8:2.service            loaded active exited  LVM2 PV scan on device 8:2
  network.service                    loaded active exited  LSB: Bring up/down networking
  NetworkManager.service             loaded active running Network Manager
  polkit.service                     loaded active running Authorization Manager
  postfix.service                    loaded active running Postfix Mail Transport Agent
  rhel-dmesg.service                 loaded active exited  Dump dmesg to /var/log/dmesg
  rhel-import-state.service          loaded active exited  Import network configuration from initramfs
  rhel-readonly.service              loaded active exited  Configure read-only root support
  rsyslog.service                    loaded active running System Logging Service
  sshd.service                       loaded active running OpenSSH server daemon
  systemd-journal-flush.service      loaded active exited  Flush Journal to Persistent Storage
  systemd-journald.service           loaded active running Journal Service
  systemd-logind.service             loaded active running Login Service
  systemd-random-seed.service        loaded active exited  Load/Save Random Seed
  systemd-remount-fs.service         loaded active exited  Remount Root and Kernel File Systems
  systemd-sysctl.service             loaded active exited  Apply Kernel Variables
  systemd-tmpfiles-setup-dev.service loaded active exited  Create Static Device Nodes in /dev
  systemd-tmpfiles-setup.service     loaded active exited  Create Volatile Files and Directories
  systemd-udev-trigger.service       loaded active exited  udev Coldplug all Devices
  systemd-udevd.service              loaded active running udev Kernel Device Manager
  systemd-update-utmp.service        loaded active exited  Update UTMP about System Boot/Shutdown
  systemd-user-sessions.service      loaded active exited  Permit User Sessions
  systemd-vconsole-setup.service     loaded active exited  Setup Virtual Console
  tuned.service                      loaded active running Dynamic System Tuning Daemon
  wpa_supplicant.service             loaded active running WPA Supplicant daemon

LOAD   = Reflects whether the unit definition was properly loaded.
ACTIVE = The high-level unit activation state, i.e. generalization of SUB.
SUB    = The low-level unit activation state, values depend on unit type.

34 loaded units listed. Pass --all to see loaded but inactive units, too.
To show all installed unit files use 'systemctl list-unit-files'.
{% endhighlight %}

---

查询服务状态：

{% highlight shell %}
[root@localhost ~]# systemctl status crond.service
● crond.service - Command Scheduler
   Loaded: loaded (/usr/lib/systemd/system/crond.service; enabled; vendor preset: enabled)
   Active: active (running) since Thu 2016-12-29 09:22:00 HKT; 4h 8min ago
 Main PID: 884 (crond)
   CGroup: /system.slice/crond.service
           └─884 /usr/sbin/crond -n

Dec 29 09:22:00 localhost.localdomain systemd[1]: Started Command Scheduler.
Dec 29 09:22:00 localhost.localdomain systemd[1]: Starting Command Scheduler...
Dec 29 09:22:00 localhost.localdomain crond[884]: (CRON) INFO (RANDOM_DELAY will be scaled with factor 52% if used.)
Dec 29 09:22:00 localhost.localdomain crond[884]: (CRON) INFO (running with inotify support)
Hint: Some lines were ellipsized, use -l to show in full.
{% endhighlight %}

---

启动或停止服务：

{% highlight shell %}
[root@localhost ~]# systemctl [start|stop|reload|restart] crond.service
{% endhighlight %}

---

设置服务开机启用或禁用：

{% highlight shell %}
[root@localhost ~]# systemctl [enable|disable] crond.service
{% endhighlight %}

---

查看服务文件：

{% highlight shell %}
[root@localhost ~]# systemctl cat crond.service
# /usr/lib/systemd/system/crond.service
[Unit]
Description=Command Scheduler
After=auditd.service systemd-user-sessions.service time-sync.target

[Service]
EnvironmentFile=/etc/sysconfig/crond
ExecStart=/usr/sbin/crond -n $CRONDARGS
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process

[Install]
WantedBy=multi-user.target
{% endhighlight %}
---

查询服务依赖：

{% highlight shell %}
[root@localhost ~]# systemctl list-dependencies crond.service
crond.service
● ├─system.slice
● └─basic.target
●   ├─firewalld.service
●   ├─microcode.service
●   ├─rhel-autorelabel-mark.service
●   ├─rhel-autorelabel.service
●   ├─rhel-configure.service
●   ├─rhel-dmesg.service
●   ├─rhel-loadmodules.service
●   ├─paths.target
●   ├─slices.target
●   │ ├─-.slice
●   │ └─system.slice
●   ├─sockets.target
●   │ ├─dbus.socket
●   │ ├─dm-event.socket
●   │ ├─systemd-initctl.socket
●   │ ├─systemd-journald.socket
●   │ ├─systemd-shutdownd.socket
●   │ ├─systemd-udevd-control.socket
●   │ └─systemd-udevd-kernel.socket
●   ├─sysinit.target
●   │ ├─dev-hugepages.mount
●   │ ├─dev-mqueue.mount
●   │ ├─kmod-static-nodes.service
●   │ ├─ldconfig.service
●   │ ├─lvm2-lvmetad.socket
●   │ ├─lvm2-lvmpolld.socket
●   │ ├─lvm2-monitor.service
●   │ ├─plymouth-read-write.service
●   │ ├─plymouth-start.service
●   │ ├─proc-sys-fs-binfmt_misc.automount
●   │ ├─sys-fs-fuse-connections.mount
●   │ ├─sys-kernel-config.mount
●   │ ├─sys-kernel-debug.mount
●   │ ├─systemd-ask-password-console.path
●   │ ├─systemd-binfmt.service
●   │ ├─systemd-firstboot.service
●   │ ├─systemd-hwdb-update.service
●   │ ├─systemd-journal-catalog-update.service
●   │ ├─systemd-journal-flush.service
●   │ ├─systemd-journald.service
●   │ ├─systemd-machine-id-commit.service
●   │ ├─systemd-modules-load.service
●   │ ├─systemd-random-seed.service
●   │ ├─systemd-sysctl.service
●   │ ├─systemd-tmpfiles-setup-dev.service
●   │ ├─systemd-tmpfiles-setup.service
●   │ ├─systemd-udev-trigger.service
●   │ ├─systemd-udevd.service
●   │ ├─systemd-update-done.service
●   │ ├─systemd-update-utmp.service
●   │ ├─systemd-vconsole-setup.service
●   │ ├─cryptsetup.target
●   │ ├─local-fs.target
●   │ │ ├─-.mount
●   │ │ ├─boot.mount
●   │ │ ├─rhel-import-state.service
●   │ │ ├─rhel-readonly.service
●   │ │ └─systemd-remount-fs.service
●   │ └─swap.target
●   │   └─dev-mapper-centos\x2dswap.swap
●   └─timers.target
●     └─systemd-tmpfiles-clean.timer
{% endhighlight %}
