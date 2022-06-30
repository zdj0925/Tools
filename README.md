# Tools
my perl test tools .
ConntionsTools   ---ssh telnet 连接工具
FIXTools         ---报文发送工具
OracleEXP2SQL    ---oracle 导出数据的insert 语句
perl             ---杂七杂八的东西
.
├── ConntionsTools                  ---ssh telnet 连接工具
│   ├── con                        --不支持隐藏密码
│   ├── hashcon                    --可以隐藏列表密码
│   └── .ssh-c                     --连接配置文件
├── FIXTools
│   ├── batch_fix_sender.pl        --批量串行发送fix报文工具
│   ├── fix                        --报文配置文件
│   │   ├── 10001.mfix
│   │   ├── 10012.fix
│   │   ├── ch.sh
│   │   ├── data                  --批量发送需要的数据文件
│   │   │   └── data.dat
│   │   └── template.mfix
│   └── fix_sender.pl              --单个fix报文发送脚本
├── openwrt-lua                     --gundip2客户端更新动态IP到二级域名支持tcp、http
│   ├── gnudip_https.conf
│   ├── gnudip_https.conf.bak
│   ├── gnudip_https.lua
│   ├── gnudip_tcp.conf
│   ├── gnudip_tcp.conf.bak
│   └── gnudip_tcps.lua
├── OracleEXP2SQL
│   ├── list.txt
│   └── pd2sql.pl
├── perl
│   ├── adjust_feeacct
│   ├── available_drivers.pl
│   ├── base64.pl
│   ├── check.pl
│   ├── OraConn.pl
│   ├── rand_test.pl
│   └── test.pl
└── README.md

30 directories, 62 files
