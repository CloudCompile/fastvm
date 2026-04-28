#!/bin/bash
# FastVM scheduled-task manager. Stores tasks as JSON in
# /config/.fastvm/tasks.json, then renders a crontab from them.
#
#     task-manager.sh list
#     task-manager.sh add  <id> <schedule> <command>
#     task-manager.sh enable  <id>
#     task-manager.sh disable <id>
#     task-manager.sh remove  <id>
#     task-manager.sh apply           # re-render crontab from JSON
#     task-manager.sh init            # install built-in defaults

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib-common.sh
source "${SCRIPT_DIR}/lib-common.sh"

ensure_dir "${FASTVM_DATA_ROOT}/.fastvm"
TASKS_FILE="${FASTVM_DATA_ROOT}/.fastvm/tasks.json"
[[ -f "$TASKS_FILE" ]] || echo '{"tasks":[]}' > "$TASKS_FILE"

require_jq() {
    command -v jq >/dev/null 2>&1 || { log_error "jq required"; exit 1; }
}

apply_crontab() {
    require_jq
    local cron_user="${FASTVM_CRON_USER:-abc}"
    local tmp; tmp=$(mktemp)
    {
        echo "# FastVM scheduled tasks (auto-generated; edit via task-manager.sh)"
        echo "SHELL=/bin/bash"
        echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
        jq -r '.tasks[] | select(.enabled==true) |
            "# " + .id + " :: " + (.description // "") + "\n" +
            .schedule + " " + .command + " >> /var/log/fastvm/cron-" + .id + ".log 2>&1"' \
            "$TASKS_FILE"
    } > "$tmp"
    if id "$cron_user" >/dev/null 2>&1; then
        crontab -u "$cron_user" "$tmp"
    else
        crontab "$tmp"
    fi
    rm -f "$tmp"
    log_success "Crontab updated for user ${cron_user}"
}

cmd_list() {
    require_jq
    if [[ "${1:-}" == "--json" ]]; then
        cat "$TASKS_FILE"
        return
    fi
    printf '%-20s  %-8s  %-20s  %s\n' "ID" "STATUS" "SCHEDULE" "COMMAND"
    jq -r '.tasks[] | [.id, (if .enabled then "enabled" else "disabled" end), .schedule, .command] | @tsv' \
        "$TASKS_FILE" | column -t -s $'\t'
}

cmd_add() {
    require_jq
    local id="$1" schedule="$2" command="${*:3}"
    local tmp; tmp=$(mktemp)
    jq --arg id "$id" --arg sched "$schedule" --arg cmd "$command" \
        '.tasks |= ([{id:$id, schedule:$sched, command:$cmd, enabled:true, created:now|floor}] + (. | map(select(.id != $id))))' \
        "$TASKS_FILE" > "$tmp"
    mv "$tmp" "$TASKS_FILE"
    log_success "Added task: $id ($schedule)"
    apply_crontab
}

cmd_set_enabled() {
    require_jq
    local id="$1" state="$2"
    local tmp; tmp=$(mktemp)
    jq --arg id "$id" --argjson en "$state" \
        '.tasks |= map(if .id == $id then .enabled=$en else . end)' \
        "$TASKS_FILE" > "$tmp"
    mv "$tmp" "$TASKS_FILE"
    apply_crontab
    log_success "Task $id $( [[ $state == true ]] && echo enabled || echo disabled )"
}

cmd_remove() {
    require_jq
    local id="$1"
    local tmp; tmp=$(mktemp)
    jq --arg id "$id" '.tasks |= map(select(.id != $id))' \
        "$TASKS_FILE" > "$tmp"
    mv "$tmp" "$TASKS_FILE"
    apply_crontab
    log_success "Task $id removed"
}

cmd_init() {
    cmd_add daily-backup    "0 2 * * *"  "/fastvm-scripts/backup-scheduler.sh"
    cmd_add hourly-prune    "30 * * * *" "find /config/.cache -mtime +7 -delete 2>/dev/null || true"
    log_success "Default tasks installed"
}

case "${1:-list}" in
    list)    shift; cmd_list "$@" ;;
    add)     shift; cmd_add "$@" ;;
    enable)  cmd_set_enabled "$2" true ;;
    disable) cmd_set_enabled "$2" false ;;
    remove)  cmd_remove "$2" ;;
    apply)   apply_crontab ;;
    init)    cmd_init ;;
    *) log_error "Unknown command: $1"; exit 1 ;;
esac
