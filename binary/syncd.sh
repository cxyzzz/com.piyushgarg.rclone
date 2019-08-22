#!/system/bin/env bash

### rclone environment
export LANG=en_US.UTF-8
export RCLONE_LOG_LEVEL=INFO
export RCLONE_LOG_FILE=/storage/emulated/0/rclone.log
export RCLONE_NO_UPDATE_MODTIME=true
export RCLONE_TRACK_RENAMES=true

# old file dated dir
#export RCLONE_BACKUP_DIR="love:/archive/$(date +%Y)/$(date +%F_%R)"

# old file dataed file name
export RCLONE_BACKUP_DIR="love:/old_files"
export RCLONE_SUFFIX="_$(date +%F_%R)"
export RCLONE_SUFFIX_KEEP_EXTENSION=true


MODDIR=${0%/*}
TMPDIR=${MODDIR}/.tmp
SYNC_PENDING=${TMPDIR}/${remote}.syncd-pend

dump_battery () {

    BATTERY_DUMP="$(dumpsys battery)"

}

battery_level () {

    echo "${BATTERY_DUMP}" |grep level |cut -d ':' -f2 |cut -d ' ' -f2

}

ac_charge () {

    echo "${BATTERY_DUMP}" |grep -w "AC powered" |cut -d ":" -f2 |cut -d " " -f2

}

usb_charge () {

    echo "${BATTERY_DUMP}" |grep -w "USB powered" |cut -d ":" -f2 |cut -d " " -f2
    
}

echo $$ >> ${PIDFILE}

while true; do

    if [[ ! -e ${SYNC_PENDING} ]]; then

        ${HOME}/inotifywait "/storage/emulated/${PROFILE}/${SYNCDIR}" -e modify,create,moved_to,close_write -q >> /dev/null 2>&1

    fi

    touch ${SYNC_PENDING}

    while true; do

        sleep 5

        dump_battery

        if [[ $(battery_level) -gt ${SYNC_BATTLVL} ]] || [[ $(bettery_level) -eq ${SYNC_BATTLVL} ]] || [[ $(ac_charge) = true ]] || [[ $(usb_charge) = true ]]; then

            echo "Sync battery check success"

        else

            sleep 300
            continue

        fi

        if [[ ${SYNCWIFI} = 1 ]]; then

            if ! ping -I wlan0 -c 1 ${NETCHK_ADDR} >> /dev/null 2>&1; then

                echo "Sync wifi check fail"
                sleep 300
                continue

            else 

                echo "Sync wifi check success"

            fi

        fi

    break

done

echo "Syncing..."

nice -n 19 ionice -c 2 -n 7 ${HOME}/rclone sync "/storage/emulated/${PROFILE}/${SYNCDIR}" "$CLOUDROOTMOUNTPOINT/${remote}/${SYNCDIR}" --retries-sleep=10m --retries 6 --transfers 1 --multi-thread-streams 1 >> /dev/null 2>&1

if [[ -e ${SYNC_PENDING} ]]; then

    rm ${SYNC_PENDING}

fi

echo "Sync finished!"

done
