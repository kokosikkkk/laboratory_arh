#!/bin/bash

DISK_NAME="vdisk.img"
MOUNT_POINT="/mnt/vdisk"
SIZE="1G"

create_disk(){
    sudo truncate -s "$SIZE" "$DISK_NAME"
    sudo mkfs.ext4 -q "$DISK_NAME"
    sudo mkdir -p "$MOUNT_POINT"
    sudo mount -o loop "$DISK_NAME" "$MOUNT_POINT" > /dev/null 2>&1

    echo "Виртуальный диск создан"
}

delete_disk(){
    if mount | grep -q "$MOUNT_POINT"; then
        sudo umount "$MOUNT_POINT"
        sudo rm $DISK_NAME
        echo "Виртуальный диск уничтожен"
        echo
    fi
}

make_files(){
    local count="$1"
    local size="$2"

    for i in $(seq 1 "$count"); do
        sudo dd if=/dev/zero of="$MOUNT_POINT/file$i.log" bs="$size" count=1 status=none
        sudo touch -d "$i days ago" "$MOUNT_POINT/file$i.log"
    done
    
}

test(){ # 70%
    NAME=$MOUNT_POINT
    OCCUPANCY_THRESHOLD="$1"
    COUNT_FILE="$2"
    SIZE_FILE="$3"

    echo "Тест запущен"
    
    create_disk 
    make_files "$COUNT_FILE" "$SIZE_FILE"
    
    sudo ./lab_file_2.sh "$NAME" "$OCCUPANCY_THRESHOLD"

    delete_disk
}

echo "ТЕСТ 1"
echo "=== Диск не переполнен ==="
test 20 1 1M

echo "ТЕСТ 2"
echo "=== Диск переполнен ==="
test 70 8 100M

echo "ТЕСТ 3"
echo "=== Памяти в диске хватает для архивации ==="
test 70 8 88M

echo "ТЕСТ 4"
echo "=== Введены некорректные данные ==="
test kkkkk 8 10M

