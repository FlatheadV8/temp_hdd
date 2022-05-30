#!/bin/sh
#
# https://github.com/cytopia/freebsd-tools/blob/master/hdd-temp.sh
#
# ----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42):
# <cytopia@everythingcli.org> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return cytopia
# ----------------------------------------------------------------------------

#VERSION="v2018040800"          # aus dem Internet kopiert
#VERSION="v2022051100"          # modifiziert; jetzt auch mit Seriennummer
VERSION="v2022052900"           # bei Kabelfehler jetzt MAGENTA, bei SMART-Fehler jetzt RED

DEFEKTE_HDDS="$(dmesg | grep -Fi error | awk -F: '{sub("[(]",""); print $1}' | sort | uniq)"

### Grenzwerte
#
#ROT="40"       # Originalwert
ROT="45"        # meine Erfahrung
#
#GELB="30"      # Originalwert
GELB="42"       # meine Erfahrung

# ---------------------------------- Global Variables --------------------------------- #
# Colors => https://misc.flogisoft.com/bash/tip_colors_and_formatting

OFF="\033[0m"
BLACK='\033[30m'
RED='\033[31m'          # HDD ist defekt, austauschen!
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
MAGENTA='\033[35m'      # HDD ist OK, vielleicht defekte Kabel?
CYAN='\033[36m'
LIGHT_GRAY='\033[37m'
DARK_GRAY='\033[90m'
LIGHT_RED='\033[91m'
LIGHT_GREEN='\033[92m'
LIGHT_YELLOW='\033[93m'
LIGHT_BLUE='\033[94m'
LIGHT_MAGENTA='\033[95m'
LIGHT_CYAN='\033[96m'
WHITE='\033[97m'

# ---------------------------------- Misc Function ---------------------------------- #

#
# Prequisites,
#  * check if this script is run by root
#  * check if smartctl is installed
#
check_requirements()
{
        # Check if we are root
        if [ "$(id -u)" != "0" ]; then
                echo "This script must be run as root" 1>&2
                exit 1
        fi

        # Check if smartctl exists on the system
        command -v smartctl >/dev/null  || { echo "smartctl not found. (install sysutils/smartmontools)"; exit 1; }
}


#
# Colorize output of temperature (all platforms)
#
colorize_temperature()
{
        TEMP="${1}"

        case "${TEMP}" in
                # no temperature obtained
                ''|*[!0-9]*)
                        TEMP="n.a."
                        ;;
                # temperature is obtained
                *)
                        if [ "${TEMP}" -gt "${ROT}" ]; then
                                TEMP="${RED}${TEMP}° C${OFF}"
                        elif [ "${TEMP}" -gt "${GELB}" ]; then
                                TEMP="${YELLOW}${TEMP}° C${OFF}"
                        else
                                TEMP="${GREEN}${TEMP}° C${OFF}"
                        fi
                        ;;
        esac

        echo "${TEMP}"
}

# ---------------------------------- Generic Disk Function ---------------------------------- #

#
# Get all devices that are attached to the system
#
get_attached_devices()
{
        DEVS="$(sysctl kern.disks | awk '{$1=""; ;print $0}' | awk 'gsub(" ", "\n")' | tail -n500 -r | sed '/^cd[0-9]/d')"
        echo "${DEVS}"
}

get_disk_bus()
{
        DEV="${1}"
        BUS="$(cat /var/run/dmesg.boot | grep -F "${DEV} at" | grep -F target | awk '{print $3}' | tail -n1)"
        echo "${BUS}"
}

get_disk_size()
{
        DEV="${1}"
        SIZE="$(diskinfo -v /dev/${DEV} | grep -F bytes | awk '{printf "%8.2f\n",($1/(1024*1024*1024))}')"
        echo "${SIZE}"
}

get_disk_speed()
{
        DEV="${1}"
        SPEED="$(cat /var/run/dmesg.boot | grep -F ${DEV}: | grep -F transfers | awk '{print $2};' | tail -n1)"
        echo "${SPEED}"
}

get_disk_number()
{
        DEV="${1}"
        DISK_NUM="$(echo "${DEV}" | sed 's/[^0-9]*//g')"
        echo "${DISK_NUM}"
}


# ---------------------------------- ATA-Device Functions ---------------------------------- #

get_ata_disk_name()
{
        DEV="${1}"
        NAME="$(cat /var/run/dmesg.boot | grep -F "${DEV}:" | grep -E '[<>]' | awk -F '[<>]' '{print $2}' | tail -n1)"
        echo "${NAME}"
}

get_ata_disk_temp()
{
        DEV="${1}"
        TEMP="$(smartctl -d atacam -A "/dev/${DEV}" | grep -F Temperature_Celsius | awk '{print $10}')"
        echo "${TEMP}"
}

# ---------------------------------- CISS-Device Functions ---------------------------------- #

get_ciss_disk_name()
{
        SMART_CTL="${1}"
        NAME="$(echo "${SMART_CTL}" | grep -F "Device Model" | awk '{$1=$2=""} {sub(/^[ \t]+/, ""); print;}')"
        FIRM="$(echo "${SMART_CTL}" | grep -F "Firmware" | awk ' {$1=$2=""} {sub(/^[ \t]+/, ""); print;}')"
        echo "${NAME} ${FIRM}"
}

get_ciss_disk_temp()
{
        SMART_CTL="${1}"
        TEMP="$(echo "${SMART_CTL}" | grep -F Temperature_Celsius | awk '{print $10}')"
        echo "${TEMP}"
}

# ---------------------------------- Main Entry Point ---------------------------------- #

# Check if script can be run
check_requirements


# Loop through all attached devices
for DEV in $(get_attached_devices)
do
        SIZE="$(get_disk_size ${DEV})"
        NVME="$(echo "${DEV}" | grep -F nvd | sed 's/^[a-z]*//g')"
        if [ "x${NVME}" = x ] ; then
                BUS="$(get_disk_bus ${DEV})"
                SPEED="$(get_disk_speed ${DEV})"
                SERIENNR="$(smartctl -i /dev/${DEV} | awk '/^Serial Number:[ ]*/{print $NF}' 2> /dev/null)"

                # check for HP Smart Array controllers
                if [ "${BUS}" == "ciss*" ]; then
                        DEVNUM="$(get_disk_number ${DEV})"
                        SMARTCTL="$(smartctl -a -T permissive -d cciss,${DEVNUM} /dev/${BUS} 2> /dev/null)"
                        NAME="$(get_ciss_disk_name "${SMARTCTL}")"      # preserve newlines by using "
                        TEMP="$(get_ciss_disk_temp "${SMARTCTL}")"
                        echo "smartctl -a -T permissive -d cciss,${DEVNUM} /dev/${BUS} 2> /dev/null"    # debug
                else
                        NAME="$(get_ata_disk_name ${DEV})"
                        TEMP="$(get_ata_disk_temp ${DEV})"
                fi

        else
                SMART_NVME="$(smartctl -a /dev/nvme${NVME} | grep -E '^Model Number:|^Serial Number:|^Namespace 1 Size/Capacity:|^Temperature:')"
                TEMP="$(echo "${SMART_NVME}" | grep -F 'Temperature:' | awk -F':' '{print $2}' | awk '{print $1}')"
                BUS="_______"
                SPEED="_______"
                SERIENNR="$(echo "${SMART_NVME}" | grep -F 'Serial Number:' | awk -F':' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')"
                NAME="$(echo "${SMART_NVME}" | grep -F 'Model Number:' | awk -F':' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//')"
        fi

        TEMP="$(colorize_temperature ${TEMP})"

        FEHLER_GEFUNDEN="$(smartctl -A /dev/${DEV} | grep -E '^[ ]*5[ ]|^[ ]*10[ ]|^[ ]*184[ ]|^[ ]*187[ ]|^[ ]*188[ ]|^[ ]*196[ ]|^[ ]*197[ ]|^[ ]*198[ ]|^[ ]*201[ ]' | grep -Ev '[ ]*0$')"
        if [ "x${FEHLER_GEFUNDEN}" = "x" ] ; then
                KAPUTT="$(echo "${DEFEKTE_HDDS}" | grep -E "^${DEV}$")"
                if [ "x${KAPUTT}" = x ] ; then
                        echo -e "${TEMP}, ${BUS}:${DEV}\t${SPEED}\t${SERIENNR}\t${SIZE} GB, ${NAME}"
                else
                        ### Das Betriebsystem erkennt Fehler, SMART jedoch nicht => Platte ist OK, vielleicht defekte Kabel?
                        echo -e "${TEMP}, ${BUS}:${MAGENTA}${DEV}${OFF}\t${SPEED}\t${MAGENTA}${SERIENNR}${OFF}\t${MAGENTA}${SIZE} GB${OFF}, ${MAGENTA}${NAME}${OFF}"
                        #echo -e "${TEMP}, ${BUS}:${CYAN}${DEV}${OFF}\t${SPEED}\t${CYAN}${SERIENNR}${OFF}\t${CYAN}${SIZE} GB${OFF}, ${CYAN}${NAME}${OFF}"
                fi
        else
                ### Das Betriebsystem und SMART erkennen Fehler => HDD ist defekt, austauschen!
                echo -e "${TEMP}, ${BUS}:${RED}${DEV}${OFF}\t${SPEED}\t${RED}${SERIENNR}${OFF}\t${RED}${SIZE} GB${OFF}, ${RED}${NAME}${OFF}"
        fi
done
