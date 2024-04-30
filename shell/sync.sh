#!/bin/bash

# A�����ϵĶ��·��
source_paths=(
    "${HOME}/etc"
    "${HOME}/bin"
    "${HOME}/sbin"
    "${HOME}/lib"
    "${HOME}/print"
    "${HOME}/tomcat"
    "${HOME}/web"
    # ��Ӹ���·��...
)

# B�����ϵ����ӦĿ¼
destination_paths=(
    "userid@199.4.169.22:/app/userid/etc"
    "userid@199.4.169.22:/app/userid/bin"
    "userid@199.4.169.22:/app/userid/sbin"
    "userid@199.4.169.22:/app/userid/lib"
    "userid@199.4.169.22:/app/userid/print"
    "userid@199.4.169.22:/app/userid/tomcat"
    "userid@199.4.169.22:/app/userid/web"
    # ��Ӹ���·��...
)

# ����Ҫͬ�����ļ��б�
EXCLUDEFILE="${HOME}/etc/exclude.txt"
# ����rsync�Ĳ���
#RSYNC_OPTIONS="-avz --delete --exclude-from=${EXCLUDEFILE}"
RSYNC_OPTIONS="-avz --exclude-from=${EXCLUDEFILE}"
# ��־�ļ�
log_file="/app/userid/log/sync_log.txt"

date >> "$log_file"
# ����ÿ��·������ͬ��
for ((i=0; i<${#source_paths[@]}; i++)); do
    source_path="${source_paths[i]}"
    destination_path="${destination_paths[i]}"

    echo "Syncing $source_path to $destination_path..." >> "$log_file"

    # ʹ��rsync�������ͬ�����ų�����Ҫͬ�����ļ�
    rsync ${RSYNC_OPTIONS} "$source_path/" "$destination_path" >> "$log_file" 2>&1

    echo "Sync completed." >> "$log_file"
done

