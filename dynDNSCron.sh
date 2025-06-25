#!/bin/bash
echo "[INFO] [DynDNSCron] Regenerating ACL.."

# Apply timeout to the generateACL.sh script (5 seconds or adjust as needed)
timeout 10s bash -c "source /generateACL.sh"
retVal=$?
if [ $retVal -eq 124 ]; then
  echo "[ERROR] [DynDNSCron] generateACL.sh timed out!"
elif [ $retVal -ne 0 ]; then
  echo "[ERROR] [DynDNSCron] generateACL.sh failed with exit code $retVal!"
else
  echo "[INFO] [DynDNSCron] ACL regenerated!"
fi

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
