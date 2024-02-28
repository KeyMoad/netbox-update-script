#!/bin/bash

LOGLEVEL='DEBUG'
declare -r GREEN=$'\033[0;32m'
declare -r YELLOW=$'\033[0;33m'
declare -r RED=$'\033[0;31m'
declare -r BLUE=$'\033[0;34m'
declare -r NC=$'\033[0m'


function log_output {
    echo -e $(date "+%Y/%m/%d %H:%M:%S")" $1"
}

function log_debug {
    if [[ "$LOGLEVEL" =~ ^(DEBUG)$ ]]; then
        log_output "${BLUE} [DEBUG] ${NC}$*"
    fi
}

function log_info {
    if [[ "$LOGLEVEL" =~ ^(DEBUG|INFO)$ ]]; then
        log_output "${GREEN} [INFO] ${NC}$*"
    fi
}

function log_warn {
    if [[ "$LOGLEVEL" =~ ^(DEBUG|INFO|WARN)$ ]]; then
        log_output "${YELLOW} [WARN] ${NC}$*"
    fi
}

function log_error {
    if [[ "$LOGLEVEL" =~ ^(DEBUG|INFO|WARN|ERROR)$ ]]; then
        log_output "${RED} [ERROR] ${NC}$*"
    fi
}


# Begining of the main procces
function help_usage {
    # Print the usage information for the script
    echo "Update NetBox Script"
    printf "Usage:\n %s \n\n" "$0 [option]"
    echo "Options:"
    printf "'--help'        '-h' \n %s \n\n" "       Show list of arguments and usage informations. No value needed."
    printf "'--version'      '-v' \n %s \n\n" "      If passed, It will Upgrade/Downgrade the NetBox to specific version."
}

function make_backup {
    log_info "Start to create backup from database"
    # Use creating backup script to make database backup
    bash /home/netbox/backup/script.sh

    # exit if anythings goes wrong
    if [[ $? -gt 0 ]]; then
        log_error "Somthings went wrong while trying to create backup"
        exit 1
    fi
}

function update_to {
    log_warn "Before starting make sure that you read Dependencies again"
    log_debug "https://github.com/netbox-community/netbox/blob/develop/docs/installation/upgrading.md#2-update-dependencies-to-required-versions"
    sleep 5

    PASSED_VERSION=$1

    # Create backup before everything
    make_backup

    # Enable exit if anythings gows wrong
    set -e

    # Change directory to NetBox directory
    cd /opt/netbox

    if [[ -z $PASSED_VERSION ]]; then
        log_debug "Try to pull latest changes"
        git checkout master
        git pull origin master
    else
        log_debug "Try to checkout to $PASSED_VERSION branch"
        git checkout "v""$PASSED_VERSION"
    fi

    log_debug "Running the upgrade script"
    ./upgrade.sh

    # Restarting the netbox services
    log_info "Restart the NetBox Services"
    systemctl restart netbox netbox-rq
    systemctl status netbox netbox-rq

    # Check if the Scheduling symlink is exists
    log_info "Verify Housekeeping Scheduling ..."
    if ls /etc/cron.daily/netbox-housekeeping > /dev/null 2>&1; then
        log_error "Somthings went wrong in updating"
        log_warn "The NetBox's housekeeping script is gone"
        log_debug "Please read => https://github.com/netbox-community/netbox/blob/develop/docs/administration/housekeeping.md"
        exit 1
    fi

    # Change directory to previous
    cd -

    # Disable exit if anythings gows wrong
    set +e
}

function check_passed_args {
    # Run update to latest if nothings passed
    if [[ $# == 0 ]]; then
        update_to
        exit 0
    fi

    # Check passed args
    while [[ $# -gt 0 ]]; do
        local PASSED_FLAG="$1"
        case $PASSED_FLAG in
            -h|--help)
                help_usage
                exit 0
                ;;
            -v|--version)
                VERSION="$2"
                if [[  -z $VERSION || $VERSION =~ ^(--help)$ || $VERSION =~ ^(-h)$ ]]; then
                    log_error "You should specify a version. Check help for more information. -h or --help"
                    exit 1
                fi
                # Update to the passed version
                update_to "$VERSION"
                shift
                shift
                ;;
            *)
                log_warn "Couldn't recognize passed arg ($PASSED_FLAG)"
                help_usage
                exit 1
                ;;
        esac
    done
}

function main {
    # Exit if passed arges are more than 2
    if [[ $# -gt 2 ]]; then
        log_warn "Too many arguments passed."
        help_usage
        exit 1
    fi

    # Passed the arguments to handle actions
    check_passed_args "$@"
}

# Run the script
main "$@"