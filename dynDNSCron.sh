#!/bin/bash
echo "[INFO] [DynDNSCron] Regenerating ACL.."
source /generateACL.sh
echo "[INFO] [DynDNSCron] ACL regenerated!"
echo "[INFO] [DynDNSCron] Reloading NginxDist ACl config"
/usr/bin/dog @127.0.0.1:5300 --short reload.acl.miniproxy.local
retVal=$?
if [ $retVal -eq 0 ]; then
  echo "[INFO] [DynDNSCron] NginxDist ACL config successfully reloaded!"
else
  echo "[ERROR] [DynDNSCron] Failed to reload NginxDist ACL config!"
fi


echo "[INFO] [DynDNSCron] reloading nginx..."
/usr/sbin/nginx -s reload
echo "[INFO] [DynDNSCron] nginx successfully reloaded"
