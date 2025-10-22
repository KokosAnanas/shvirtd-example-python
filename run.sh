set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/KokosAnanas/shvirtd-example-python.git}"
APP_DIR="/opt/shvirtd-example-python"
log(){ printf "[%(%F %T)T] %s\n" -1 "$*"; }
need(){ command -v "$1" >/dev/null 2>&1 || { log "ERROR: '$1' not found"; exit 1; }; }

main() {
  need git; need docker
  docker compose version >/dev/null 2>&1 || { log "ERROR: docker compose plugin not found"; exit 1; };
 if [[ ! -d "$APP_DIR/.git" ]]; then
    sudo mkdir -p /opt
    sudo chown "$(id -u)":"$(id -g)" /opt
    log "Cloning $REPO_URL -> $APP_DIR"
    git clone "$REPO_URL" "$APP_DIR"
  else
    log "Pull latest in $APP_DIR"
    git -C "$APP_DIR" pull --ff-only
  fi
ENV_FILE="$APP_DIR/.env"
  if [[ ! -f "$ENV_FILE" ]]; then
    log "Creating $ENV_FILE"
    cat > "$ENV_FILE" <<ENV
MYSQL_ROOT_PASSWORD=StrongRootPass123
MYSQL_DATABASE=appdb
MYSQL_USER=appuser
MYSQL_PASSWORD=AppUserPass123
ENV
chmod 600 "$ENV_FILE"
fi
cd "$APP_DIR"
if docker compose config >/dev/null 2>&1; then
  log "Starting with docker compose up -d --build"
  docker compose up -d --build
else
  log "Starting with docker compose -f compose.yaml -f proxy.yaml up -d --build"
  docker compose -f compose.yaml -f proxy.yaml up -d --build
fi

log "Status:"
docker compose ps || docker compose -f compose.yaml -f proxy.yaml ps
}
main "$@"
