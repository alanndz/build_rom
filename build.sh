#!/usr/bin/env bash
#
# Copyright (C) 2019 @alanndz (Telegram and Github)
# SPDX-License-Identifier: GPL-3.0-or-later
#
#

DEVICE="lavender"
CDIR=$PWD

DATELOG=$(date "+%H%M-%d%m%Y")
BUILDLOG="$CDIR/out/KomodOS-${DEVICE}-$DATELOG.log"

export USER_MEGA
export PASS_MEGA

# Make It OFFICIAL
export KOMODO_BUILD_TYPE=OFFICIAL

# Clone Device Tree, Kernel, and Vendor
git clone --depth=1 -b pie https://github.com/alanndz/device_xiaomi_lavender device/xiaomi/lavender
git clone --depth=1 -b aosp-eas-inline https://github.com/alanndz/kernel_xiaomi_lavender kernel/xiaomi/lavender
git clone --depth=1 https://github.com/alanndz/vendor_xiaomi_lavender vendor/xiaomi/lavender

# Telegram Function
export BOT_API_KEY
CHANNEL_ID=$(openssl enc -base64 -d <<< LTEwMDEzMDIxNzg3NjcK)
LOG_ID=$(openssl enc -base64 -d <<< LTEwMDEzNzM5MjM3ODIK)

function sendInfo() {
    curl -s -X POST https://api.telegram.org/bot$BOT_API_KEY/sendMessage -d chat_id=$CHANNEL_ID -d "parse_mode=HTML" -d text="$(
            for POST in "${@}"; do
                echo "${POST}"
            done
        )" 
&>/dev/null
}

function sendLog() {
	curl -F chat_id=$LOG_ID -F document=@"$BUILDLOG" https://api.telegram.org/bot$BOT_API_KEY/sendDocument &>/dev/null
}

#####

function sendRom() {
    cd out
    FILEPATH=$(find -iname "KomodOS-*-${DEVICE}-${KOMODO_BUILD_TYPE}-*.zip)
    if [[ ! -f FILEPATH ]]; then
        sendInfo "Build Failed, See log"
        sendInfo "Total time elapsed: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
        sendLog
        exit 1
    fi
    megaput -u $USER_NAME -p $(openssl enc -base64 -d <<< $PASS_MEGA) $FILEPATH
    cd $CDIR
}

BUILD_START=$(date +"%s")
DATE=`date`

sendInfo "Starting Build KomodOS ROM" \
    "<b>Device:</b> <code>${DEVICE}</code>" \
    "<b>Started at</b> <code>$DATE</code>"

function start() {
    . build/envsetup.sh
    lunch komodo_"${DEVICE}"-userdebug
    mka bacon komodo
}

start 2>&1 | tee "${BUILDLOG}"

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))

sendRom
sendLog
sendInfo "Total time elapsed: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
