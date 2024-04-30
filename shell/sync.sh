#!/bin/bash

# A机器上的多个路径
source_paths=(
    "${HOME}/etc"
    "${HOME}/bin"
    "${HOME}/sbin"
    "${HOME}/lib"
    "${HOME}/print"
    "${HOME}/tomcat"
    "${HOME}/web"
    # 添加更多路径...
)

# B机器上的相对应目录
destination_paths=(
    "userid@199.4.169.22:/app/userid/etc"
    "userid@199.4.169.22:/app/userid/bin"
    "userid@199.4.169.22:/app/userid/sbin"
    "userid@199.4.169.22:/app/userid/lib"
    "userid@199.4.169.22:/app/userid/print"
    "userid@199.4.169.22:/app/userid/tomcat"
    "userid@199.4.169.22:/app/userid/web"
    # 添加更多路径...
)

# 不需要同步的文件列表
EXCLUDEFILE="${HOME}/etc/exclude.txt"
# 设置rsync的参数
#RSYNC_OPTIONS="-avz --delete --exclude-from=${EXCLUDEFILE}"
RSYNC_OPTIONS="-avz --exclude-from=${EXCLUDEFILE}"
# 日志文件
log_file="/app/userid/log/sync_log.txt"

date >> "$log_file"
# 遍历每个路径进行同步
for ((i=0; i<${#source_paths[@]}; i++)); do
    source_path="${source_paths[i]}"
    destination_path="${destination_paths[i]}"

    echo "Syncing $source_path to $destination_path..." >> "$log_file"

    # 使用rsync命令进行同步，排除不需要同步的文件
    rsync ${RSYNC_OPTIONS} "$source_path/" "$destination_path" >> "$log_file" 2>&1

    echo "Sync completed." >> "$log_file"
done

