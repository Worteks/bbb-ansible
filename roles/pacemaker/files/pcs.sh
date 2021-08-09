if test `id -u` = 0; then
    pcs status >&2 || true
fi
