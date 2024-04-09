#!/bin/bash
# CONFIGURATION
DB_USER="ubuntu" # root, debian, ubuntu, admin... 
DB_PASSWORD=""
DB_NAME="doly"
BACKUP_DIR="/home" # Path to save the SQL backup file
REMOTE_USER="root"
REMOTE_IP="codoly.fr" # Server IP domain name
REMOTE_DEST="/root/backups"
MYSQLDUMPPATH="mysqldump.exe" # Xampp Windows : C:/xampp/mysql/bin/mysqldump.exe

# UTILS
function loading() {
    local N=10
    local T=0.2
    for ((i = 0; i < N; i++)); do
        echo -n "."
        sleep $T
    done
    echo ""
}

function logger() {
    local msg="$1"
    local logType="$2"
    local color=""
    case "$logType" in
        "INFORMATION")
            color="\033[1;34m"
            ;;
        "SUCCESS")
            color="\033[1;32m"
            ;;
        "ERROR")
            color="\033[1;31m"
            ;;
        *)
            color="\033[0m"
            ;;
    esac
    echo -e "[$color$logType\033[0m] - [$(date +"%Y-%m-%d %H:%M:%S")] $msg"
}

# MAIN CODE EXECUTION
logger "Sauvegarde en cours..." "INFORMATION"
loading

current_datetime=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="$BACKUP_DIR/backup_$current_datetime.sql"

if [ -n "$DB_PASSWORD" ]; then
    mysqldump_command=("$MYSQLDUMPPATH" -u $DB_USER -p$DB_PASSWORD $DB_NAME)
else
    mysqldump_command=("$MYSQLDUMPPATH" -u $DB_USER $DB_NAME)
fi

"${mysqldump_command[@]}" > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    logger "La sauvegarde de la base de données $DB_NAME a réussi, en cours de transfert." "SUCCESS"
    loading
    scp "$BACKUP_FILE" $REMOTE_USER@$REMOTE_IP:$REMOTE_DEST
    if [ $? -eq 0 ]; then
        logger "La sauvegarde a été transférée avec succès vers $REMOTE_IP." "SUCCESS"
    else
        logger "Échec du transfert de la sauvegarde vers $REMOTE_IP." "ERROR"
        logger "Veuillez vérifier les paramètres de connexion SSH ou l'accessibilité du serveur distant." "INFORMATIONRMATION"
    fi
else
    logger "Échec de la sauvegarde de la base de données $DB_NAME." "ERROR"
    logger "Veuillez vérifier les paramètres de connexion MySQL ou assurez-vous que MySQL est installé et fonctionne correctement." "ERROR"
fi
