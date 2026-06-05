# Source WARP cert config if present (work machines only)
_warp_certs="$HOME/.local/share/cloudflare-warp-certs/config.sh"
[ -f "$_warp_certs" ] && . "$_warp_certs"
unset _warp_certs
